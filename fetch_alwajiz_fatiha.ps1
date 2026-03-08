
$surahCount = 1
$outputFile = "lib/initial_data_wajeez.dart"

Set-Content -Path $outputFile -Value "final Map<int, List<Map<String, String>>> wajeezAllSurahsData = {" -Encoding UTF8

for ($s = 1; $s -le $surahCount; $s++) {
    Add-Content -Path $outputFile -Value "  $s: [" -Encoding UTF8
    $maxAyah = 7
    for ($a = 1; $a -le $maxAyah; $a++) {
        $url = "https://tafsir.app/get.php?src=alwajeez&s=$s&a=$a&ver=1"
        $resp = Invoke-RestMethod -Uri $url
        $tafsir = $resp.data -replace '<[^>]+>', ''
        $tafsir = $tafsir -replace "'", "''"
        Add-Content -Path $outputFile -Value "    {" -Encoding UTF8
        Add-Content -Path $outputFile -Value "      'n': '$a'," -Encoding UTF8
        Add-Content -Path $outputFile -Value "      't': '$tafsir'," -Encoding UTF8
        Add-Content -Path $outputFile -Value "    }," -Encoding UTF8
    }
    Add-Content -Path $outputFile -Value "  ]," -Encoding UTF8
}

Add-Content -Path $outputFile -Value "};" -Encoding UTF8
Write-Host "Done! Saved to $outputFile"
