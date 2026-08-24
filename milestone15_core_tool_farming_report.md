# PHASE 15 — CORE FARMING & TOOL SYSTEM
	## Final Milestone Architectural Report
	
	---
	
	## 1. Yönetici Özeti (Executive Summary)
	
	Botanical Haven projesinde **Stardew Valley + Terraria** tarzı fiziksel etkileşim, alet (tool), zemin işleme ve kaynak toplama (resource node) döngüsü başarıyla tamamlanmıştır.
	
	- **Data-Driven Tool & Resource Mimarisi**: Tüm alet özellikleri (güç, enerji maliyeti, menzil, yükseltme seviyeleri, ses ve efektler) `res://data/tools/tools.json` tablosuna; kaynak düğümleri (ağaç, kütük, dal, kaya, bakır ve demir cevherleri) ise `res://data/resources/resource_nodes.json` tablosuna taşınmıştır.
	- **Context-Sensitive Etkileşim**: Sol tık eylemi, oyuncunun o anda seçili hotbar nesnesine (Çapa, Sulama Kabı, Balta, Kazma, Tohum) göre dinamik olarak belirlenir. Geçersiz hedeflerde hiçbir state mutation yapılmaz, enerji harcanmaz.
	- **Stamina / Enerji Entegrasyonu**: Her alet kullanımı oyuncunun enerjisini tüketir (`PlayerState.energy`). Enerji yetersiz olduğunda eylem reddedilir ve ekranda görsel uyarı belirir.
	- **Kaynak Düğümü & Drop Sistemi**: Kaynakların canı (health) takip edilir. Vurulduğunda hasar alır, canı 0'a ulaştığında parçalanarak oyuncunun envanterine kaynak ekler.
	- **Alet Geliştirme (Tool Upgrades)**: Basic → Copper → Iron → Gold seviyeleri arasında data-driven yükseltme altyapısı kurulmuştur.
	
	---
	
	## 2. Oluşturulan ve Değiştirilen Sistemler
	
	| Dosya | Durum | Açıklama |
	| :--- | :--- | :--- |
	| `res://data/tools/tools.json` | 🆕 Yeni | 16 alet varyasyonu (4 alet tipi × 4 kalite seviyesi) için güç, maliyet ve efekt tanımları. |
	| `res://data/resources/resource_nodes.json` | 🆕 Yeni | Ağaç, kütük, kaya ve cevherler için can, gerekli alet/güç ve drop tabloları. |
	| `res://docs/TOOL_SYSTEM_GUIDE.md` | 🆕 Yeni | Geliştiriciler ve tasarımcılar için detaylı sistem kılavuzu. |
	| `res://systems/tools/tool_use_manager.gd` | 🔄 Genişletildi | JSON manifest yükleme, enerji kontrolü, alet geliştirme ve universal kullanım motoru. |
	| `res://systems/grid/grid_manager.gd` | 🔄 Genişletildi | `interactables_hp` can takibi, `hit_resource`, `chop_tile`, `mine_tile` ve drop dağıtımı. |
	| `res://systems/player/player_interaction.gd` | 🔄 Güncellendi | Dinamik alet menzili (`range_dist`) desteği. |
	| `res://core/event_bus.gd` | 🔄 Güncellendi | `tool_used`, `soil_tilled`, `resource_hit`, `resource_destroyed`, `resource_collected`, `tool_upgraded` sinyalleri. |
	| `res://localization/game.csv` | 🔄 Güncellendi | Alet, kalite ve kaynak çevirileri eklendi. |
	
	---
	
	## 3. Alet ve Kalite Özellikleri Tablosu
	
	| Alet Türü | Kalite | Güç (Power) | Enerji Maliyeti | Menzil |
	| :--- | :--- | :---: | :---: | :---: |
	| **Hoe (Çapa)** | Basic / Copper / Iron / Gold | 1 / 2 / 3 / 4 | 2.0 / 1.75 / 1.5 / 1.0 | 1 / 1 / 1 / 2 |
	| **Watering Can (Sulama Kabı)** | Basic / Copper / Iron / Gold | 1 / 2 / 3 / 4 | 2.0 / 1.75 / 1.5 / 1.0 | 1 / 1 / 1 / 2 |
	| **Axe (Balta)** | Basic / Copper / Iron / Gold | 1 / 2 / 3 / 4 | 3.0 / 2.5 / 2.0 / 1.5 | 1 / 1 / 1 / 2 |
	| **Pickaxe (Kazma)** | Basic / Copper / Iron / Gold | 1 / 2 / 3 / 4 | 3.0 / 2.5 / 2.0 / 1.5 | 1 / 1 / 1 / 2 |
	
	---
	
	## 4. 36-Point Test Suite Sonuçları (36/36 PASS ✅)
	
	```
	[Phase 15 Core Tool & Farming Test Suite]
	T01_ToolDefinitionLoading:           PASS ✅ (tools.json başarıyla yüklendi ve ayrıştırıldı)
	T02_ToolQualityResolution:           PASS ✅ (Alet kalite sıralaması doğru çözümlendi)
	T03_HoeSelection:                    PASS ✅ (Çapa hotbar'da seçilebiliyor)
	T04_HoeValidTarget:                  PASS ✅ (Çim/toprak başarıyla çapalanıyor)
	T05_HoeInvalidTarget:                PASS ✅ (Çit/kaya zemin çapalanamıyor)
	T06_WateringCanValidTarget:          PASS ✅ (İşlenmiş toprak başarıyla sulanıyor)
	T07_WateringCanInvalidTarget:        PASS ✅ (Geçersiz zemin sulanamıyor)
	T08_PickaxeValidResource:            PASS ✅ (Kaya kazma ile hedefleniyor)
	T09_PickaxeInvalidResource:          PASS ✅ (Çim kazma ile hedeflenemiyor)
	T10_AxeValidTree:                    PASS ✅ (Ağaç/kütük balta ile hedefleniyor)
	T11_AxeInvalidTarget:                PASS ✅ (Geçersiz hedef baltalanamıyor)
	T12_ToolStaminaConsumption:          PASS ✅ (Alet kullanımı enerjiyi düşürüyor)
	T13_InsufficientStaminaRejection:    PASS ✅ (Enerji yetersizse işlem iptal ediliyor)
	T14_HotbarToolSelection:             PASS ✅ (Hotbar slot seçimi çalışıyor)
	T15_MouseWheelToolSelection:         PASS ✅ (Fare tekerleği ile hotbar slot değişimi çalışıyor)
	T16_NumberKeyToolSelection:          PASS ✅ (1-0 tuşları ile hotbar slot seçimi çalışıyor)
	T17_MouseTargetIndicator:            PASS ✅ (Hedef hücre görsel vurgusu aktif)
	T18_ResourceDrops:                   PASS ✅ (Ağaç kesildiğinde odun drop'u üretiliyor)
	T19_ResourceCollection:              PASS ✅ (Düşen kaynak oyuncu envanterine ekleniyor)
	T20_ResourceNodeDestruction:         PASS ✅ (Canı biten kaynak dünyadan siliniyor)
	T21_SaveLoadToolUpgrades:            PASS ✅ (Alet geliştirmeleri oyuncu durumuna kaydediliyor)
	T22_SaveLoadTilledSoil:              PASS ✅ (Çapalanmış toprak durumu korunuyor)
	T23_SaveLoadResourceNodes:           PASS ✅ (Kaynak düğüm durumları kayıt sistemine uyumlu)
	T24_ToolAnimationResolution:         PASS ✅ (Alet kullanım animasyonları AssetRegistry üzerinden çözülüyor)
	T25_ToolAudioResolution:             PASS ✅ (Alet sesleri AudioManager üzerinden çözülüyor)
	T26_ToolVFXResolution:               PASS ✅ (Efektler EffectSpawner üzerinden tetikleniyor)
	T27_Localization:                    PASS ✅ (Alet ve kaynak isimleri çeviri tablosundan geliyor)
	T28_WorldBuilderResourcePlacement:   PASS ✅ (World Builder kaynakları doğru yerleştiriyor)
	T29_MultiplayerSimultaneousUse:      PASS ✅ (Ağ istekleri NetworkGameplay tarafından işleniyor)
	T30_MultiplayerRaceCondition:        PASS ✅ (Host yetkili doğrulama uygulanıyor)
	T31_MultiplayerInventoryIsolation:   PASS ✅ (Oyuncuların envanterleri izole tutuluyor)
	T32_MultiplayerWorldSync:            PASS ✅ (Zemin değişiklikleri ağda senkronize ediliyor)
	T33_SingleplayerRegression:          PASS ✅ (Tek oyunculu tarım döngüsü hatasız)
	T34_SaveLoadRegression:              PASS ✅ (Kayıt ve yükleme döngüsü hatasız)
	T35_WorldTransitionRegression:       PASS ✅ (Dünyalar arası geçişler hatasız)
	T36_AssetPipelineRegression:         PASS ✅ (AssetPipelineValidator 0 hata ile geçti)
	```
	
	---
	
	## 5. Doğrulama Metrikleri
	
	- `script_validate`: **129/129 GDScript hatasız (0 failed)**
	- `scene_validate`: **0 issue**
	- `runtime_errors`: **0 error**
	- `AssetPipelineValidator`: **0 broken reference, 0 duplicate ID, 96 valid assets**
	