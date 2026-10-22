
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Models;
using MunicipalElectionsManagementSystem.Services;

namespace MunicipalElectionsManagementSystem.Data;

public static class DbInitializer
{
    public static async Task InitializeAsync(
        IServiceProvider services,
        IConfiguration configuration)
    {
        var db = services.GetRequiredService<ApplicationDbContext>();
        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

        //apply pending EF Core migrations
        await db.Database.MigrateAsync();

        //seed sample domain data only into an empty database,
        //so rows an admin deletes do not come back on restart
        if (!await db.Municipalities.AnyAsync())
        {
            await SeedDomainDataAsync(db);
        }

        //create required roles: Super Admin plus one admin group per municipality
        var municipalityNames = await db.Municipalities
            .Select(m => m.Name)
            .ToListAsync();

        var roles = municipalityNames
            .Select(AdminRoles.ForMunicipality)
            .Prepend(AdminRoles.SuperAdmin);

        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                var result = await roleManager.CreateAsync(
                    new IdentityRole(role));

                EnsureSuccess(result, $"Create role {role}");
            }
        }

        var pittMeadows = await db.Municipalities
            .FirstOrDefaultAsync(m => m.Name == "Pitt Meadows");

        //seed users
        await CreateUserAsync(
            userManager,
            "super",
            AdminRoles.SuperAdmin,
            null,
            configuration["SeedUsers:SuperPassword"]);

        //Pitt Meadows cannot be deleted while pm is assigned to it,
        //so it is only missing if an admin removed both
        if (pittMeadows != null)
        {
            await CreateUserAsync(
                userManager,
                "pm",
                AdminRoles.ForMunicipality(pittMeadows.Name),
                pittMeadows.MunicipalityId,
                configuration["SeedUsers:PmPassword"]);
        }
    }

    private static async Task SeedDomainDataAsync(ApplicationDbContext db)
    {
        var pittMeadows = NewMunicipality("Pitt Meadows");
        var mapleRidge = NewMunicipality("Maple Ridge");
        var burnaby = NewMunicipality("Burnaby");

        //seed positions
        var pittMayor = NewPosition(pittMeadows, "Mayor", 1);
        var pittCouncil = NewPosition(pittMeadows, "Councilor", 6);
        var pittTrustee = NewPosition(pittMeadows, "School Trustee", 2);

        var mapleMayor = NewPosition(mapleRidge, "Mayor", 1);
        var mapleCouncil = NewPosition(mapleRidge, "Councilor", 6);
        var mapleTrustee = NewPosition(mapleRidge, "School Trustee", 5);

        var burnabyMayor = NewPosition(burnaby, "Mayor", 1);
        var burnabyCouncil = NewPosition(burnaby, "Councilor", 8);
        var burnabyTrustee = NewPosition(burnaby, "School Trustee", 7);

        //seed sample candidates
        (string Name, string Profile, Position Position)[] candidates =
        {
            ("Alex Morgan", "Focused on community development and local services.", pittMayor),
            ("Jordan Lee", "Interested in transportation and affordable housing.", pittCouncil),
            ("Priya Sandhu", "Small business owner advocating for a vibrant downtown core.", pittCouncil),
            ("Daniel Okafor", "Former teacher committed to smaller class sizes and school safety.", pittTrustee),
            ("Taylor Chen", "Supports local businesses and community programs.", mapleMayor),
            ("Maria Gonzalez", "Wants better transit links and safer cycling routes.", mapleCouncil),
            ("Liam O'Brien", "Volunteer firefighter focused on emergency preparedness.", mapleCouncil),
            ("Hannah Kim", "Parent advocate for inclusive education and arts programs.", mapleTrustee),
            ("Samuel Wright", "Focused on housing supply and responsible budgeting.", burnabyMayor),
            ("Aisha Rahman", "Environmental scientist championing parks and climate action.", burnabyCouncil),
            ("Kevin Tran", "Tech worker pushing for digital city services.", burnabyCouncil),
            ("Emily Fraser", "Community organizer supporting seniors and youth programs.", burnabyCouncil),
            ("Robert Singh", "Retired principal focused on school capital projects.", burnabyTrustee),
            ("Grace Liu", "Advocates for mental health supports in schools.", burnabyTrustee)
        };

        foreach (var (name, profile, position) in candidates)
        {
            position.Candidates.Add(new Candidate
            {
                Name = name,
                Profile = profile
            });
        }

        db.Municipalities.AddRange(pittMeadows, mapleRidge, burnaby);
        await db.SaveChangesAsync();
    }

    private static Municipality NewMunicipality(string name) => new()
    {
        Name = name,
        Province = "British Columbia",
        ElectionDate = new DateTime(2026, 10, 17),
        Description = $"Municipal elections for {name}."
    };

    private static Position NewPosition(
        Municipality municipality,
        string name,
        int seats)
    {
        var position = new Position
        {
            Name = name,
            SeatsAvailable = seats
        };

        municipality.Positions.Add(position);
        return position;
    }

    private static async Task CreateUserAsync(
        UserManager<ApplicationUser> userManager,
        string username,
        string role,
        int? municipalityId,
        string? password)
    {
        var user = await userManager.FindByNameAsync(username);

        if (user == null)
        {
            if (string.IsNullOrWhiteSpace(password))
            {
                throw new InvalidOperationException(
                    $"Seed password for {username} is missing.");
            }

            user = new ApplicationUser
            {
                UserName = username,
                MunicipalityId = municipalityId
            };

            var result = await userManager.CreateAsync(user, password);
            EnsureSuccess(result, $"Create user {username}");
        }

        if (!await userManager.IsInRoleAsync(user, role))
        {
            var result = await userManager.AddToRoleAsync(user, role);
            EnsureSuccess(result, $"Assign role {role} to {username}");
        }
    }

    private static void EnsureSuccess(
        IdentityResult result,
        string operation)
    {
        if (result.Succeeded)
        {
            return;
        }

        var errors = string.Join(
            "; ",
            result.Errors.Select(e => e.Description));

        throw new InvalidOperationException(
            $"{operation} failed: {errors}");
    }
}
