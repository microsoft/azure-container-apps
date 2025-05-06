var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "App1");

app.Run();