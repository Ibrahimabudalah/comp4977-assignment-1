
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Data;
using MunicipalElectionsManagementSystem.Models;
using MunicipalElectionsManagementSystem.Services;
using MunicipalElectionsManagementSystem.ViewModels;

namespace MunicipalElectionsManagementSystem.Areas.Admin.Controllers;

[Area("Admin")]
[Authorize(Policy = "AdminAccess")]
public class CandidatesController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly MunicipalityAuthorizationService _authorization;
    private readonly ImageUploadService _imageUploadService;

    public CandidatesController(
        ApplicationDbContext context,
        UserManager<ApplicationUser> userManager,
        MunicipalityAuthorizationService authorization,
        ImageUploadService imageUploadService)
    {
        _context = context;
        _userManager = userManager;
        _authorization = authorization;
        _imageUploadService = imageUploadService;
    }

    public async Task<IActionResult> Index()
    {
        var candidates = _context.Candidates
            .Include(c => c.Position)
            .ThenInclude(p => p!.Municipality)
            .AsQueryable();

        if (!_authorization.CanManageAllMunicipalities(User))
        {
            var user = await _userManager.GetUserAsync(User);

            if (user?.MunicipalityId == null ||
                !await _authorization.CanManageMunicipalityAsync(
                    User, user.MunicipalityId.Value))
            {
                return Forbid();
            }

            candidates = candidates.Where(
                c => c.Position.MunicipalityId ==
                     user.MunicipalityId.Value);
        }

        return View(await candidates
            .OrderBy(c => c.Name)
            .ToListAsync());
    }

    private async Task<bool> LoadPositionsAsync()
    {
        var positions = _context.Positions
            .Include(p => p.Municipality)
            .AsQueryable();

        if (!_authorization.CanManageAllMunicipalities(User))
        {
            var user = await _userManager.GetUserAsync(User);

            if (user?.MunicipalityId == null ||
                !await _authorization.CanManageMunicipalityAsync(
                    User, user.MunicipalityId.Value))
            {
                return false;
            }

            positions = positions.Where(
                p => p.MunicipalityId == user.MunicipalityId.Value);
        }

        var availablePositions = await positions
            .OrderBy(p => p.Municipality!.Name)
            .ThenBy(p => p.Name)
            .ToListAsync();

        ViewBag.Positions = new SelectList(
            availablePositions.Select(p => new
            {
                p.PositionId,
                DisplayName = $"{p.Municipality!.Name} - {p.Name}"
            }),
            "PositionId",
            "DisplayName");

        return true;
    }

    [HttpGet]
    public async Task<IActionResult> Create()
    {
        if (!await LoadPositionsAsync())
        {
            return Forbid();
        }

        return View(new CandidateFormViewModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CandidateFormViewModel model)
    {
        if (!await LoadPositionsAsync())
        {
            return Forbid();
        }

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        //find the position and its municipality
        var position = await _context.Positions
            .FirstOrDefaultAsync(p => p.PositionId == model.PositionId);

        if (position == null)
        {
            ModelState.AddModelError(
                nameof(model.PositionId),
                "The selected position does not exist.");

            return View(model);
        }

        if (!await _authorization.CanManageMunicipalityAsync(
            User, position.MunicipalityId))
        {
            return Forbid();
        }

        string? photoFileName = null;

        try
        {
            photoFileName = await _imageUploadService.SaveImageAsync(
                model.Photo, "candidates");
        }
        catch (ArgumentException ex)
        {
            ModelState.AddModelError(
                nameof(model.Photo),
                ex.Message);

            return View(model);
        }

        var candidate = new Candidate
        {
            Name = model.Name,
            Profile = model.Profile,
            Website = model.Website,
            Email = model.Email,
            PositionId = model.PositionId,
            PhotoFileName = photoFileName,
            DateCreated = DateTime.UtcNow
        };

        try
        {
            _context.Candidates.Add(candidate);
            await _context.SaveChangesAsync();
        }
        catch
        {
            //remove uploaded photo if saving fails
            _imageUploadService.DeleteImage(
                photoFileName, "candidates");

            throw;
        }

        TempData["SuccessMessage"] =
            "Candidate created successfully.";

        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Details(int id)
    {
        var candidate = await _context.Candidates
            .Include(c => c.Position)
            .ThenInclude(p => p!.Municipality)
            .FirstOrDefaultAsync(c => c.CandidateId == id);

        if (candidate == null)
        {
            return NotFound();
        }

        if (!await _authorization.CanManageMunicipalityAsync(
            User, candidate.Position.MunicipalityId))
        {
            return Forbid();
        }

        return View(candidate);
    }

    [HttpGet]
    public async Task<IActionResult> Edit(int id)
    {
        var candidate = await _context.Candidates
            .Include(c => c.Position)
            .FirstOrDefaultAsync(c => c.CandidateId == id);

        if (candidate == null)
        {
            return NotFound();
        }

        if (!await _authorization.CanManageMunicipalityAsync(
            User, candidate.Position.MunicipalityId))
        {
            return Forbid();
        }

        if (!await LoadPositionsAsync())
        {
            return Forbid();
        }

        var model = new CandidateFormViewModel
        {
            Name = candidate.Name,
            Profile = candidate.Profile,
            Website = candidate.Website,
            Email = candidate.Email,
            PositionId = candidate.PositionId,
            ExistingPhotoFileName = candidate.PhotoFileName
        };

        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(
        int id,
        CandidateFormViewModel model)
    {
        var candidate = await _context.Candidates
            .Include(c => c.Position)
            .FirstOrDefaultAsync(c => c.CandidateId == id);

        if (candidate == null)
        {
            return NotFound();
        }

        if (!await _authorization.CanManageMunicipalityAsync(
            User, candidate.Position.MunicipalityId))
        {
            return Forbid();
        }

        if (!await LoadPositionsAsync())
        {
            return Forbid();
        }

        model.ExistingPhotoFileName = candidate.PhotoFileName;

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var newPosition = await _context.Positions
            .FirstOrDefaultAsync(p => p.PositionId == model.PositionId);

        if (newPosition == null)
        {
            ModelState.AddModelError(
                nameof(model.PositionId),
                "The selected position does not exist.");

            return View(model);
        }

        //check access to the new selected municipality
        if (!await _authorization.CanManageMunicipalityAsync(
            User, newPosition.MunicipalityId))
        {
            return Forbid();
        }

        string? newPhotoFileName = null;

        try
        {
            newPhotoFileName = await _imageUploadService.SaveImageAsync(
                model.Photo, "candidates");
        }
        catch (ArgumentException ex)
        {
            ModelState.AddModelError(
                nameof(model.Photo),
                ex.Message);

            return View(model);
        }

        var oldPhotoFileName = candidate.PhotoFileName;

        candidate.Name = model.Name;
        candidate.Profile = model.Profile;
        candidate.Website = model.Website;
        candidate.Email = model.Email;
        candidate.PositionId = model.PositionId;

        if (newPhotoFileName != null)
        {
            candidate.PhotoFileName = newPhotoFileName;
        }

        try
        {
            await _context.SaveChangesAsync();
        }
        catch
        {
            _imageUploadService.DeleteImage(
                newPhotoFileName, "candidates");

            throw;
        }

        if (newPhotoFileName != null)
        {
            _imageUploadService.DeleteImage(
                oldPhotoFileName, "candidates");
        }

        TempData["SuccessMessage"] =
            "Candidate updated successfully.";

        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Delete(int id)
    {
        var candidate = await _context.Candidates
            .Include(c => c.Position)
            .ThenInclude(p => p!.Municipality)
            .FirstOrDefaultAsync(c => c.CandidateId == id);

        if (candidate == null)
        {
            return NotFound();
        }

        if (!await _authorization.CanManageMunicipalityAsync(
            User, candidate.Position.MunicipalityId))
        {
            return Forbid();
        }

        return View(candidate);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var candidate = await _context.Candidates
            .Include(c => c.Position)
            .FirstOrDefaultAsync(c => c.CandidateId == id);

        if (candidate == null)
        {
            return NotFound();
        }

        if (!await _authorization.CanManageMunicipalityAsync(
            User, candidate.Position.MunicipalityId))
        {
            return Forbid();
        }

        var photoFileName = candidate.PhotoFileName;

        _context.Candidates.Remove(candidate);
        await _context.SaveChangesAsync();

        //remove the photo only after database deletion succeeds
        _imageUploadService.DeleteImage(
            photoFileName, "candidates");

        TempData["SuccessMessage"] =
            "Candidate deleted successfully.";

        return RedirectToAction(nameof(Index));
    }
}