import os
import re

def clean_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except UnicodeDecodeError:
        with open(filepath, 'r', encoding='cp1252') as f:
            content = f.read()

    original = content
    replacements = {
        "🌿": "",
        "💾": "[Save]",
        "🔄": "[Reset]",
        "� ": "[World]",
        "👤": "[NPC]",
        "💬": "[Dialogue]",
        "📜": "[Quest]",
        "�Z�": "[Item]",
        "🌱": "[Crop]",
        "� �": "[Shop]",
        "📦": "[Asset]",
        "🗺�": "[Map]",
        "🗂�": "[Layers]",
        "� ": "[Select]",
        "🖌�": "[Paint]",
        "🧹": "[Erase]",
        "🪣": "[Fill]",
        "� ": "[Spawn]",
        "🚪": "[Transition]",
        "� �": "[Vis]",
        "🔒": "[Lock]",
        "▭": "[Rect]",
        "╱": "[Line]",
        "✦": "[Scatter]",
        "⚡": "[Event]",
        "??": "[Settings]",
        "??": "[Transition]",
        "?": "[Scatter]",
        "??": "[Line]",
        "� ��": "[Tile]",
        "âš™ï¸� ": "[Inspector]",
        "ğŸ“¦": "[Assets]",
        "ğŸ—‚ï¸� ": "[Layers]",
        "â–­": "[Rect]",
        "â•±": "[Line]",
        "âœ¦": "[Scatter]",
        "ğŸ� � ": "[Select]",
        "ğŸ–Œï¸� ": "[Paint]",
        "ğŸ§¹": "[Erase]",
        "ğŸª£": "[Fill]",
        "🧩": "[Component]",
        "â™›": "[Cog]"
    }
    
    for bad, good in replacements.items():
        content = content.replace(bad, good)
        
    content = re.sub(r'�[\w\d]+�', '', content)
    content = re.sub(r'�[\w\d]+', '', content)
    content = re.sub(r'â[\w\d]+�', '', content)
    content = re.sub(r'ğŸ.*?�', '', content)

    content = content.replace("[Save] Save", "[Save]")
    content = content.replace("[Reset] Reset All", "[Reset All]")
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Cleaned {filepath}")

for root, _, files in os.walk('editor'):
    for file in files:
        if file.endswith('.gd'):
            clean_file(os.path.join(root, file))

