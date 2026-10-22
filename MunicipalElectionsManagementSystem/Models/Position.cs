using System.ComponentModel.DataAnnotations;

namespace MunicipalElectionsManagementSystem.Models;

public class Position
{
    public int PositionId { get; set; }

    [Required(ErrorMessage = "Position name is required.")]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Range(1, 100, ErrorMessage = "Seats must be between 1 and 100.")]
    public int SeatsAvailable { get; set; }

    [Required(ErrorMessage = "Municipality is required.")]
    public int MunicipalityId { get; set; }

    //each position belongs to one municipality
    public Municipality Municipality { get; set; } = null!;

    // each position can have multiple candidates
    public ICollection<Candidate> Candidates { get; set; }
        = new List<Candidate>();
}