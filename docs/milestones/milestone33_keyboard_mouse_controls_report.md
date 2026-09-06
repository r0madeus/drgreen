# MILESTONE 33 — STARDEW-STYLE KEYBOARD + MOUSE CONTROL SYSTEM
	## System Architecture & Milestone Completion Report
	
	---
	
	## 1. Genel Bakış (Overview)
	
	Bu milestone ile oyunun tamamen klavye odaklı olan kontrol şeması, **Stardew Valley / Terraria PC kontrol standartlarına** yükseltilmiştir:
	- **WASD / Ok Tuşları**: Karakterin 16x16 grid üzerinde akıcı hareketi.
	- **Sol Fare Tuşu (LMB / `use_tool`)**: Menüden seçili aleti / tohumu kullanma (Toprağı çapalama, tohum ekme, sulama, hasat etme).
	- **Sağ Fare Tuşu (RMB / `interact`)**: NPC'lerle konuşma, sandık açma, dükkan açma, harita geçişi kapılarını kullanma ve çevre nesneleriyle etkileşim.
	- **Fare Tekerleği (Mouse Wheel Up / Down)**: Hotbar eşyaları arasında ileri/geri geçiş.
	- **Rakam Tuşları (1..9)**: Hotbar slotlarını doğrudan seçme.
	- **Shift**: Koşma modu (Run / 2x hız).
	- **E / I**: Envanter açma/kapama.
	- **F / Q**: Günlük / Görev günlüğü açma/kapama.
	- **Space / Escape**: İkincil etkileşim ve Duraklatma menüsü.
	
	```
	+---------------------------------------------------------------------------------------------------+
	|                        STARDEW-STYLE HYBRID INPUT PIPELINE                                        |
	+---------------------------------------------------------------------------------------------------+
	|  [Hardware Events] (Mouse Move, LMB, RMB, Wheel, Keys 1..9, WASD)                                |
	|        │                                                                                          |
	|        ▼                                                                                          |
	|  [Input Isolation Check] (Is Mouse over UI? / Is WorldBuilder Active?)                            |
	|   ├── TRUE  ➔ Route directly to UI / Inspector / Modal Dialogs (Suppress World Clicks)           |
	|   └── FALSE ➔ Continue to World & Tile Target Pipeline                                           |
	|              │                                                                                    |
	|              ▼                                                                                    |
	|        [Coordinate Mapping] (Camera2D Viewport Transform ➔ World Pos ➔ Grid Pos)                  |
	|              │                                                                                    |
	|              ▼                                                                                    |
	|        [Distance Validation] (Chebyshev Distance <= 2 Tiles)                                      |
	|              │                                                                                    |
	|        ┌─────┴──────────────────────────────────────────────────────┐                             |
	|        ▼                                                            ▼                             |
	|  [TileHighlight Overlay]                                     [Action Execution]                   |
	|   - Green: Valid In-Range Action (Plant/Water/Harvest)       - LMB: use_tool_at()                 |
	|   - Red: Out-of-Range / Blocked                              - RMB: interact_at()                 |
	|   - Cyan: World Exit Portal                                  - Wheel: cycle_hotbar()              |
	|   - Gold: NPC / Rowan Dialogue                               - 1..9: select_slot_index()          |
	+---------------------------------------------------------------------------------------------------+
	```
	
	---
	
	## 2. Fare Hedefleme, Çözünürlük & Kamera Eşleme
	
	### A. Viewport & Kamera Koordinat Dönüşümü
	- Fare koordinatı doğrudan ekran pikseli olarak değil, `player.get_global_mouse_position()` ve `grid_manager.world_to_grid(mouse_world)` üzerinden dönüştürülür.
	- Godot 4 `Camera2D` yakınlaştırma (Zoom 0.75x - 3.0x), `canvas_items` ölçekleme ve pencere çözünürlükleri (1152x648, 1280x720, 1920x1080) altında farenin işaret ettiği karo kusursuz doğrulukla hesaplanır.
	
	### B. Mesafe Kontrolü (Interaction Range)
	- Oyuncunun bulunduğu `grid_position` ile hedeflenen `mouse_grid_position` arasındaki mesafe `MAX_INTERACTION_DISTANCE = 2` karo ile sınırlandırılmıştır.
	- Oyuncunun erişemeyeceği karolar kırmızı uyarı ile işaretlenir ve gereksiz eylemler engellenir.
	
	---
	
	## 3. Dinamik Karo Vurgulama & Araç Önizleme (`TileHighlight`)
	
	[`systems/grid/tile_highlight.gd`](file:///C:/Users/Melih Uçgun/Documents/aitest/systems/grid/tile_highlight.gd) bileşeni oyun dünyasına pixel-art estetiğinde dinamik bir overlay ekler:
	- **Ekim Modu (Plant - Yeşil)**: Seçili tohum ve ekilebilir toprak olduğunda yeşil çerçeve ve tohum önizlemesi.
	- **Sulama Modu (Water - Mavi)**: Kuru toprak veya susuz bitki üzerinde mavi çerçeve.
	- **Hasat Modu (Harvest - Altın Sarısı)**: Olgunlaşmış bitki üzerinde altın sarısı parlama.
	- **Etkileşim Modu (Interact - Mor/Sarı)**: Rowan veya NPC üzerinde mor/altın çerçeve ve etkileşim ipucu.
	- **Kapı/Çıkış Modu (Exit - Turkuaz)**: Harita çıkışları üzerinde turkuaz çerçeve.
	- **Erişim Dışı (Invalid - Kırmızı)**: Menzil dışındaki karolar için soluk kırmızı çerçeve.
	- **UI Koruması**: Envanter, dükkan, diyalog veya World Builder açıkken karo vurgulaması otomatik olarak gizlenir.
	
	---
	
	## 4. UI & World Builder Giriş İzolasyonu
	
	- `PlayerInteraction.is_mouse_over_ui()` fonksiyonu; `InventoryUI`, `ShopUI`, `DialogueUI`, `CombinationUI`, `QuestUI`, `SettingsUI`, `PauseMenu`, `SaveSelectUI` veya `WorldBuilder` sahnelerinin açık olup olmadığını denetler.
	- Herhangi bir arayüz açıkken dünyaya sol veya sağ tık ile eylem gönderilmesi kesinlikle engellenir.
	
	---
	
	## 5. Çok Oyunculu Uyumluluk (Multiplayer Authority)
	
	- İstemci (Client) fare ile sol/sağ tık yaptığında doğrudan dünyayı değiştirmez; `NetworkGameplay.request_plant()`, `request_water()`, `request_harvest()`, `NetworkNPC` ve `NetworkContainers` API'lerini tetikler.
	- Host eylemi doğrular ve yetkili sonucu tüm oyunculara yayınlar (`SharedWorldState`).
	
	---
	
	## 6. Test Sonuçları (50/50 PASS ✅)
	
	```
	[Milestone 33 Test Suite]
	BASIC TESTS (T01 - T08):
	T01_WASDMovement:                    PASS ✅ (WASD hareketi akıcı çalışıyor)
	T02_LeftClickUseTool:                PASS ✅ (Sol tık alet/tohum kullanımı başarılı)
	T03_RightClickInteract:              PASS ✅ (Sağ tık etkileşimi başarılı)
	T04_MouseWorldPosition:              PASS ✅ (Fare dünya koordinatı doğru hesaplanıyor)
	T05_GridTargetCalc:                  PASS ✅ (Fare karo koordinatı doğru hesaplanıyor)
	T06_TileHighlight:                   PASS ✅ (Karo vurgulama bileşeni devrede)
	T07_ToolPreview:                     PASS ✅ (Dinamik tohum/sulama/hasat modları doğru)
	T08_OutOfRangeReject:                PASS ✅ (Menzil dışı tıklamalar güvenle reddediliyor)
	
	FARMING TESTS (T09 - T12):
	T09_SeedPlacement:                   PASS ✅ (Fare ile tohum ekimi başarılı)
	T10_Watering:                        PASS ✅ (Fare ile sulama başarılı)
	T11_Harvest:                         PASS ✅ (Fare ile hasat başarılı)
	T12_ToolTargetCorrectness:           PASS ✅ (Hedeflenen karonun durumu doğru güncelleniyor)
	
	INTERACTION TESTS (T13 - T18):
	T13_NPCDialogue:                     PASS ✅ (NPC'ye sağ tık ile diyalog başlatılabiliyor)
	T14_ChestOpen:                       PASS ✅ (Sandığa sağ tık ile sandık açılabiliyor)
	T15_ShopOpen:                        PASS ✅ (Tüccara sağ tık ile dükkan açılabiliyor)
	T16_WorldExit:                       PASS ✅ (Kapıya sağ tık ile harita geçişi tetikleniyor)
	T17_LabInteraction:                  PASS ✅ (Sentez laboratuvarı etkileşimi başarılı)
	T18_ResourceInteraction:             PASS ✅ (Çevre kaynakları etkileşimi başarılı)
	
	UI TESTS (T19 - T24):
	T19_InventoryMouse:                  PASS ✅ (Envanter fare ile yönetilebiliyor)
	T20_ShopMouse:                       PASS ✅ (Dükkan alışverişi fare ile yapılabiliyor)
	T21_DialogueMouse:                   PASS ✅ (Diyalog seçimleri fare ile tıklanabiliyor)
	T22_SettingsMouse:                   PASS ✅ (Ayarlar menüsü fare ile kontrol ediliyor)
	T23_SaveSelectMouse:                 PASS ✅ (Save slotları fare ile seçilebiliyor)
	T24_PauseMouse:                      PASS ✅ (Duraklatma menüsü fare ile kontrol ediliyor)
	
	INPUT & HOTBAR TESTS (T25 - T30):
	T25_MouseWheelHotbar:                PASS ✅ (Fare tekerleği ile hotbar eşya değişimi çalışıyor)
	T26_NumberKeyHotbar:                 PASS ✅ (1..9 tuşları ile doğrudan slot seçimi çalışıyor)
	T27_KeyboardStillWorks:              PASS ✅ (Klavye tuşları tam fonksiyonel kalmaya devam ediyor)
	T28_RebindMouseButton:               PASS ✅ (Fare tuşu tuş atama sistemiyle uyumlu)
	T29_UIBlocksWorldClicks:             PASS ✅ (Arayüz açıkken dünya tıklamaları bloke ediliyor)
	T30_WorldBuilderBlocks:              PASS ✅ (World Builder açıkken oynanış tıklamaları bloke ediliyor)
	
	CAMERA & DISPLAY TESTS (T31 - T35):
	T31_Res1152x648Mapping:              PASS ✅ (1152x648 çözünürlükte fare hedeflemesi tam isabet)
	T32_Res1920x1080Mapping:             PASS ✅ (1920x1080 çözünürlükte fare hedeflemesi tam isabet)
	T33_FullscreenMapping:               PASS ✅ (Tam ekranda fare koordinat dönüşümü doğru)
	T34_BorderlessMapping:               PASS ✅ (Borderless modda fare koordinat dönüşümü doğru)
	T35_CameraZoomMapping:               PASS ✅ (Kamera yakınlaştırmalarında karo eşlemesi doğru)
	
	MULTIPLAYER TESTS (T36 - T43):
	T36_ClientToolReq:                   PASS ✅ (İstemci alet isteği yetkili sunucuya iletiliyor)
	T37_ClientInteractReq:               PASS ✅ (İstemci etkileşim isteği sunucuya iletiliyor)
	T38_ClientFarmingReq:                PASS ✅ (İstemci ekim/sulama/hasat istekleri iletiliyor)
	T39_HostValidation:                  PASS ✅ (Sunucu yetkisi korunuyor)
	T40_SharedWorldSync:                 PASS ✅ (Paylaşılan dünya senkronize ediliyor)
	T41_InventoryIsolation:              PASS ✅ (Oyuncu envanterleri birbirinden izole)
	T42_TwoPlayerInteract:               PASS ✅ (2 oyunculu etkileşim doğrulandı)
	T43_FourPlayerRegression:            PASS ✅ (4 oyunculu regresyon testi başarılı)
	
	SYSTEM REGRESSIONS (T44 - T50):
	T44_SaveLoadRegression:              PASS ✅ (Kayıt/Yükleme sistemi hatasız)
	T45_WorldTransitionRegression:       PASS ✅ (Harita geçiş sistemi hatasız)
	T46_QuestRegression:                 PASS ✅ (Görev sistemi hatasız)
	T47_SynthesisRegression:             PASS ✅ (Sentez sistemi hatasız)
	T48_ContainerRegression:             PASS ✅ (Sandık sistemi hatasız)
	T49_ShopRegression:                  PASS ✅ (Dükkan sistemi hatasız)
	T50_WorldBuilderRegression:          PASS ✅ (World Builder seviye editörü hatasız)
	```
	
	---
	
	## 7. Doğrulama Metrikleri
	
	- `script_validate`: **123/123 passed (0 failed)**
	- `scene_validate`: **0 issues**
	- `runtime_errors`: **0 errors**
	
	---
	
	## 8. Değiştirilen & Eklenen Dosyalar
	
	1. `res://systems/grid/tile_highlight.gd` (YENİ: Dinamik karo vurgulama ve araç önizleme katmanı)
	2. `res://systems/player/player_interaction.gd` (DÜZENLENDİ: Fare hedeflemesi, menzil kontrolü ve UI bloklama)
	3. `res://systems/player/player.gd` (DÜZENLENDİ: Fare sol/sağ tık, tekerlek hotbar, Shift koşma ve alet yürütme)
	4. `res://systems/inventory/inventory_manager.gd` (DÜZENLENDİ: `cycle_hotbar` ve `select_slot_index` eklendi)
	5. `res://systems/local/local_state.gd` (DÜZENLENDİ: Fare eylemleri ve erişilebilirlik seçenekleri eklendi)
	6. `res://systems/local/local_state_manager.gd` (DÜZENLENDİ: Fare tuşları ve tekerleği `InputMap` olaylarına dönüştürüldü)
	