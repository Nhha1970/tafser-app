
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$chapter = 5
$versesUrl = "https://api.quran.com/api/v4/quran/verses/uthmani?chapter_number=$chapter"
$tafsirUrl = "https://api.quran.com/api/v4/tafsirs/169/by_chapter/$chapter" # 169 is Jalalayn Arabic
$chapterUrl = "https://api.quran.com/api/v4/chapters/$chapter"

Write-Host "Fetching chapter info..."
$chapterResp = Invoke-RestMethod -Uri $chapterUrl
$surahName = $chapterResp.chapter.name_arabic

Write-Host "Fetching verses..."
$versesResp = Invoke-RestMethod -Uri $versesUrl
$verses = $versesResp.verses

Write-Host "Fetching tafsir..."
$tafsirResp = Invoke-RestMethod -Uri $tafsirUrl
$tafsirs = $tafsirResp.tafsirs

$results = @()

for ($i = 0; $i -lt $verses.Count; $i++) {
    $v = $verses[$i]
    $t = $tafsirs[$i]
    
    $ayaNum = $v.verse_key.Split(':')[1]
    
    # Clean tafsir text from HTML tags
    $cleanTafsir = $t.text -replace '<[^>]+>', ''
    
    $item = @{
        s = $surahName
        n = $ayaNum
        v = $v.text_uthmani
        t = $cleanTafsir
    }
    $results += New-Object PSObject -Property $item
}

$results | ConvertTo-Json -Depth 10 | Out-File -FilePath "maidah_merged.json" -Encoding UTF8
Write-Host "Done! Saved to maidah_merged.json"
