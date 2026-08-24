# Botanical Haven — Art & Audio Asset Pipeline Guide
	
	---
	
	## 1. Sanatçılar İçin Temel İlkeler ve Kurallar
	
	Botanical Haven, **Pixel-Art Estetiği** ve **Veri Odaklı (Data-Driven) Mimari** ile geliştirilmektedir. Bir pixel-art sanatçısı veya ses tasarımcısı olarak projeye yeni bir içerik eklemek ya da mevcut bir görseli değiştirmek için **kod bilmenize veya GDScript düzenlemenize gerek yoktur**.
	
	### 🎨 Görsel Standartlar (Pixel Art Guidelines)
	- **Texture Filtering**: Daima `Nearest` (piksellerin net ve keskin kalması için).
	- **Zemin & Eşya Grid Boyutu**: `16x16` piksel.
	- **Karakter & NPC Boyutu**: `16x24` piksel (veya `16x32`).
	- **Büyük Çevre & Binalar**: `32x32` veya `48x48` piksel.
	- **Diyalog Portreleri**: `48x48` piksel.
	- **Renk Paleti**: Sıcak ve masalsı Cozy Botanical paleti (sıcak yeşiller, pastel toprak tonları, canlı çiçek renkleri).
	
	---
	
	## 2. Dizin Yapısı & Dosya Konumları
	
	```
	res://assets/
	  ├── sprites/
	  │     ├── items/          # Tohum, mahsul, iksir ve alet ikonları (16x16 PNG)
	  │     ├── tiles/          # Zemin, toprak, çim ve çit dokuları (16x16 PNG)
	  │     ├── environment/    # Ağaçlar, kayalar, binalar ve çalılar (PNG)
	  │     ├── npc/            # NPC sprite'ları ve portreleri (PNG)
	  │     ├── player/         # Oyuncu yürüme ve alet animasyon kareleri (PNG)
	  │     └── ui/             # Arayüz ikonları ve dekoratif çerçeveler (PNG)
	  ├── audio/
	  │     ├── sfx/            # Ses efektleri (16-bit 44.1kHz WAV)
	  │     └── music/          # Arka plan müzikleri ve ambiyans (OGG/WAV)
	  └── fonts/                # Piksel fontları (.ttf / .tres)
	```
	
	---
	
	## 3. Adım Adım Asset Ekleme Rehberi
	
	### 3.1. Yeni Eşya / Tohum / Hasat Görseli Ekleme
	1. Çizdiğiniz `16x16` PNG dosyasını `res://assets/sprites/items/<item_id>.png` olarak kaydedin.
	2. `res://data/assets/asset_manifest.json` dosyasına yeni eşyanın ID'sini ekleyin:
	   ```json
	   "item.my_new_flower": {
	       "category": "item",
	       "texture": "res://assets/sprites/items/my_new_flower.png",
	       "size": [16, 16]
	   }
	   ```
	3. Eşya oyunda ve envanterde otomatik olarak yeni görseliyle render edilir.
	
	### 3.2. Yeni Alet & Kalite Seviyesi Ekleme
	- Alet ikonları `res://assets/sprites/items/hoe_gold.png` veya `watering_can_iron.png` formatındadır.
	- `ItemRegistry` ve `UIConstants` kalite seviyesine göre altın/demir/bakır çerçevelerini otomatik uygular.
	
	### 3.3. Yeni NPC Sprite & Portresi Ekleme
	1. NPC'nin dünya üzerindeki sprite'ını `res://assets/sprites/npc/<npc_id>_idle_0.png` olarak kaydedin.
	2. Diyalog penceresi portresini `res://assets/sprites/npc/<npc_id>_portrait.png` (`48x48`) olarak kaydedin.
	3. `asset_manifest.json` dosyasına kaydedin:
	   ```json
	   "npc.lumina": {
	       "category": "npc",
	       "texture": "res://assets/sprites/npc/lumina_idle_0.png",
	       "portrait": "npc.lumina.portrait",
	       "size": [16, 24]
	   },
	   "npc.lumina.portrait": {
	       "category": "npc_portrait",
	       "texture": "res://assets/sprites/npc/lumina_portrait.png",
	       "size": [48, 48]
	   }
	   ```
	
	### 3.4. Yeni Ses Efekti (SFX) Ekleme
	1. Ses dosyasını `res://assets/audio/sfx/<sound_name>.wav` olarak kaydedin.
	2. `asset_manifest.json` içine ekleyin:
	   ```json
	   "audio.sfx.farming.magic_water": {
	       "category": "audio_sfx",
	       "path": "res://assets/audio/sfx/magic_water.wav"
	   }
	   ```
	
	### 3.5. Yeni UI İkonu ve Stili Ekleme
	- İkonlar: `res://assets/sprites/ui/icon_<name>.png`
	- Arayüz Teması: `res://ui/theme/botanical_haven_theme.tres` ve `res://ui/theme/ui_constants.gd`
	- Bir buton veya kart stilini değiştirmek için tema dosyasındaki ilgili StyleBox'ı güncellemeniz yeterlidir.
	
	---
	
	## 4. World Builder Entegrasyonu
	
	World Builder, harita nesnelerini dosya yollarıyla değil `AssetRegistry`'deki **Stable ID**'lerle saklar:
	- `prop.tree_stump`
	- `prop.rock_small`
	- `tile.watered_soil`
	- `building.greenhouse_repaired`
	
	Harita dosyaları (`farm.json`, `town.json`) fiziksel dosya yollarını içermez; bu sayede bir ağacın çizimini değiştirdiğinizde daha önce inşa ettiğiniz hiçbir dünya haritası bozulmaz.
	
	---
	
	## 5. Doğrulama ve Kalite Kontrolü (Asset Pipeline Validator)
	
	Projedeki tüm görsel ve seslerin eksiksiz olduğunu doğrulamak için:
	
	```gdscript
	var report = AssetPipelineValidator.validate_all()
	if report.valid:
	    print("All %d assets are intact and properly referenced!" % report.asset_count)
	```
	
	Denetlenenler:
	- Mükerrer (Duplicate) Asset ID'leri
	- Eksik veya kırık dosya bağlantıları (Broken references)
	- Kod içine gömülü fiziksel dosya yolları (Hardcoded paths)
	- Dünya haritalarındaki kararlılık
	- Güvenli yedek görsel (Fallback placeholder) üretimi
	