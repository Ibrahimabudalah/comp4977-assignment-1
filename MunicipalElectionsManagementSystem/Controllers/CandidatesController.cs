using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Data;

namespace MunicipalElectionsManagementSystem.Controllers;

//public candidate directory with search and filters
public class CandidatesController : Controller
{
    private readonly ApplicationDbContext _context;

    public CandidatesController(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<IActionResult> Index(
        string? search, int? municipalityId, string? position)
    {
        var candidates = _context.Candidates
            .AsNoTracking()
            .Include(c => c.Position)
                .ThenInclude(p => p.Municipality)
            .AsQueryable();

        //LIKE is case-insensitive in SQLite
        if (!string.IsNullOrWhiteSpace(search))
        {
            candidates = candidates.Where(c =>
                EF.Functions.Like(c.Name, $"%{search.Trim()}%"));
        }

        if (municipalityId.HasValue)
        {
            candidates = candidates.Where(c =>
                c.Position.MunicipalityId == municipalityId);
        }

        //filter by position name so "Mayor" matches every municipality
        if (!string.IsNullOrWhiteSpace(position))
        {
            candidates = candidates.Where(c =>
                c.Position.Name == position);
        }

        ViewData["Search"] = search;

        ViewData["Municipalities"] = new SelectList(
            await _context.Municipalities
                .OrderBy(m => m.Name)
                .ToListAsync(),
            "MunicipalityId", "Name", municipalityId);

        ViewData["Positions"] = new SelectList(
            await _context.Positions
                .Select(p => p.Name)
                .Distinct()
                .OrderBy(n => n)
                .ToListAsync(),
            position);

        return View(await candidates
            .OrderBy(c => c.Name)
            .ToListAsync());
    }

    public async Task<IActionResult> Details(int id)
    {
        var candidate = await _context.Candidates
            .AsNoTracking()
            .Include(c => c.Position)
                .ThenInclude(p => p.Municipality)
            .FirstOrDefaultAsync(c => c.CandidateId == id);

        if (candidate == null)
        {
            return NotFound();
        }

        return View(candidate);
    }

    public async Task<IActionResult> Compare(int[] ids)
    {
        ids = ids.Distinct().ToArray();

        if (ids.Length < 2 || ids.Length > 3)
        {
            TempData["ErrorMessage"] = "Select 2 or 3 candidates to compare.";
            return RedirectToAction(nameof(Index));
        }

        var candidates = await _context.Candidates
            .AsNoTracking()
            .Include(c => c.Position)
                .ThenInclude(p => p.Municipality)
            .Where(c => ids.Contains(c.CandidateId))
            .ToListAsync();

        if (candidates.Count != ids.Length)
        {
            return NotFound();
        }

        //SQL IN does not keep order, so match the order of the ids in the URL
        return View(ids.Select(id => candidates.First(c => c.CandidateId == id)).ToList());
    }
}
