[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$targetFile = "lib/initial_data_muyassar.dart"
$header = "// Tafsir Al-Muyassar - King Fahad Quran Complex`n"
Set-Content -Path $targetFile -Value $header -Encoding UTF8

$files = @(
    'fatiha','baqarah','aliImran','nisa','maidah','anam','araaf','anfal',
    'tawbah','yunus','hud','yusuf','rad','ibrahim','hijr','nahl',
    'isra','kahf','maryam','taha','anbiya','hajj','muminun','nur',
    'furqan','shuara','naml','qasas','ankabut','rum','luqman','sajdah',
    'ahzab','saba','fatir','yasin','saffat','sad','zumar','ghafir',
    'fussilat','shura','zukhruf','dukhan','jathiya','ahqaf','muhammad','fath',
    'hujurat','qaf','dhariyat','tur','najm','qamar','rahman','waqia',
    'hadid','mujadila','hashr','mumtahina','saff','jumuah','munafiqun','taghabun',
    'talaq','tahrim','mulk','qalam','haqqah','maarij','nuh','jinn',
    'muzzammil','muddaththir','qiyamah','insan','mursalat','naba','naziat','abasa',
    'takwir','infitar','mutaffifin','inshiqaq','buruj','tariq','ala','ghashiyah',
    'fajr','balad','shams','layl','duha','sharh','tin','alaq',
    'qadr','bayyinah','zalzalah','adiyat','qariah','takathur','asr','humazah',
    'fil','quraish','maun','kawthar','kafirun','nasr','masad','ikhlas',
    'falaq','nas'
)

foreach ($f in $files) {
    $path = "${f}_muyassar_dart.txt"
    if (Test-Path $path) {
        $content = Get-Content $path -Encoding UTF8
        Add-Content $targetFile -Value $content -Encoding UTF8
        Write-Host "Added: $f"
    } else {
        Write-Host "NOT FOUND: $path"
    }
}

Write-Host "Finished combining data."
