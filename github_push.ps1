$gitPath = "C:\Users\DELL\Desktop\flutter\bin\mingit\cmd\git.exe"
$repoUrl = Read-Host "أدخل رابط مستودع GitHub الخاص بك (مثلاً: https://github.com/username/repo.git)"

if ($repoUrl -eq "") {
    Write-Host "خطأ: يجب إدخال رابط المستودع." -ForegroundColor Red
    exit
}

Write-Host "--- جاري ربط المستودع ورفع الكود المصدري ---" -ForegroundColor Cyan
& $gitPath remote add origin $repoUrl
& $gitPath branch -M main
& $gitPath push -u origin main --force

Write-Host "--- جاري بناء نسخة الويب النهائية ---" -ForegroundColor Cyan
& "C:\Users\DELL\Desktop\flutter\bin\flutter.bat" build web --release

Write-Host "--- جاري نشر نسخة الويب على فرع gh-pages ---" -ForegroundColor Cyan
if (Test-Path "build/web/.git") { Remove-Item -Recurse -Force "build/web/.git" }
Set-Location build/web
& $gitPath init
& $gitPath add .
& $gitPath commit -m "Deploy to GitHub Pages"
& $gitPath branch -M gh-pages
& $gitPath remote add origin $repoUrl
& $gitPath push origin gh-pages --force

Set-Location ../..
Write-Host "--- تمت العملية بنجاح! ---" -ForegroundColor Green
Write-Host "رابط موقعك سيكون متاحاً قريباً على: " -ForegroundColor Yellow
$cleanUrl = $repoUrl -replace '\.git$', ''
$parts = $cleanUrl -split '/'
$user = $parts[-2]
$repo = $parts[-1]
Write-Host "https://$user.github.io/$repo/" -ForegroundColor Green
