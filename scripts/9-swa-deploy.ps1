<#
.SYNOPSIS
    Deploy the Astro app to Azure Static Web Apps.

.DESCRIPTION
    Script Sequence: [9] <-- You are here
    1. BUILD - Basic project build
    2. START - Run the Astro app locally
    3. UPDATE-DEPS - Update dependencies
    4. SWA-INIT - Initialize SWA CLI configuration
    5. SWA-BUILD - Build with SWA CLI
    6. SWA-START - Run with SWA emulator
    7. SWA-LOGIN - Log in to Azure
    8. SWA-AZURE - Create Azure resources
    9. SWA-DEPLOY - Deploy to Azure (current)
    
.NOTES
    This script deploys the Astro application to the appropriate environment
    in Azure Static Web Apps based on the current branch.
#>

# Deploy to Azure Static Web App

# Get the repository root path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Change to repository root directory first
Set-Location $repoRoot

# Check if we have uncommitted changes
Write-Host "Checking Git status..." -ForegroundColor Cyan
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "⚠️ You have uncommitted changes. Please commit them first." -ForegroundColor Yellow
    git status --short
    $continueChoice = Read-Host "Continue deployment anyway? (Y/N)"
    if ($continueChoice -ne "Y") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit
    }
}

# Deploy using npm script
Write-Host "Deploying to Azure Static Web Apps..." -ForegroundColor Cyan
Write-Host "Using npm script: npm run deploy" -ForegroundColor Yellow
Write-Host "This uses SWA CLI to deploy both app and API to Azure" -ForegroundColor Yellow

npm run deploy

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
} else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
}
            Write-Host "Changes committed locally but not pushed." -ForegroundColor Yellow
            Write-Host "Remember to push your changes later with 'git push origin $currentBranch'" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Proceeding with uncommitted changes. These changes will NOT be included in the deployment." -ForegroundColor Yellow
        $proceed = Read-Host "Do you want to continue anyway? (Y/N)"
        if ($proceed -ne "Y") {
            Write-Host "Deployment canceled." -ForegroundColor Red
            exit
        }
    }
} else {
    Write-Host "✅ Git repository is clean - no uncommitted changes." -ForegroundColor Green
    
    # Check if current branch has upstream and needs pushing
    $currentBranch = git rev-parse --abbrev-ref HEAD
    try {
        # Check if there's an upstream branch
        $upstream = git rev-parse --abbrev-ref "$currentBranch@{upstream}" 2>$null
        if ($LASTEXITCODE -eq 0) {
            # Branch has an upstream, check if we're ahead
            $ahead = git rev-list --count "$currentBranch@{upstream}..$currentBranch" 2>$null
            if ($ahead -gt 0) {
                Write-Host "⚠️ Your local branch '$currentBranch' has $ahead commit(s) that need to be pushed to the remote repository." -ForegroundColor Yellow
                
                $pushChoice = Read-Host "Would you like to push these changes to the remote repository? (Y/N)"
                if ($pushChoice -eq "Y") {
                    git push origin $currentBranch
                    Write-Host "Changes pushed to $currentBranch" -ForegroundColor Green
                } else {
                    Write-Host "Proceeding without pushing changes. Your deployment may not match your local code." -ForegroundColor Yellow
                    $proceed = Read-Host "Do you want to continue anyway? (Y/N)"
                    if ($proceed -ne "Y") {
                        Write-Host "Deployment canceled." -ForegroundColor Red
                        exit
                    }
                }
            } else {
                Write-Host "✅ Your branch is up to date with the remote repository." -ForegroundColor Green
            }
        } else {
            # Branch has no upstream
            Write-Host "⚠️ Your branch '$currentBranch' has no upstream branch set." -ForegroundColor Yellow
            $pushChoice = Read-Host "Would you like to push and set upstream for this branch? (Y/N)"
            if ($pushChoice -eq "Y") {
                git push --set-upstream origin $currentBranch
                Write-Host "Branch pushed and upstream set to origin/$currentBranch" -ForegroundColor Green
            } else {
                Write-Host "Proceeding without pushing changes. Your deployment will only include committed changes." -ForegroundColor Yellow
                $proceed = Read-Host "Do you want to continue anyway? (Y/N)"
                if ($proceed -ne "Y") {
                    Write-Host "Deployment canceled." -ForegroundColor Red
                    exit
                }
            }
        }
    } catch {
        Write-Host "⚠️ Unable to check remote branch status. Git may not be properly configured." -ForegroundColor Yellow
        $proceed = Read-Host "Do you want to continue anyway? (Y/N)"
        if ($proceed -ne "Y") {
            Write-Host "Deployment canceled." -ForegroundColor Red
            exit
        }
    }
}

# First build the application
Write-Host "Building the Astro application..." -ForegroundColor Cyan
swa build astro-app

# Get current git branch
$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host "Current git branch: $currentBranch" -ForegroundColor Green

# Recommend environment based on branch
$recommendedEnv = if ($currentBranch -eq "main") { "production" } else { "dev" }
Write-Host "Recommended environment for this branch: $recommendedEnv" -ForegroundColor Yellow

# Ask user which environment to deploy to
Write-Host "Select deployment environment:" -ForegroundColor Cyan
Write-Host "[1] Production (main branch)" -ForegroundColor White
Write-Host "[2] Development (dev branch)" -ForegroundColor White
Write-Host "[3] Custom environment name" -ForegroundColor White

$choice = Read-Host "Enter your choice (default: $recommendedEnv)"

$deployEnv = switch ($choice) {
    "1" { "production" }
    "2" { "dev" }
    "3" { Read-Host "Enter custom environment name" }
    default { $recommendedEnv }
}

# Confirm deployment
Write-Host "Ready to deploy to environment: $deployEnv" -ForegroundColor Yellow
$confirm = Read-Host "Continue? (Y/N)"

if ($confirm -ne "Y") {
    Write-Host "Deployment canceled." -ForegroundColor Red
    exit
}

# Deploy to selected environment
Write-Host "Deploying to $deployEnv environment..." -ForegroundColor Cyan
swa deploy astro-app --env $deployEnv

Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host "Visit the Azure portal to find your app URLs:" -ForegroundColor Cyan
Write-Host "https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.Web%2FStaticSites" -ForegroundColor Blue