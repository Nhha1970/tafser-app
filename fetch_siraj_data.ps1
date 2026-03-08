$surahsJson = Get-Content -Path "surahs_info.json" -Raw
$surahs = $surahsJson | ConvertFrom-Json
$outputFile = "siraj_complete_data.json"

if (Test-Path $outputFile) {
    try {
        $allData = Get-Content $outputFile -Raw | ConvertFrom-Json -AsHashtable
    } catch {
        $allData = @{}
    }
} else {
    $allData = @{}
}

foreach ($surah in $surahs.chapters) {
    $sid = $surah.id.ToString()
    $vcount = $surah.verses_count
    
    if (-not $allData.ContainsKey($sid)) {
        $allData[$sid] = @()
    }
    
    Write-Host "Surah $sid ..."
    
    $existing = @{}
    foreach ($item in $allData[$sid]) {
        $existing[$item.n.ToString()] = $true
    }

    $newItems = @()
    foreach ($entry in $allData[$sid]) { $newItems += $entry }

    for ($a = 1; $a -le $vcount; $a++) {
        $akey = $a.ToString()
        if ($existing.ContainsKey($akey)) {
            continue
        }

        $url = "https://tafsir.app/get.php?src=siraaj-ghareeb&s=" + $sid + "&a=" + $a + "&ver=1"
        try {
            $resp = Invoke-RestMethod -Uri $url -TimeoutSec 10
            $txt = ""
            if ($resp -is [string]) {
                $txt = $resp.Trim()
            } elseif ($resp.data) {
                $txt = $resp.data.ToString().Trim()
            }

            if ($txt.Length -gt 0) {
                $obj = @{ n = $a; t = $txt }
                $newItems += $obj
                Write-Host "  Ayah $a ok"
            }
        } catch {
            Write-Host "  Error $a"
        }
    }
    
    $allData[$sid] = $newItems
    $allData | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding utf8
}

Write-Host "Done"
