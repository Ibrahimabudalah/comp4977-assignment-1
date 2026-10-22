
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using MunicipalElectionsManagementSystem.Data;
using MunicipalElectionsManagementSystem.Models;

namespace MunicipalElectionsManagementSystem.Services;

public class MunicipalityAuthorizationService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ApplicationDbContext _context;

    public MunicipalityAuthorizationService(
        UserManager<ApplicationUser> userManager,
        ApplicationDbContext context)
    {
        _userManager = userManager;
        _context = context;
    }

    public async Task<bool> CanManageMunicipalityAsync(
        ClaimsPrincipal principal,
        int municipalityId)
    {
        if (principal.Identity?.IsAuthenticated != true)
        {
            return false;
        }

        var user = await _userManager.GetUserAsync(principal);

        if (user == null)
        {
            return false;
        }

        if (await _userManager.IsInRoleAsync(user, AdminRoles.SuperAdmin))
        {
            return true;
        }

        if (user.MunicipalityId != municipalityId)
        {
            return false;
        }

        //a municipality admin must be assigned to the municipality
        //and be a member of that municipality's admin group
        var municipality = await _context.Municipalities.FindAsync(municipalityId);

        return municipality != null && await _userManager.IsInRoleAsync(
            user, AdminRoles.ForMunicipality(municipality.Name));
    }

    public bool CanManageAllMunicipalities(
        ClaimsPrincipal principal)
    {
        return principal.Identity?.IsAuthenticated == true
            && principal.IsInRole(AdminRoles.SuperAdmin);
    }
}
