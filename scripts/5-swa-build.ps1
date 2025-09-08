<#
.SYNOPSIS
    Build the Astro app using Azure Static Web Apps CLI.

.DESCRIPTION
    Script Sequence: [5] <-- You are here
    1. BUILD - Basic project build
    2. START - Run the Astro app locally
    3. UPDATE-DEPS - Update dependencies
    4. SWA-INIT - Initialize SWA CLI configuration
    5. SWA-BUILD - Build with SWA CLI (current)
    6. SWA-START - Run with SWA emulator
    7. SWA-LOGIN - Log in to Azure
    8. SWA-AZURE - Create Azure resources
    9. SWA-DEPLOY - Deploy to Azure
    
.NOTES
    This script uses the SWA CLI to build the Astro application using the configuration from swa-cli.config.json.
#>

# Get the repository root path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Change to repository root directory first
Set-Location $repoRoot

# Build using SWA CLI which handles the integrated build process
Write-Host "Building with Azure Static Web Apps CLI..." -ForegroundColor Cyan
Write-Host "Using npm script: npm run build:swa" -ForegroundColor Yellow
Write-Host "This uses SWA CLI to build both Astro app and Azure Functions API" -ForegroundColor Yellow

npm run build:swa

Write-Host "SWA build completed! Ready for deployment." -ForegroundColor Green