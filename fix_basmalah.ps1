# Read file as bytes to avoid PowerShell encoding issues
$bytes = [System.IO.File]::ReadAllBytes("$PWD\lib\initial_data.dart")
$content = [System.Text.Encoding]::UTF8.GetString($bytes)

# Find maidahData by looking for the unique marker
$marker = "maidahData"
$idx = $content.IndexOf($marker)
if ($idx -ge 0) {
    Write-Host "Found maidahData at position $idx"
    
    # Find the first 'v': ' after maidahData
    $vMarker = "'v': '"
    $vIdx = $content.IndexOf($vMarker, $idx)
    if ($vIdx -ge 0) {
        $vStart = $vIdx + $vMarker.Length
        # Get char codes at that position to find the basmalah
        Write-Host "Verse 1 starts at position $vStart"
        $first20 = @()
        for ($i = 0; $i -lt 20; $i++) {
            $first20 += "U+{0:X4}" -f [int][char]$content[$vStart + $i]
        }
        Write-Host "First 20 char codes: $($first20 -join ' ')"
        
        # The basmalah is: U+0628 U+0650 U+0633 U+0652 U+0645 U+0650 U+0020 ...
        # Check if it starts with Ba with kasra (U+0628 U+0650)
        if ([int][char]$content[$vStart] -eq 0x0628) {
            Write-Host "Starts with Ba - this is Basmalah!"
            
            # Find the space before the actual verse text
            # The basmalah ends after the last meem+kasra followed by a space
            # We need to find where the basmalah ends
            # Look for the pattern: the actual verse starts after basmalah
            # Search for the ya char (U+064A) that starts the actual verse
            $searchFrom = $vStart
            $basmalahEnd = -1
            for ($i = $searchFrom; $i -lt $searchFrom + 200; $i++) {
                $c = [int][char]$content[$i]
                # Space followed by ya (the actual verse start)
                if ($c -eq 0x064A -and [int][char]$content[$i-1] -eq 0x0020) {
                    # Check previous char before space - should be meem+kasra (end of basmalah)
                    $basmalahEnd = $i
                    Write-Host "Found verse start at position $i"
                    break
                }
            }
            
            if ($basmalahEnd -gt 0) {
                $removed = $content.Substring($vStart, $basmalahEnd - $vStart)
                Write-Host "Removing basmalah text (length $($removed.Length)): [$removed]"
                $newContent = $content.Substring(0, $vStart) + $content.Substring($basmalahEnd)
                $newBytes = [System.Text.Encoding]::UTF8.GetBytes($newContent)
                [System.IO.File]::WriteAllBytes("$PWD\lib\initial_data.dart", $newBytes)
                Write-Host "SUCCESS: Basmalah removed from Al-Maidah verse 1!"
            } else {
                Write-Host "Could not find verse start after basmalah"
            }
        } else {
            Write-Host "Does NOT start with Ba - no basmalah to remove"
        }
    }
} else {
    Write-Host "maidahData not found"
}
