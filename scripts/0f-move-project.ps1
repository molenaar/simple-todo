param(
    [string]$targetPath = "c:\git",
    [string]$excludeDirs = ".git,.vscode,node_modules",
    [string]$projectName,
    [switch]$force,
    [switch]$cleanup
)

function Get-ProjectDirectories {
    $excludeList = $excludeDirs -split ','
    Get-ChildItem -Directory | 
        Where-Object { $excludeList -notcontains $_.Name } |
        Sort-Object Name
}

function Test-TargetPath {
    param($path)
    if (-not (Test-Path $path)) {
        throw "Target path does not exist: $path"
    }
    if (-not (Get-Item $path).PSIsContainer) {
        throw "Target path is not a directory: $path"
    }
    return $true
}

function Test-ProjectStructure {
    param($projectDir)
    $requiredFiles = @("package.json", "astro.config.mjs")
    $hasValidStructure = $false
    
    foreach ($file in $requiredFiles) {
        if (Test-Path (Join-Path $projectDir $file)) {
            $hasValidStructure = $true
            break
        }
    }
    
    if (-not $hasValidStructure) {
        Write-Warning "Project directory '$($projectDir)' may not be an Astro project (missing package.json or astro.config.mjs)"
        if (-not $force) {
            $response = Read-Host "Continue anyway? (y/N)"
            return ($response -eq 'y' -or $response -eq 'Y')
        }
    }
    return $true
}

function Move-ProjectWithCleanup {
    param($sourceDir, $targetPath, $cleanup)
    
    $sourceName = $sourceDir.Name
    $destinationPath = Join-Path $targetPath $sourceName
    
    # Check if destination already exists
    if (Test-Path $destinationPath) {
        if (-not $force) {
            $response = Read-Host "Destination '$destinationPath' already exists. Overwrite? (y/N)"
            if ($response -ne 'y' -and $response -ne 'Y') {
                Write-Host "Operation cancelled" -ForegroundColor Yellow
                return $false
            }
        }
        Remove-Item $destinationPath -Recurse -Force
        Write-Host "Removed existing destination: $destinationPath" -ForegroundColor Yellow
    }
    
    # Move the directory
    Move-Item -Path $sourceDir.FullName -Destination $targetPath -Force
    Write-Host "Moved '$sourceName' to '$targetPath'" -ForegroundColor Green
    
    # Optional cleanup tasks
    if ($cleanup) {
        $newLocation = Join-Path $targetPath $sourceName
        Write-Host "Performing cleanup tasks..." -ForegroundColor Yellow
        
        # Remove node_modules if exists
        $nodeModulesPath = Join-Path $newLocation "node_modules"
        if (Test-Path $nodeModulesPath) {
            Remove-Item $nodeModulesPath -Recurse -Force
            Write-Host "Removed node_modules" -ForegroundColor Gray
        }
        
        # Remove .astro cache if exists  
        $astroCachePath = Join-Path $newLocation ".astro"
        if (Test-Path $astroCachePath) {
            Remove-Item $astroCachePath -Recurse -Force
            Write-Host "Removed .astro cache" -ForegroundColor Gray
        }
        
        # Remove dist if exists
        $distPath = Join-Path $newLocation "dist"
        if (Test-Path $distPath) {
            Remove-Item $distPath -Recurse -Force
            Write-Host "Removed dist folder" -ForegroundColor Gray
        }
    }
    
    return Join-Path $targetPath $sourceName
}

function Show-DirectoryMenu {
    param($directories)
    Write-Host "`nAvailable project directories:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $directories.Count; $i++) {
        $dir = $directories[$i]
        $hasPackageJson = Test-Path (Join-Path $dir.FullName "package.json")
        $hasAstroConfig = Test-Path (Join-Path $dir.FullName "astro.config.mjs")
        $indicator = if ($hasPackageJson -or $hasAstroConfig) { " ✓" } else { "" }
        Write-Host "$($i+1)) $($dir.Name)$indicator"
    }
    Write-Host "0) Exit"
    Write-Host "`n✓ = Detected Astro project" -ForegroundColor Gray
}

try {
    # Validate target path
    Test-TargetPath $targetPath | Out-Null
    
    if ($projectName) {
        # Direct mode with project name
        $projectDir = Get-ChildItem -Directory | Where-Object { $_.Name -eq $projectName }
        if (-not $projectDir) {
            Write-Host "Error: Project directory '$projectName' not found" -ForegroundColor Red
            exit 1
        }
        
        if (-not (Test-ProjectStructure $projectDir.FullName)) {
            exit 1
        }
        
        $newLocation = Move-ProjectWithCleanup $projectDir $targetPath $cleanup
        if ($newLocation) {
            Set-Location $newLocation
            Write-Host "Changed directory to: $newLocation" -ForegroundColor Green
            Write-Host "Project move completed successfully!" -ForegroundColor Green
        }
        exit 0
    }
    
    # Interactive mode
    $dirs = @(Get-ProjectDirectories)
    if ($dirs.Count -eq 0) {
        throw "No valid project directories found"
    }

    Show-DirectoryMenu $dirs
    $selection = Read-Host "`nSelect project to move (1-$($dirs.Count), 0 to exit)"

    if ($selection -eq "0") { 
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0 
    }

    if ([int]::TryParse($selection, [ref]$null) -and $selection -ge 1 -and $selection -le $dirs.Count) {
        $selectedDir = $dirs[$selection-1]
        
        # Validate project structure
        if (-not (Test-ProjectStructure $selectedDir.FullName)) {
            exit 1
        }
        
        # Get target path
        $userPath = Read-Host "Enter target path [$targetPath]"
        if (![string]::IsNullOrWhiteSpace($userPath)) {
            $targetPath = $userPath
            Test-TargetPath $targetPath | Out-Null
        }

        # Confirm operation
        $cleanupText = if ($cleanup) { " with cleanup" } else { "" }
        $confirm = Read-Host "Move '$($selectedDir.Name)' to '$targetPath'$cleanupText? (y/n)"
        
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            $newLocation = Move-ProjectWithCleanup $selectedDir $targetPath $cleanup
            if ($newLocation) {
                Set-Location $newLocation
                Write-Host "Changed directory to: $newLocation" -ForegroundColor Green
                Write-Host "Project move completed successfully!" -ForegroundColor Green
            }
        } else {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
        }
        exit 0
    } else {
        throw "Invalid selection"
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}