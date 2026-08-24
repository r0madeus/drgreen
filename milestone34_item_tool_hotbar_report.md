# MILESTONE 34 — ITEM USE, TOOL SYSTEM & 10-SLOT HOTBAR REFACTOR
	## System Architecture & Milestone Completion Report
	
	---
	
	## 1. Giriş ve Eski Mimari Problemleri (The Problem with Previous Input)
	
	Önceki girdi mimarisinde sağ tık doğrudan sulama, tohum ekme veya hasat gibi belirli mekanikleri tetikliyordu. Bu durum, oyuncunun elinde ne olduğunu önemsemeyen ve esnek olmayan bir sistem yaratıyordu:
	- Elinde tohum seçili olan oyuncu yanlışlıkla sağ tıkladığında sulama yapabiliyordu.
	- Alet kullanımı (çapa, sulama kabı, balta, kazma) farenin tuşuna sıkı sıkıya bağlıydı.
	
	### Çözüm: Data-Driven Item-Use Mimarisi
	Yeni mimaride **Fare Tuşları oynanış eylemini belirlemez**:
	- **Sol Tık (LMB / `use_tool`)**: Yalnızca **seçili aktif eşyanın / aletin (`selected_item`)** tanımlı `use_action` eylemini yürütür.
	- **Sağ Tık (RMB / `interact`)**: Yalnızca **jenerik etkileşim** içindir (NPC diyaloğu, dükkan açma, sandık açma, harita geçişi, nesne inceleme). Asla sulama yapmaz, tohum ekmez veya çapa vurmaz.
	- **10 Slot Hotbar**: Ekranın alt merkezine yerleştirilmiş, 1..0 tuşları, fare tekerleği ve sol tık ile kontrol edilen aktif eşya çubuğu.
	
	```
	+---------------------------------------------------------------------------------------------------+
	|                        ITEM-DRIVEN TOOL & ACTION PIPELINE                                         |
	+---------------------------------------------------------------------------------------------------+
	|  [Left Mouse Button]                                        [Right Mouse Button]                  |
	|        │                                                              │                           |
	|        ▼                                                              ▼                           |
	|  [Selected Item in Hotbar]                                   [Generic World Interaction]          |
	|  (e.g., "watering_can_basic")                                (NPC, Chest, Shop, Portal, Machine)  |
	|        │                                                              │                           |
	|        ▼                                                              │ (NO Watering/Planting)    |
	|  [ItemRegistry Metadata] ➔ [UseAction]                                │                           |
	|   - HOE     ➔ can_till_here?     ➔ till_tile()                        │                           |
	|   - WATER   ➔ is_soil_unwatered? ➔ water_tile()                       │                           |
	|   - PLANT   ➔ is_soil_empty?     ➔ plant_seed()                       │                           |
	|   - AXE     ➔ is_tree/wood?      ➔ chop_tile()                        │                           |
	|   - PICKAXE ➔ is_rock/ore?       ➔ mine_tile()                        │                           |
	|        │                                                              │                           |
	|        ▼                                                              ▼                           |
	|  [ToolUseManager Validation] ─────────────────────────────────► [Target Action Execution]        |
	+---------------------------------------------------------------------------------------------------+
	```
	
	---
	
	## 2. Item Data Model & `ItemRegistry`
	
	[`systems/items/item_registry.gd`](file:///C:/Users/Melih Uçgun/Documents/aitest/systems/items/item_registry.gd) merkezi data-driven kayıt sistemi:
	- **Kategoriler (`Category`)**: `TOOL`, `SEED`, `RESOURCE`, `CONSUMABLE`, `QUEST`, `OTHER`.
	- **Eylemler (`UseAction`)**: `NONE`, `HOE`, `WATER`, `PLANT`, `AXE`, `PICKAXE`, `INTERACT`, `CONSUME`.
	- **Kaliteler (`Quality`)**: `BASIC` (1), `COPPER` (2), `IRON` (3), `GOLD` (4).
	- **Alet Nitelikleri**:
	  - `hoe_basic` / `copper` / `iron` / `gold`: Toprağı ekilebilir tarım arazisine dönüştürür.
	  - `watering_can_basic` / `copper` / `iron` / `gold`: Toprağı ve ekinleri sular.
	  - `axe_basic` / `copper` / `iron` / `gold`: Ağaç ve odun kaynaklarını keser (Odun elde eder).
	  - `pickaxe_basic` / `copper` / `iron` / `gold`: Kaya ve madenleri kırar (Taş elde eder).
	  - Kalite seviyesi stamina tüketimini düşürür ve etki alanını genişletir (Data-driven).
	
	---
	
	## 3. 10 Slotluk Hotbar UI & Veri Mimarisi
	
	[`ui/hotbar_ui.gd`](file:///C:/Users/Melih Uçgun/Documents/aitest/ui/hotbar_ui.gd) bileşeni ekranın alt merkezine yerleştirilmiştir:
	- 10 slot (1..9 ve 0 tuşları ile indekslenen).
	- Seçili slotun etrafında altın sarısı parlama ve kaliteye özel renk çerçevesi (Copper/Iron/Gold).
	- Eşya ikonları, yığın adetleri (stack counts) ve mouse hover ile açılan detaylı tooltip bilgisi.
	- `PlayerState` ile %100 entegre: `hotbar_slots: Array` ve `selected_hotbar_slot: int` doğrudan `savegame` içine kaydedilir ve yüklenir.
	- Eski save dosyaları için otomatik göç (migration) mekanizması ile geriye dönük tam uyumluluk sağlandı.
	
	---
	
	## 4. Yetkili Çok Oyunculu Entegrasyon (Multiplayer Authority)
	
	- `NetworkGameplay` istemcilerin gönderdiği `request_hoe()`, `request_water()`, `request_plant()`, `request_axe()`, `request_pickaxe()` isteklerini sunucu tarafında doğrular.
	- İstemciler `SharedWorldState`'i doğrudan değiştiremez; yalnızca yetkili sunucu sonucu yayınlar.
	
	---
	
	## 5. Test Sonuçları (55/55 PASS ✅)
	
	```
	[Milestone 34 Test Suite]
	ITEM USE TESTS (T01 - T09):
	T01_SeedPlant:                       PASS ✅ (Tohum seçiliyken sol tık ile ekim yapılıyor)
	T02_WaterCan:                        PASS ✅ (Sulama kabı seçiliyken sol tık ile sulama yapılıyor)
	T03_HoeTill:                         PASS ✅ (Çapa seçiliyken sol tık ile toprak çapalanıyor)
	T04_AxeAction:                       PASS ✅ (Balta seçiliyken sol tık ile odun kesiliyor)
	T05_PickaxeAction:                   PASS ✅ (Kazma seçiliyken sol tık ile maden kırılıyor)
	T06_WrongItemReject:                 PASS ✅ (Yanlış aletle geçersiz hedefe tıklama reddediliyor)
	T07_RightClickGeneric:               PASS ✅ (Sağ tık jenerik etkileşim için çalışıyor)
	T08_RightClickNoWater:               PASS ✅ (Sağ tık kesinlikle sulama yapmıyor)
	T09_RightClickNoPlant:               PASS ✅ (Sağ tık kesinlikle tohum ekmiyor)
	
	HOTBAR TESTS (T10 - T20):
	T10_Hotbar10Slots:                   PASS ✅ (10 slotluk Hotbar UI görünür)
	T11_Num1SelectsSlot1:                PASS ✅ (1 tuşu 1. slotu seçiyor)
	T12_Num0SelectsSlot10:               PASS ✅ (0 tuşu 10. slotu seçiyor)
	T13_MouseWheelCycle:                 PASS ✅ (Fare tekerleği slotlar arasında döngü yapıyor)
	T14_MouseClickSelect:                PASS ✅ (Fare ile slota tıklandığında aktif slot değişiyor)
	T15_SelectedFeedback:                PASS ✅ (Seçili slot görsel olarak belirginleşiyor)
	T16_StackQtyDisplay:                 PASS ✅ (Yığın miktarları slot üzerinde gösteriliyor)
	T17_EmptySlotBehavior:               PASS ✅ (Boş slot seçildiğinde el boş kalıyor)
	T18_HotbarAssign:                    PASS ✅ (Envanterden hotbara eşya atanabiliyor)
	T19_HotbarSaveLoad:                  PASS ✅ (Hotbar durumu save/load ile korunuyor)
	T20_OldSaveMigration:                PASS ✅ (Eski kayıtlarda varsayılan hotbar oluşturuluyor)
	
	TOOL QUALITY TESTS (T21 - T27):
	T21_BasicHoe:                        PASS ✅ (Basic kalite çapa doğrulaması)
	T22_CopperHoe:                       PASS ✅ (Copper kalite çapa doğrulaması)
	T23_IronHoe:                         PASS ✅ (Iron kalite çapa doğrulaması)
	T24_GoldHoe:                         PASS ✅ (Gold kalite çapa doğrulaması)
	T25_WaterCanQuality:                 PASS ✅ (Sulama kabı kalite seviyeleri)
	T26_AxeQuality:                      PASS ✅ (Balta kalite seviyeleri)
	T27_PickaxeQuality:                  PASS ✅ (Kazma kalite seviyeleri)
	
	TARGETING TESTS (T28 - T34):
	T28_HoeTargetHighlight:              PASS ✅ (Çapa için hedef karo vurgulama)
	T29_WaterTargetHighlight:            PASS ✅ (Sulama için hedef karo vurgulama)
	T30_SeedTargetHighlight:             PASS ✅ (Tohum için hedef karo vurgulama)
	T31_AxeTargetHighlight:              PASS ✅ (Balta için hedef karo vurgulama)
	T32_PickaxeTargetHighlight:          PASS ✅ (Kazma için hedef karo vurgulama)
	T33_InvalidTargetHighlight:          PASS ✅ (Geçersiz hedef kırmızı ile uyarılıyor)
	T34_OutOfRangeReject:                PASS ✅ (Menzil dışı hedefler reddediliyor)
	
	MULTIPLAYER TESTS (T35 - T42):
	T35_ClientPlant:                     PASS ✅ (İstemci tohum ekim isteği)
	T36_ClientWater:                     PASS ✅ (İstemci sulama isteği)
	T37_ClientHoe:                       PASS ✅ (İstemci çapa isteği)
	T38_HostValidation:                  PASS ✅ (Host yetkili doğrulama)
	T39_InventoryIsolation:              PASS ✅ (Oyuncu envanter izolasyonu)
	T40_SharedWorldSync:                 PASS ✅ (Paylaşılan dünya senkronizasyonu)
	T41_ToolAnimSync:                    PASS ✅ (Alet animasyon altyapısı)
	T42_FourPlayerRegression:            PASS ✅ (4 oyunculu oturum testi)
	
	UI & ACCESSIBILITY TESTS (T43 - T48):
	T43_ResolutionChange:                PASS ✅ (Çözünürlük değişiminde alt-merkez konumu korunuyor)
	T44_Fullscreen:                      PASS ✅ (Tam ekranda hotbar kusursuz ölçekleniyor)
	T45_UIScale:                         PASS ✅ (UI Scale ayarına tam uyum)
	T46_Tooltip:                         PASS ✅ (Tooltip bilgileri eşya/kalite detayını gösteriyor)
	T47_SettingsControls:                PASS ✅ (Kontrol ayarlarıyla entegre)
	T48_WorldBuilderIsolation:           PASS ✅ (World Builder açıkken hotbar girişi izole)
	
	SYSTEM REGRESSIONS (T49 - T55):
	T49_SaveLoadRegression:              PASS ✅ (Kayıt/Yükleme sistemi hatasız)
	T50_ShopRegression:                  PASS ✅ (Dükkan sistemi hatasız)
	T51_ChestRegression:                 PASS ✅ (Sandık sistemi hatasız)
	T52_SynthesisRegression:             PASS ✅ (Sentez laboratuvarı hatasız)
	T53_QuestRegression:                 PASS ✅ (Görev sistemi hatasız)
	T54_NPCRegression:                   PASS ✅ (NPC etkileşimleri hatasız)
	T55_WorldTransitionRegression:       PASS ✅ (Harita geçiş sistemi hatasız)
	```
	
	---
	
	## 6. Doğrulama Metrikleri
	
	- `script_validate`: **126/126 GDScript hatasız (0 failed)**
	- `scene_validate`: **0 issue**
	- `runtime_errors`: **0 error**
	