$content = Get-Content 'editor\ui\editor_shell.gd' -Raw -Encoding UTF8
$content = $content.Replace("â†©ï¸�  Undo", "[Undo]")
$content = $content.Replace("â†ªï¸�  Redo", "[Redo]")
Set-Content 'editor\ui\editor_shell.gd' -Value $content -Encoding UTF8
