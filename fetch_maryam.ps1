
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$chapter = 19

Write-Host "Fetching Quran Uthmani for Surah Maryam..."
$quranUrl = "https://api.alquran.cloud/v1/surah/$chapter/quran-uthmani"
$quranResp = Invoke-RestMethod -Uri $quranUrl
$verses = $quranResp.data.ayahs
$surahName = $quranResp.data.name

Write-Host "Fetching Jalalayn Tafsir literal..."
$tafsirUrl = "https://api.alquran.cloud/v1/surah/$chapter/ar.jalalayn"
$tafsirResp = Invoke-RestMethod -Uri $tafsirUrl
$tafsirs = $tafsirResp.data.ayahs

$results = @()

for ($i = 0; $i -lt $verses.Count; $i++) {
    $v = $verses[$i]
    $t = $tafsirs[$i]
    
    $ayaNum = $v.numberInSurah
    
    $item = @{
        s = $surahName
        n = [string]$ayaNum
        v = $v.text
        t = $t.text
    }
    $results += New-Object PSObject -Property $item
}

$results | ConvertTo-Json -Depth 10 | Out-File -FilePath "maryam_merged.json" -Encoding UTF8
Write-Host "Done! Saved to maryam_merged.json - Count: $($results.Count)"
