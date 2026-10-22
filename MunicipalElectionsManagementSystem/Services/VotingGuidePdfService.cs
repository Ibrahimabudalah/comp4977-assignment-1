using MunicipalElectionsManagementSystem.Models;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace MunicipalElectionsManagementSystem.Services;

//builds the printable voting guide as a PDF file
public class VotingGuidePdfService
{
    private readonly string _uploadRoot;

    public VotingGuidePdfService(
        IWebHostEnvironment environment,
        IConfiguration configuration)
    {
        _uploadRoot = ImageUploadService.GetUploadRoot(environment, configuration);
    }

    //candidates must include Position and Position.Municipality
    public byte[] Generate(IEnumerable<Candidate> candidates, DateTime printDate)
    {
        var municipalities = candidates
            .GroupBy(c => c.Position.MunicipalityId)
            .Select(g => (Info: g.First().Position.Municipality, Candidates: g
                .OrderBy(c => c.Position.Name)
                .ThenBy(c => c.Name)
                .ToList()))
            .OrderBy(g => g.Info.Name)
            .ToList();

        return Document.Create(document =>
        {
            document.Page(page =>
            {
                page.Size(PageSizes.Letter);
                page.Margin(40);
                page.PageColor(Colors.White);
                page.DefaultTextStyle(text => text.FontSize(11));

                page.Header().Column(header =>
                {
                    header.Item().Text("My Voting Guide").FontSize(22).Bold();
                    header.Item().Text($"Printed on {printDate:MMMM d, yyyy}")
                        .FontColor(Colors.Grey.Darken1);
                    header.Item().PaddingTop(8).LineHorizontal(1)
                        .LineColor(Colors.Grey.Lighten2);
                });

                page.Content().PaddingTop(12).Column(content =>
                {
                    content.Spacing(18);

                    foreach (var (municipality, list) in municipalities)
                    {
                        content.Item().Column(section =>
                        {
                            section.Item().Text(municipality.Name).FontSize(16).Bold();
                            section.Item().Text(
                                    $"Election date: {municipality.ElectionDate:MMMM d, yyyy}")
                                .FontColor(Colors.Grey.Darken1);

                            section.Item().PaddingTop(6).Table(table =>
                            {
                                table.ColumnsDefinition(columns =>
                                {
                                    columns.ConstantColumn(60);
                                    columns.RelativeColumn(2);
                                    columns.RelativeColumn(1);
                                });

                                table.Header(row =>
                                {
                                    row.Cell().Element(HeaderCell).Text("Photo");
                                    row.Cell().Element(HeaderCell).Text("Candidate");
                                    row.Cell().Element(HeaderCell).Text("Position");
                                });

                                foreach (var candidate in list)
                                {
                                    var photoPath = GetPhotoPath(candidate.PhotoFileName);

                                    if (photoPath != null)
                                    {
                                        BodyCell(table).Height(50).Image(photoPath).FitArea();
                                    }
                                    else
                                    {
                                        BodyCell(table).Text("—").FontColor(Colors.Grey.Medium);
                                    }

                                    BodyCell(table).Text(candidate.Name);
                                    BodyCell(table).Text(candidate.Position.Name);
                                }
                            });
                        });
                    }
                });

                page.Footer().AlignCenter().Text(text =>
                {
                    text.Span("Municipal Elections Management System · Page ");
                    text.CurrentPageNumber();
                    text.Span(" of ");
                    text.TotalPages();
                });
            });
        }).GeneratePdf();
    }

    private static IContainer HeaderCell(IContainer container) => container
        .BorderBottom(1)
        .BorderColor(Colors.Grey.Lighten1)
        .PaddingVertical(4)
        .DefaultTextStyle(text => text.SemiBold());

    private static IContainer BodyCell(TableDescriptor table) => table.Cell()
        .BorderBottom(1)
        .BorderColor(Colors.Grey.Lighten3)
        .PaddingVertical(6)
        .AlignMiddle();

    private string? GetPhotoPath(string? fileName)
    {
        if (string.IsNullOrEmpty(fileName))
        {
            return null;
        }

        var path = Path.Combine(_uploadRoot, "candidates", Path.GetFileName(fileName));

        return File.Exists(path) ? path : null;
    }
}
