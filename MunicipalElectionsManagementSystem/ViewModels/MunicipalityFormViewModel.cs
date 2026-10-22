
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace MunicipalElectionsManagementSystem.ViewModels;

public class MunicipalityFormViewModel
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Province is required.")]
    [StringLength(100)]
    [RegularExpression(
    @"^[A-Za-z]+(?:[ '\-][A-Za-z]+)*$",
    ErrorMessage = "Province must contain letters only.")]
    public string Province { get; set; } = string.Empty;

    [Required]
    [DataType(DataType.Date)]
    public DateTime ElectionDate { get; set; } = DateTime.Today;

    [StringLength(2000)]
    public string? Description { get; set; }

    public IFormFile? Logo { get; set; }

    public string? ExistingLogoFileName { get; set; }
}