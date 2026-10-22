using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.ModelBinding.Metadata;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using MunicipalElectionsManagementSystem.Data;
using MunicipalElectionsManagementSystem.Models;
using MunicipalElectionsManagementSystem.Services;

var builder = WebApplication.CreateBuilder(args);

//camelCase keys in API validation errors; ModelState lookups are case-insensitive, so MVC forms are unaffected
builder.Services.AddControllersWithViews(options =>
    options.ModelMetadataDetailsProviders.Add(
        new SystemTextJsonValidationMetadataProvider()));

//SQLite db connection
var connectionString = builder.Configuration
    .GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException(
        "Database connection string was not found.");

//SQLite will not create missing folders, e.g. /home/data on Azure
var databaseFolder = Path.GetDirectoryName(Path.GetFullPath(
    new SqliteConnectionStringBuilder(connectionString).DataSource));

if (!string.IsNullOrEmpty(databaseFolder))
{
    Directory.CreateDirectory(databaseFolder);
}

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlite(connectionString));

//ASP.NET identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequiredLength = 8;

    options.User.RequireUniqueEmail = false;

    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(5);
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.AllowedForNewUsers = true;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

//JWT bearer for the mobile app API; the Identity cookie stays the default scheme for MVC
builder.Services.AddAuthentication()
    .AddJwtBearer(options =>
    {
        //keep claim names as issued (sub, email, name)
        options.MapInboundClaims = false;

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidateAudience = true,
            ValidAudience = builder.Configuration["Jwt:Audience"],
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = JwtTokenService.GetSigningKey(builder.Configuration),
            ValidateLifetime = true,
            NameClaimType = JwtRegisteredClaimNames.Name
        };
    });

builder.Services.AddScoped<JwtTokenService>();

//re-check sign-in cookies against the database every minute,
//so role changes and deleted users take effect quickly
builder.Services.Configure<SecurityStampValidatorOptions>(options =>
    options.ValidationInterval = TimeSpan.FromMinutes(1));

//login and access denied paths
builder.Services.ConfigureApplicationCookie(options =>
{
    options.LoginPath = "/Account/Login";
    options.AccessDeniedPath = "/Account/AccessDenied";
});

//session state holds the public voting guide
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromHours(2);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

builder.Services.AddScoped<MunicipalityAuthorizationService>();
builder.Services.AddScoped<ImageUploadService>();
builder.Services.AddScoped<VotingGuidePdfService>();

//QuestPDF Community license: free for learning and small organisations
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("SuperAdminOnly", policy =>
        policy.RequireRole(AdminRoles.SuperAdmin));

    //any admin group; data is then scoped per municipality by MunicipalityAuthorizationService
    options.AddPolicy("AdminAccess", policy =>
        policy.RequireAssertion(context =>
            context.User.HasClaim(c => c.Type == ClaimTypes.Role)));
});

var app = builder.Build();

// HTTP request pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

//serve uploaded images from Uploads:Path when it is outside wwwroot
var uploadRoot = ImageUploadService.GetUploadRoot(
    app.Environment, app.Configuration);

if (app.Configuration["Uploads:Path"] != null)
{
    Directory.CreateDirectory(uploadRoot);

    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new PhysicalFileProvider(uploadRoot),
        RequestPath = "/uploads"
    });
}

app.UseRouting();
app.UseSession();

app.UseAuthentication();
app.UseAuthorization();

//admin route
app.MapControllerRoute(
    name: "areas",
    pattern: "{area:exists}/{controller=Dashboard}/{action=Index}/{id?}");

//default route
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");



//migrate and seed initial data
using (var scope = app.Services.CreateScope())
{
    await DbInitializer.InitializeAsync(
        scope.ServiceProvider,
        app.Configuration);
}

app.Run();