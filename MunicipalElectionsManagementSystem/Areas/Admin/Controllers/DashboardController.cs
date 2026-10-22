
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Data;
using MunicipalElectionsManagementSystem.Models;
using MunicipalElectionsManagementSystem.Services;

namespace MunicipalElectionsManagementSystem.Areas.Admin.Controllers;

[Area("Admin")]
[Authorize(Policy = "AdminAccess")]
public class DashboardController : Controller
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly MunicipalityAuthorizationService _authorization;

    public DashboardController(
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
        var user = await _userManager.GetUserAsync(User);

        if (user == null)
        {
            return Challenge();
        }

        var municipalities = _context.Municipalities.AsQueryable();
        var positions = _context.Positions.AsQueryable();
        var candidates = _context.Candidates.AsQueryable();

        if (!_authorization.CanManageAllMunicipalities(User))
        {
            if (user.MunicipalityId == null ||
                !await _authorization.CanManageMunicipalityAsync(
                    User, user.MunicipalityId.Value))
            {
                return Forbid();
            }

            int municipalityId = user.MunicipalityId.Value;

            municipalities = municipalities.Where(
                m => m.MunicipalityId == municipalityId);

            positions = positions.Where(
                p => p.MunicipalityId == municipalityId);

            candidates = candidates.Where(
                c => c.Position.MunicipalityId == municipalityId);
        }

        ViewBag.MunicipalityCount = await municipalities.CountAsync();
        ViewBag.PositionCount = await positions.CountAsync();
        ViewBag.CandidateCount = await candidates.CountAsync();

        return View();
    }
}