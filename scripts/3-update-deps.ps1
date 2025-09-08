<#
.SYNOPSIS
    Update npm dependencies for the project.

.DESCRIPTION
    Script Sequence: [3] <-- You are here
    1. BUILD - Basic project build
    2. START - Run the Astro app locally
    3. UPDATE-DEPS - Update dependencies (current)
    4. SWA-INIT - Initialize SWA CLI configuration
    5. SWA-BUILD - Build with SWA CLI
    6. SWA-START - Run with SWA emulator
    7. SWA-LOGIN - Log in to Azure
    8. SWA-AZURE - Create Azure resources
    9. SWA-DEPLOY - Deploy to Azure
    
.NOTES
    Simplified dependency update script that uses npm-check-updates for safe updates.
#>

# Get the repository root path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Change to repository root directory first
Set-Location $repoRoot

Write-Host "📦 Updating Project Dependencies" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

# Check if ncu is installed, install if needed
Write-Host "Checking npm-check-updates..." -ForegroundColor Yellow
if (!(Get-Command ncu -ErrorAction SilentlyContinue)) {
    Write-Host "Installing npm-check-updates globally..." -ForegroundColor Yellow
    npm install -g npm-check-updates
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install npm-check-updates" -ForegroundColor Red
        exit 1
    }
}

# Show current outdated packages
Write-Host "Checking for outdated dependencies..." -ForegroundColor Cyan
ncu

Write-Host ""
$choice = Read-Host "Update dependencies? (Y/N)"
if ($choice -eq "Y") {
    # Create backup
    Write-Host "Creating backup..." -ForegroundColor Yellow
    if (Test-Path package.json) { Copy-Item package.json package.json.bak }
    
    # Update dependencies
    Write-Host "Updating dependencies..." -ForegroundColor Cyan
    ncu -u
    
    # Install updated dependencies for all projects
    Write-Host "Installing updated dependencies..." -ForegroundColor Cyan
    npm run install:all
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Dependencies updated successfully!" -ForegroundColor Green
        
        # Test with build
        $testChoice = Read-Host "Test with build? (Y/N)"
        if ($testChoice -eq "Y") {
            npm run build
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Build successful - update verified!" -ForegroundColor Green
            } else {
                Write-Host "❌ Build failed. Consider rolling back." -ForegroundColor Red
            }
        }
    } else {
        Write-Host "❌ Installation failed" -ForegroundColor Red
        if (Test-Path package.json.bak) {
            Copy-Item package.json.bak package.json -Force
            Write-Host "Restored from backup" -ForegroundColor Yellow
        }
    }
    
    # Cleanup backup
    $keepBackup = Read-Host "Keep backup? (Y/N)"
    if ($keepBackup -ne "Y" -and (Test-Path package.json.bak)) {
        Remove-Item package.json.bak -Force
    }
} else {
    Write-Host "Dependencies not updated." -ForegroundColor Yellow
}