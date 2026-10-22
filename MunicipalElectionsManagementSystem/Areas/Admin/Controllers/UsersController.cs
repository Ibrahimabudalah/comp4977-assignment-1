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

//Super Admin manages admin accounts and which admin group each belongs to
[Area("Admin")]
[Authorize(Policy = "SuperAdminOnly")]
public class UsersController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly RoleManager<IdentityRole> _roleManager;
    private readonly SignInManager<ApplicationUser> _signInManager;

    public UsersController(
        ApplicationDbContext context,
        UserManager<ApplicationUser> userManager,
        RoleManager<IdentityRole> roleManager,
        SignInManager<ApplicationUser> signInManager)
    {
        _context = context;
        _userManager = userManager;
        _roleManager = roleManager;
        _signInManager = signInManager;
    }

    public async Task<IActionResult> Index()
    {
        var users = await _context.Users
            .Include(u => u.Municipality)
            .OrderBy(u => u.UserName)
            .ToListAsync();

        var userRoles = new Dictionary<string, IList<string>>();

        foreach (var user in users)
        {
            userRoles[user.Id] = await _userManager.GetRolesAsync(user);
        }

        var roleCounts = new Dictionary<string, int>();

        foreach (var role in await _roleManager.Roles.OrderBy(r => r.Name).ToListAsync())
        {
            roleCounts[role.Name!] = (await _userManager.GetUsersInRoleAsync(role.Name!)).Count;
        }

        ViewBag.UserRoles = userRoles;
        ViewBag.RoleCounts = roleCounts;

        return View(users);
    }

    [HttpGet]
    public async Task<IActionResult> Create()
    {
        await LoadMunicipalitiesAsync(null);
        return View(new UserFormViewModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(UserFormViewModel model)
    {
        if (string.IsNullOrEmpty(model.Password))
        {
            ModelState.AddModelError(nameof(model.Password), "Password is required.");
        }

        var municipality = await ValidateMunicipalityAsync(model.MunicipalityId);

        if (!ModelState.IsValid)
        {
            await LoadMunicipalitiesAsync(model.MunicipalityId);
            return View(model);
        }

        var user = new ApplicationUser
        {
            UserName = model.UserName.Trim(),
            MunicipalityId = municipality?.MunicipalityId
        };

        var result = await _userManager.CreateAsync(user, model.Password!);

        if (result.Succeeded)
        {
            result = await _userManager.AddToRoleAsync(user, await GetRoleNameAsync(municipality));

            //do not leave an account without an admin group behind
            if (!result.Succeeded)
            {
                await _userManager.DeleteAsync(user);
            }
        }

        if (!result.Succeeded)
        {
            AddErrors(result);
            await LoadMunicipalitiesAsync(model.MunicipalityId);
            return View(model);
        }

        TempData["SuccessMessage"] = $"Administrator \"{user.UserName}\" created.";
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Edit(string id)
    {
        var user = await _userManager.FindByIdAsync(id);

        if (user == null)
        {
            return NotFound();
        }

        var isSuperAdmin = await _userManager.IsInRoleAsync(user, AdminRoles.SuperAdmin);

        var model = new UserFormViewModel
        {
            Id = user.Id,
            UserName = user.UserName ?? string.Empty,
            MunicipalityId = isSuperAdmin ? null : user.MunicipalityId
        };

        await LoadMunicipalitiesAsync(model.MunicipalityId);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(string id, UserFormViewModel model)
    {
        var user = await _userManager.FindByIdAsync(id);

        if (user == null)
        {
            return NotFound();
        }

        model.Id = id;

        var municipality = await ValidateMunicipalityAsync(model.MunicipalityId);

        //prevent a Super Admin from locking themselves out
        if (user.Id == _userManager.GetUserId(User) && municipality != null)
        {
            ModelState.AddModelError(nameof(model.MunicipalityId),
                "You cannot remove your own Super Admin access.");
        }

        if (!ModelState.IsValid)
        {
            await LoadMunicipalitiesAsync(model.MunicipalityId);
            return View(model);
        }

        var result = await _userManager.SetUserNameAsync(user, model.UserName.Trim());

        if (result.Succeeded && !string.IsNullOrEmpty(model.Password))
        {
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            result = await _userManager.ResetPasswordAsync(user, token, model.Password);
        }

        if (result.Succeeded)
        {
            result = await SetAdminGroupAsync(user, municipality);
        }

        if (!result.Succeeded)
        {
            AddErrors(result);
            await LoadMunicipalitiesAsync(model.MunicipalityId);
            return View(model);
        }

        //the security stamp changed, so re-issue the current admin's own cookie
        if (user.Id == _userManager.GetUserId(User))
        {
            await _signInManager.RefreshSignInAsync(user);
        }

        TempData["SuccessMessage"] = $"Administrator \"{user.UserName}\" updated.";
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Delete(string id)
    {
        var user = await _context.Users
            .Include(u => u.Municipality)
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound();
        }

        ViewBag.Roles = await _userManager.GetRolesAsync(user);
        return View(user);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(string id)
    {
        var user = await _userManager.FindByIdAsync(id);

        if (user == null)
        {
            return NotFound();
        }

        if (user.Id == _userManager.GetUserId(User))
        {
            TempData["ErrorMessage"] = "You cannot delete your own account.";
            return RedirectToAction(nameof(Index));
        }

        var result = await _userManager.DeleteAsync(user);

        TempData[result.Succeeded ? "SuccessMessage" : "ErrorMessage"] = result.Succeeded
            ? $"Administrator \"{user.UserName}\" deleted."
            : string.Join(" ", result.Errors.Select(e => e.Description));

        return RedirectToAction(nameof(Index));
    }

    //replace the user's admin group with Super Admin or one municipality's group
    private async Task<IdentityResult> SetAdminGroupAsync(
        ApplicationUser user,
        Municipality? municipality)
    {
        var result = await _userManager.RemoveFromRolesAsync(
            user, await _userManager.GetRolesAsync(user));

        if (!result.Succeeded)
        {
            return result;
        }

        result = await _userManager.AddToRoleAsync(user, await GetRoleNameAsync(municipality));

        if (!result.Succeeded)
        {
            return result;
        }

        user.MunicipalityId = municipality?.MunicipalityId;
        await _userManager.UpdateAsync(user);

        //signs the user out of other sessions at the next cookie check
        return await _userManager.UpdateSecurityStampAsync(user);
    }

    //returns the group name, creating a municipality group if it is missing
    private async Task<string> GetRoleNameAsync(Municipality? municipality)
    {
        if (municipality == null)
        {
            return AdminRoles.SuperAdmin;
        }

        var roleName = AdminRoles.ForMunicipality(municipality.Name);

        if (!await _roleManager.RoleExistsAsync(roleName))
        {
            await _roleManager.CreateAsync(new IdentityRole(roleName));
        }

        return roleName;
    }

    private async Task<Municipality?> ValidateMunicipalityAsync(int? municipalityId)
    {
        if (municipalityId == null)
        {
            return null;
        }

        var municipality = await _context.Municipalities.FindAsync(municipalityId);

        if (municipality == null)
        {
            ModelState.AddModelError(nameof(UserFormViewModel.MunicipalityId),
                "Please select a valid municipality.");
        }

        return municipality;
    }

    private async Task LoadMunicipalitiesAsync(int? selectedId)
    {
        var municipalities = await _context.Municipalities.OrderBy(m => m.Name).ToListAsync();
        ViewBag.Municipalities = municipalities.Select(m => new SelectListItem(
            AdminRoles.ForMunicipality(m.Name), m.MunicipalityId.ToString(), m.MunicipalityId == selectedId)).ToList();
    }

    private void AddErrors(IdentityResult result)
    {
        foreach (var error in result.Errors)
        {
            ModelState.AddModelError(string.Empty, error.Description);
        }
    }
}
