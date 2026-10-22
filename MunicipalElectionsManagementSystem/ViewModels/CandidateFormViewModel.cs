
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace MunicipalElectionsManagementSystem.ViewModels;

public class CandidateFormViewModel
{
    [Required(ErrorMessage = "Candidate name is required.")]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Candidate profile is required.")]
    [StringLength(3000)]
    public string Profile { get; set; } = string.Empty;

    [Url(ErrorMessage = "Enter a valid website URL.")]
    [StringLength(300)]
    public string? Website { get; set; }

    [EmailAddress(ErrorMessage = "Enter a valid email address.")]
    [StringLength(200)]
    public string? Email { get; set; }

    [Required(ErrorMessage = "Please select a position.")]
    [Range(1, int.MaxValue, ErrorMessage = "Please select a position.")]
    public int PositionId { get; set; }

    public IFormFile? Photo { get; set; }

    public string? ExistingPhotoFileName { get; set; }
}