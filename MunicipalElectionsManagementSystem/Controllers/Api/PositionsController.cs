using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Data;
using MunicipalElectionsManagementSystem.Dtos;

namespace MunicipalElectionsManagementSystem.Controllers.Api;

[ApiController]
[Route("api/positions")]
public class PositionsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public PositionsController(ApplicationDbContext context)
    {
        _context = context;
    }

    //GET /api/positions?municipalityId=
    [HttpGet]
    public async Task<ActionResult<List<PositionDto>>> GetAll(int? municipalityId)
    {
        var positions = _context.Positions
            .AsNoTracking()
            .Include(p => p.Municipality)
            .AsQueryable();

        if (municipalityId.HasValue)
        {
            positions = positions.Where(p => p.MunicipalityId == municipalityId);
        }

        var result = await positions
            .OrderBy(p => p.Municipality.Name)
            .ThenBy(p => p.Name)
            .ToListAsync();

        return result.Select(p => p.ToDto()).ToList();
    }

    //GET /api/positions/{id}
    [HttpGet("{id:int}")]
    public async Task<ActionResult<PositionDto>> Get(int id)
    {
        var position = await _context.Positions
            .AsNoTracking()
            .Include(p => p.Municipality)
            .FirstOrDefaultAsync(p => p.PositionId == id);

        if (position == null)
        {
            return NotFound();
        }

        return position.ToDto();
    }
}
