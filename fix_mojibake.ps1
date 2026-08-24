$files = Get-ChildItem -Path editor -Recurse -Filter *.gd

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $original = $content

    $replacements = @{
        '🌿' = ''
        '💾' = '[Save]'
        '🔄' = '[Reset]'
        '� ' = '[World]'
        '👤' = '[NPC]'
        '💬' = '[Dialogue]'
        '📜' = '[Quest]'
        '�Z�' = '[Item]'
        '🌱' = '[Crop]'
        '� �' = '[Shop]'
        '📦' = '[Asset]'
        '🗺�' = '[Map]'
        '🗂�' = '[Layers]'
        '� ' = '[Select]'
        '🖌�' = '[Paint]'
        '🧹' = '[Erase]'
        '🪣' = '[Fill]'
        '� ' = '[Spawn]'
        '🚪' = '[Transition]'
        '� �' = '[Vis]'
        '🔒' = '[Lock]'
        '▭' = '[Rect]'
        '╱' = '[Line]'
        '✦' = '[Scatter]'
        '⚡' = '[Event]'
        '??' = '[Settings]'
        '??' = '[Transition]'
        '?' = '[Scatter]'
        '??' = '[Line]'
        '� ��' = '[Tile]'
        'âš™ï¸� ' = '[Inspector]'
        'ğŸ“¦' = '[Assets]'
        'ğŸ—‚ï¸� ' = '[Layers]'
        'â–­' = '[Rect]'
        'â•±' = '[Line]'
        'âœ¦' = '[Scatter]'
        'ğŸ� � ' = '[Select]'
        'ğŸ–Œï¸� ' = '[Paint]'
        'ğŸ§¹' = '[Erase]'
        'ğŸª£' = '[Fill]'
        '🧩' = '[Component]'
        'â™›' = '[Cog]'
    }

    foreach ($k in $replacements.Keys) {
        $content = $content.Replace($k, $replacements[$k])
    }

    $content = $content.Replace("[Save] Save", "[Save]")
    $content = $content.Replace("[Reset] Reset All", "[Reset All]")
    
    if ($content -cne $original) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        Write-Host "Cleaned $($file.Name)"
    }
}
