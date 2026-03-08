
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$data = Get-Content -Path "araaf_merged.json" -Raw | ConvertFrom-Json
$output = "const List<Map<String, String>> araafData = [`n"

foreach ($item in $data) {
    $v = $item.v
    if ($item.n -eq "1") {
        # The Basmalah in Uthmani is 39 characters long (including trailing space)
        # We check if it starts with the word 'Bismi' (بِسْمِ) which is 5 chars? No, it has diacritics.
        # But we know it's there. We'll remove the first 39 chars.
        $v = $v.Substring(39)
    }
    
    # Escape single quotes and backslashes for Dart string
    $v = $v -replace "'", "\'"
    $t = $item.t -replace "'", "\'"
    $s = $item.s
    $n = $item.n
    $output += "  {'s': '$s', 'n': '$n', 'v': '$v', 't': '$t'},`n"
}
$output += "];`n"
$output | Out-File -FilePath "araaf_dart.txt" -Encoding UTF8
