# Quick Upload Script for Azure Container Apps Repository
# This script helps you fork, clone, and prepare a PR

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Azure Container Apps - Upload Helper" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$sourceFolder = "c:\Users\vyomnagrani\OneDrive - Microsoft\Documents\Code\dev\aca-getting-started"
$workDir = "c:\Users\vyomnagrani\OneDrive - Microsoft\Documents\Code\dev"

Write-Host "Step 1: Fork the repository" -ForegroundColor Yellow
Write-Host "Please fork https://github.com/microsoft/azure-container-apps on GitHub" -ForegroundColor White
Write-Host "Press Enter when you've forked the repository..." -ForegroundColor Green
Read-Host

Write-Host ""
Write-Host "Step 2: Enter your GitHub username" -ForegroundColor Yellow
$githubUsername = Read-Host "GitHub Username"

Write-Host ""
Write-Host "Step 3: Cloning your fork..." -ForegroundColor Yellow
Set-Location $workDir

if (Test-Path "azure-container-apps") {
    Write-Host "Repository already exists. Pulling latest changes..." -ForegroundColor Cyan
    Set-Location azure-container-apps
    git pull
} else {
    git clone "https://github.com/$githubUsername/azure-container-apps.git"
    Set-Location azure-container-apps
}

Write-Host ""
Write-Host "Step 4: Setting upstream remote..." -ForegroundColor Yellow
git remote add upstream https://github.com/microsoft/azure-container-apps.git 2>$null
git fetch upstream

Write-Host ""
Write-Host "Step 5: Creating new branch..." -ForegroundColor Yellow
git checkout -b add-getting-started-resources

Write-Host ""
Write-Host "Step 6: Copying aca-getting-started folder..." -ForegroundColor Yellow
Copy-Item -Path $sourceFolder -Destination "." -Recurse -Force

Write-Host ""
Write-Host "Step 7: Staging changes..." -ForegroundColor Yellow
git add aca-getting-started/

Write-Host ""
Write-Host "Step 8: Committing changes..." -ForegroundColor Yellow
git commit -m "Add: Comprehensive getting started resources page

- New resource hub similar to Azure API Management resources
- Includes documentation links, samples, tools, and community resources
- Fully responsive design with modern UI
- Contribution guidelines and GitHub Actions workflows
- FAQ and getting started guides
- Issue and PR templates"

Write-Host ""
Write-Host "Step 9: Pushing to your fork..." -ForegroundColor Yellow
git push origin add-getting-started-resources

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "SUCCESS! Next Steps:" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""
Write-Host "1. Go to: https://github.com/$githubUsername/azure-container-apps" -ForegroundColor Cyan
Write-Host "2. Click 'Compare & pull request'" -ForegroundColor Cyan
Write-Host "3. Fill in the PR details and submit" -ForegroundColor Cyan
Write-Host ""
Write-Host "Opening your fork in browser..." -ForegroundColor Yellow
Start-Process "https://github.com/$githubUsername/azure-container-apps"

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Green
Read-Host
