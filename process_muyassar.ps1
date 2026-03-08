
param (
    [int]$chapter,
    [string]$shortName
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "Processing Muyassar Chapter $chapter ($shortName)..."

# Fetch Muyassar Tafsir
$tafsirUrl = "https://api.alquran.cloud/v1/surah/$chapter/ar.muyassar"
$tafsirResp = Invoke-RestMethod -Uri $tafsirUrl
$tafsirs = $tafsirResp.data.ayahs
$surahName = $tafsirResp.data.name

# Process and Gen Dart Format
$output = "const List<Map<String, String>> ${shortName}MuyassarData = [`n"

for ($i = 0; $i -lt $tafsirs.Count; $i++) {
    $ayaNum = $tafsirs[$i].numberInSurah
    $tText = $tafsirs[$i].text

    # Escape single quotes
    $tEncoded = $tText -replace "'", "\'"

    $output += "  {'s': '$surahName', 'n': '$ayaNum', 't': '$tEncoded'},`n"
}

$output += "];`n"

# Save to file
$fileName = "${shortName}_muyassar_dart.txt"
$output | Out-File -FilePath $fileName -Encoding UTF8

Write-Host "Done! Saved to $fileName"
