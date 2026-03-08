$gitPath = "git"
$flutterPath = "flutter"
# Using explicit PAT from local git config to avoid hardcoding secrets
$repoUrl = & $gitPath config --get remote.origin.url
$currentDir = Get-Location

Write-Host "=== Starting Web Build and Deploy Process ===" -ForegroundColor Cyan
Write-Host "Current Directory: $currentDir" -ForegroundColor Gray

# 1. Build Web
Write-Host "=== Building Web... ===" -ForegroundColor Yellow
& $flutterPath build web --release --base-href "/tafser-app/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed!" -ForegroundColor Red
    exit
}

# 2. Prepare Build Directory
$webBuildPath = Join-Path $currentDir "build\web"
if (-not (Test-Path $webBuildPath)) {
    Write-Host "Error: Build directory not found at $webBuildPath" -ForegroundColor Red
    exit
}
Write-Host "Navigating to: $webBuildPath" -ForegroundColor Gray
Set-Location $webBuildPath

# Clean previous git safely
if (Test-Path ".git") { 
    Write-Host "Removing existing .git folder..." -ForegroundColor Gray
    Remove-Item -Recurse -Force ".git" 
}

# Init and Push
Write-Host "Initializing new Git repository..." -ForegroundColor Gray
& $gitPath init
& $gitPath config user.email "nhha1970@users.noreply.github.com"
& $gitPath config user.name "Nhha1970"
& $gitPath add .
& $gitPath commit -m "Deploy to GitHub Pages - Forced Update"
& $gitPath branch -M gh-pages

# Ensure clean remote
Write-Host "Setting up remote origin..." -ForegroundColor Gray
& $gitPath remote add origin $repoUrl

Write-Host "=== Pushing to GitHub (Force) ... ===" -ForegroundColor Yellow
# Using -c credential.helper= to bypass the system credential manager
& $gitPath -c credential.helper= push origin gh-pages --force

if ($LASTEXITCODE -eq 0) {
    Write-Host "=== Deployment Successful! ===" -ForegroundColor Green
    Write-Host "URL: https://nhha1970.github.io/tafser-app/" -ForegroundColor Green
}
else {
    Write-Host "=== Error during push ===" -ForegroundColor Red
}

Set-Location $currentDir
