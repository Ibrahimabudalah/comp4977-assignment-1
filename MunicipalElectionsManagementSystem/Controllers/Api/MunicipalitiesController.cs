using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Data;
using MunicipalElectionsManagementSystem.Dtos;

namespace MunicipalElectionsManagementSystem.Controllers.Api;

[ApiController]
[Route("api/municipalities")]
public class MunicipalitiesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public MunicipalitiesController(ApplicationDbContext context)
    {
        _context = context;
    }

    //GET /api/municipalities
    [HttpGet]
    public async Task<ActionResult<List<MunicipalityDto>>> GetAll()
    {
        var municipalities = await _context.Municipalities
            .AsNoTracking()
            .OrderBy(m => m.Name)
            .ToListAsync();

        return municipalities.Select(m => m.ToDto(Request)).ToList();
    }

    //GET /api/municipalities/{id}
    [HttpGet("{id:int}")]
    public async Task<ActionResult<MunicipalityDto>> Get(int id)
    {
        var municipality = await _context.Municipalities
            .AsNoTracking()
            .Include(m => m.Positions)
            .FirstOrDefaultAsync(m => m.MunicipalityId == id);

        if (municipality == null)
        {
            return NotFound();
        }

        return municipality.ToDto(Request, includePositions: true);
    }
}
