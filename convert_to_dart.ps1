$jsonPath = "siraj_complete_data.json"
$dartPath = "lib/initial_data_ghareeb.dart"

if (-not (Test-Path $jsonPath)) {
    Write-Host "Error: JSON file not found." -ForegroundColor Red
    exit
}

$data = Get-Content $jsonPath -Raw | ConvertFrom-Json -AsHashtable

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("const Map<int, List<Map<String, String>>> ghareebAllSurahsData = {")

# Sort suras by ID
$sortedSurahIds = $data.Keys | ForEach-Object { [int]$_ } | Sort-Object

foreach ($sid in $sortedSurahIds) {
    [void]$sb.AppendLine("  $sid: [")
    
    $ayahs = $data[$sid.ToString()] | Sort-Object { [int]$_.n }
    foreach ($ayah in $ayahs) {
        $n = $ayah.n
        $t = $ayah.t.Replace('"', '\"').Replace("`n", "\n")
        [void]$sb.AppendLine("    {'n': '$n', 'v': '', 't': ""$t""},")
    }
    
    [void]$sb.AppendLine("  ],")
}

[void]$sb.AppendLine("};")

$sb.ToString() | Out-File -FilePath $dartPath -Encoding utf8
Write-Host "Dart file generated at $dartPath" -ForegroundColor Green
