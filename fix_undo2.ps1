$content = Get-Content 'editor\ui\panels\world_editor_panel.gd' -Raw -Encoding UTF8
$content = $content.Replace("â†º Undo", "[Undo]")
$content = $content.Replace("â†» Redo", "[Redo]")
Set-Content 'editor\ui\panels\world_editor_panel.gd' -Value $content -Encoding UTF8
