using System.ComponentModel.DataAnnotations;

namespace MunicipalElectionsManagementSystem.Models;

public class Municipality
{
    public int MunicipalityId { get; set; }

    [Required(ErrorMessage = "Municipality name is required.")]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required(ErrorMessage = "Province is required.")]
    [StringLength(100)]
    public string Province { get; set; } = string.Empty;

    [Required]
    [DataType(DataType.Date)]
    public DateTime ElectionDate { get; set; }

    [StringLength(2000)]
    public string? Description { get; set; }

    public string? LogoFileName { get; set; }

    //one municipality can have multiple positions
    public ICollection<Position> Positions { get; set; }
        = new List<Position>();
}