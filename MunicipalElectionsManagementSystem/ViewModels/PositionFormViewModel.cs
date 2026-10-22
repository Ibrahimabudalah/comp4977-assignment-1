
using System.ComponentModel.DataAnnotations;

namespace MunicipalElectionsManagementSystem.ViewModels;

public class PositionFormViewModel
{
    [Required(ErrorMessage = "Position name is required.")]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [Range(1, 100, ErrorMessage = "Seats available must be between 1 and 100.")]
    public int SeatsAvailable { get; set; } = 1;

    [Required(ErrorMessage = "Please select a municipality.")]
    [Range(1, int.MaxValue, ErrorMessage = "Please select a municipality.")]
    public int MunicipalityId { get; set; }
}