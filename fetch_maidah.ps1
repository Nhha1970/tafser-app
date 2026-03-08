$ErrorActionPreference = 'Continue'
$results = @()

for ($i = 1; $i -le 120; $i++) {
    $url = "https://quran.ksu.edu.sa/tafseer/jalpieces/sura5-aya$i.html"
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15
        $html = $response.Content
        
        # Extract tafsir text - it's usually in a specific div
        # Try to find the jalalayn tafsir section
        if ($html -match '<s[^>]*class="[^"]*jalpieces[^"]*"[^>]*>(.*?)</s') {
            $tafsir = $matches[1]
        } elseif ($html -match 'id="TextTafseer"[^>]*>(.*?)</div') {
            $tafsir = $matches[1]
        } elseif ($html -match '<div[^>]*class="[^"]*tafseerText[^"]*"[^>]*>(.*?)</div') {
            $tafsir = $matches[1]
        } else {
            # Try broader pattern
            if ($html -match '(?s)class="jalpieces"[^>]*>(.*?)</') {
                $tafsir = $matches[1]
            } else {
                $tafsir = "NOT_FOUND"
            }
        }
        
        # Clean HTML tags
        $tafsir = $tafsir -replace '<[^>]+>', ''
        $tafsir = $tafsir.Trim()
        
        Write-Host "Aya $i : $($tafsir.Substring(0, [Math]::Min(80, $tafsir.Length)))..."
        $results += [PSCustomObject]@{
            Aya = $i
            Tafsir = $tafsir
        }
    } catch {
        Write-Host "Error fetching aya $i : $_"
        $results += [PSCustomObject]@{
            Aya = $i
            Tafsir = "ERROR"
        }
    }
    
    Start-Sleep -Milliseconds 300
}

# Save results
$results | ConvertTo-Json -Depth 10 | Out-File -FilePath "c:\Users\DELL\Desktop\tafser\tafser\maidah_tafsir.json" -Encoding UTF8
Write-Host "`nDone! Saved to maidah_tafsir.json"
