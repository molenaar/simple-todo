<#
.SYNOPSIS
    Create a new Astro project following Elio Struyf's methodology.

.DESCRIPTION
    Creates a clean        Show-Templates
        $selection = Read-Host "`nEnter your choice (1-23 for templates, c for Custom Enhanced, g for GitHub, 0 to cancel)"stro project optimized for Azure Static Web Apps integration.
    Follows Elio Struyf's best practices for project structure and configuration.
    
    📖 Reference: https://www.eliostruyf.com/deploy-astro-azure-static-web-apps-github-cli/
    📖 Documentation: docs/elio-struyf-methodology.md

.PARAMETER template
    Astro template to use. Recommended: 'with-tailwindcss' for full-stack projects.
#>

param(
    [string]$template = "with-tailwindcss",  # Changed default to align with Elio's examples
    [string]$ProjectName = "my-astro-project"
)

# Get the full list of templates
$templates = @(
    "basics",
    "blog",
    "component",
    "container-with-vitest",
    "framework-alpine",
    "framework-multiple",
    "framework-preact",
    "framework-react",
    "framework-solid",
    "framework-svelte",
    "framework-vue",
    "hackernews",
    "integration",
    "minimal",
    "portfolio",
    "ssr",
    "starlog",
    "toolbar-app",
    "with-markdoc",
    "with-mdx",
    "with-nanostores",
    "with-tailwindcss",
    "with-vitest"
)

function Show-Templates {
    Write-Host "`nTemplate Options:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "� Astro Templates:" -ForegroundColor Cyan
    for ($i = 1; $i -le $templates.Count; $i++) {
        $template = $templates[$i-1]
        if ($template -eq "with-tailwindcss") {
            Write-Host "$i) $template (⭐ Popular choice)" -ForegroundColor White
        } elseif ($template -eq "minimal" -or $template -eq "basics") {
            Write-Host "$i) $template (Good starting point)" -ForegroundColor White
        } else {
            Write-Host "$i) $template" -ForegroundColor Gray
        }
    }
    Write-Host ""
    Write-Host "� ENHANCED:" -ForegroundColor Green
    Write-Host "c) Custom Enhanced Template (Astro + Tailwind CSS v4 + Azure Ready) ⭐ RECOMMENDED" -ForegroundColor Yellow
    Write-Host "   ✅ Pre-configured with Tailwind CSS v4" -ForegroundColor White
    Write-Host "   ✅ Dark mode support built-in" -ForegroundColor White  
    Write-Host "   ✅ Azure Static Web Apps optimized" -ForegroundColor White
    Write-Host "   ✅ TypeScript ready" -ForegroundColor White
    Write-Host ""
    Write-Host "🌐 Community:" -ForegroundColor Cyan
    Write-Host "g) GitHub repo (browse community templates)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "0) Exit" -ForegroundColor Red
}

try {
    Write-Host "Creating project structure for: $ProjectName" -ForegroundColor Cyan
    
    # Initialize template tracking variable
    $useCustomTemplate = $false
    
    # Step 1: Create the main project directory
    if (Test-Path $ProjectName) {
        Write-Host "Warning: Directory '$ProjectName' already exists" -ForegroundColor Yellow
        $response = Read-Host "Remove existing directory? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Remove-Item $ProjectName -Recurse -Force
            Write-Host "Removed existing directory" -ForegroundColor Yellow
        } else {
            Write-Host "Aborting project creation" -ForegroundColor Red
            exit 1
        }
    }
    
    # Create main project directory
    New-Item -ItemType Directory -Name $ProjectName | Out-Null
    Write-Host "✓ Created project directory: $ProjectName" -ForegroundColor Green
    
    # Step 2: Create the app subdirectory
    $appPath = Join-Path $ProjectName "app"
    New-Item -ItemType Directory -Path $appPath | Out-Null
    Write-Host "✓ Created app directory: $appPath" -ForegroundColor Green
    
    # Step 3: Navigate to app directory and create Astro project there
    Push-Location $appPath
    
    # Initialize cancellation flag
    $userCancelled = $false
    
    # Temporarily isolate from parent package.json to avoid npm confusion
    $parentPackageJson = Join-Path (Split-Path $appPath -Parent) ".." "package.json"
    $tempPackageJson = $null
    if (Test-Path $parentPackageJson) {
        $tempPackageJson = "$parentPackageJson.temp"
        Move-Item $parentPackageJson $tempPackageJson
        Write-Host "✓ Temporarily isolated from parent package.json" -ForegroundColor Green
    }
    
    try {
        Show-Templates
        $selection = Read-Host "`nPlease enter your choice (c for Custom Enhanced, 0 to exit, enter for basic Astro)"

        # Handle different selection cases
        switch ($selection) {
            "" {  # Empty selection (Enter key)
                Write-Host "Creating basic Astro project without template..." -ForegroundColor Yellow
                npm create astro@latest . -- --install --yes --skip-git
                $useCustomTemplate = $false
            }
            { $_ -eq "c" -or $_ -eq "C" } {  # Custom Enhanced Template
                Write-Host "Creating minimal Astro project for custom template..." -ForegroundColor Green
                npm create astro@latest . -- --template minimal --install --yes --skip-git
                $useCustomTemplate = $true
                Write-Host "✓ Minimal Astro project created, will copy enhanced template..." -ForegroundColor Green
            }
            "0" { 
                Write-Host "User cancelled template selection." -ForegroundColor Yellow
                # Set a flag to indicate cancellation instead of throwing
                $userCancelled = $true
                break
            }
            "g" {
                Start-Process "https://astro.build/themes/"
                $repoUrl = Read-Host "`nEnter GitHub repo URL or username/repo"
                
                # Extract username/repo from full URL or use as-is
                if ($repoUrl -match "github.com/([^/]+)/([^/]+)") {
                    $username = $matches[1]
                    $repo = $matches[2].TrimEnd(".git")
                    $repoUrl = "$username/$repo"
                }
                
                Write-Host "Using GitHub template: $repoUrl" -ForegroundColor Yellow
                npm create astro@latest . -- --template "github:$repoUrl" --install --yes --skip-git
                $useCustomTemplate = $false
            }
            default {
                if ([int]::TryParse($selection, [ref]$null)) {
                    $selectedTemplate = $templates[$selection-1]
                    Write-Host "Creating Astro project in app/ with template: $selectedTemplate" -ForegroundColor Yellow
                    npm create astro@latest . -- --template $selectedTemplate --install --yes --skip-git
                    $useCustomTemplate = $false
                } else {
                    throw "Invalid selection"
                }
            }
        }
    }
    finally {
        # Restore parent package.json
        if ($tempPackageJson -and (Test-Path $tempPackageJson)) {
            Move-Item $tempPackageJson $parentPackageJson
            Write-Host "✓ Restored parent package.json" -ForegroundColor Green
        }
    }
    
    # Return to parent directory
    Pop-Location
    
    # Check if user cancelled - if so, clean up and exit gracefully
    if ($userCancelled) {
        Write-Host ""
        Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
        
        # Remove the created project directory
        if (Test-Path $ProjectName) {
            Remove-Item $ProjectName -Recurse -Force
            Write-Host "✓ Removed project directory: $ProjectName" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "❌ Project creation cancelled by user." -ForegroundColor Yellow
        Write-Host "💡 Run the script again when you're ready to create a project." -ForegroundColor Cyan
        exit 0  # Clean exit without error
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✓ Astro project created successfully in app/ directory!" -ForegroundColor Green
        
        # Apply custom template if selected
        if ($useCustomTemplate) {
            Write-Host "`n🎨 Applying Custom Enhanced Template..." -ForegroundColor Cyan
            
            # Get paths
            $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
            $repoRoot = Split-Path -Parent $scriptDir
            $templatesPath = Join-Path $repoRoot "templates" "app" "src"
            $appSrcPath = Join-Path $ProjectName "app" "src"
            
            if (Test-Path $templatesPath) {
                # Copy our enhanced template files
                Write-Host "Copying enhanced template files..." -ForegroundColor Yellow
                Copy-Item -Path "$templatesPath\*" -Destination $appSrcPath -Recurse -Force
                Write-Host "✅ Enhanced template files copied" -ForegroundColor Green
                
                # Install and configure Tailwind CSS v4
                Write-Host "Setting up Tailwind CSS v4..." -ForegroundColor Yellow
                Push-Location (Join-Path $ProjectName "app")
                
                try {
                    # Install Tailwind CSS v4 and Vite plugin
                    Write-Host "Installing Tailwind CSS v4 dependencies..." -ForegroundColor Gray
                    npm install tailwindcss @tailwindcss/vite
                    
                    # Configure Vite plugin in astro.config.mjs
                    $astroConfigPath = "astro.config.mjs"
                    if (Test-Path $astroConfigPath) {
                        Write-Host "Configuring Tailwind CSS v4 Vite plugin..." -ForegroundColor Gray
                        $astroConfig = Get-Content $astroConfigPath -Raw
                        
                        # Check if tailwindcss is already configured
                        if ($astroConfig -notmatch "@tailwindcss/vite") {
                            # Add import for Tailwind CSS Vite plugin
                            if ($astroConfig -match "import { defineConfig } from 'astro/config';") {
                                $astroConfig = $astroConfig -replace "import { defineConfig } from 'astro/config';", "import { defineConfig } from 'astro/config';`nimport tailwindcss from '@tailwindcss/vite';"
                            }
                            
                            # Add Vite configuration with Tailwind plugin
                            if ($astroConfig -match "export default defineConfig\(\{\s*\}\);") {
                                # Empty config - add vite section
                                $astroConfig = $astroConfig -replace "export default defineConfig\(\{\s*\}\);", "export default defineConfig({`n  vite: {`n    plugins: [tailwindcss()],`n  },`n});"
                            } elseif ($astroConfig -match "export default defineConfig\(\{([^}]*)\}\);") {
                                # Existing config - add vite section
                                $astroConfig = $astroConfig -replace "export default defineConfig\(\{", "export default defineConfig({`n  vite: {`n    plugins: [tailwindcss()],`n  },"
                            }
                            
                            Set-Content $astroConfigPath $astroConfig -Encoding utf8
                            Write-Host "✅ Tailwind CSS v4 Vite plugin configured in astro.config.mjs" -ForegroundColor Green
                        } else {
                            Write-Host "✓ Tailwind CSS v4 already configured in astro.config.mjs" -ForegroundColor Green
                        }
                    }
                    
                    Write-Host "✅ Tailwind CSS v4 setup completed" -ForegroundColor Green
                    Write-Host "   → global.css already includes @import 'tailwindcss'" -ForegroundColor Gray
                    Write-Host "   → BaseLayout.astro imports global.css" -ForegroundColor Gray
                    
                }
                finally {
                    Pop-Location
                }
                
                Write-Host "🎉 Custom Enhanced Template applied successfully!" -ForegroundColor Green
                Write-Host "   ✅ Tailwind CSS v4 configured (Vite plugin)" -ForegroundColor White
                Write-Host "   ✅ Dark mode support with CSS variables" -ForegroundColor White
                Write-Host "   ✅ Enhanced global styles included" -ForegroundColor White
                Write-Host "   ✅ Azure-optimized project structure" -ForegroundColor White
            } else {
                Write-Warning "Template source not found: $templatesPath"
            }
        }
        
        # Remove .vscode folder from app directory (we use root-level .vscode)
        $appVscodePath = Join-Path $ProjectName "app" ".vscode"
        if (Test-Path $appVscodePath) {
            Remove-Item $appVscodePath -Recurse -Force
            Write-Host "✓ Removed app/.vscode folder (using root-level .vscode instead)" -ForegroundColor Green
        }
        
        # Update package.json in the app directory with actual project name
        Write-Host "Updating app/package.json with project name..." -ForegroundColor Yellow
        $packageJsonPath = Join-Path $ProjectName "app" "package.json"
        if (Test-Path $packageJsonPath) {
            try {
                $packageContent = Get-Content $packageJsonPath -Raw
                $packageContent = $packageContent -replace '\{\{PROJECT_NAME\}\}', $ProjectName
                # Also update the name field to reflect it's the app component
                $packageContent = $packageContent -replace '"name": "[^"]*"', "`"name`": `"$ProjectName-app`""
                Set-Content $packageJsonPath $packageContent -Encoding utf8
                Write-Host "✓ Updated app/package.json with project name: $ProjectName-app" -ForegroundColor Green
            }
            catch {
                Write-Warning "Could not update app/package.json: $_"
            }
        }
        
        Write-Host "`n🎉 Project '$ProjectName' structure ready!" -ForegroundColor Cyan
        Write-Host "   📁 $ProjectName/" -ForegroundColor White
        Write-Host "     📁 app/        (Astro application)" -ForegroundColor White
        
        # Write template flag for copy script
        $flagFile = Join-Path $ProjectName ".template-flag"
        if ($useCustomTemplate) {
            Set-Content $flagFile "CUSTOM_ENHANCED" -Encoding utf8
            Write-Host "✓ Custom Enhanced Template flag set" -ForegroundColor Green
        } else {
            Set-Content $flagFile "STANDARD_ASTRO" -Encoding utf8
            Write-Host "✓ Standard Astro Template flag set" -ForegroundColor Green
        }
        
        exit 0
    } else {
        throw "Astro project creation failed"
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
