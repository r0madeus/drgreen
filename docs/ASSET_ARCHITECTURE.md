# Botanical Haven — Data-Driven Asset & UI Architecture Guide
	
	---
	
	## 1. Mimari Genel Bakış ve Temel Felsefe
	
	Botanical Haven projesinde tüm görsel (texture, sprite, icon), işitsel (SFX, music, ambient), parçacık ve arayüz (UI theme/style) kaynakları **Data-Driven & Decoupled Architecture** prensibiyle yönetilir.
	
	- **Temel Kural**: Gameplay kodu fiziksel dosya yollarını (`res://assets/sprites/items/seed_red_flower.png`, `res://assets/audio/sfx/water.wav`) ASLA doğrudan bilmemelidir.
	- **Stable ID Standardı**: Tüm asset talepleri `AssetRegistry.get_texture(id)` veya `AudioManager.play_sfx(id)` gibi merkezi sağlayıcılar üzerinden stabil ID'ler ile çözümlenir.
	- **Sıfır Kod Değişikliğiyle Asset Değişimi**: Bir grafiği, sesi veya UI stilini değiştirmek istediğinizde gameplay GDScript dosyalarında tek bir satır kod değiştirmeniz gerekmez.
	
	---
	
	## 2. Asset ID Standartları & İsimlendirme Formatı
	
	| Kategori | Stable ID Örneği | Açıklama |
	| :--- | :--- | :--- |
	| **Items** | `item.seed_red_flower`, `seed_blue_flower` | Tohum ve hasat eşyaları |
	| **Tools** | `tool.hoe.basic`, `tool.watering_can.gold` | Aletler ve kalite varyasyonları |
	| **Tiles** | `tile.grass`, `tile.soil`, `watered_soil` | Zemin ve arazi döşemeleri |
	| **Props** | `prop.tree_stump`, `prop.rock_small` | Çevre nesneleri, ağaçlar, kayalar |
	| **NPCs** | `npc.rowan`, `npc.portrait.rowan.neutral` | NPC sprite ve diyalog portreleri |
	| **UI Icons** | `ui.icon.gold`, `ui.icon.inventory` | HUD ve buton ikonları |
	| **SFX** | `farming.water`, `farming.plant`, `ui.select` | Ses efektleri |
	| **Music** | `music.spring.day`, `ambient.rain` | Müzik ve arka plan ambiyansı |
	| **Effects** | `farming.plant`, `farming.harvest`, `text` | Parçacık ve açılır metin efektleri |
	
	---
	
	## 3. Yeni Asset Ekleme ve Güncelleme Adımları
	
	### 3.1. Yeni Texture / Eşya İkonu Ekleme
	1. Pixel-art PNG görselinizi `res://assets/sprites/items/<item_id>.png` dizinine kaydedin.
	2. `ItemRegistry.gd` içerisinde eşyanızı tanımlayın (`id: "my_new_seed"`).
	3. `AssetRegistry.get_item_icon("my_new_seed")` otomatik olarak görseli yükler. Hiçbir render kodu yazılmasına gerek yoktur.
	
	### 3.2. Yeni Ses Efekti (SFX) / Müzik Ekleme
	1. WAV veya OGG ses dosyanızı `res://assets/audio/sfx/<sound_name>.wav` dizinine ekleyin.
	2. Gerekirse `AudioManager.SOUND_MAP` içerisine alias ekleyin:
	   ```gdscript
	   "my_action": "res://assets/audio/sfx/my_action.wav"
	   ```
	3. Gameplay kodunda doğrudan `AudioManager.play_sfx("my_action")` çağırın.
	
	### 3.3. Yeni Alet ve Kalite Seviyesi Ekleme
	- Alet kaliteleri `ItemRegistry.Quality` enum'u ile yönetilir (`BASIC`, `COPPER`, `IRON`, `GOLD`).
	- Hotbar ve envanter renklendirmeleri `UIConstants.create_slot_stylebox()` üzerinden otomatik kalite çerçevesi kazanır.
	
	### 3.4. UI Theme ve Stillendirme Değişimi
	- Tüm paneller, butonlar, slotlar ve tooltip'ler `res://ui/theme/botanical_haven_theme.tres` ve `res://ui/theme/ui_constants.gd` tarafından beslenir.
	- Bir butonun stilini değiştirmek için `botanical_haven_theme.tres` dosyasında `Button` stili düzenlenir; HUD, Hotbar, Shop ve Menü butonları anında yeni stili benimser.
	
	---
	
	## 4. Runtime Asset Swapping & Modding Desteği
	
	Oyun çalışırken veya test esnasında kod değiştirmeden asset değiştirmek için dinamik override API'si mevcuttur:
	
	```gdscript
	# Texture Override
	AssetRegistry.register_texture_override("item.seed_red_flower", new_texture)
	
	# Sound Override
	AudioManager.register_sound_override("farming.water", new_audio_stream)
	
	# Override'ları temizleme (orijinal asset'e dönme)
	AssetRegistry.clear_texture_overrides()
	AudioManager.clear_sound_overrides()
	```
	
	---
	
	## 5. World Builder ile Entegrasyon
	
	World Builder editorü ve runtime oyun motoru aynı `AssetRegistry` resolver'ını paylaşır:
	- World JSON dosyalarında `asset_id` (örneğin `"tree_stump"`, `"rock"`, `"rowan"`) depolanır.
	- Asset dosyasının konumu değişse bile `AssetRegistry` içindeki alias haritası sayesinde eski dünyalar hiçbir bozulma olmadan yüklenmeye devam eder.
	
	---
	
	## 6. Sık Sorulan Sorular
	
	**S: Bir asset değiştirildiğinde hangi gameplay scriptlerine dokunmam gerekir?**
	*C: Hiçbirine! Yalnızca asset dosyasını ilgili klasöre koymanız veya AssetRegistry'ye kaydetmeniz yeterlidir.*
	
	**S: Bir texture bulunamazsa oyun çöker mi?**
	*C: Hayır! `AssetRegistry.get_fallback_placeholder_texture()` otomatik olarak temiz bir pixel-art renkli yer tutucu oluşturur ve konsola uyarı bırakır.*
	