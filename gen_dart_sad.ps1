
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$data = Get-Content -Path "sad_merged.json" -Raw | ConvertFrom-Json
$output = "const List<Map<String, String>> sadData = [`n"

foreach ($item in $data) {
    $v = $item.v
    if ($item.n -eq "1") {
        # Standard Uthmani Basmalah prefix is 39 characters
        if ($v.Length -gt 39) {
            $v = $v.Substring(39)
        }
    }
    
    # Escape single quotes and backslashes for Dart string
    $v = $v -replace "'", "\'"
    $t = $item.t -replace "'", "\'"
    $s = $item.s
    $n = $item.n
    $output += "  {'s': '$s', 'n': '$n', 'v': '$v', 't': '$t'},`n"
}
$output += "];`n"
$output | Out-File -FilePath "sad_dart.txt" -Encoding UTF8
