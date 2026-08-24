# Botanical Haven — Core Farming & Tool System Guide
	
	---
	
	## 1. Mimari Genel Bakış ve Temel Felsefe
	
	Botanical Haven'ın Core Tool & Farming sistemi, **Stardew Valley** ve **Terraria** fiziksel etkileşim standartlarına uygun olarak tasarlanmıştır.
	
	- **Data-Driven Tasarım**: Alet güçleri, enerji maliyetleri, menziller ve kaynak düğümleri (resource nodes) GDScript içerisine hardcode edilmez; `res://data/tools/tools.json` ve `res://data/resources/resource_nodes.json` dosyalarından okunur.
	- **Context-Sensitive Etkileşim**: Sol tık eylemi, oyuncunun o anda elinde tuttuğu / seçtiği nesneye (Çapa, Sulama Kabı, Balta, Kazma, Tohum) göre belirlenir.
	- **Enerji / Stamina Entegrasyonu**: Her alet kullanımı oyuncunun enerjisini tüketir (`PlayerState.energy`). Enerji yetersizse işlem iptal edilir ve oyuncuya görsel uyarı verilir.
	- **Host-Authoritative Multiplayer**: Çok oyunculu modda kaynak kırma ve zemin işleme eylemleri Host tarafından doğrulanır; yarış durumları (race conditions) engellenir.
	
	---
	
	## 2. Desteklenen Temel Aletler ve Kalite Seviyeleri
	
	| Alet Tipi | Kalite Seviyeleri | Eylem Türü | Enerji Maliyeti | Güç | Açıklama |
	| :--- | :--- | :--- | :--- | :--- | :--- |
	| **Hoe (Çapa)** | Basic, Copper, Iron, Gold | Toprak İşleme | 2.0 → 1.0 | 1 → 4 | Çim/toprak zeminleri ekilebilir tarlaya dönüştürür. |
	| **Watering Can (Sulama Kabı)** | Basic, Copper, Iron, Gold | Sulama | 2.0 → 1.0 | 1 → 4 | Ekili ve kuru toprakları sular. |
	| **Axe (Balta)** | Basic, Copper, Iron, Gold | Ağaç / Odun Kesme | 3.0 → 1.5 | 1 → 4 | Ağaç, kütük ve kırık dalları keser, odun düşürür. |
	| **Pickaxe (Kazma)** | Basic, Copper, Iron, Gold | Kaya / Maden Kırma | 3.0 → 1.5 | 1 → 4 | Kaya ve cevherleri kırar, taş ve maden düşürür. |
	
	---
	
	## 3. Veri Tanımları & Konfigürasyon
	
	### 3.1. Yeni Alet Tanımlama (`res://data/tools/tools.json`)
	```json
	"hoe_copper": {
	    "id": "hoe_copper",
	    "type": "hoe",
	    "quality": "copper",
	    "power": 2,
	    "energy_cost": 1.75,
	    "range": 1,
	    "upgrade_level": 1,
	    "name_key": "tool.hoe.copper.name",
	    "description_key": "tool.hoe.copper.desc",
	    "asset_id": "tool.hoe.copper",
	    "sfx_id": "farming.plant",
	    "effect_id": "effect.farming.plant"
	}
	```
	
	### 3.2. Yeni Kaynak Düğümü (Resource Node) Tanımlama (`res://data/resources/resource_nodes.json`)
	```json
	"resource.copper_ore": {
	    "id": "resource.copper_ore",
	    "name_key": "resource.copper_ore.name",
	    "required_tool": "pickaxe",
	    "required_power": 2,
	    "max_health": 4,
	    "drops": [
	        { "item_id": "stone", "min": 1, "max": 2, "chance": 1.0 },
	        { "item_id": "copper_ore", "min": 1, "max": 3, "chance": 1.0 }
	    ],
	    "hit_sfx": "ui.select",
	    "destroy_sfx": "farming.harvest",
	    "hit_effect": "effect.farming.plant",
	    "destroy_effect": "effect.farming.harvest"
	}
	```
	
	---
	
	## 4. Etkileşim & Kontrol Akışı (Gameplay Flow)
	
	1. **Mouse / Klavye Hedefleme**:
	   - Oyuncu fareyi harita üzerinde gezdirdiğinde `TileHighlight` göstergesi hedef grid hücresini işaretler.
	   - Hücre menzil içindeyse ve eldeki alet için uygunsa yeşil/mavi highlight; geçersizse kırmızı/soluk highlight gösterilir.
	2. **Sol Tık (Use Tool / Plant Seed)**:
	   - `ToolUseManager.use_selected_item(player, target_pos, selected_item)` çağrılır.
	   - Menzil, enerji ve hedef uygunluğu kontrol edilir.
	   - Uygunsa enerji düşülür, dünya değiştirilir, SFX/VFX oynatılır ve `EventBus` sinyalleri tetiklenir.
	3. **Sağ Tık (Context Interaction)**:
	   - NPC konuşması, dükkan açma, sandık açma veya dünya geçişleri gibi genel etkileşimleri tetikler.
	
	---
	
	## 5. EventBus Sinyalleri & Görev Entegrasyonu
	
	Tool sistemi aşağıdaki global sinyalleri yayınlar:
	- `tool_used(tool_id: String, target_pos: Vector2i)`
	- `soil_tilled(pos: Vector2i)`
	- `plant_watered(pos: Vector2i)`
	- `resource_hit(node_id: String, pos: Vector2i, damage: int, remaining_hp: int)`
	- `resource_destroyed(node_id: String, pos: Vector2i)`
	- `resource_collected(item_id: String, count: int)`
	- `tool_upgraded(tool_id: String, new_quality: String)`
	
	Görev sistemi (`QuestManager`), örneğin 5 ağaç kesildiğinde `resource_destroyed` sinyalini dinleyerek hedefleri otomatik ilerletir.
	
	---
	
	## 6. Alet Geliştirme (Tool Upgrades)
	
	Aletler `ToolUseManager.upgrade_tool(player_state, "hoe")` çağrısı ile bir üst seviyeye taşınır:
	- Basic → Copper → Iron → Gold
	- Oyuncunun envanterindeki ve hotbar'ındaki alet otomatik olarak güncellenir.
	- Kayıt/Yükleme (Save/Load) sırasında geliştirilmiş aletler korunur.
	