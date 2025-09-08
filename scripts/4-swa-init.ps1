<#
.SYNOPSIS
    Initialize Azure Static Web Apps CLI configuration.

.DESCRIPTION
    Script Sequence: [4] <-- You are here
    1. BUILD - Basic project build
    2. START - Run the Astro app locally
    3. UPDATE-DEPS - Update dependencies
    4. SWA-INIT - Initialize SWA CLI configuration (current)
    5. SWA-BUILD - Build with SWA CLI
    6. SWA-START - Run with SWA emulator
    7. SWA-LOGIN - Log in to Azure
    8. SWA-AZURE - Create Azure resources
    9. SWA-DEPLOY - Deploy to Azure

.NOTES
    This script creates the swa-cli.config.json file with Astro-specific settings.
#>

# Initialize SWA with Astro configuration (following Elio Struyf's approach)

# Get the repository root path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Change to repository root directory first
Set-Location $repoRoot

Write-Host "Azure Static Web Apps CLI Configuration Setup" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  IMPORTANT: This script creates a clean, readable configuration" -ForegroundColor Yellow       
Write-Host "   instead of using 'swa init' which generates lots of unnecessary" -ForegroundColor Yellow       
Write-Host "   boilerplate and complex settings you don't need." -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ Our approach (following Elio Struyf's method):" -ForegroundColor Green
Write-Host "   • Clean, minimal configuration" -ForegroundColor White
Write-Host "   • Easy to read and understand" -ForegroundColor White
Write-Host "   • Only essential settings included" -ForegroundColor White
Write-Host "   • App and API settings logically grouped together" -ForegroundColor White
Write-Host ""
Write-Host "❌ 'swa init' creates:" -ForegroundColor Red
Write-Host "   • Verbose, complex configurations" -ForegroundColor White
Write-Host "   • Many unnecessary default settings" -ForegroundColor White
Write-Host "   • Harder to read and maintain" -ForegroundColor White
Write-Host "   • Separated configurations that don't make sense" -ForegroundColor White
Write-Host ""
Write-Host "Choose your project type:" -ForegroundColor Cyan
Write-Host "1. 🌐 Basic Astro website (frontend only)" -ForegroundColor White
Write-Host "   📖 Guide: https://www.eliostruyf.com/deploy-astro-azure-static-web-apps-github-cli/" -ForegroundColor Gray
Write-Host ""
Write-Host "2. ⚡ Full-stack Astro + Azure Functions (frontend + API)" -ForegroundColor White
Write-Host "   📖 Guide: https://www.eliostruyf.com/integrating-azure-functions-astro-site/" -ForegroundColor Gray
Write-Host ""

do {
    $choice = Read-Host "Enter your choice (1 or 2)"
} while ($choice -ne "1" -and $choice -ne "2")

# If full-stack, ask for language choice
$apiLanguage = ""
$apiVersion = ""
if ($choice -eq "2") {
    Write-Host ""
    Write-Host "Choose your API language:" -ForegroundColor Cyan
    Write-Host "1. 🐍 Python (3.10, 3.11, 3.12 - Flex Consumption Plan supported)" -ForegroundColor White
    Write-Host "2. 🟢 Node.js (18, 20 - recommended for Azure Functions)" -ForegroundColor White
    Write-Host "3. 🔧 Other (manual configuration required)" -ForegroundColor White
    Write-Host ""
    
    do {
        $langChoice = Read-Host "Enter your language choice (1, 2, or 3)"
    } while ($langChoice -ne "1" -and $langChoice -ne "2" -and $langChoice -ne "3")
    
    if ($langChoice -eq "1") {
        $apiLanguage = "python"
        Write-Host ""
        Write-Host "Choose Python version:" -ForegroundColor Cyan
        Write-Host "1. 🐍 Python 3.12 (Latest GA - Recommended)" -ForegroundColor White
        Write-Host "2. 🐍 Python 3.11 (GA - Stable)" -ForegroundColor White
        Write-Host "3. 🐍 Python 3.10 (GA - Stable)" -ForegroundColor White
        Write-Host ""
        
        do {
            $pyVersion = Read-Host "Enter Python version choice (1, 2, or 3)"
        } while ($pyVersion -ne "1" -and $pyVersion -ne "2" -and $pyVersion -ne "3")
        
        switch ($pyVersion) {
            "1" { $apiVersion = "3.12" }
            "2" { $apiVersion = "3.11" }
            "3" { $apiVersion = "3.10" }
        }
    } elseif ($langChoice -eq "2") {
        $apiLanguage = "node"
        Write-Host ""
        Write-Host "Choose Node.js version:" -ForegroundColor Cyan
        Write-Host "1. 🟢 Node.js 20 (Latest LTS - Recommended)" -ForegroundColor White
        Write-Host "2. 🟢 Node.js 18 (LTS - Stable)" -ForegroundColor White
        Write-Host ""
        
        do {
            $nodeVersion = Read-Host "Enter Node.js version choice (1 or 2)"
        } while ($nodeVersion -ne "1" -and $nodeVersion -ne "2")
        
        switch ($nodeVersion) {
            "1" { $apiVersion = "20" }
            "2" { $apiVersion = "18" }
        }
    } else {
        $apiLanguage = Read-Host "Enter your API language (e.g., java, dotnet, etc.)"
        $apiVersion = Read-Host "Enter your API version"
    }
}

# Get the path to the swa-cli.config.json file
$configPath = Join-Path -Path (Get-Location) -ChildPath "swa-cli.config.json"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "Creating basic Astro website configuration..." -ForegroundColor Green
    Write-Host "📖 Following: https://www.eliostruyf.com/deploy-astro-azure-static-web-apps-github-cli/" -ForegroundColor Gray

    $configContent = @"
{
  "`$schema": "https://aka.ms/azure/static-web-apps-cli/schema",
  "configurations": {
    "astro-basic": {
      "appLocation": "./app",
      "outputLocation": "dist",
      "appDevserverUrl": "http://localhost:4321"
    }
  }
}
"@

    Write-Host ""
    Write-Host "✅ Basic Astro configuration created" -ForegroundColor Green
    Write-Host ""
    Write-Host "Configuration details:" -ForegroundColor Yellow
    Write-Host "  • App Location:        ./app" -ForegroundColor White
    Write-Host "  • Output Location:     dist" -ForegroundColor White
    Write-Host "  • App Dev Server:      http://localhost:4321" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 Usage: swa start" -ForegroundColor Cyan
    Write-Host "🌐 Access: http://localhost:4280" -ForegroundColor Green

} else {
    Write-Host ""
    Write-Host "Creating full-stack Astro + Azure Functions configuration..." -ForegroundColor Green
    Write-Host "📖 Following: https://www.eliostruyf.com/integrating-azure-functions-astro-site/" -ForegroundColor Gray

    $configContent = @"
{
  "`$schema": "https://aka.ms/azure/static-web-apps-cli/schema",
  "configurations": {
    "astro-func-swa": {
      "appLocation": "./app",
      "outputLocation": "dist",
      "appDevserverUrl": "http://localhost:4321",
      "apiLocation": "./api",
      "apiLanguage": "$apiLanguage",
      "apiVersion": "$apiVersion",
      "apiDevserverUrl": "http://localhost:7071"
    }
  }
}
"@

    Write-Host ""
    Write-Host "✅ Full-stack Astro + Functions configuration created" -ForegroundColor Green
    Write-Host ""
    Write-Host "Configuration details:" -ForegroundColor Yellow
    Write-Host "  • App Location:        ./app" -ForegroundColor White
    Write-Host "  • Output Location:     dist" -ForegroundColor White
    Write-Host "  • App Dev Server:      http://localhost:4321" -ForegroundColor White
    Write-Host "  • API Location:        ./api" -ForegroundColor White
    Write-Host "  • API Language:        $apiLanguage" -ForegroundColor White
    Write-Host "  • API Version:         $apiVersion" -ForegroundColor White
    Write-Host "  • API Dev Server:      http://localhost:7071" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 Usage: swa start" -ForegroundColor Cyan
    Write-Host "🌐 Access: http://localhost:4280" -ForegroundColor Green
    Write-Host "🔧 API endpoints: http://localhost:4280/api/*" -ForegroundColor Green
}

# Write the config file
$configContent | Out-File -FilePath $configPath -Encoding utf8

Write-Host ""
Write-Host "✅ Configuration file created: $configPath" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Why this approach is better than 'swa init':" -ForegroundColor Cyan
Write-Host "   • Clean and readable - no bloat" -ForegroundColor White
Write-Host "   • Only essential settings included" -ForegroundColor White
Write-Host "   • Follows proven patterns from Elio Struyf's tutorials" -ForegroundColor White
Write-Host "   • Easy to understand and modify" -ForegroundColor White
Write-Host "   • Reusable across different project types" -ForegroundColor White
Write-Host ""
Write-Host "💡 Note: You can still use 'swa init' if you want, but this" -ForegroundColor Yellow
Write-Host "   clean configuration is much more maintainable and readable!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  npm run dev          - Start unified development (recommended)" -ForegroundColor White
Write-Host "  swa start            - Start SWA CLI directly" -ForegroundColor White
Write-Host "  swa --print-config   - View configuration" -ForegroundColor White