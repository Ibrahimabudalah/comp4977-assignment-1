
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Data;
using MunicipalElectionsManagementSystem.Models;
using MunicipalElectionsManagementSystem.ViewModels;
using MunicipalElectionsManagementSystem.Services;

namespace MunicipalElectionsManagementSystem.Areas.Admin.Controllers;

[Area("Admin")]
[Authorize(Policy = "SuperAdminOnly")]
public class MunicipalitiesController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly ImageUploadService _imageUploadService;
    private readonly RoleManager<IdentityRole> _roleManager;

    public MunicipalitiesController(
        ApplicationDbContext context,
        ImageUploadService imageUploadService,
        RoleManager<IdentityRole> roleManager)
    {
        _context = context;
        _imageUploadService = imageUploadService;
        _roleManager = roleManager;
    }

    public async Task<IActionResult> Index()
    {
        var municipalities = await _context.Municipalities
            .OrderBy(m => m.Name)
            .ToListAsync();

        return View(municipalities);
    }

    [HttpGet]
    public IActionResult Create()
    {
        return View(new MunicipalityFormViewModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(
    MunicipalityFormViewModel model)
    {
        await ValidateUniqueNameAsync(model.Name, null);

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        string? logoFileName = null;

        try
        {
            logoFileName = await _imageUploadService.SaveImageAsync(
                model.Logo, "municipalities");
        }
        catch (ArgumentException ex)
        {
            ModelState.AddModelError(nameof(model.Logo), ex.Message);
            return View(model);
        }

        var municipality = new Municipality
        {
            Name = model.Name,
            Province = model.Province,
            ElectionDate = model.ElectionDate,
            Description = model.Description,
            LogoFileName = logoFileName
        };

        try
        {
            _context.Municipalities.Add(municipality);
            await _context.SaveChangesAsync();
        }
        catch
        {
            _imageUploadService.DeleteImage(
                logoFileName, "municipalities");
            throw;
        }

        //each municipality gets its own admin group
        var roleName = AdminRoles.ForMunicipality(municipality.Name);

        if (!await _roleManager.RoleExistsAsync(roleName))
        {
            await _roleManager.CreateAsync(new IdentityRole(roleName));
        }

        TempData["SuccessMessage"] =
            $"Municipality created successfully with admin group \"{roleName}\".";

        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Details(int id)
    {
        var municipality = await _context.Municipalities
            .Include(m => m.Positions)
            .FirstOrDefaultAsync(m => m.MunicipalityId == id);

        if (municipality == null)
        {
            return NotFound();
        }

        return View(municipality);
    }

    [HttpGet]
    public async Task<IActionResult> Edit(int id)
    {
        var municipality = await _context.Municipalities.FindAsync(id);

        if (municipality == null)
        {
            return NotFound();
        }

        var model = new MunicipalityFormViewModel
        {
            Name = municipality.Name,
            Province = municipality.Province,
            ElectionDate = municipality.ElectionDate,
            Description = municipality.Description,
            ExistingLogoFileName = municipality.LogoFileName
        };

        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(
    int id,
    MunicipalityFormViewModel model)
    {
        var municipality = await _context.Municipalities.FindAsync(id);

        if (municipality == null)
        {
            return NotFound();
        }

        model.ExistingLogoFileName = municipality.LogoFileName;

        await ValidateUniqueNameAsync(model.Name, id);

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        string? newLogoFileName = null;

        try
        {
            newLogoFileName = await _imageUploadService.SaveImageAsync(
                model.Logo, "municipalities");
        }
        catch (ArgumentException ex)
        {
            ModelState.AddModelError(nameof(model.Logo), ex.Message);
            return View(model);
        }

        var oldLogoFileName = municipality.LogoFileName;
        var oldRoleName = AdminRoles.ForMunicipality(municipality.Name);

        municipality.Name = model.Name;
        municipality.Province = model.Province;
        municipality.ElectionDate = model.ElectionDate;
        municipality.Description = model.Description;

        if (newLogoFileName != null)
        {
            municipality.LogoFileName = newLogoFileName;
        }

        try
        {
            await _context.SaveChangesAsync();
        }
        catch
        {
            _imageUploadService.DeleteImage(
                newLogoFileName, "municipalities");
            throw;
        }

        if (newLogoFileName != null)
        {
            _imageUploadService.DeleteImage(
                oldLogoFileName, "municipalities");
        }

        //keep the admin group name in step with the municipality name;
        //members keep their access because the role id does not change
        var newRoleName = AdminRoles.ForMunicipality(municipality.Name);
        var role = await _roleManager.FindByNameAsync(oldRoleName);

        if (role == null)
        {
            await _roleManager.CreateAsync(new IdentityRole(newRoleName));
        }
        else if (oldRoleName != newRoleName)
        {
            await _roleManager.SetRoleNameAsync(role, newRoleName);
            await _roleManager.UpdateAsync(role);
        }

        TempData["SuccessMessage"] =
            "Municipality updated successfully.";

        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Delete(int id)
    {
        var municipality = await _context.Municipalities
            .Include(m => m.Positions)
            .FirstOrDefaultAsync(m => m.MunicipalityId == id);

        if (municipality == null)
        {
            return NotFound();
        }

        return View(municipality);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var municipality = await _context.Municipalities
            .Include(m => m.Positions)
            .FirstOrDefaultAsync(m => m.MunicipalityId == id);

        if (municipality == null)
        {
            return NotFound();
        }

        if (municipality.Positions.Any())
        {
            TempData["ErrorMessage"] =
                "Cannot delete a municipality that has positions.";

            return RedirectToAction(nameof(Index));
        }

        bool hasAdmins = await _context.Users
            .AnyAsync(u => u.MunicipalityId == id);

        if (hasAdmins)
        {
            TempData["ErrorMessage"] =
                "Cannot delete a municipality that has assigned administrators.";

            return RedirectToAction(nameof(Index));
        }

        _context.Municipalities.Remove(municipality);
        await _context.SaveChangesAsync();

        var role = await _roleManager.FindByNameAsync(
            AdminRoles.ForMunicipality(municipality.Name));

        if (role != null)
        {
            await _roleManager.DeleteAsync(role);
        }

        _imageUploadService.DeleteImage(
    municipality.LogoFileName, "municipalities");

        TempData["SuccessMessage"] = "Municipality deleted successfully.";

        return RedirectToAction(nameof(Index));
    }

    //municipality names must be unique because each one names an admin group;
    //Identity matches role names case-insensitively, so this check does too
    private async Task ValidateUniqueNameAsync(string name, int? excludeId)
    {
        var normalized = name.Trim().ToUpper();

        bool exists = await _context.Municipalities.AnyAsync(m =>
            m.Name.ToUpper() == normalized && m.MunicipalityId != excludeId);

        if (exists)
        {
            ModelState.AddModelError(nameof(MunicipalityFormViewModel.Name),
                "A municipality with this name already exists.");
        }
    }
}
