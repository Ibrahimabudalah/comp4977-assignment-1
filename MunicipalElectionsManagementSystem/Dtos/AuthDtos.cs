using System.ComponentModel.DataAnnotations;

namespace MunicipalElectionsManagementSystem.Dtos;

//requests use properties, not positional parameters, so validation error keys are camelCase
public record RegisterRequest
{
    [Required, StringLength(100)]
    public string Name { get; init; } = string.Empty;

    [Required, EmailAddress, StringLength(254)]
    public string Email { get; init; } = string.Empty;

    [Required, StringLength(100, MinimumLength = 8)]
    public string Password { get; init; } = string.Empty;
}

public record LoginRequest
{
    [Required, EmailAddress]
    public string Email { get; init; } = string.Empty;

    [Required]
    public string Password { get; init; } = string.Empty;
}

public record TokenResponse(string Token);

public record UserResponse(string Name, string Email);
