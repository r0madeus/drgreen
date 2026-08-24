# Botanical Haven — Comprehensive Localization & Internationalization Guide
	
	---
	
	## 1. Mimari Genel Bakış
	
	Botanical Haven, **Key-Based Translation** ve **Decoupled ID Architecture** prensipleriyle uluslararasılaştırma (i18n) standartlarına tam uyumlu olarak geliştirilmiştir.
	
	- **İngilizce Metinler Key Değildir**: Asla `tr("Hello World")` kullanılmaz. Key her zaman namespace tabanlıdır (`ui.menu.new_game`, `item.seed_red_flower.name`).
	- **Stable IDs**: Oyun mantığı, save dosyaları ve network paketleri ASLA lokalize edilmiş metin taşımaz; daima stable ID (`seed_red_flower`, `quest_01`, `farm`, `rowan`) kullanır.
	- **Runtime Dynamic Translation**: Çeviri metinleri runtime anında `LocalizationManager` ve `TranslationServer` üzerinden dinamik olarak çözümlenir.
	
	---
	
	## 2. Translation Dosya Yapısı ve Yeni Dil Ekleme
	
	Tüm çeviriler `res://localization/game.csv` dosyasında tutulur:
	
	```csv
	keys,en,tr,de,fr,es,pt_BR,ja,ko,zh_CN,ru
	ui.menu.new_game,New Game,Yeni Oyun,Neues Spiel,Nouvelle Partie,Nueva Partida,Novo Jogo,新規ゲーム,새 게임,新游戏,Новая игра
	ui.menu.continue,Continue,Devam Et,Fortsetzen,Continuer,Continuar,Continuar,つづきから,이어하기,继续游戏,Продолжить
	```
	
	### Adım Adım Yeni Dil Ekleme:
	1. `res://localization/game.csv` dosyasının ilk satırındaki (header) locale listesine yeni dil kodunu ekleyin (örneğin `de` veya `ja`).
	2. İlgili satırların altına o dilin çevirilerini yazın (çift tırnak içeren metinler için CSV escaping kurallarına uyun).
	3. `LocalizationManager.SUPPORTED_LOCALES` tablosunda dil adının yer aldığından emin olun (örn. `"de": "Deutsch"`).
	4. Godot Editor'de Project Settings -> Internationalization -> Translations altında CSV dosyasının tanımlı olduğunu doğrulayın.
	5. Oyunu açıp Settings -> Language menüsünden yeni dili seçin. **Hiçbir gameplay kodunu değiştirmeye gerek yoktur!**
	
	---
	
	## 3. Placeholder ve Şablon Kullanımı
	
	String birleştirmeleri (`"Day " + str(d)`) asla kullanılmaz. Bunun yerine `{placeholder}` şablonları kullanılır:
	
	```gdscript
	# CSV Tanımı:
	# ui.hud.day_season,Day {day} • {season},Gün {day} • {season}
	
	# GDScript Kullanımı:
	var text = LocalizationManager.format("ui.hud.day_season", {
	    "day": 5,
	    "season": LocalizationManager.get_season_name("spring")
	})
	```
	
	---
	
	## 4. Pluralization (Çoğul Desteği)
	
	Farklı dillerin çoğul kuralları için `LocalizationManager.get_plural()` kullanılır:
	
	```gdscript
	# CSV Tanımı:
	# ui.inventory.items_count,{count} item,{count} eşya
	# ui.inventory.items_count_plural,{count} items,{count} eşya
	
	var text = LocalizationManager.get_plural("ui.inventory.items_count", "ui.inventory.items_count_plural", item_count)
	```
	
	---
	
	## 5. Veri Odaklı Sistemler (Quests, Items, Dialogues, Worlds)
	
	### Quests (`data/quests/base_quests.json`):
	```json
	{
	  "id": "quest_01",
	  "title_key": "quest.quest_01.title",
	  "description_key": "quest.quest_01.desc",
	  "objectives": [
	    {
	      "text_key": "quest.quest_01.obj",
	      "amount": 1
	    }
	  ]
	}
	```
	
	### Items & Tools (`ItemRegistry`):
	- `ItemRegistry.get_localized_name(item_id)`
	- `ItemRegistry.get_localized_description(item_id)`
	- `ItemRegistry.get_quality_name(item_id)`
	
	### Dialogue JSON (`data/dialogue/*.json`):
	```json
	{
	  "npc_id": "rowan",
	  "npc_name_key": "dialogue.rowan.name",
	  "nodes": {
	    "intro": {
	      "lines_keys": [
	        "dialogue.rowan.intro_1",
	        "dialogue.rowan.intro_2"
	      ]
	    }
	  }
	}
	```
	
	---
	
	## 6. Translation Validation & Kalite Kontrolü
	
	Projedeki çevirilerin bütünlüğünü ve placeholder eşleşmelerini test etmek için `LocalizationValidator` kullanılır:
	
	```gdscript
	var report = LocalizationValidator.validate_all("res://localization/game.csv")
	if not report["valid"]:
	    print("Localization Errors: ", report["errors"])
	```
	
	Kontrol edilenler:
	- Mükerrer (duplicate) key kontrolü
	- İngilizce (Fallback) çevirisi eksik olan key'ler
	- Placeholder `{placeholder}` eksiklikleri ve yazım hataları
	- Hatalı CSV yapısı
	
	---
	
	## 7. Pseudo-Localization ile UI Testi
	
	Farklı dillerdeki metin uzunluklarının UI taşmalarına yol açıp açmadığını test etmek için **Pseudo-Localization** modu mevcuttur:
	
	- Oyun esnasında **`F8`** tuşuna basarak Pseudo-Localization modunu açıp kapatabilirsiniz.
	- Metinler otomatik olarak genişletilip aksanlandırılır: `[Mëët Røwån ~!]`
	- Bu sayede dialog kutuları, butonlar, slotlar ve tooltip'lerin taşma yapıp yapmadığı gerçek çeviri olmadan test edilebilir.
	
	---
	
	## 8. Multiplayer ve Save/Load Uyumluluğu
	
	- **Ağ İletişimi**: Client ve Host yalnızca `quest_id`, `item_id`, `dialogue_id` ve `action` taşır. Host İngilizce, Client Türkçe oynasa dahi her iki taraf kendi arayüzünde doğru dilde görür.
	- **Save/Load**: Kayıt dosyalarında yalnızca ham ID'ler depolanır. Dil değiştirildiğinde veya farklı dillerde kayıt yüklendiğinde hiçbir veri kaybı ya da uyumsuzluk oluşmaz.
	
