#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test the enhanced template system with Custom Enhanced Template.

.DESCRIPTION
    This script demonstrates the new template functionality by creating
    a test project with the Custom Enhanced Template option.

.EXAMPLE
    .\test-custom-template.ps1
    Creates a test project named "test-enhanced-blog"
#>

$ErrorActionPreference = "Stop"

# Configuration
$TestProjectName = "test-enhanced-blog"
$TestLocation = "c:\temp"

Write-Host "🧪 Testing Custom Enhanced Template System" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Ensure test location exists
    if (-not (Test-Path $TestLocation)) {
        New-Item -ItemType Directory -Path $TestLocation -Force | Out-Null
    }
    
    # Change to test location
    Push-Location $TestLocation
    
    # Remove existing test project if it exists
    $testProjectPath = Join-Path $TestLocation $TestProjectName
    if (Test-Path $testProjectPath) {
        Write-Host "🧹 Cleaning up existing test project..." -ForegroundColor Yellow
        Remove-Item $testProjectPath -Recurse -Force
    }
    
    # Run the setup script with our test project name
    Write-Host "🚀 Creating project with Custom Enhanced Template..." -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 When prompted, choose 'c' for Custom Enhanced Template" -ForegroundColor Cyan
    Write-Host "   This will create a minimal Astro project and apply our enhanced template" -ForegroundColor Gray
    Write-Host "   You can also choose '0' to cancel if needed" -ForegroundColor Gray
    Write-Host ""
    
    & "c:\git\astro\0-setup-astro-project.ps1" -ProjectName $TestProjectName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Project created successfully!" -ForegroundColor Green
        Write-Host "📁 Location: $testProjectPath" -ForegroundColor White
        
        # Navigate to project
        Set-Location $TestProjectName
        
        Write-Host ""
        Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Initialize SWA configuration:" -ForegroundColor White
        Write-Host "   npm run swa:init" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Start development:" -ForegroundColor White  
        Write-Host "   npm run dev          # Frontend-only" -ForegroundColor Gray
        Write-Host "   npm run dev:full     # Full-stack" -ForegroundColor Gray
        Write-Host ""
        Write-Host "💡 Features included:" -ForegroundColor Yellow
        Write-Host "   ✅ Tailwind CSS v4 with dark mode" -ForegroundColor White
        Write-Host "   ✅ TypeScript ready" -ForegroundColor White
        Write-Host "   ✅ Azure Static Web Apps optimized" -ForegroundColor White
        Write-Host "   ✅ Enhanced layouts and components" -ForegroundColor White
        
    } else {
        throw "Project creation failed"
    }
    
} catch {
    Write-Host "❌ Test failed: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "🎉 Test completed successfully!" -ForegroundColor Green
Write-Host "📖 See TEMPLATE-GUIDE.md for full documentation" -ForegroundColor Cyan
