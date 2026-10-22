using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;

namespace MunicipalElectionsManagementSystem.Models;

public class ApplicationUser : IdentityUser
{
    //display name for users who register through the API
    [StringLength(100)]
    public string? FullName { get; set; }

    public int? MunicipalityId { get; set; }

    public Municipality? Municipality { get; set; }
}