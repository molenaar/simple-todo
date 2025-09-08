# Stop Azurite Storage Emulator
# This script finds and terminates Azurite processes running on ports 10000, 10001, 10002

Write-Host "Stopping Azurite storage emulator..." -ForegroundColor Yellow

# Find processes listening on Azurite ports
try {
    $azuriteProcessIds = (netstat -ano | Select-String "10000|10001|10002" | ForEach-Object { ($_ -split "\s+")[-1] } | Sort-Object -Unique)
    
    if ($azuriteProcessIds) {
        Write-Host "Found Azurite processes: $($azuriteProcessIds -join ', ')" -ForegroundColor Cyan
        
        $azuriteProcessIds | ForEach-Object {
            try {
                Stop-Process -Id $_ -Force -ErrorAction Stop
                Write-Host "Stopped process ID: $_" -ForegroundColor Green
            }
            catch {
                Write-Host "Could not stop process ID: $_ (may already be stopped)" -ForegroundColor Yellow
            }
        }
        
        Write-Host "Azurite storage emulator stopped successfully" -ForegroundColor Green
    } else {
        Write-Host "Azurite is not running" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error stopping Azurite: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
