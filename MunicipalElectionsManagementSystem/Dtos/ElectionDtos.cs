using System.ComponentModel.DataAnnotations;
using MunicipalElectionsManagementSystem.Models;

namespace MunicipalElectionsManagementSystem.Dtos;

//response shapes are the iOS contract (plan section 2.0); change only with the partner
public record PositionSummaryDto(int PositionId, string Name, int SeatsAvailable);

public record MunicipalityDto(
    int MunicipalityId,
    string Name,
    string Province,
    DateOnly ElectionDate,
    string? Description,
    string? LogoUrl,
    List<PositionSummaryDto>? Positions);

public record PositionDto(
    int PositionId,
    string Name,
    int SeatsAvailable,
    int MunicipalityId,
    string MunicipalityName);

public record CandidateDto(
    int CandidateId,
    string Name,
    string Biography,
    string? PhotoUrl,
    string? Website,
    string? Email,
    int PositionId,
    string PositionName,
    int MunicipalityId,
    string MunicipalityName);

//userId and candidateId match the partner's flat Swift model; candidate saves a request per entry
public record SavedCandidateDto(
    int SavedCandidateId,
    string UserId,
    int CandidateId,
    DateTimeOffset DateSaved,
    CandidateDto Candidate);

public record SaveCandidateRequest
{
    [Required]
    public int? CandidateId { get; init; }
}

//maps entities loaded with their navigations; never return entities from the API
public static class ElectionDtoMapping
{
    //absolute URL because the app has no base page to resolve "/uploads/..." against
    public static string? ImageUrl(this HttpRequest request, string folder, string? fileName) =>
        string.IsNullOrEmpty(fileName)
            ? null
            : $"{request.Scheme}://{request.Host}{request.PathBase}/uploads/{folder}/{fileName}";

    //positions are only sent by GET /api/municipalities/{id}
    public static MunicipalityDto ToDto(
        this Municipality m, HttpRequest request, bool includePositions = false) => new(
        m.MunicipalityId,
        m.Name,
        m.Province,
        DateOnly.FromDateTime(m.ElectionDate),
        NullIfEmpty(m.Description),
        request.ImageUrl("municipalities", m.LogoFileName),
        includePositions
            ? m.Positions
                .OrderBy(p => p.Name)
                .Select(p => new PositionSummaryDto(p.PositionId, p.Name, p.SeatsAvailable))
                .ToList()
            : null);

    public static PositionDto ToDto(this Position p) => new(
        p.PositionId,
        p.Name,
        p.SeatsAvailable,
        p.MunicipalityId,
        p.Municipality.Name);

    public static CandidateDto ToDto(this Candidate c, HttpRequest request) => new(
        c.CandidateId,
        c.Name,
        c.Profile,
        request.ImageUrl("candidates", c.PhotoFileName),
        NullIfEmpty(c.Website),
        NullIfEmpty(c.Email),
        c.PositionId,
        c.Position.Name,
        c.Position.MunicipalityId,
        c.Position.Municipality.Name);

    //SQLite returns DateTimeKind.Unspecified, which would otherwise take the server's local offset
    public static SavedCandidateDto ToDto(this SavedCandidate s, HttpRequest request) => new(
        s.SavedCandidateId,
        s.UserId,
        s.CandidateId,
        new DateTimeOffset(DateTime.SpecifyKind(s.DateSaved, DateTimeKind.Utc)),
        s.Candidate.ToDto(request));

    //the contract sends null, never "", so Swift optionals decode cleanly
    private static string? NullIfEmpty(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value;
}
