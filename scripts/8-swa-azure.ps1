<#
.SYNOPSIS
    Create Azure Static Web App resources in Azure.

.DESCRIPTION
    Script Sequence: [8] <-- You are here
    1. BUILD - Basic project build
    2. START - Run the Astro app locally
    3. UPDATE-DEPS - Update dependencies
    4. SWA-INIT - Initialize SWA CLI configuration
    5. SWA-BUILD - Build with SWA CLI
    6. SWA-START - Run with SWA emulator
    7. SWA-LOGIN - Log in to Azure
    8. SWA-AZURE - Create Azure resources (current)
    9. SWA-DEPLOY - Deploy to Azure
    
.NOTES
    This script creates the Azure Static Web App resource and configures
    the GitHub repository integration for your Astro site.
#>

# Variables
# Azure configuration
$resourceGroup = "rg-swa"
$location = "westeurope"
$appName = "swa-website"
$skuName = "Free"

# GitHub configuration
$githubUsername = "molenaar"
$githubRepo = "website"
$branchName = "main"

# App configuration - specific to Astro
$appLocation = "."
$outputLocation = "dist"
$apiLocation = ""

# Check if logged in already
$loginStatus = az account show 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged into Azure. Please run 7-swa-login.ps1 first." -ForegroundColor Red
    exit 1
}
Write-Host "Already logged into Azure." -ForegroundColor Green

# Ask the user to verify the github username and repo
Write-Host "GitHub username: $githubUsername"
Write-Host "GitHub repo: $githubRepo"
Write-Host "Branch: $branchName"
$userInput = Read-Host -Prompt "Is this correct? (Y/N)"
if ($userInput -ne "Y") {
    $userInput = Read-Host -Prompt "Enter the GitHub username"
    $githubUsername = ($userInput.Length -gt 0) ? $userInput : $githubUsername
    $userInput = Read-Host -Prompt "Enter the GitHub repo"
    $githubRepo = ($userInput.Length -gt 0) ? $userInput : $githubRepo
    $userInput = Read-Host -Prompt "Enter the branch name"
    $branchName = ($userInput.Length -gt 0) ? $userInput : $branchName
}

$githubUrl = "https://github.com/$githubUsername/$githubRepo"

# Ask the user to verify the resource group and location
Write-Host "Resource group: $resourceGroup"
Write-Host "Location: $location"
Write-Host "App name: $appName"
$userInput = Read-Host -Prompt "Is this correct? (Y/N)"
if ($userInput -ne "Y") {
    $userInput = Read-Host -Prompt "Enter the resource group"
    $resourceGroup = ($userInput.Length -gt 0) ? $userInput : $resourceGroup
    $userInput = Read-Host -Prompt "Enter the location"
    $location = ($userInput.Length -gt 0) ? $userInput : $location
    $userInput = Read-Host -Prompt "Enter the app name"
    $appName = ($userInput.Length -gt 0) ? $userInput : $appName
}

# Summary
Write-Host "Resource group: $resourceGroup"
Write-Host "Location: $location"
Write-Host "App name: $appName"
Write-Host "GitHub username: $githubUsername"
Write-Host "GitHub repo: $githubRepo"
Write-Host "GitHub URL: $githubUrl"
Write-Host "SKU: $skuName"
Write-Host "Branch: $branchName"
Write-Host "App location: $appLocation"
Write-Host "Output location: $outputLocation"
Write-Host "API location: $apiLocation"

# Ask the user to confirm
$userInput = Read-Host -Prompt "Do you want to continue? (Y/N)"
if ($userInput -ne "Y") {
    Write-Host "Operation canceled." -ForegroundColor Yellow
    exit
}

# Create resource group if not exists
az group create --name $resourceGroup --location $location

# Create Static Web App with Free SKU
if ($apiLocation -eq "") {
    # Command without the api-location parameter
    az staticwebapp create `
        --name $appName `
        --resource-group $resourceGroup `
        --location $location `
        --source $githubUrl `
        --branch $branchName `
        --app-location $appLocation `
        --output-location $outputLocation `
        --sku $skuName `
        --login-with-github
} else {
    # Command with the api-location parameter
    az staticwebapp create `
        --name $appName `
        --resource-group $resourceGroup `
        --location $location `
        --source $githubUrl `
        --branch $branchName `
        --app-location $appLocation `
        --output-location $outputLocation `
        --api-location $apiLocation `
        --sku $skuName `
        --login-with-github
}

# Show deployment URL
Write-Host "Deployment URL:" -ForegroundColor Cyan
az staticwebapp show --name $appName --resource-group $resourceGroup --query "defaultHostname" -o tsv