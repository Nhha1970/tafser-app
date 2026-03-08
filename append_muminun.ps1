
$content = Get-Content -Path "muminun_dart.txt" -Raw
[System.IO.File]::AppendAllText("lib\initial_data.dart", $content, [System.Text.Encoding]::UTF8)
