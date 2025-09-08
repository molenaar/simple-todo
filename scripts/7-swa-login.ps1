<#
.SYNOPSIS
    Log in to Azure and set up SWA CLI authentication.

.DESCRIPTION
    Script Sequence: [7] <-- You are here
    1. BUILD - Basic project build
    2. START - Run the Astro app locally
    3. UPDATE-DEPS - Update dependencies
    4. SWA-INIT - Initialize SWA CLI configuration
    5. SWA-BUILD - Build with SWA CLI
    6. SWA-START - Run with SWA emulator
    7. SWA-LOGIN - Log in to Azure (current)
    8. SWA-AZURE - Create Azure resources
    9. SWA-DEPLOY - Deploy to Azure
    
.NOTES
    This script handles authentication with Azure CLI and SWA CLI, including selection
    of subscription when multiple subscriptions are available across tenants.
#>

# Login to Azure with interactive selection for multiple subscriptions and tenants

# First, login to Azure
Write-Host "Logging in to Azure..." -ForegroundColor Cyan
az login

# List available subscriptions and let user select one
Write-Host "Fetching available subscriptions..." -ForegroundColor Cyan
$subscriptions = az account list --output json | ConvertFrom-Json
Write-Host "Available subscriptions:" -ForegroundColor Green

for ($i = 0; $i -lt $subscriptions.Length; $i++) {
    Write-Host "[$i] $($subscriptions[$i].name) (ID: $($subscriptions[$i].id), Tenant: $($subscriptions[$i].tenantId))"
}

$subscriptionIndex = Read-Host "Select subscription by number"
$selectedSubscription = $subscriptions[$subscriptionIndex]

Write-Host "Setting active subscription to: $($selectedSubscription.name)" -ForegroundColor Yellow
az account set --subscription $selectedSubscription.id

# Set environment variables for SWA CLI
$env:AZURE_SUBSCRIPTION_ID = $selectedSubscription.id
$env:AZURE_TENANT_ID = $selectedSubscription.tenantId

Write-Host "Environment variables set:" -ForegroundColor Green
Write-Host "AZURE_SUBSCRIPTION_ID: $env:AZURE_SUBSCRIPTION_ID"
Write-Host "AZURE_TENANT_ID: $env:AZURE_TENANT_ID"

# Login with SWA CLI using the selected subscription and tenant
Write-Host "Logging in to SWA CLI..." -ForegroundColor Cyan
swa login --tenant-id $env:AZURE_TENANT_ID --subscription-id $env:AZURE_SUBSCRIPTION_ID

Write-Host "Login complete! Ready to deploy." -ForegroundColor Green