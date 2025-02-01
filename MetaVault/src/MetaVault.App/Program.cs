// Program.cs
using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using MetaVault.App;
using MetaVault.App.Services;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

// Configuration
builder.Services.AddScoped<IWeb3Service, Web3Service>();
builder.Services.AddScoped<IMetaVaultService, MetaVaultService>();

// HTTP Client
builder.Services.AddScoped(sp => new HttpClient 
{ 
    BaseAddress = new Uri(builder.HostEnvironment.BaseAddress) 
});

// Logging
builder.Logging.SetMinimumLevel(LogLevel.Information);

await builder.Build().RunAsync();