param(
    [string]$excludeDirs = ".git,.vscode,node_modules",
    [string]$ProjectName = "my-astro-project",
    [string]$ProjectPath,  # Full path to target project
    [switch]$force,
    [switch]$skipOverwriteCheck  # Skip overwrite confirmation (for orchestrated installs)
)

function Get-ProjectDirectories {
    $excludeList = $excludeDirs -split ','
    Get-ChildIt    if ([int]::TryParse($selection, [ref]$null) -and $selection -ge 1 -and $selection -le $dirs.Count) {
        $targetDir = $dirs[$selection-1].FullName
        
        # Validate project structure
        if (-not (Test-ProjectStructure $targetDir)) {
            exit 1
        }
        
        if (-not (Confirm-Overwrite $targetDir)) {
            exit 0
        }
        
        Copy-TemplateFiles $targetDir $templatePath
        Write-Host "Template files copied successfully!" -ForegroundColor Green
        exit 0
    } else {
        throw "Invalid selection"
    } | 
        Where-Object { $excludeList -notcontains $_.Name } |
        Sort-Object Name
}

function Test-TemplatePath {
    # When running from template location, we ARE in templates/scripts/, so go up to templates/
    $templatePath = Split-Path $PSScriptRoot -Parent
    if (-not (Test-Path $templatePath)) {
        throw "Template directory not found at: $templatePath"
    }
    return $templatePath
}

function Copy-TemplateFiles {
    param($targetDir, $templatePath)
    
    Write-Host "Copying template files to $targetDir..." -ForegroundColor Yellow
    
    # With new structure, everything is in templates directory
    $templatesDir = Join-Path $templatePath "templates"
    
    if (-not (Test-Path $templatesDir)) {
        throw "Templates directory not found at: $templatesDir"
    }
    
    # Check template flag to determine what to copy
    $flagFile = Join-Path $targetDir ".template-flag"
    $templateType = "STANDARD_ASTRO"  # Default
    if (Test-Path $flagFile) {
        $templateType = Get-Content $flagFile -Raw | ForEach-Object { $_.Trim() }
        Write-Host "Template type detected: $templateType" -ForegroundColor Cyan
    }
    
    # Copy all template files and directories to target (except scripts which we handle separately)
    Write-Host "Using templates from: $templatesDir" -ForegroundColor Cyan
    Get-ChildItem $templatesDir | Where-Object { 
        $_.Name -ne "scripts" -and 
        # Skip app folder for standard templates (Astro CLI already created it)
        -not ($_.Name -eq "app" -and $templateType -eq "STANDARD_ASTRO")
    } | ForEach-Object {
        $destination = Join-Path $targetDir $_.Name
        if ($_.PSIsContainer) {
            Copy-Item $_.FullName -Destination $destination -Recurse -Force
            Write-Host "Copied directory: $($_.Name)" -ForegroundColor Gray
        } else {
            Copy-Item $_.FullName -Destination $destination -Force
            Write-Host "Copied file: $($_.Name)" -ForegroundColor Gray
        }
    }
    
    # Clean up the flag file (no longer needed)
    if (Test-Path $flagFile) {
        Remove-Item $flagFile -Force
        Write-Host "✓ Cleaned up template flag file" -ForegroundColor Green
    }
    
    # Copy scripts separately (current scripts, not template scripts)
    $scriptsDir = Join-Path $targetDir "scripts"
    if (-not (Test-Path $scriptsDir)) {
        New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
        Write-Host "Created directory: scripts" -ForegroundColor Green
    }
    
    $scriptFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | 
        Where-Object { 
            $_.Name -notlike "*template*" -and 
            $_.Name -ne "0-setup-astro-project.ps1"  # Don't copy the main orchestrator
        }
    
    foreach ($file in $scriptFiles) {
        Copy-Item $file.FullName -Destination $scriptsDir -Force
        Write-Host "Copied script: $($file.Name)" -ForegroundColor Gray
    }
    
    # Replace template variables in copied files
    Update-TemplateVariables $targetDir $ProjectName
}

function Update-TemplateVariables {
    param($targetDir, $projectName)
    
    Write-Host "Updating template variables..." -ForegroundColor Yellow
    
    # Get all files that might contain template variables (excluding node_modules, .git, etc.)
    $filesToUpdate = Get-ChildItem -Path $targetDir -Recurse -File | 
        Where-Object { 
            $_.Extension -match '\.(json|md|ps1|astro|ts|js|css|html|yml|yaml)$' -and
            $_.FullName -notmatch '\\(node_modules|\.git|\.next|dist|build)\\' 
        }
    
    foreach ($file in $filesToUpdate) {
        try {
            $content = Get-Content $file.FullName -Raw -ErrorAction Stop
            if ($content -and $content.Contains("{{PROJECT_NAME}}")) {
                $newContent = $content -replace "\{\{PROJECT_NAME\}\}", $projectName
                Set-Content $file.FullName -Value $newContent -NoNewline
                Write-Host "Updated variables in: $($file.Name)" -ForegroundColor Green
            }
        } catch {
            Write-Warning "Could not update variables in: $($file.FullName) - $($_.Exception.Message)"
        }
    }
}

function Show-DirectoryMenu {
    param($directories)
    Write-Host "`nAvailable project directories:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $directories.Count; $i++) {
        Write-Host "$($i+1)) $($directories[$i].Name)"
    }
    Write-Host "0) Exit"
    Write-Host "`n💡 Tip: For projects in other locations, use:" -ForegroundColor Yellow
    Write-Host "   .\scripts\0e-copy-scripts.ps1 -ProjectPath `"C:\path\to\your\project`"" -ForegroundColor Gray
}

function Show-UsageHelp {
    Write-Host "`n🚀 Astro Template Enhancer" -ForegroundColor Cyan
    Write-Host "This script copies enhanced development templates to existing Astro projects." -ForegroundColor White
    Write-Host ""
    Write-Host "📁 Important: Project Structure Requirement" -ForegroundColor Yellow
    Write-Host "This template system expects your Astro website to be in an 'app/' subfolder." -ForegroundColor White
    Write-Host "If your Astro files are in the root directory, please:" -ForegroundColor White
    Write-Host "  1. Create an 'app' folder in your project root" -ForegroundColor Gray
    Write-Host "  2. Move all Astro files (src/, public/, astro.config.mjs, etc.) into app/" -ForegroundColor Gray
    Write-Host "  3. Then run this script to add the enhanced workflow" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Usage examples:" -ForegroundColor Yellow
    Write-Host "  .\scripts\0e-copy-scripts.ps1 -ProjectPath `"C:\git\my-project`" -force" -ForegroundColor Gray
    Write-Host "  .\scripts\0e-copy-scripts.ps1 -ProjectName `"local-project`" -force" -ForegroundColor Gray
    Write-Host "  .\scripts\0e-copy-scripts.ps1 (interactive mode)" -ForegroundColor Gray
    Write-Host "  .\scripts\0e-copy-scripts.ps1 -ProjectPath `"C:\git\project`" -skipOverwriteCheck" -ForegroundColor Gray
    Write-Host ""
    Write-Host "What gets copied:" -ForegroundColor Yellow
    Write-Host "  • Development scripts (build, start, SWA integration)" -ForegroundColor Gray
    Write-Host "  • VS Code configuration (settings, tasks, launch)" -ForegroundColor Gray
    Write-Host "  • GitHub Copilot templates (instructions, chat modes)" -ForegroundColor Gray
    Write-Host "  • Azure Functions API setup" -ForegroundColor Gray
    Write-Host "  • Documentation and guides" -ForegroundColor Gray
    Write-Host ""
}

function Confirm-Overwrite {
    param($targetDir)
    
    # Skip confirmation if requested (for orchestrated installs)
    if ($skipOverwriteCheck) {
        return $true
    }
    
    # Check for various indicators that this is an existing project
    $existingFiles = @()
    
    # Check for scripts directory (indicates previous template installation)
    if (Test-Path (Join-Path $targetDir "scripts")) {
        $existingFiles += "scripts/"
    }
    
    # Check for app folder with Astro files
    $appDir = Join-Path $targetDir "app"
    if (Test-Path $appDir) {
        $astroFiles = @("src", "public", "astro.config.mjs", "astro.config.js", "astro.config.ts", "package.json")
        $foundAstroFiles = $astroFiles | Where-Object { Test-Path (Join-Path $appDir $_) }
        if ($foundAstroFiles.Count -gt 0) {
            $existingFiles += "app/ (with Astro project files)"
        }
    }
    
    # Check for other common project files in root
    $rootFiles = @(".vscode", ".github", "api", "package.json", "README.md")
    $foundRootFiles = $rootFiles | Where-Object { Test-Path (Join-Path $targetDir $_) }
    $existingFiles += $foundRootFiles
    
    if ($existingFiles.Count -gt 0) {
        if (-not $force) {
            Write-Host "`n⚠️  Existing project files detected:" -ForegroundColor Yellow
            $existingFiles | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }
            Write-Host ""
            Write-Host "This will overwrite/merge with existing files." -ForegroundColor White
            $response = Read-Host "Continue and overwrite existing files? (y/N)"
            if ($response -ne 'y' -and $response -ne 'Y') {
                Write-Host "Operation cancelled" -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host "Force mode: Overwriting existing project files..." -ForegroundColor Yellow
        }
    }
    return $true
}

function Test-ProjectStructure {
    param($targetDir)
    
    $appDir = Join-Path $targetDir "app"
    $hasAppFolder = Test-Path $appDir
    
    # Check for common Astro files in root (indicates wrong structure)
    $astroFiles = @("src", "public", "astro.config.mjs", "astro.config.js", "astro.config.ts")
    $astroFilesInRoot = $astroFiles | Where-Object { Test-Path (Join-Path $targetDir $_) }
    
    if (-not $hasAppFolder -and $astroFilesInRoot.Count -gt 0) {
        Write-Host "`n❌ Project Structure Issue Detected!" -ForegroundColor Red
        Write-Host "Your Astro project files are in the root directory, but this template system" -ForegroundColor Yellow
        Write-Host "expects them to be in an 'app/' subfolder." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Found Astro files in root:" -ForegroundColor White
        $astroFilesInRoot | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }
        Write-Host ""
        Write-Host "Please restructure your project first:" -ForegroundColor Cyan
        Write-Host "  1. Create an 'app' folder: mkdir app" -ForegroundColor Gray
        Write-Host "  2. Move Astro files into app/: move src app/, move public app/, etc." -ForegroundColor Gray
        Write-Host "  3. Update any path references in your project" -ForegroundColor Gray
        Write-Host "  4. Then re-run this script" -ForegroundColor Gray
        Write-Host ""
        return $false
    }
    
    if (-not $hasAppFolder) {
        Write-Host "`n⚠️  No 'app' folder found in target directory." -ForegroundColor Yellow
        Write-Host "This template system expects your Astro project to be in an 'app/' subfolder." -ForegroundColor White
        Write-Host "Please ensure your project structure is correct before continuing." -ForegroundColor White
        Write-Host ""
        if (-not $force) {
            $response = Read-Host "Continue anyway? (y/N)"
            if ($response -ne 'y' -and $response -ne 'Y') {
                Write-Host "Operation cancelled" -ForegroundColor Yellow
                return $false
            }
        }
    }
    
    return $true
}

try {
    # Validate template directory
    $templatePath = Test-TemplatePath
    
    if ($ProjectPath) {
        # Direct mode with full project path
        $targetDir = $ProjectPath
        if (-not (Test-Path $targetDir)) {
            Write-Host "Error: Project directory '$ProjectPath' not found" -ForegroundColor Red
            exit 1
        }
        
        # Validate project structure
        if (-not (Test-ProjectStructure $targetDir)) {
            exit 1
        }
        
        if (-not (Confirm-Overwrite $targetDir)) {
            exit 0
        }
        
        # Use the directory name as project name if not specified
        if ($ProjectName -eq "my-astro-project") {
            $ProjectName = Split-Path $ProjectPath -Leaf
        }
        
        Copy-TemplateFiles $targetDir $templatePath
        Write-Host "Template files copied successfully to $ProjectPath!" -ForegroundColor Green
        exit 0
    }
    
    if ($projectName -and $projectName -ne "my-astro-project") {
        # Direct mode with project name (legacy behavior)
        $targetDir = Join-Path (Get-Location) $projectName
        if (-not (Test-Path $targetDir)) {
            Write-Host "Error: Project directory '$projectName' not found" -ForegroundColor Red
            exit 1
        }
        
        # Validate project structure
        if (-not (Test-ProjectStructure $targetDir)) {
            exit 1
        }
        
        if (-not (Confirm-Overwrite $targetDir)) {
            exit 0
        }
        
        Copy-TemplateFiles $targetDir $templatePath
        Write-Host "Template files copied successfully to $projectName!" -ForegroundColor Green
        exit 0
    }
    
    # Interactive mode
    $dirs = @(Get-ProjectDirectories)
    
    # Check if we're in the template directory (not useful for interactive mode)
    $currentPath = Get-Location
    $isTemplateDir = $currentPath.Path -like "*astro*" -and (Test-Path "templates")
    
    if ($dirs.Count -eq 0 -or ($isTemplateDir -and $dirs.Count -le 3)) {
        Show-UsageHelp
        Write-Host "⚠️  No suitable project directories found in current location." -ForegroundColor Yellow
        Write-Host "This script is designed to enhance existing Astro projects." -ForegroundColor White
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "1. Navigate to parent directory containing your projects" -ForegroundColor Gray
        Write-Host "2. Use -ProjectPath parameter with full path to your project" -ForegroundColor Gray
        Write-Host "3. Use -ProjectName parameter if project is in current directory" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Example: .\scripts\0e-copy-scripts.ps1 -ProjectPath `"C:\git\my-astro-project`"" -ForegroundColor Green
        exit 0
    }

    Show-DirectoryMenu $dirs
    $selection = Read-Host "`nSelect project directory (1-$($dirs.Count), 0 to exit)"

    if ($selection -eq "0") { 
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0 
    }

    if ([int]::TryParse($selection, [ref]$null) -and $selection -ge 1 -and $selection -le $dirs.Count) {
        $targetDir = $dirs[$selection-1].FullName
        
        if (-not (Confirm-Overwrite $targetDir)) {
            exit 0
        }
        
        Copy-TemplateFiles $targetDir $templatePath
        Write-Host "Template files copied successfully!" -ForegroundColor Green
        exit 0
    } else {
        throw "Invalid selection"
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}