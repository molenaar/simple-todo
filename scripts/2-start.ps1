<#
.SYNOPSIS
    Start the Astro application locally.

.DESCRIPTION
    Script Sequence: [2] <-- You are here
    1. BUILD - Basic project build
    2. START - Run the Astro app locally (current)
    3. UPDATE-DEPS - Update dependencies
    4. SWA-INIT - Initialize SWA CLI configuration
    5. SWA-BUILD - Build with SWA CLI
    6. SWA-START - Run with SWA emulator
    7. SWA-LOGIN - Log in to Azure
    8. SWA-AZURE - Create Azure resources
    9. SWA-DEPLOY - Deploy to Azure
    
.NOTES
    This script runs the Astro development server using npm.
#>

# Get the repository root path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Change to repository root directory first
Set-Location $repoRoot

# Start the development server
Write-Host "Starting Astro development server..." -ForegroundColor Cyan
npm run dev