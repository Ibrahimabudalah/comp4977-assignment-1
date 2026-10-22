using System.ComponentModel.DataAnnotations;

namespace MunicipalElectionsManagementSystem.Models;

public class Candidate
{
    public int CandidateId { get; set; }

    [Required(ErrorMessage = "Candidate name is required.")]
    [StringLength(150)]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Candidate biography is required.")]
    [StringLength(3000, ErrorMessage = "Biography cannot exceed 3000 characters.")]
    public string Profile { get; set; } = string.Empty;

    public string? PhotoFileName { get; set; }

    [Url(ErrorMessage = "Please enter a valid website URL.")]
    [StringLength(500)]
    public string? Website { get; set; }

    [EmailAddress(ErrorMessage = "Please enter a valid email address.")]
    [StringLength(254)]
    public string? Email { get; set; }

    [Required(ErrorMessage = "Position is required.")]
    public int PositionId { get; set; }

    //each candidate runs for one position
    public Position Position { get; set; } = null!;

    public DateTime DateCreated { get; set; }
        = DateTime.UtcNow;
}