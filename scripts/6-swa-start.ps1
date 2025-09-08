<#
.SYNOPSIS
    Start the Astro app with Azure Static Web Apps emulator.

.DESCRIPTION
    Script Sequence: [6] <-- You are here
    1. BUILD - Basic project build
    2. START - Run the Astro app locally
    3. UPDATE-DEPS - Update dependencies
    4. SWA-INIT - Initialize SWA CLI configuration
    5. SWA-BUILD - Build with SWA CLI
    6. SWA-START - Run with SWA emulator (current)
    7. SWA-LOGIN - Log in to Azure
    8. SWA-AZURE - Create Azure resources
    9. SWA-DEPLOY - Deploy to Azure
    
.NOTES
    This script starts the SWA emulator for local testing of Astro app with SWA features.
#>

# Get the repository root path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Change to repository root directory first
Set-Location $repoRoot

# Start the SWA emulator with integrated Astro + Azure Functions
Write-Host "Starting SWA emulator with integrated Astro app and Azure Functions API..." -ForegroundColor Cyan
Write-Host "SWA CLI will automatically start and proxy:" -ForegroundColor Yellow
Write-Host "  - Astro dev server (internal)" -ForegroundColor Yellow
Write-Host "  - Azure Functions API (internal)" -ForegroundColor Yellow
Write-Host "  - Unified access through SWA proxy on port 4280" -ForegroundColor Yellow
Write-Host "" -ForegroundColor White
Write-Host "🌐 Access your app at: http://localhost:4280" -ForegroundColor Green
Write-Host "🔧 API endpoints at: http://localhost:4280/api/*" -ForegroundColor Green
Write-Host "📝 No CORS issues - everything runs on the same domain!" -ForegroundColor Cyan

# Use npm run dev which triggers the SWA CLI to start everything
npm run dev