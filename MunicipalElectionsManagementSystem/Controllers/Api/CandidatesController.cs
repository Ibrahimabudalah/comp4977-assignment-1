using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Data;
using MunicipalElectionsManagementSystem.Dtos;
using MunicipalElectionsManagementSystem.Models;

namespace MunicipalElectionsManagementSystem.Controllers.Api;

[ApiController]
[Route("api/candidates")]
public class CandidatesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CandidatesController(ApplicationDbContext context)
    {
        _context = context;
    }

    //GET /api/candidates?municipalityId=&positionId=
    //municipalityId is required (400 without it) so one city's data never leaks into another's
    [HttpGet]
    public async Task<ActionResult<List<CandidateDto>>> GetAll(
        [BindRequired] int municipalityId, int? positionId)
    {
        var candidates = WithPosition()
            .Where(c => c.Position.MunicipalityId == municipalityId);

        if (positionId.HasValue)
        {
            candidates = candidates.Where(c => c.PositionId == positionId);
        }

        return await ToDtosAsync(candidates);
    }

    //GET /api/candidates/search?municipalityId=&name=
    [HttpGet("search")]
    public async Task<ActionResult<List<CandidateDto>>> Search(
        [BindRequired] int municipalityId, string? name)
    {
        var candidates = WithPosition()
            .Where(c => c.Position.MunicipalityId == municipalityId);

        //LIKE is case-insensitive in SQLite; a blank name returns everyone, like the list
        if (!string.IsNullOrWhiteSpace(name))
        {
            candidates = candidates.Where(c =>
                EF.Functions.Like(c.Name, $"%{name.Trim()}%"));
        }

        return await ToDtosAsync(candidates);
    }

    //GET /api/candidates/{id}
    [HttpGet("{id:int}")]
    public async Task<ActionResult<CandidateDto>> Get(int id)
    {
        var candidate = await WithPosition()
            .FirstOrDefaultAsync(c => c.CandidateId == id);

        if (candidate == null)
        {
            return NotFound();
        }

        return candidate.ToDto(Request);
    }

    private IQueryable<Candidate> WithPosition() =>
        _context.Candidates
            .AsNoTracking()
            .Include(c => c.Position)
                .ThenInclude(p => p.Municipality);

    private async Task<List<CandidateDto>> ToDtosAsync(IQueryable<Candidate> candidates)
    {
        var result = await candidates
            .OrderBy(c => c.Name)
            .ToListAsync();

        return result.Select(c => c.ToDto(Request)).ToList();
    }
}
