
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Data;
using MunicipalElectionsManagementSystem.Models;
using MunicipalElectionsManagementSystem.Services;
using Microsoft.AspNetCore.Mvc.Rendering;
using MunicipalElectionsManagementSystem.ViewModels;

namespace MunicipalElectionsManagementSystem.Areas.Admin.Controllers;

[Area("Admin")]
[Authorize(Policy = "AdminAccess")]
public class PositionsController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly MunicipalityAuthorizationService _authorization;

    public PositionsController(
        ApplicationDbContext context,
        UserManager<ApplicationUser> userManager,
        MunicipalityAuthorizationService authorization)
    {
        _context = context;
        _userManager = userManager;
        _authorization = authorization;
    }

    public async Task<IActionResult> Index()
    {
        var positions = _context.Positions
            .Include(p => p.Municipality)
            .AsQueryable();

        if (!_authorization.CanManageAllMunicipalities(User))
        {
            var user = await _userManager.GetUserAsync(User);

            if (user?.MunicipalityId == null)
            {
                return Forbid();
            }

            if (!await _authorization.CanManageMunicipalityAsync(
                    User, user.MunicipalityId.Value))
            {
                return Forbid();
            }

            positions = positions.Where(
                p => p.MunicipalityId == user.MunicipalityId.Value);
        }

        return View(await positions
            .OrderBy(p => p.Municipality!.Name)
            .ThenBy(p => p.Name)
            .ToListAsync());
    }

    private async Task<bool> LoadMunicipalitiesAsync()
    {
        var municipalities = _context.Municipalities.AsQueryable();

        if (!_authorization.CanManageAllMunicipalities(User))
        {
            var user = await _userManager.GetUserAsync(User);

            if (user?.MunicipalityId == null ||
                !await _authorization.CanManageMunicipalityAsync(
                    User, user.MunicipalityId.Value))
            {
                return false;
            }

            municipalities = municipalities.Where(
                m => m.MunicipalityId == user.MunicipalityId.Value);
        }

        ViewBag.Municipalities = new SelectList(
            await municipalities.OrderBy(m => m.Name).ToListAsync(),
            "MunicipalityId",
            "Name");

        return true;
    }

    [HttpGet]
    public async Task<IActionResult> Create()
    {
        if (!await LoadMunicipalitiesAsync())
        {
            return Forbid();
        }

        var model = new PositionFormViewModel();

        if (!_authorization.CanManageAllMunicipalities(User))
        {
            var user = await _userManager.GetUserAsync(User);
            model.MunicipalityId = user!.MunicipalityId!.Value;
        }

        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(PositionFormViewModel model)
    {
        if (!ModelState.IsValid)
        {
            if (!await LoadMunicipalitiesAsync())
            {
                return Forbid();
            }

            return View(model);
        }

        if (!await _authorization.CanManageMunicipalityAsync(
            User, model.MunicipalityId))
        {
            return Forbid();
        }

        bool municipalityExists = await _context.Municipalities
            .AnyAsync(m => m.MunicipalityId == model.MunicipalityId);

        if (!municipalityExists)
        {
            ModelState.AddModelError(
                nameof(model.MunicipalityId),
                "The selected municipality does not exist.");

            if (!await LoadMunicipalitiesAsync())
            {
                return Forbid();
            }

            return View(model);
        }

        var position = new Position
        {
            Name = model.Name,
            SeatsAvailable = model.SeatsAvailable,
            MunicipalityId = model.MunicipalityId
        };

        _context.Positions.Add(position);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = "Position created successfully.";

        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Details(int id)
    {
        var position = await _context.Positions
            .Include(p => p.Municipality)
            .Include(p => p.Candidates)
            .FirstOrDefaultAsync(p => p.PositionId == id);

        if (position == null)
            return NotFound();

        if (!await _authorization.CanManageMunicipalityAsync(
            User, position.MunicipalityId))
            return Forbid();

        return View(position);
    }

    [HttpGet]
    public async Task<IActionResult> Edit(int id)
    {
        var position = await _context.Positions.FindAsync(id);

        if (position == null)
            return NotFound();

        if (!await _authorization.CanManageMunicipalityAsync(
            User, position.MunicipalityId))
            return Forbid();

        if (!await LoadMunicipalitiesAsync())
            return Forbid();

        var model = new PositionFormViewModel
        {
            Name = position.Name,
            SeatsAvailable = position.SeatsAvailable,
            MunicipalityId = position.MunicipalityId
        };

        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(
        int id,
        PositionFormViewModel model)
    {
        var position = await _context.Positions.FindAsync(id);

        if (position == null)
            return NotFound();

        //check access to the original municipality
        if (!await _authorization.CanManageMunicipalityAsync(
            User, position.MunicipalityId))
            return Forbid();

        //check access to the newly selected municipality
        if (!await _authorization.CanManageMunicipalityAsync(
            User, model.MunicipalityId))
            return Forbid();

        if (!await LoadMunicipalitiesAsync())
            return Forbid();

        if (!ModelState.IsValid)
            return View(model);

        bool municipalityExists = await _context.Municipalities
            .AnyAsync(m => m.MunicipalityId == model.MunicipalityId);

        if (!municipalityExists)
        {
            ModelState.AddModelError(
                nameof(model.MunicipalityId),
                "The selected municipality does not exist.");

            return View(model);
        }

        if (position.MunicipalityId != model.MunicipalityId &&
            await _context.Candidates.AnyAsync(
                c => c.PositionId == position.PositionId))
        {
            ModelState.AddModelError(
                nameof(model.MunicipalityId),
                "Cannot move a position that already has candidates.");

            return View(model);
        }

        position.Name = model.Name;
        position.SeatsAvailable = model.SeatsAvailable;
        position.MunicipalityId = model.MunicipalityId;

        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = "Position updated successfully.";

        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Delete(int id)
    {
        var position = await _context.Positions
            .Include(p => p.Municipality)
            .Include(p => p.Candidates)
            .FirstOrDefaultAsync(p => p.PositionId == id);

        if (position == null)
            return NotFound();

        if (!await _authorization.CanManageMunicipalityAsync(
            User, position.MunicipalityId))
            return Forbid();

        return View(position);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var position = await _context.Positions.FindAsync(id);

        if (position == null)
            return NotFound();

        if (!await _authorization.CanManageMunicipalityAsync(
            User, position.MunicipalityId))
            return Forbid();

        bool hasCandidates = await _context.Candidates
            .AnyAsync(c => c.PositionId == id);

        if (hasCandidates)
        {
            TempData["ErrorMessage"] =
                "Cannot delete a position that has candidates.";

            return RedirectToAction(nameof(Index));
        }

        _context.Positions.Remove(position);
        await _context.SaveChangesAsync();

        TempData["SuccessMessage"] = "Position deleted successfully.";

        return RedirectToAction(nameof(Index));
    }
}