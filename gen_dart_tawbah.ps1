
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$data = Get-Content -Path "tawbah_merged.json" -Raw | ConvertFrom-Json
$output = "const List<Map<String, String>> tawbahData = [`n"

foreach ($item in $data) {
    $v = $item.v
    
    # Escape single quotes and backslashes for Dart string
    $v = $v -replace "'", "\'"
    $t = $item.t -replace "'", "\'"
    $s = $item.s
    $n = $item.n
    $output += "  {'s': '$s', 'n': '$n', 'v': '$v', 't': '$t'},`n"
}
$output += "];`n"
$output | Out-File -FilePath "tawbah_dart.txt" -Encoding UTF8
