using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Data;
using MunicipalElectionsManagementSystem.Dtos;
using MunicipalElectionsManagementSystem.Models;

namespace MunicipalElectionsManagementSystem.Controllers.Api;

//the signed-in user's voting guide; the user always comes from the token, never the request
[ApiController]
[Route("api/savedcandidates")]
[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
public class SavedCandidatesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public SavedCandidatesController(ApplicationDbContext context)
    {
        _context = context;
    }

    //GET /api/savedcandidates
    [HttpGet]
    public async Task<ActionResult<List<SavedCandidateDto>>> GetAll()
    {
        var userId = await GetCurrentUserIdAsync();

        if (userId == null)
        {
            return Unauthorized();
        }

        var saved = await _context.SavedCandidates
            .AsNoTracking()
            .Include(s => s.Candidate)
                .ThenInclude(c => c.Position)
                    .ThenInclude(p => p.Municipality)
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.DateSaved)
                .ThenByDescending(s => s.SavedCandidateId)
            .ToListAsync();

        return saved.Select(s => s.ToDto(Request)).ToList();
    }

    //POST /api/savedcandidates
    [HttpPost]
    public async Task<IActionResult> Save(SaveCandidateRequest request)
    {
        var userId = await GetCurrentUserIdAsync();

        if (userId == null)
        {
            return Unauthorized();
        }

        var candidate = await _context.Candidates
            .Include(c => c.Position)
                .ThenInclude(p => p.Municipality)
            .FirstOrDefaultAsync(c => c.CandidateId == request.CandidateId);

        if (candidate == null)
        {
            return Problem(
                statusCode: StatusCodes.Status404NotFound,
                title: "Candidate not found.");
        }

        if (await _context.SavedCandidates.AnyAsync(s =>
                s.UserId == userId && s.CandidateId == candidate.CandidateId))
        {
            return AlreadySaved();
        }

        //whole seconds, so the JSON date has no fraction for the iOS decoder
        var now = DateTime.UtcNow;

        var saved = new SavedCandidate
        {
            UserId = userId,
            CandidateId = candidate.CandidateId,
            Candidate = candidate,
            DateSaved = new DateTime(
                now.Ticks - now.Ticks % TimeSpan.TicksPerSecond, DateTimeKind.Utc)
        };

        _context.SavedCandidates.Add(saved);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            //a second request saved the same candidate between the check and the insert;
            //the unique (UserId, CandidateId) index rejects it
            return AlreadySaved();
        }

        return StatusCode(StatusCodes.Status201Created, saved.ToDto(Request));
    }

    //DELETE /api/savedcandidates/{id}
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var userId = await GetCurrentUserIdAsync();

        if (userId == null)
        {
            return Unauthorized();
        }

        //someone else's entry is reported as not found, so ids of other users' entries are not revealed
        var saved = await _context.SavedCandidates
            .FirstOrDefaultAsync(s => s.SavedCandidateId == id && s.UserId == userId);

        if (saved == null)
        {
            return NotFound();
        }

        _context.SavedCandidates.Remove(saved);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    //JWTs are not re-checked like cookies, so a deleted user's token must be refused here
    private async Task<string?> GetCurrentUserIdAsync()
    {
        var userId = User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

        if (userId == null || !await _context.Users.AnyAsync(u => u.Id == userId))
        {
            return null;
        }

        return userId;
    }

    private ObjectResult AlreadySaved() =>
        Problem(
            statusCode: StatusCodes.Status409Conflict,
            title: "Candidate is already in your voting guide.");
}
