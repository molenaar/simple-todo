Write-Host "=== Environment Verification ===" -ForegroundColor Cyan

# 0. Astro CLI Installation Check
Write-Host "`nChecking Astro CLI installation..." -ForegroundColor Yellow
try {
    $astroVersion = astro --version
    Write-Host "Astro CLI found: $astroVersion" -ForegroundColor Green
} catch {
    Write-Host "Astro CLI not found - Installing now..." -ForegroundColor Yellow
    try {
        npm install -g astro
        Write-Host "Astro CLI installed successfully" -ForegroundColor Green
        
        # Refresh environment variables
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        $astroVersion = astro --version
        Write-Host "Astro CLI version: $astroVersion" -ForegroundColor Green
    } catch {
        Write-Host "Error installing Astro CLI: $_" -ForegroundColor Red
        Write-Host "Please restart your terminal and try again" -ForegroundColor Yellow
    }
}

# 1. Version checks
Write-Host "`n1. Version Information:" -ForegroundColor Yellow
Write-Host "Node.js: $(node --version)"
Write-Host "npm: $(npm --version)"
Write-Host "Astro: $(try { astro --version } catch { 'Not installed' })"

# 2. Global npm packages
Write-Host "`n2. Global npm packages:" -ForegroundColor Yellow
npm list -g --depth=0

# 3. Global paths
Write-Host "`n3. Environment Paths:" -ForegroundColor Yellow
Write-Host "npm global: $(npm prefix -g)"
Write-Host "npm root: $(npm root -g)"

# 4. SSL verification
Write-Host "`n4. SSL Connection Test:" -ForegroundColor Yellow
$sslTest = Test-NetConnection -ComputerName "registry.npmjs.org" -Port 443
Write-Host "SSL Connection: $($sslTest.TcpTestSucceeded)"

# 5. Project readiness
Write-Host "`n5. Project Setup Test:" -ForegroundColor Yellow
if (Test-Path "package.json") {
    Write-Host "package.json exists: Yes"
    $packageJson = Get-Content "package.json" | ConvertFrom-Json
    
    Write-Host "Dependencies:"
    if ($packageJson.dependencies) {
        $packageJson.dependencies | Format-Table -AutoSize
    } else {
        Write-Host "  No production dependencies found"
    }
    
    Write-Host "Dev Dependencies:"
    if ($packageJson.devDependencies) {
        $packageJson.devDependencies | Format-Table -AutoSize
    } else {
        Write-Host "  No dev dependencies found"
    }
} else {
    Write-Host "package.json exists: No"
}

Write-Host "`nVerification complete!" -ForegroundColor Green