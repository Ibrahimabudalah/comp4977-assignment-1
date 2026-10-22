using System.ComponentModel.DataAnnotations;

namespace MunicipalElectionsManagementSystem.ViewModels;

public class UserFormViewModel
{
    public string? Id { get; set; }

    [Required(ErrorMessage = "Username is required.")]
    [StringLength(50)]
    [RegularExpression(@"^[a-zA-Z0-9._@-]+$",
        ErrorMessage = "Use letters, numbers, and . _ @ - only.")]
    public string UserName { get; set; } = string.Empty;

    //required when creating; optional when editing (leave blank to keep)
    [DataType(DataType.Password)]
    [StringLength(100, MinimumLength = 8,
        ErrorMessage = "Password must be at least 8 characters.")]
    public string? Password { get; set; }

    [DataType(DataType.Password)]
    [Compare(nameof(Password), ErrorMessage = "Passwords do not match.")]
    public string? ConfirmPassword { get; set; }

    //null means Super Admin; otherwise the user joins that municipality's admin group
    public int? MunicipalityId { get; set; }
}
