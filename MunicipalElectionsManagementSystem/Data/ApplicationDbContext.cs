using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using MunicipalElectionsManagementSystem.Models;

namespace MunicipalElectionsManagementSystem.Data;

public class ApplicationDbContext
    : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(
        DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Municipality> Municipalities { get; set; }
        = null!;

    public DbSet<Position> Positions { get; set; }
        = null!;

    public DbSet<Candidate> Candidates { get; set; }
        = null!;

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        //one municipality has many positions
        builder.Entity<Position>()
            .HasOne(p => p.Municipality)
            .WithMany(m => m.Positions)
            .HasForeignKey(p => p.MunicipalityId)
            .OnDelete(DeleteBehavior.Restrict);

        //one position has many candidates
        builder.Entity<Candidate>()
            .HasOne(c => c.Position)
            .WithMany(p => p.Candidates)
            .HasForeignKey(c => c.PositionId)
            .OnDelete(DeleteBehavior.Restrict);

        //municipality assignment for admin users
        builder.Entity<ApplicationUser>()
            .HasOne(u => u.Municipality)
            .WithMany()
            .HasForeignKey(u => u.MunicipalityId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}