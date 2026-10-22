using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Data;

namespace MunicipalElectionsManagementSystem.Controllers;

//public, read-only municipality pages
public class MunicipalitiesController : Controller
{
    private readonly ApplicationDbContext _context;

    public MunicipalitiesController(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IActionResult> Index()
    {
        var municipalities = await _context.Municipalities
            .AsNoTracking()
            .OrderBy(m => m.Name)
            .ToListAsync();

        return View(municipalities);
    }

    public async Task<IActionResult> Details(int id)
    {
        var municipality = await _context.Municipalities
            .AsNoTracking()
            .Include(m => m.Positions)
                .ThenInclude(p => p.Candidates)
            .FirstOrDefaultAsync(m => m.MunicipalityId == id);

        if (municipality == null)
        {
            return NotFound();
        }

        return View(municipality);
    }
}
