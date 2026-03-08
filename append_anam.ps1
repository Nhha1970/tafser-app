
$content = Get-Content -Path "anam_dart.txt" -Raw
[System.IO.File]::AppendAllText("lib\initial_data.dart", $content, [System.Text.Encoding]::UTF8)
