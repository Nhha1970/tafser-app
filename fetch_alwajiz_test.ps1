
$surahCount = 2
$results = @{}

for ($s = 1; $s -le $surahCount; $s++) {
    $maxAyah = 7
    if ($s -eq 2) { $maxAyah = 20 }
    
    $ayahs = @()
    for ($a = 1; $a -le $maxAyah; $a++) {
        $url = "https://tafsir.app/get.php?src=alwajeez&s=$s&a=$a&ver=1"
        Write-Host "Fetching S$s A$a..."
        try {
            $resp = Invoke-RestMethod -Uri $url
            $tafsir = $resp.data -replace '<[^>]+>', ''
            $ayahs += @{
                n = "$a"
                t = $tafsir
            }
        } catch {
            Write-Host "Failed to fetch S$s A$a"
        }
    }
    $results[$s] = $ayahs
}

$results | ConvertTo-Json -Depth 10 | Out-File -FilePath "alwajiz_test.json" -Encoding UTF8
Write-Host "Done! Saved to alwajiz_test.json"
