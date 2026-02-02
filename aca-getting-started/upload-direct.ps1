# Direct Upload Script for Azure Container Apps Repository
# This script clones the repo directly and creates a branch for PR

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Azure Container Apps - Direct Upload" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$sourceFolder = "c:\Users\vyomnagrani\OneDrive - Microsoft\Documents\Code\dev\aca-getting-started"
$workDir = "c:\Users\vyomnagrani\OneDrive - Microsoft\Documents\Code\dev"
$repoUrl = "https://github.com/microsoft/azure-container-apps.git"

Write-Host "Step 1: Cloning repository..." -ForegroundColor Yellow
Set-Location $workDir

if (Test-Path "azure-container-apps") {
    Write-Host "Repository already exists. Using existing clone..." -ForegroundColor Cyan
    Set-Location azure-container-apps
    Write-Host "Fetching latest changes..." -ForegroundColor Cyan
    git fetch origin
    git checkout main
    git pull origin main
} else {
    Write-Host "Cloning microsoft/azure-container-apps..." -ForegroundColor Cyan
    git clone $repoUrl
    Set-Location azure-container-apps
}

Write-Host ""
Write-Host "Step 2: Creating new branch..." -ForegroundColor Yellow
$branchName = "add-getting-started-resources"
git checkout -b $branchName 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Branch already exists, switching to it..." -ForegroundColor Cyan
    git checkout $branchName
}

Write-Host ""
Write-Host "Step 3: Copying aca-getting-started folder..." -ForegroundColor Yellow
if (Test-Path "aca-getting-started") {
    Write-Host "Removing existing aca-getting-started folder..." -ForegroundColor Cyan
    Remove-Item -Path "aca-getting-started" -Recurse -Force
}
Copy-Item -Path $sourceFolder -Destination "." -Recurse -Force
Write-Host "✓ Folder copied successfully" -ForegroundColor Green

Write-Host ""
Write-Host "Step 4: Staging changes..." -ForegroundColor Yellow
git add aca-getting-started/
Write-Host "✓ Changes staged" -ForegroundColor Green

Write-Host ""
Write-Host "Step 5: Committing changes..." -ForegroundColor Yellow
git commit -m "Add: Comprehensive getting started resources page

- New resource hub similar to Azure API Management resources
- Includes documentation links, samples, tools, and community resources
- Fully responsive design with modern UI
- Contribution guidelines and GitHub Actions workflows
- FAQ and getting started guides
- Issue and PR templates
- SEO optimization with sitemap and robots.txt"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Changes committed successfully" -ForegroundColor Green
} else {
    Write-Host "! Nothing to commit or commit failed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 6: Pushing to remote..." -ForegroundColor Yellow
Write-Host "Attempting to push branch to origin..." -ForegroundColor Cyan

git push origin $branchName 2>&1 | Tee-Object -Variable pushOutput

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "SUCCESS! Branch pushed to GitHub" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Go to: https://github.com/microsoft/azure-container-apps/pulls" -ForegroundColor White
    Write-Host "2. You should see a prompt to create a PR from your branch" -ForegroundColor White
    Write-Host "3. Click 'Compare & pull request'" -ForegroundColor White
    Write-Host "4. Fill in the PR details and submit" -ForegroundColor White
    Write-Host ""
    Write-Host "Opening GitHub in browser..." -ForegroundColor Yellow
    Start-Process "https://github.com/microsoft/azure-container-apps/compare/main...$branchName"
} else {
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Red
    Write-Host "Push Failed - Authentication Required" -ForegroundColor Red
    Write-Host "=====================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "It looks like you need to authenticate with GitHub." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Use GitHub CLI (Recommended)" -ForegroundColor Cyan
    Write-Host "  gh auth login" -ForegroundColor White
    Write-Host "  Then run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2: Use GitHub Desktop" -ForegroundColor Cyan
    Write-Host "  1. Open GitHub Desktop" -ForegroundColor White
    Write-Host "  2. File -> Add Local Repository" -ForegroundColor White
    Write-Host "  3. Select: $workDir\azure-container-apps" -ForegroundColor White
    Write-Host "  4. Publish the branch" -ForegroundColor White
    Write-Host "  5. Create Pull Request" -ForegroundColor White
    Write-Host ""
    Write-Host "Option 3: Manual Upload" -ForegroundColor Cyan
    Write-Host "  See UPLOAD_INSTRUCTIONS.md for alternative methods" -ForegroundColor White
}

Write-Host ""
Write-Host "Current location: $(Get-Location)" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Green
Read-Host
