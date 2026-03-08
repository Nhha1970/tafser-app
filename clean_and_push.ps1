$repoUrl = 'https://YOUR_TOKEN_HERE@github.com/NHHA669266/tafser-app.git'
$gitPath = 'C:\Users\DELL\Desktop\flutter\bin\mingit\cmd\git.exe'
$flutterPath = 'C:\Users\DELL\Desktop\flutter\bin\flutter.bat'

Write-Host '=== Starting Clean Build and Deploy to tafser-app ===' -ForegroundColor Cyan

# 1. Build
Write-Host 'Building Web Application...' -ForegroundColor Yellow
& $flutterPath build web --release --base-href '/tafser-app/'

if ($LASTEXITCODE -ne 0) {
    Write-Host 'Error: Build Failed!' -ForegroundColor Red
    exit
}

# 2. Cleanup and Init
Set-Location 'C:\Users\DELL\Desktop\tafser\tafser\build\web'
if (Test-Path '.git') { Remove-Item -Recurse -Force '.git' }

& $gitPath init
& $gitPath config user.email 'nhha1970@users.noreply.github.com'
& $gitPath config user.name 'Nhha1970'
& $gitPath remote add origin $repoUrl

# 3. Push
& $gitPath add .
& $gitPath commit -m 'Final clean deploy with fixed icons and safety code'
& $gitPath branch -M gh-pages

Write-Host 'Pushing to GitHub (Auto-Authenticating)...' -ForegroundColor Yellow
& $gitPath push origin gh-pages --force

if ($LASTEXITCODE -eq 0) {
    Write-Host 'Done! Success!' -ForegroundColor Green
    Write-Host 'Link: https://nhha1970.github.io/tafser-app/' -ForegroundColor Green
} else {
    Write-Host 'Error during Push!' -ForegroundColor Red
}

Set-Location 'C:\Users\DELL\Desktop\tafser\tafser'
# Cleanup: Remove the token from the script after execution for safety
$scriptPath = $MyInvocation.MyCommand.Path
$content = Get-Content $scriptPath
$newContent = $content -replace 'YOUR_TOKEN_HERE', 'YOUR_TOKEN_HERE'
$newContent | Set-Content $scriptPath
