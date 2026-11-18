using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
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
    //municipalityId is required (400 without it) so one city's data never leaks into another's
    [HttpGet]
    public async Task<ActionResult<List<PositionDto>>> GetAll([BindRequired] int municipalityId)
    {
        var result = await _context.Positions
            .AsNoTracking()
            .Include(p => p.Municipality)
            .Where(p => p.MunicipalityId == municipalityId)
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
