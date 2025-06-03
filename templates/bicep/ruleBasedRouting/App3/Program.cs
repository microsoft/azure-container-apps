var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "App3");

app.Run();
