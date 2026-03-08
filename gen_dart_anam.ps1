
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$data = Get-Content -Path "anam_merged.json" -Raw | ConvertFrom-Json
$output = "const List<Map<String, String>> anamData = [`n"
foreach ($item in $data) {
    # Escape single quotes and backslashes for Dart string
    # We use a space after the backslash in the regex to avoid PowerShell eating it
    $v = $item.v -replace "'", "\'"
    $t = $item.t -replace "'", "\'"
    $s = $item.s
    $n = $item.n
    $output += "  {'s': '$s', 'n': '$n', 'v': '$v', 't': '$t'},`n"
}
$output += "];`n"
$output | Out-File -FilePath "anam_dart.txt" -Encoding UTF8
