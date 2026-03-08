$gitPath = "C:\Users\DELL\Desktop\flutter\bin\mingit\cmd\git.exe"
$flutterPath = "C:\Users\DELL\Desktop\flutter\bin\flutter.bat"
$repoUrl = "https://github.com/Nhha1970/tafser.git"

Write-Host "=== جاري بدء عملية بناء ونشر تطبيق التفسير === " -ForegroundColor Cyan

# 1. بناء التطبيق للويب مع إصلاح الأيقونات
Write-Host "=== جاري بناء نسخة الويب... ===" -ForegroundColor Yellow
& $flutterPath build web --release --base-href "/tafser/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "خطأ: فشل بناء التطبيق!" -ForegroundColor Red
    exit
}

# 2. تهيئة مجلد البناء للرفع
Set-Location "C:\Users\DELL\Desktop\tafser\tafser\build\web"

# حذف أي git قديم (لضمان رفع نظيف)
if (Test-Path ".git") { Remove-Item -Recurse -Force ".git" }

# تهيئة git جديد
& $gitPath init
& $gitPath config user.email "nhha1970@users.noreply.github.com"
& $gitPath config user.name "Nhha1970"
& $gitPath add .
& $gitPath commit -m "Deploy to GitHub Pages - Icons & Login Fix"
& $gitPath branch -M gh-pages
& $gitPath remote add origin $repoUrl

Write-Host "=== جاري رفع الملفات إلى GitHub... ===" -ForegroundColor Yellow
& $gitPath push origin gh-pages --force

if ($LASTEXITCODE -eq 0) {
    Write-Host "=== تم النشر بنجاح! ===" -ForegroundColor Green
    Write-Host "رابط الموقع: https://nhha1970.github.io/tafser/" -ForegroundColor Green
} else {
    Write-Host "=== حدث خطأ في الرفع ===" -ForegroundColor Red
}

Set-Location "C:\Users\DELL\Desktop\tafser\tafser"
