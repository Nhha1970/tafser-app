
$json = Get-Content 'maidah_merged.json' -Raw | ConvertFrom-Json
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$stream = [System.IO.File]::OpenWrite((Join-Path (Get-Location) 'maidah_dart.txt'))
$writer = New-Object System.IO.StreamWriter $stream, $utf8NoBom

$writer.WriteLine("const List<Map<String, String>> maidahData = [")
foreach ($v in $json) {
    # Escape single quotes for Dart
    $t = $v.t -replace "'", "\'"
    # The JSON's 's' field has the surah name already
    $line = "  {'s': '$($v.s)', 'n': '$($v.n)', 'v': '$($v.v)', 't': '$t'},"
    $writer.WriteLine($line)
}
$writer.WriteLine("];")
$writer.Close()
$stream.Close()
Write-Host "Done! Generated maidah_dart.txt"
