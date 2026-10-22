namespace MunicipalElectionsManagementSystem.Services;

//every role in the system is an admin group:
//"Super Admin" plus one "{Municipality} Admin" group per municipality
public static class AdminRoles
{
    public const string SuperAdmin = "Super Admin";

    public static string ForMunicipality(string municipalityName) =>
        $"{municipalityName} Admin";
}
