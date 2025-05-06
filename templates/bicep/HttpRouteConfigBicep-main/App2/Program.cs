var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "App2");

app.Run();
