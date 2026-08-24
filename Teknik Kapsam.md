## 🎯 **I. CORE CONCEPT (Tek cümle)**

```
*"Bir biyoloji öğretmeni işinden ve şehirdeki kaotik yaşamından ayrılmış, çocukluğunun geçtiği kasabasına dönmüştür. Başlarda ailesinin yanına dönmüş olmaktan büyük keyif alırken zamanla bundan sıkılmaya başladığını fark eder ve biyoloji bilgisini kullanmaya karar verir. Başlangıçta hobi olarak tarım yaparken zamanla bitkileri/mantarları çaprazlayarak yeni, imkansız türler yaratmaya başlar.*"
```

**Genre:** Cozy farming + Discovery puzzle  
**Platform:** PC (Steam), eventual ports  
**Target:** Stardew Valley + Little Alchemy fanları  
**USP:** Kombinasyon keşfi + Open source community-driven

---

## 🧬 **II. CORE PROTOTYPE - "Playable Nucleus"**

### **Kapsam: İlk 3 Ay Hedefi**

```
🎯 GOAL: 10 dakika oynanabilen demo
         "Grow, Combine, Discover" döngüsü çalışıyor

Oyuncu yapabilir:
✅ Karakteri hareket ettir (WASD, grid-based)
✅ Tohum ek (click)
✅ Su ver (manuel, can ile)
✅ Hasat et (tıkla)
✅ Envantere bak (I tuşu)
✅ İki bitki seç, kombinasyon yap (C tuşu)
✅ Yeni tür keşfet (discovery moment!)
✅ Günü bitir (uyuma/fast forward)
✅ Kaydet/yükle (F5/F9)
✅ Esc basınca ara menü. Ayarlar, ana menüye gidiş, kayıtlar vs.

İçerik:
├── 5 başlangıç bitkisi (tohumdan büyür)
├── 5 başlangıç mantarı (sporundan büyür)
├── 15 kombinasyon (A+B=C)
├── 1 NPC (tohumcu, placeholder diyalog)
├── 1 küçük map (16x16 tile)
└── Basit UI (envanter, kombinasyon ekranı)

Teknik:
├── Godot 4.6+
├── 16x16 tile base
├── JSON-driven data
├── Modular systems (aşağıda detay)
└── Save/load (JSON format)
```

---

## 🏗️ **III. MODULAR ARCHITECTURE - Sistem Breakdown**

### **A. CORE SYSTEMS (Çekirdek - En Önce Bunlar)**

#### **1. PLAYER CONTROLLER**

```
📁 systems/player/
├── player.gd                 # Main controller
├── player_movement.gd        # Grid movement (WASD)
├── player_interaction.gd     # Interact with objects (E key)
└── player_animation.gd       # Sprite animation (4 directions)

Özellikler:
- Grid-based movement (16x16 snap)
- Collision detection (tilemap)
- Interaction raycast (face direction)
- Animation state machine (idle, walk, interact)

State:
{
  "position": Vector2i(x, y),
  "direction": "down",  // up, down, left, right
  "is_moving": false,
  "energy": 100  // Daily energy (optional for core)
}

Dependencies: None
Priority: 🔴 CRITICAL (Week 1)
```

---

#### **2. TILE/GRID SYSTEM**

```
📁 systems/grid/
├── grid_manager.gd           # Grid state manager
├── tile_data.gd              # Tile properties
└── grid_renderer.gd          # Visual representation

Özellikler:
- 16x16 tile grid
- Tile types: soil, path, water, blocked
- Tile state: empty, planted, watered, mature
- Tile metadata: plant_id, growth_stage, watered_today

State (per tile):
{
  "type": "soil",
  "state": "planted",
  "plant_id": "red_flower",
  "growth_stage": 1,
  "days_in_stage": 0,
  "watered_today": false,
  "position": Vector2i(x, y)
}

API:
- plant_seed(position, plant_id)
- water_tile(position)
- harvest_tile(position) -> item
- get_tile_state(position) -> dict
- can_plant_here(position) -> bool

Dependencies: None
Priority: 🔴 CRITICAL (Week 1)
```

---

#### **3. PLANT SYSTEM**

```
📁 systems/plants/
├── plant_manager.gd          # Database + logic
├── plant_instance.gd         # Individual plant (scene)
└── plant_data.json           # Data-driven definitions

Özellikler:
- JSON-driven plant database
- Growth stages (3-5 per plant)
- Water requirement (daily)
- Harvest yield (1-3 items)
- Quality system (normal/silver/gold - OPTIONAL for core)

Plant Data Schema:
{
  "id": "red_flower",
  "name": "Red Flower",
  "type": "plant",
  "rarity": "common",
  
  "growth": {
    "stages": 3,
    "days_per_stage": [1, 2, 2],  // Total: 5 days
    "water_daily": true
  },
  
  "sprites": {
    "seed": "res://sprites/plants/red_flower_seed.png",
    "stage_1": "res://sprites/plants/red_flower_1.png",
    "stage_2": "res://sprites/plants/red_flower_2.png",
    "mature": "res://sprites/plants/red_flower_mature.png"
  },
  
  "harvest": {
    "yield": [1, 2],  // Min-max
    "item_id": "red_flower"
  },
  
  "value": {
    "base_price": 50
  }
}

API:
- get_plant(id) -> dict
- get_growth_sprite(id, stage) -> Texture2D
- calculate_growth(plant_id, days_elapsed) -> new_stage
- get_harvest_yield(plant_id) -> int

Dependencies: Grid System
Priority: 🔴 CRITICAL (Week 2)
```

---

#### **4. COMBINATION SYSTEM**

```
📁 systems/combination/
├── combination_manager.gd    # Logic + database
├── combination_ui.gd         # UI scene
└── combinations.json         # Data-driven combos

Özellikler:
- A + B = C formula
- Discovery tracking (unlocked combos)
- Success rate (optional: 100% for core)
- Visual feedback (animation, particles)

Combination Schema:
{
  "id": "combo_001",
  "input_a": "red_flower",
  "input_b": "blue_mushroom",
  "output": "purple_glowshroom",
  "success_rate": 1.0,
  "hidden": false  // Show in recipe book?
}

Workflow:
1. Player opens combo UI (C key)
2. Selects 2 items from inventory
3. Click "Combine"
4. Animation plays (3 sec)
5. Result shown (discovery moment!)
6. New item added to inventory
7. Combo logged in discovery journal

API:
- get_combination(input_a, input_b) -> combo_data or null
- perform_combination(input_a, input_b) -> result_item
- is_combo_discovered(combo_id) -> bool
- get_all_combos() -> Array

Dependencies: Inventory System
Priority: 🔴 CRITICAL (Week 3)
```

---

#### **5. INVENTORY SYSTEM**

```
📁 systems/inventory/
├── inventory_manager.gd      # Data + logic
├── inventory_ui.gd           # UI scene
└── item_slot.gd              # UI component

Özellikler:
- Dictionary-based storage {item_id: quantity}
- Stack limits (99 per slot - optional)
- Add/remove/check items
- UI grid display

State:
{
  "items": {
    "red_flower": 5,
    "blue_mushroom": 3,
    "purple_glowshroom": 1
  }
}

API:
- add_item(item_id, quantity)
- remove_item(item_id, quantity) -> bool
- has_item(item_id, quantity) -> bool
- get_item_count(item_id) -> int
- get_all_items() -> Dictionary

Dependencies: None
Priority: 🔴 CRITICAL (Week 2)
```

---

#### **6. TIME SYSTEM**

```
📁 systems/time/
├── time_manager.gd           # Day/night cycle
└── time_ui.gd                # Clock display

Özellikler:
- Day counter (Day 1, Day 2...)
- Season tracking (Spring, Summer... - OPTIONAL for core)
- Sleep/advance day function
- Daily reset events (water status, growth)

State:
{
  "current_day": 1,
  "season": "spring",  // Optional
  "time_of_day": "morning"  // Optional
}

Daily Cycle:
1. Morning: Player wakes up
2. Daytime: Gameplay
3. Evening: Player can sleep (bed interaction)
4. Sleep triggers:
   - Save game
   - Advance day counter
   - Grow all plants (1 stage if watered)
   - Reset water status
   - Emit "day_ended" signal

API:
- advance_day()
- get_current_day() -> int
- get_season() -> String (optional)

Dependencies: None
Priority: 🟡 HIGH (Week 2)
```

---

#### **7. SAVE/LOAD SYSTEM**

```
📁 systems/save/
├── save_manager.gd           # Core logic
└── save_data.gd              # Data structure

Özellikler:
- JSON format (human-readable, mod-friendly)
- Auto-save on sleep
- Manual save (F5)
- Manual load (F9)
- Save slots (3 slots - optional)

Save Data Schema:
{
  "version": "0.1",
  "timestamp": "2025-12-11T10:30:00",
  
  "player": {
    "position": [5, 5],
    "direction": "down",
    "inventory": {...}
  },
  
  "grid": {
    "tiles": [
      {"pos": [0,0], "state": "empty", ...},
      {"pos": [1,1], "state": "planted", "plant_id": "red_flower", ...}
    ]
  },
  
  "discovered_combos": ["combo_001", "combo_003"],
  
  "time": {
    "current_day": 5,
    "season": "spring"
  },
  
  "flags": {}  // Quest/event flags (future)
}

API:
- save_game(slot = 0)
- load_game(slot = 0) -> bool
- has_save(slot) -> bool
- delete_save(slot)

Dependencies: All systems (reads state)
Priority: 🟡 HIGH (Week 3)
```

---

### **B. UI SYSTEMS (Core Prototype İçin Minimal)**

#### **8. UI MANAGER**

```
📁 ui/
├── ui_manager.gd             # Scene transitions
├── hud.gd                    # Main HUD (day, money)
├── inventory_ui.tscn         # Inventory panel
├── combination_ui.tscn       # Combo crafting panel
└── pause_menu.tscn           # Pause (ESC)

Özellikler:
- Panel toggle (I = inventory, C = combination)
- Only one panel open at a time
- ESC pauses game
- Tooltip system (hover over items)

Priority: 🟡 HIGH (Week 2-3)
```

---

#### **9. DISCOVERY JOURNAL (Optional, but nice)**

```
📁 ui/journal/
├── journal_ui.gd
└── discovery_entry.gd

Özellikler:
- List of discovered species
- List of unlocked combinations
- "???" for unknown combos
- Screenshot/timestamp per discovery

Priority: 🟢 MEDIUM (Week 4+)
```

---

### **C. CONTENT (Data-Driven)**

#### **10. BASE CONTENT**

```
📁 data/
├── plants/
│   └── base_plants.json      # 5 starter plants
├── mushrooms/
│   └── base_mushrooms.json   # 5 starter mushrooms
├── combinations/
│   └── base_combos.json      # 15 combos
└── npcs/
    └── seed_merchant.json    # 1 NPC (placeholder)

PLANTS (5):
1. Red Flower (3 days, common)
2. Blue Flower (4 days, common)
3. Yellow Herb (2 days, common)
4. Green Vine (5 days, uncommon)
5. White Lily (4 days, uncommon)

MUSHROOMS (5):
1. Brown Mushroom (3 days, common)
2. Blue Mushroom (4 days, common)
3. Red Toadstool (3 days, common)
4. Purple Fungus (5 days, uncommon)
5. Glowcap (6 days, rare)

COMBINATIONS (15 examples):
Red Flower + Blue Flower = Purple Flower
Red Flower + Brown Mushroom = Red-Brown Hybrid
Blue Flower + Yellow Herb = Green Herb
Yellow Herb + White Lily = Golden Lily
Green Vine + Purple Fungus = Toxic Vine
Blue Mushroom + Red Toadstool = Rainbow Mushroom
... (10 more combos)

Priority: 🟡 HIGH (Week 2-3, parallel with systems)
```

---

### **D. VISUAL/AUDIO (Minimal for Prototype)**

#### **11. ART ASSETS**

```
📁 assets/sprites/
├── player/
│   ├── idle_down.png (16x24)
│   ├── walk_down_1.png
│   └── ... (4 directions × 2-3 frames)
├── plants/
│   ├── red_flower_seed.png (16x16)
│   ├── red_flower_1.png
│   ├── red_flower_2.png
│   └── red_flower_mature.png
│   └── ... (10 plants × 4 stages = 40 sprites)
├── tiles/
│   ├── soil.png (16x16)
│   ├── soil_wet.png
│   ├── path.png
│   └── grass.png
└── ui/
    ├── panel.png
    ├── button.png
    └── slot.png

Pixel Art Style:
- 16x16 base tile
- 3-5 color palette per sprite
- Stardew-inspired but unique
- Clean, readable

Priority: 🔴 CRITICAL (Week 1-3, parallel development)
```

---

#### **12. AUDIO (Placeholder OK)**

```
📁 assets/audio/
├── music/
│   └── calm_day.ogg (loop, 1 track OK)
├── sfx/
│   ├── plant.wav
│   ├── water.wav
│   ├── harvest.wav
│   ├── combine.wav (magic sound)
│   └── ui_click.wav

Priority: 🟢 LOW (Week 4+, can use free assets)
```

---

## 🔗 **IV. SYSTEM DEPENDENCIES GRAPH**

```
EventBus (Singleton)
    ↓
┌───────────────────────────────────────┐
│   CORE SYSTEMS (No Dependencies)     │
├───────────────────────────────────────┤
│ • Player Controller                   │
│ • Grid Manager                        │
│ • Time Manager                        │
│ • Inventory Manager                   │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│   GAMEPLAY SYSTEMS                    │
├───────────────────────────────────────┤
│ • Plant System → Grid + Time          │
│ • Combination System → Inventory      │
│ • Save System → ALL                   │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│   UI SYSTEMS                          │
├───────────────────────────────────────┤
│ • UI Manager → Inventory, Combo       │
│ • HUD → Time, Player                  │
└───────────────────────────────────────┘
```

**Load Order (Godot Autoload):**

```
1. EventBus
2. SaveManager
3. TimeManager
4. InventoryManager
5. GridManager
6. PlantManager
7. CombinationManager
8. UIManager
```

---

## 📅 **V. DEVELOPMENT TIMELINE - Core Prototype (12 Hafta)**

### **WEEK 1-2: Foundation**

```
□ Project setup (Godot 4.3)
□ Folder structure (modular from day 1)
□ EventBus + Autoload setup
□ Player controller (movement, animation)
□ Grid system (tiles, state management)
□ Camera (follow player, bounded)
□ Placeholder art (colored squares OK)

Milestone: Player hareket ediyor, grid render oluyor
```

### **WEEK 3-4: Core Loop Part 1**

```
□ Inventory system (data + UI)
□ Plant system (JSON database)
□ Plant interaction (click to plant seed)
□ Watering mechanic (click with can)
□ Growth logic (advance day = grow 1 stage)
□ Harvest mechanic (click mature plant)
□ 5 plants implemented (data + art)

Milestone: Plant → Water → Harvest döngüsü çalışıyor
```

### **WEEK 5-6: Core Loop Part 2**

```
□ Combination system (logic)
□ Combination UI (select 2 items, combine)
□ Discovery animation (particles, sound)
□ Journal system (track discovered species)
□ 10 plants/mushrooms total
□ 15 combinations implemented

Milestone: Kombinasyon sistemi çalışıyor, discovery moment tatmin edici
```

### **WEEK 7-8: Time & Persistence**

```
□ Time system (day counter)
□ Sleep mechanic (bed interaction, advance day)
□ Save/load system (JSON)
□ Daily reset (water status, growth)
□ UI polish (HUD, clock, day counter)

Milestone: Oyun kaydedilebiliyor, günler ilerliyor
```

### **WEEK 9-10: Content & Polish**

```
□ NPC system (basic dialogue)
□ Seed merchant NPC (buy seeds)
□ Economy system (money, prices)
□ Tutorial hints (on-screen text)
□ Sound effects (basic)
□ Music (1 track, loop)

Milestone: İlk oynanabilir demo (10-15 dakika)
```

### **WEEK 11-12: Playtest & Iterate**

```
□ Balance pass (growth times, prices)
□ Bug fixing
□ Playtest with friends (5-10 kişi)
□ Feedback iteration
□ Documentation (modding guide başlangıcı)
□ GitHub repo hazırla (ilk commit)

Milestone: CORE PROTOTYPE COMPLETE ✅
```

---

## 🎮 **VI. CORE PROTOTYPE SUCCESS CRITERIA**

### **Oyuncu yapabilir:**

```
✅ Karakteri hareket ettir (smooth, responsive)
✅ 10 farklı türü ek ve yetiştirebilir
✅ 15 kombinasyon keşfedebilir
✅ Envanterini yönetir
✅ Para kazanır (hasat satışı)
✅ Yeni tohum satın alır
✅ Günleri ilerletebilir (uyuyarak)
✅ Oyunu kaydedip yükler
✅ 30 dakika oynamaktan keyif alır
```

### **Teknik standartlar:**

```
✅ 60 FPS (düşük-spec PC'de)
✅ No game-breaking bugs
✅ Save/load %100 çalışıyor
✅ Modular code (her sistem ayrı dosya)
✅ JSON-driven data (code içinde hard-code yok)
✅ Git history clean (mantıklı commit'ler)
```

### **Feel/Juice:**

```
✅ Bitki büyümesi tatmin edici (animasyon)
✅ Kombinasyon anı "aha!" hissi veriyor
✅ Harvest feedback (particle, sound)
✅ UI responsive (no lag)
✅ Cozy atmosphere (müzik, colors)
```

---

## 🚀 **VII. POST-PROTOTYPE ROADMAP (Öncelik Sırası)**

### **Phase 2: Content Expansion (Ay 4-6)**

```
□ 30+ total species
□ 50+ combinations
□ 5 NPCs (unique personalities)
□ Quest system (fetch quests başlangıç)
□ Map expansion (3-4 connected areas)
□ Seasons (4 mevsim, visual variation)
```

### **Phase 3: Depth (Ay 7-9)**

```
□ Quality system (normal/silver/gold)
□ Rare mutations (0.1% special species)
□ Relationship system (NPC friendship)
□ Home upgrade (expand farm)
□ Tools upgrade (sprinkler, auto-harvest)
□ Mini-games (fishing? optional)
```

### **Phase 4: Polish (Ay 10-12)**

```
□ Particle effects polish
□ Sound design pass
□ Music (3-5 tracks)
□ Tutorial system (smooth onboarding)
□ Achievements
□ Screenshot mode
```

### **Phase 5: Community (Ay 13-15)**

```
□ Modding API finalize
□ Example mods (3-5)
□ Discord community
□ Beta testing (50-100 players)
□ Feedback iteration
```

### **Phase 6: Launch Prep (Ay 16-18)**

```
□ Steam page
□ Trailer
□ Press kit
□ Marketing campaign
□ Wishlists
□ Early Access Launch!
```

---

## 📊 **VIII. CORE METRICS TO TRACK**

### **Development Metrics:**

```
□ Lines of code (target: <5000 for core prototype)
□ JSON data size (should be > code size)
□ Systems implemented (target: 7/7 core systems)
□ Bugs found/fixed (track in issues)
□ Playtime achieved (target: 30+ min enjoyable)
```

### **Playtest Metrics:**

```
□ First combination time (target: <5 min)
□ Discovery per hour (target: 5-8 new species)
□ Drop-off point (where players quit)
□ Confusion points (tutorial needs)
□ Fun rating (1-10, target: 7+)
```

---

## 🗂️ **IX. FILE ORGANIZATION - Final Structure**

```
my_cozy_game/
├── 📁 .git/
├── 📄 .gitignore
├── 📄 README.md
├── 📄 GDD.md (THIS DOCUMENT)
├── 📄 project.godot
│
├── 📁 core/
│   ├── event_bus.gd
│   ├── game_manager.gd
│   └── mod_loader.gd (skeleton for future)
│
├── 📁 systems/
│   ├── player/
│   │   ├── player.gd
│   │   ├── player.tscn
│   │   └── player_movement.gd
│   ├── grid/
│   │   ├── grid_manager.gd
│   │   └── tile_data.gd
│   ├── plants/
│   │   ├── plant_manager.gd
│   │   ├── plant_instance.gd
│   │   └── plant_instance.tscn
│   ├── inventory/
│   │   ├── inventory_manager.gd
│   │   └── inventory_ui.tscn
│   ├── combination/
│   │   ├── combination_manager.gd
│   │   └── combination_ui.tscn
│   ├── time/
│   │   └── time_manager.gd
│   └── save/
│       └── save_manager.gd
│
├── 📁 data/
│   ├── plants/
│   │   ├── base_plants.json
│   │   └── schema.json
│   ├── combinations/
│   │   └── base_combos.json
│   └── npcs/
│       └── seed_merchant.json
│
├── 📁 assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── plants/
│   │   ├── tiles/
│   │   └── ui/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
│
├── 📁 ui/
│   ├── hud.tscn
│   ├── pause_menu.tscn
│   └── theme.tres
│
├── 📁 scenes/
│   ├── main.tscn (entry point)
│   ├── farm.tscn (main gameplay)
│   └── menu.tscn (main menu)
│
├── 📁 mods/ (future)
│   └── README_MODDING.md
│
└── 📁 docs/
    ├── architecture.md
    ├── api_reference.md
    └── changelog.md
```

---

## ✅ **X. WEEKLY CHECKLIST TEMPLATE**

### **Her Pazartesi Sabah:**

```
□ GDD'yi oku (10 dk)
□ Bu hafta hedefi belirle (1-2 sistem)
□ GitHub issue oluştur (task breakdown)
□ Zaman planla (12 saat bu hafta nereye?)
```

### **Her Cuma Akşam:**

```
□ Bu hafta ne bitti? (commit log)
□ Demo'yu test et (5 dk playthrough)
□ Bug list güncelle
□ Gelecek hafta plan (öncelik değişti mi?)
□ Progress screenshot al (portfolio için)
```

### **Her Ay Sonu:**

```
□ Playtest (1-2 arkadaş)
□ Feedback topla
□ Roadmap adjust et
□ Burnout check (dinlenme gerekli mi?)
```

---

## 🎯 **XI. CRITICAL SUCCESS FACTORS**

### **Core Prototype için EN ÖNEMLİ 3 ŞEY:**

**1. Core Loop Tatmin Edici Olmalı**

```
Plant → Water → Harvest → Combine → Discover
↑_______________|

Bu döngü 5 dakikada keyifli olmazsa oyun başarısız!
Her iterasyonda bu loop'u test et.
```

**2. Discovery Moment "Aha!" Vermeli**

```
Kombinasyon sonucu = dopamine hit
Particle, sound, animation = juice
"I want to discover more!" hissi
```

**3. Modular Architecture = Uzun Vadeli Başarı**

```
Her sistem ayrı = kolay genişletme
JSON-driven = modding-friendly
Event-driven = decoupled systems
```

---

## 📝 **XII. NOTES & PHILOSOPHY**

### **Design Prensipleri:**

```
✅ Simplicity first (karmaşıklık sonra ekle)
✅ Player agency (zorla bir şey yok)
✅ Positive feedback (ceza yok, ödül var)
✅ Discovery over instruction (tutorial minimal)
✅ Cozy over stressful (no time pressure)
```

### **Development Prensipleri:**

```
✅ Playable > Perfect (her hafta oyna)
✅ Iterate fast (big refactor yerine small tweaks)
✅ Data-driven (code değiştirme, JSON değiştir)
✅ Version control (her gün commit)
✅ Document as you go (future-you'ya hediye)
```

### **Community Prensipleri:**

```
✅ Transparency (progress share et)
✅ Open to feedback (ama vision'ı koru)
✅ Modding-first (community = content machine)
✅ Give credit (contributor'ları unutma)
```

---

## 🔄 **XIII. ITERATION PROTOCOL**

### **Her Feature Eklerken:**

```
1. GDD'ye ekle (bu dokümana)
2. JSON schema tanımla (eğer data-driven)
3. Interface/API tasarla (kod yazmadan önce)
4. Implement et (küçük commit'ler)
5. Test et (5 dk playthrough)
6. Document et (code comment + GDD update)
7. Git commit (meaningful message)
```

### **Feature Değiştiğinde:**

```
1. GDD'yi güncelle (outdated bilgi tehlikeli)
2. Related sistemleri check et (dependency break?)
3. Save format etkilendi mi? (migration gerekli mi?)
4. Mod API etkilendi mi? (breaking change?)
```

---

## 🎓 **XIV. LEARNING RESOURCES (Godot Specific)**

### **Godot Tutorials (Core Prototype İçin):**

```
□ Heartbeast - "Godot Action RPG Tutorial"
  → Movement, animation, state machines
  
□ GDQuest - "Learn GDScript From Zero"
  → Syntax, patterns, best practices
  
□ Brackeys (old but gold) - "How to make a Game"
  → General game dev concepts
```

### **Pixel Art (Paralel Öğren):**

```
□ Mortmort - "Pixel Art Class"
  → 16x16 basics, color theory
  
□ Brandon James Greer - "Pixel Art Tips"
  → Advanced techniques
```

### **Game Design (Okuma):**

```
□ "The Art of Game Design" - Jesse Schell
  → Lens'ler, design thinking
  
□ "Game Feel" - Steve Swink
  → Juice, feedback, satisfaction
```

---

## ✅ **XV. DONE DEFINITION - "Core Prototype Complete"**

### **Bu listeyi check edebildiğinde prototype bitti:**

```
GAMEPLAY:
□ 30 dakika keyifli gameplay loop
□ 10 tür yetiştirilebilir
□ 15 kombinasyon keşfedilebilir
□ Save/load çalışıyor
□ Hiçbir game-breaking bug yok

TECHNICAL:
□ 7/7 core system implemented
□ JSON-driven data architecture
□ Modular, decoupled systems
□ Git history clean, documented
□ 60 FPS stable

ART:
□ 40+ sprite (10 tür × 4 stage)
□ Player animation (4 direction)
□ UI mockup (inventory, combo) 
□ Tileset (soil, grass, path) □ Consistent style/palette

AUDIO: 
□ 1 music track (loop) □ 5 SFX (plant, water, harvest, combine, click)

DOCUMENTATION: 
□ GDD up-to-date (this doc) 
□ Code comments (complex logic) 
□ README.md (setup instructions) 
□ Modding guide (skeleton)

PLAYTEST: 
□ 5 people played (friends/family) 
□ Feedback documented 
□ Major issues fixed 
□ Fun factor validated (7+/10)

```

## 🚀 **BAŞLA!**

### **İlk Adım (Bugün):**

1. ✅ GDD'yi kaydet (bu dosya)
2. □ Godot 4.3 indir + proje oluştur
3. □ Folder structure kur (yukarıdaki gibi)
4. □ Git init + first commit
5. □ EventBus.gd yaz (skeleton)
6. □ Player scene oluştur (placeholder sprite)
7. □ 30 dakika pixel art practice (Mortmort) 
8. □ Player movement (WASD) 
9. □ Grid manager (tile rendering) 
10. □ Camera follow player

```

---

## 📄 **VERSION HISTORY**

```

v0.1 (2025-12-11): Initial GDD

- Core concept defined
- 12-week prototype roadmap
- Modular architecture planned
- System breakdown complete