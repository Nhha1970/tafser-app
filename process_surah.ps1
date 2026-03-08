
param (
    [int]$chapter,
    [string]$shortName
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "Processing Chapter $chapter ($shortName)..."

# 1. Fetch Quran Uthmani
$quranUrl = "https://api.alquran.cloud/v1/surah/$chapter/quran-uthmani"
$quranResp = Invoke-RestMethod -Uri $quranUrl
$verses = $quranResp.data.ayahs
$surahName = $quranResp.data.name

# 2. Fetch Jalalayn Tafsir
$tafsirUrl = "https://api.alquran.cloud/v1/surah/$chapter/ar.jalalayn"
$tafsirResp = Invoke-RestMethod -Uri $tafsirUrl
$tafsirs = $tafsirResp.data.ayahs

# 3. Process and Gen Dart Format
$output = "const List<Map<String, String>> $($shortName)Data = [`n"

for ($i = 0; $i -lt $verses.Count; $i++) {
    $vText = $verses[$i].text
    $ayaNum = $verses[$i].numberInSurah
    
    if ($ayaNum -eq 1 -and $chapter -ne 1) {
        # Remove standard Basmalah (39 chars)
        if ($vText.Length -gt 39) {
            $vText = $vText.Substring(39)
        }
    }
    
    # Escape quotes
    $vEncoded = $vText -replace "'", "\'"
    $tEncoded = $tafsirs[$i].text -replace "'", "\'"
    
    $output += "  {'s': '$surahName', 'n': '$ayaNum', 'v': '$vEncoded', 't': '$tEncoded'},`n"
}

$output += "];`n"

# 4. Save to file
$fileName = "$($shortName)_dart.txt"
$output | Out-File -FilePath $fileName -Encoding UTF8

Write-Host "Done! Saved to $fileName"
