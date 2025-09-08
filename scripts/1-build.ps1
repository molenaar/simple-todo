<#
.SYNOPSIS
    Build the Astro application.

.DESCRIPTION
    Script Sequence: [1] <-- You are here
    1. BUILD - Basic project build (current)
    2. START - Run the Astro app locally
    3. UPDATE-DEPS - Update dependencies
    4. SWA-INIT - Initialize SWA CLI configuration
    5. SWA-BUILD - Build with SWA CLI
    6. SWA-START - Run with SWA emulator
    7. SWA-LOGIN - Log in to Azure
    8. SWA-AZURE - Create Azure resources
    9. SWA-DEPLOY - Deploy to Azure
    
.NOTES
    This script installs dependencies and performs basic npm audits.
#>

# Get the repository root path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Change to repository root directory first
Set-Location $repoRoot

# Build the project using our npm script which handles both app and API
Write-Host "Building project for production..." -ForegroundColor Cyan
Write-Host "Using npm script: npm run build" -ForegroundColor Yellow
Write-Host "This will build both the Astro app and Azure Functions API" -ForegroundColor Yellow

npm run build

Write-Host "Build completed!" -ForegroundColor Green