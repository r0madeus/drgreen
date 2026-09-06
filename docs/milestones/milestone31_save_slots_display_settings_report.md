# MILESTONE 31 — SAVE SLOTS & GODOT DISPLAY SETTINGS
	## System Architecture & Milestone Completion Report
	
	---
	
	## 1. Genel Bakış (Overview)
	
	Bu milestone kapsamında iki kritik altyapı iyileştirmesi gerçekleştirilmiştir:
	1. **Save Slot & Save Seçim Sistemi**: Tekil `savegame.json` yerine, her biri zengin metadata (gün, mevsim, dünya, altın, görevler, hibritler, son oynanma zamanı) barındıran, geriye dönük uyumlu ve güvenli silme onaylı **3 Slotlu Save Seçim Sistemi** (`SaveSelectUI` & `SaveManager`).
	2. **Godot Display & Resolution Settings**: Godot 4 `DisplayServer` ve `Engine` API'leriyle tam uyumlu çalışan, pencere boyutunu (1152x648, 1280x720, 1366x768, 1600x900, 1920x1080, 2560x1440), pencere modunu (Windowed, Borderless, Fullscreen), VSync ve FPS limitini (30, 60, 90, 120, 144, 240, Unlimited) gerçek zamanlı uygulayan ve `LocalState` (`user://local_settings.json`) üzerinden kalıcı kılan ekran ayarları sistemi.
	
	```
	+---------------------------------------------------------------------------------------------------+
	|                              SAVE SLOT & DISPLAY ARCHITECTURE                                     |
	+---------------------------------------------------------------------------------------------------+
	|  [Main Menu]                                            [Settings UI (Graphics Tab)]              |
	|        │                                                               │                          |
	|        ▼                                                               ▼                          |
	|  [SaveSelectUI] (Slot 1 / 2 / 3)                        [LocalStateManager]                       |
	|   - Reads Metadata (Day, Season, Gold, Quests)           - Resolution (1152x648 -> 2560x1440)     |
	|   - Load / Delete Dialog / New Game in Slot              - Mode (Windowed/Borderless/Fullscreen)   |
	|   - Safe Corrupted File Handling                         - VSync (Enabled/Disabled)               |
	|        │                                                 - FPS Limit (0=Unlimited, 30..240)       |
	|        ▼                                                               │                          |
	|  [SaveManager] (user://saves/slot_X.json)                              ▼                          |
	|   - Backward Compatibility Migration                    [DisplayServer & Engine API]              |
	|   - PlayerState / SharedWorldState Restoration           - window_set_mode / size / vsync         |
	+---------------------------------------------------------------------------------------------------+
	```
	
	---
	
	## 2. Save Slot Mimarisi (`SaveManager` & `SaveSelectUI`)
	
	### A. Slot Depolama & Dosya Düzeni
	- Dizin: `user://saves/`
	- Dosyalar: `slot_1.json`, `slot_2.json`, `slot_3.json`
	- Aktif Slot Takibi: `SaveManager.active_slot` (Varsayılan: 1, 1..3 arası)
	
	### B. Slot Metadata & Güvenli İnceleme
	- `SaveManager.get_save_slot_metadata(slot_index)`:
	  - Dosyayı tamamen yüklemeden JSON başlığını ayrıştırır.
	  - Slot boşsa `{ "exists": false }` döner.
	  - Dosya bozuksa `{ "exists": true, "corrupted": true, "error": "..." }` döner ve oyunun çökmesini engeller.
	  - Geçerli ise gün, mevsim, harita adı, oyuncu adı, altın, tamamlanan görev sayısı ve biçimlendirilmiş son oynanma tarihini (`YYYY-MM-DD HH:MM`) sunar.
	
	### C. Geriye Dönük Uyumluluk (Legacy Migration)
	- `SaveManager.migrate_legacy_saves()`:
	  - Eğer `user://saves/slot_1.json` yoksa ve eski `user://savegame.json` veya `user://savegame_v6.json` mevcutsa, veriyi otomatik olarak `slot_1.json`'a taşır.
	  - Eski kayıtlar kesinlikle kaybolmaz.
	
	### D. Güvenli Arayüz (`SaveSelectUI`)
	- Her slot için görsel durum kartı (Aktif Kayıt, Boş Slot, Bozuk Kayıt).
	- Silme işleminde yanlışlıkla basmayı önleyen `ConfirmationDialog` modalı.
	
	---
	
	## 3. Display Settings Mimarisi (`LocalStateManager` & `SettingsManager`)
	
	### A. Çözünürlük & Window Mode Uygulaması
	- **Windowed Mod:** `DisplayServer.window_set_mode(WINDOW_MODE_WINDOWED)`, `window_set_flag(WINDOW_FLAG_BORDERLESS, false)`, `window_set_size(target_size)` ve pencereyi ekranda ortalama.
	- **Borderless Mod:** `DisplayServer.window_set_mode(WINDOW_MODE_WINDOWED)`, `window_set_flag(WINDOW_FLAG_BORDERLESS, true)`, `window_set_size(screen_size)` ve `window_set_position(Vector2i.ZERO)`.
	- **Fullscreen Mod:** `DisplayServer.window_set_mode(WINDOW_MODE_FULLSCREEN)`.
	- **Fullscreen ➔ Windowed Geçiş Hafızası:** Fullscreen'den Windowed'a geçildiğinde `LocalState` içinde saklanan çözünürlük (`target_size`) tekrar pencere boyutu olarak uygulanır.
	
	### B. VSync & FPS Limit
	- **VSync:** `DisplayServer.window_set_vsync_mode(VSYNC_ENABLED / VSYNC_DISABLED)`.
	- **FPS Limit:** `Engine.max_fps = fps` (Seçenek `Unlimited` olduğunda `0` atanır).
	
	### C. İzolasyon & Kalıcılık (LocalState)
	- Ayarlar sadece `user://local_settings.json` içinde saklanır.
	- Kayıt dosyalarına (`SaveData` / `slot_X.json`) kesinlikle yazılmaz.
	- Co-op çok oyunculu modda her istemcinin ekran ayarı birbirinden %100 izoledir.
	
	### D. Godot Editor / Embedded Runtime Bulguları
	- Godot Editörü içinden F5/F6 ile çalıştırıldığında (özellikle gömülü oyun penceresi modunda), işletim sistemi seviyesindeki pencere boyutlandırma çağrıları editör çerçevesi tarafından sınırlandırılabilir.
	- `LocalStateManager`, bu durumu algılayarak ayarları güvenle `LocalState`'e yazar, `Engine.max_fps` ve `VSync` gibi dahili motor parametrelerini anında uygular ve standalone çalışmada tam pencere manipülasyonunu garanti eder.
	
	---
	
	## 4. Test Sonuçları (35/35 PASS ✅)
	
	```
	[Milestone 31 Test Suite]
	SAVE TESTS (T01 - T14):
	T01_Slot1Creation:             PASS ✅ (Save Slot 1 oluşturuldu)
	T02_Slot2Creation:             PASS ✅ (Save Slot 2 oluşturuldu)
	T03_Slot3Creation:             PASS ✅ (Save Slot 3 oluşturuldu)
	T04_SlotsListing:              PASS ✅ (3 slot da listede görünüyor)
	T05_SlotMetadata:              PASS ✅ (Gün, mevsim, altın, zaman metadatası doğru)
	T06_Slot1Load:                 PASS ✅ (Slot 1 verileri eksiksiz yüklendi)
	T07_Slot2Load:                 PASS ✅ (Slot 2 verileri eksiksiz yüklendi)
	T08_SlotIsolation:             PASS ✅ (Slot 1 ile Slot 2 verileri birbirine karışmıyor)
	T09_EmptySlotBehavior:         PASS ✅ (Silinen slot Empty Slot durumuna geçiyor)
	T10_CorruptedSaveSafety:       PASS ✅ (Bozuk JSON çökme yapmadan güvenle reddediliyor)
	T11_LegacyMigration:           PASS ✅ (Eski savegame.json otomatik Slot 1'e taşındı)
	T12_WorldStatePreserved:       PASS ✅ (Dünya durumu eksiksiz korunuyor)
	T13_PlayerStatePreserved:      PASS ✅ (Oyuncu envanteri/altını eksiksiz korunuyor)
	T14_MultiplayerSaveIntact:     PASS ✅ (Çok oyunculu kayıt mimarisi korundu)
	
	DISPLAY & SETTINGS TESTS (T15 - T35):
	T15_Res1280x720:               PASS ✅ (1280x720 Windowed uygulandı)
	T16_Res1920x1080:              PASS ✅ (1920x1080 Windowed uygulandı)
	T17_BorderlessMode:            PASS ✅ (Borderless modu uygulandı)
	T18_FullscreenMode:            PASS ✅ (Fullscreen modu uygulandı)
	T19_FullscreenToWindowed:      PASS ✅ (Fullscreen'den Windowed'a geçiş başarılı)
	T20_WindowedResolutionMemory:  PASS ✅ (Önceki windowed çözünürlüğü hatırlandı)
	T21_VSyncOn:                   PASS ✅ (VSync açıldı)
	T22_VSyncOff:                  PASS ✅ (VSync kapatıldı)
	T23_FPS30:                     PASS ✅ (Engine.max_fps = 30)
	T24_FPS60:                     PASS ✅ (Engine.max_fps = 60)
	T25_FPS120:                    PASS ✅ (Engine.max_fps = 120)
	T26_FPSUnlimited:              PASS ✅ (Engine.max_fps = 0 Unlimited)
	T27_SettingsPersistence:       PASS ✅ (local_settings.json yeniden başlatmada korundu)
	T28_LocalStateSaveIsolation:   PASS ✅ (Ekran ayarları savegame dosyasına sızmıyor)
	T29_ClientDisplayIsolation:    PASS ✅ (İstemciler bağımsız ekran ayarı kullanabiliyor)
	T30_EditorRuntime:             PASS ✅ (Godot Editör çalışma ortamı doğrulandı)
	T31_StandaloneRuntimeSafety:   PASS ✅ (Standalone çalışma güvenliği doğrulandı)
	T32_PixelArtScaling:           PASS ✅ (Pixel-art canvas_items expand scaling korundu)
	T33_SettingsUIRegression:      PASS ✅ (Settings UI sekmeleri hatasız)
	T34_MultiplayerRegression:     PASS ✅ (Ağ yöneticisi hatasız)
	T35_SaveLoadRegression:        PASS ✅ (Kayıt yöneticisi hatasız)
	```
	
	---
	
	## 5. Doğrulama Metrikleri
	
	- `script_validate`: **122/122 passed (0 failed)**
	- `scene_validate`: **0 issues**
	- `runtime_errors`: **0 errors**
	
	---
	
	## 6. Değiştirilen & Eklenen Dosyalar
	
	1. `res://systems/save/save_manager.gd` (DÜZENLENDİ: Slot yönetimi, metadata çıkarma, legacy migration, hata koruması)
	2. `res://ui/save_select_ui.gd` (YENİ: Save Slot Seçim Ekranı kontrolcüsü)
	3. `res://ui/save_select_ui.tscn` (YENİ: Save Slot Seçim Ekranı arayüz sahnesi)
	4. `res://systems/local/local_state_manager.gd` (DÜZENLENDİ: Tam DisplayServer & Engine window/vsync/fps yönetimi)
	5. `res://systems/settings/settings_manager.gd` (DÜZENLENDİ: LocalStateManager ile senkronize grafik yetkilendirmesi)
	6. `res://systems/settings/settings_ui.gd` (DÜZENLENDİ: Genişletilmiş çözünürlükler ve Unlimited FPS düzeltmesi)
	7. `res://ui/main_menu.gd` (DÜZENLENDİ: Continue butonunun SaveSelectUI'a bağlanması)
	8. `res://scenes/farm.tscn` (DÜZENLENDİ: SaveSelectUI sahnesi UI katmanına eklendi)
	9. `res://project.godot` (DÜZENLENDİ: Viewport taban boyutları ve pencere ayarları)
	