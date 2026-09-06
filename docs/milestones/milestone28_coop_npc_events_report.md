# PHASE 8 — CO-OP NPC, DIALOGUE & SHARED WORLD EVENTS
	## Milestone Completion Report
	
	---
	
	## 1. Mimari Genel Bakış (Architecture Overview)
	
	Phase 8, 2–4 kişilik co-op çok oyunculu oturumlarda (Stardew Valley / Terraria modeli) NPC'lerin fiziksel varlığını, diyalog seçimlerini, kişisel/ortak görevleri ve dünya olaylarını Host-authoritative ağ mimarisine başarıyla entegre etmiştir.
	
	```
	+--------------------------------------------------------------------------------+
	|                             CO-OP NETWORK TOPOLOGY                             |
	+--------------------------------------------------------------------------------+
	|                                                                                |
	|   [Client 1 (Host)]                              [Client 2 / 3 / 4 (Peers)]    |
	|   - Host Authoritative Execution                 - Local Dialogue UI           |
	|   - SharedWorldState (NPC Pos/Events)            - PlayerState (Friendship)    |
	|   - PlayerState 1                                - NetworkNPC RPC Requests     |
	|          |                                              |                      |
	|          +-------------------- RPC Mesh ----------------+                      |
	|          | (request_npc_interaction / request_dialogue_action / snapshot)      |
	+--------------------------------------------------------------------------------+
	```
	
	---
	
	## 2. NPC State Sınıflandırması (Shared vs Personal)
	
	### A. SHARED NPC STATE (`SharedWorldState`)
	- **NPC World Presence & Position:** NPC'nin hangi haritada (`farm`, `town`, `botanical_grove`) ve hangi grid koordinatında (`Vector2i`) bulunduğu.
	- **Schedule State:** Zaman dilimine (`morning`, `afternoon`, `evening`) göre aktif rota ve dünya.
	- **Shared World Events (`shared_events`):** NPC tarafından tetiklenen dünya açılışları, bina onarımları ve festival durumları (ör: `"npc_event:rowan:unlock_greenhouse"`).
	- **Idempotency Register:** Her shared event benzersiz bir ID ile saklanır; aynı event iki farklı oyuncu tarafından eşzamanlı tetiklense dahi yalnızca bir kez uygulanır.
	
	### B. PLAYER NPC STATE (`PlayerState`)
	- **Friendship & Relationship:** Oyuncunun NPC ile olan bireysel samimiyeti (`friendship: { "rowan": 30 }`).
	- **Personal Dialogue Progression:** Oyuncunun NPC ile gördüğü diyalog düğümleri (`personal_dialogue_history`).
	- **Personal Quests & Rewards:** Bireysel görev ilerlemesi ve alınan ödüller (`personal_claimed_rewards`).
	- **Personal Dialogue Choices:** Oyuncunun yaptığı konuşma tercihleri.
	
	---
	
	## 3. Diyalog Mimarisi (Dialogue Architecture)
	
	- **Strictly Player-Local UI:** Player A Rowan ile konuştuğunda, `DialogueUI` yalnızca Player A'nın ekranında açılır. Player B'nin ekranında hiçbir UI açılmaz veya kesinti oluşmaz.
	- **Networked Gameplay Consequence:** Diyalog tamamlandığında veya bir seçim yapıldığında:
	  - **Kişisel Ödül / Dükkan:** Host yalnızca istekte bulunan oyuncunun `PlayerState`'ine altın/eşya yansıtır (`personal_reward`).
	  - **Ortak Dünya Olayı:** Host `SharedWorldState`'i günceller ve tüm bağlı oyunculara `broadcast_shared_npc_event` RPC'si gönderir.
	
	---
	
	## 4. Host Authority & Network API (`NetworkNPC`)
	
	`res://systems/network/network_npc.gd` Autoload singleton olarak oluşturulmuştur.
	
	### Client Request APIs:
	- `request_npc_interaction(world_id: String, npc_id: String)`
	- `request_dialogue_action(world_id: String, npc_id: String, action_id: String, action_params: Dictionary)`
	- `request_npc_event(world_id: String, event_id: String, event_data: Dictionary)`
	- `request_npc_snapshot(world_id: String)`
	- `broadcast_npc_movement(world_id: String, npc_id: String, new_pos: Vector2i)`
	
	### Host Validation & Handlers:
	- `host_request_interaction`: Oyuncunun mesafesini, dünyasını ve NPC geçerliliğini doğrular.
	- `host_request_dialogue_action`: Kişisel vs ortak eylem ayrımını yapar; ortak eylemlerde `is_event_applied` kontrolü ile çift tetiklenmeyi engeller.
	- `host_request_npc_snapshot`: Late-join veya reconnect yapan oyuncuya tüm NPC pozisyonlarını ve event geçmişini paketleyip iletir.
	
	---
	
	## 5. Late Join, Disconnect / Reconnect & Save/Load
	
	- **Late Join:** Katılan oyuncu `receive_npc_snapshot` alarak mevcut dünyadaki NPC'lerin en güncel pozisyonlarını ve tamamlanmış shared event'leri anında senkronize eder.
	- **Disconnect / Reconnect:** Oyuncu koptuğunda Host üzerindeki `SharedWorldState` bozulmaz; oyuncu geri bağlandığında kendi `PlayerState`'i korunarak en güncel snapshot ile oyuna devam eder.
	- **Save / Load (`SaveData` v8):**
	  - `SharedWorldState` (`shared_events`, `npc_positions`, `plants`, `containers`) -> `world_states` altında saklanır.
	  - `PlayerState` (`friendship`, `personal_quests`, `personal_claimed_rewards`) -> `players` altında saklanır.
	  - Geriye dönük uyumluluk (v1-v7 migration) tam olarak korunmuştur.
	
	---
	
	## 6. Test Sonuçları (26/26 PASS ✅)
	
	| # | Test Adı | Sonuç | Açıklama |
	|---|----------|-------|----------|
	| T01 | Singleplayer NPC Dialogue | ✅ PASS | Tek oyunculu modda diyalog motoru sorunsuz çalışıyor |
	| T02 | Two Players See Same NPC | ✅ PASS | İki oyuncu aynı dünyada aynı NPC instance'ını görüyor |
	| T03 | No Duplicate NPC | ✅ PASS | Statik ve dinamik NPC'ler çakışmadan tek instance olarak yönetiliyor |
	| T04 | Late Join NPC State | ✅ PASS | Geç katılan oyuncu NPC snapshot'ını eksiksiz alıyor |
	| T05 | NPC Movement Sync | ✅ PASS | Host üzerinden yapılan NPC hareketleri tüm istemcilere senkronize |
	| T06 | Dialogue UI Player Local | ✅ PASS | Player A konuştuğunda Player B'nin UI'ı açılmıyor |
	| T07 | Personal Reward Isolated | ✅ PASS | Player A ödül aldığında Player B'nin altını/envanteri etkilenmiyor |
	| T08 | Friendship Isolated | ✅ PASS | Samimiyet puanı oyuncu bazında bağımsız saklanıyor |
	| T09 | Shared NPC Event Replicated | ✅ PASS | Dünya çapındaki NPC event'leri tüm istemcilere yansıyor |
	| T10 | Shared Event Idempotent | ✅ PASS | Aynı event ID iki kez uygulanamıyor |
	| T11 | Concurrent Event Single Mutation | ✅ PASS | Eşzamanlı tetiklenen ortak event yalnızca 1 kez mutasyona uğruyor |
	| T12 | Personal Quest Isolated | ✅ PASS | Player A görev tamamlarken Player B'nin kişisel görevi etkilenmiyor |
	| T13 | Shared Quest Progression | ✅ PASS | Ortak dünya kilitleri (Botanical Grove vb.) tüm oyunculara açılıyor |
	| T14 | NPC World Isolation | ✅ PASS | Farm'daki NPC'ler Town'da görünmüyor, harita izolasyonu tam |
	| T15 | World Transition NPC State | ✅ PASS | Farm ➜ Town ➜ Farm geçişinde NPC varlığı ve durumu korunuyor |
	| T16 | Disconnect Preserves Shared State | ✅ PASS | Oyuncu ayrıldığında paylaşılan NPC ve event durumu bozulmuyor |
	| T17 | Reconnect Snapshot Valid | ✅ PASS | Tekrar bağlanan oyuncu en güncel durumu alıyor |
	| T18 | Save/Load State Preserved | ✅ PASS | Kayıt dosyasından yüklendiğinde hem shared hem player NPC state korunuyor |
	| T19 | Farming Regression | ✅ PASS | Co-op tarım mekaniği regrese olmadı |
	| T20 | Shop Regression | ✅ PASS | Dükkan ve stok senkronizasyonu regrese olmadı |
	| T21 | Container Regression | ✅ PASS | Sandık senkronizasyonu regrese olmadı |
	| T22 | Synthesis Regression | ✅ PASS | Sentez laboratuvarı regrese olmadı |
	| T23 | World Transition Regression | ✅ PASS | Dünya geçişleri regrese olmadı |
	| T24 | 2-Player Session | ✅ PASS | 2 kişilik oturum tam kararlılıkla çalışıyor |
	| T25 | 3-Player Session | ✅ PASS | 3 kişilik oturum tam kararlılıkla çalışıyor |
	| T26 | 4-Player Session | ✅ PASS | 4 kişilik oturum tam kararlılıkla çalışıyor |
	
	---
	
	## 7. Doğrulama Metrikleri
	
	- `script_validate`: **118/118 passed (0 failed)**
	- `scene_validate`: **0 issues**
	- `runtime_errors`: **0 errors**
	
	---
	
	## 8. Değiştirilen & Eklenen Dosyalar
	
	1. `res://systems/network/network_npc.gd` (YENİ Autoload)
	2. `res://systems/world/shared_world_state.gd` (DÜZENLENDİ: shared_events, npc_positions)
	3. `res://systems/player/player_state.gd` (DÜZENLENDİ: friendship, dialogue history, claimed rewards)
	4. `res://systems/npc/npc_manager.gd` (DÜZENLENDİ: multi-world positioning, duplicate prevention)
	5. `res://systems/npc/npc_instance.gd` (DÜZENLENDİ: NetworkNPC entegrasyonu)
	6. `res://systems/npc/seed_merchant.gd` (DÜZENLENDİ: NetworkNPC entegrasyonu, _update_position)
	7. `res://systems/dialogue/dialogue_manager.gd` (DÜZENLENDİ: history tracking, networked actions)
	8. `res://systems/quest/reward_manager.gd` (DÜZENLENDİ: targeted PlayerState rewards)
	9. `res://systems/quest/quest_manager.gd` (DÜZENLENDİ: targeted claim_reward)
	10. `res://systems/network/network_manager.gd` (DÜZENLENDİ: peer connection snapshot sync)
	11. `res://project.godot` (DÜZENLENDİ: NetworkNPC autoload)
	