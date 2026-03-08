$gitPath = "C:\Users\DELL\Desktop\flutter\bin\mingit\cmd\git.exe"
$repoUrl = "https://github.com/Nhha1970/tafser1.git"
$flutterPath = "C:\Users\DELL\Desktop\flutter\bin\flutter.bat"

Write-Host "=== جاري نشر تطبيق التفسير على GitHub Pages (المستودع الجديد tafser1) ===" -ForegroundColor Cyan

# الانتقال إلى مجلد المشروع
Set-Location "C:\Users\DELL\Desktop\tafser\tafser"

Write-Host "=== جاري بناء التطبيق للويب... ===" -ForegroundColor Yellow
& $flutterPath build web --release --base-href "/tafser1/"

# التأكد من نجاح البناء
if (-not (Test-Path "build\web\index.html")) {
    Write-Host "خطأ: فشل بناء التطبيق! لم يتم العثور على index.html" -ForegroundColor Red
    exit
}

if (-not (Test-Path "build\web\main.dart.js")) {
    Write-Host "خطأ: فشل بناء التطبيق! لم يتم العثور على main.dart.js" -ForegroundColor Red
    exit
}

# تهيئة مجلد البناء للرفع
Set-Location "build\web"
if (Test-Path ".git") { Remove-Item -Recurse -Force ".git" }

& $gitPath init
& $gitPath config user.email "nhha1970@users.noreply.github.com"
& $gitPath config user.name "Nhha1970"
& $gitPath add .
& $gitPath commit -m "Deploy to GitHub Pages (tafser1) - Full Build"
& $gitPath branch -M gh-pages
& $gitPath remote add origin $repoUrl

Write-Host "=== جاري رفع الملفات إلى GitHub... ===" -ForegroundColor Yellow
& $gitPath push origin gh-pages --force

if ($LASTEXITCODE -eq 0) {
    Write-Host "=== تم الرفع بنجاح! ===" -ForegroundColor Green
    Write-Host "الرابط: https://nhha1970.github.io/tafser1/" -ForegroundColor Green
} else {
    Write-Host "=== حدث خطأ في الرفع ===" -ForegroundColor Red
}

Set-Location "C:\Users\DELL\Desktop\tafser\tafser"
Write-Host "=== اكتملت العملية ===" -ForegroundColor Cyan
