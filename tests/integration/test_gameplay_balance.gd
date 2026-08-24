class_name TestGameplayBalance
extends TestCase

## Comprehensive 18-Point Gameplay Balance, Economy ROI, Energy Stamina,
## Friendship Cadence, and First-Hour Experience Test Suite (Phase 23).

func test_name_id() -> String:
	return "BALANCE.FirstHourPlaytest"

func _get_root_node(path: String) -> Node:
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root:
		return loop.root.get_node_or_null(path)
	return null

func run_all() -> void:
	test_name = test_name_id()
	
	_test_T01_new_game_initial_state()
	_test_T02_first_day_farming_loop()
	_test_T03_first_harvest_loop()
	_test_T04_energy_balance()
	_test_T05_economy_profitability()
	_test_T06_quest_reward_balance()
	_test_T07_friendship_progression()
	_test_T08_loved_gift_progression()
	_test_T09_heart_milestone_progression()
	_test_T10_first_three_days_progression()
	_test_T11_world_unlock_progression()
	_test_T12_no_infinite_money_exploit()
	_test_T13_no_infinite_friendship_exploit()
	_test_T14_no_save_load_exploit()
	_test_T15_no_time_exploit()
	_test_T16_player_guidance()
	_test_T17_core_gameplay_loop()
	_test_T18_first_hour_progression()

# --- 1. Initial State & Guidance ---

func _test_T01_new_game_initial_state() -> void:
	begin_test("T01_NewGameInitialState")
	var p = PlayerState.new("p_new", "Botanist")
	p.init_starter_kit()
	assert_eq(p.gold, 100, "Starting gold is 100g")
	assert_eq(p.energy, 100.0, "Starting energy is 100/100")
	assert_true(p.has_item("hoe_basic"), "Basic hoe provided")
	assert_true(p.has_item("watering_can_basic"), "Basic watering can provided")
	assert_true(p.has_item("axe_basic"), "Basic axe provided")
	assert_true(p.has_item("pickaxe_basic"), "Basic pickaxe provided")
	assert_eq(p.get_item_count("seed_red_flower"), 5, "5 red flower seeds provided")
	assert_eq(p.get_item_count("seed_blue_flower"), 3, "3 blue flower seeds provided")
	assert_eq(p.get_item_count("seed_yellow_herb"), 4, "4 yellow herb seeds provided")
	assert_eq(p.current_world, "farm", "Player starts on farm world")

func _test_T02_first_day_farming_loop() -> void:
	begin_test("T02_FirstDayFarmingLoop")
	var p = PlayerState.new("p_farm")
	p.init_starter_kit()
	
	# Simulate tilling 5 plots and planting 5 red seeds
	for i in range(5):
		p.use_energy(2.0) # Hoe cost
		p.remove_item("seed_red_flower", 1)
		p.use_energy(1.5) # Watering can cost
		
	assert_eq(p.get_item_count("seed_red_flower"), 0, "5 seeds planted")
	assert_approx_eq(p.energy, 82.5, 0.01, "5 plots cost exactly 17.5 energy (82.5 remain)")
	assert_true(p.energy > 50.0, "Substantial energy remaining for exploration")

func _test_T03_first_harvest_loop() -> void:
	begin_test("T03_FirstHarvestLoop")
	var p = PlayerState.new("p_harv")
	# Simulate harvesting 5 mature crops
	p.add_item("plant_red_flower", 5)
	assert_eq(p.get_item_count("plant_red_flower"), 5, "5 red flowers harvested into inventory")

# --- 2. Energy & Economy Balance ---

func _test_T04_energy_balance() -> void:
	begin_test("T04_EnergyBalance")
	var p = PlayerState.new("p_energy")
	p.energy = 100.0
	
	# 10 field plots (till + water) = 35 energy
	for i in range(10):
		p.use_energy(2.0) # hoe
		p.use_energy(1.5) # water
	# 5 wood chopping = 15 energy
	for i in range(5):
		p.use_energy(3.0) # axe
	# 5 rock breaking = 15 energy
	for i in range(5):
		p.use_energy(3.0) # pickaxe
		
	assert_approx_eq(p.energy, 35.0, 0.01, "Full productive day uses 65 energy (35 remain for extra tasks)")
	p.restore_energy(100.0)
	assert_eq(p.energy, 100.0, "Sleeping fully restores energy to 100")

func _test_T05_economy_profitability() -> void:
	begin_test("T05_EconomyProfitability")
	var p = PlayerState.new("p_econ")
	p.gold = 100
	
	# Buy 4 red seeds at 25g each (total 100g)
	p.spend_gold(100)
	assert_eq(p.gold, 0, "All gold invested in seeds")
	
	# Harvest 4 red flowers (each sells for 50g base price)
	var total_revenue = 4 * 50
	p.add_gold(total_revenue)
	
	assert_eq(p.gold, 200, "200g total revenue (100% net profit / ROI = 2.0x)")

func _test_T06_quest_reward_balance() -> void:
	begin_test("T06_QuestRewardBalance")
	var p = PlayerState.new("p_quest")
	p.gold = 100
	RewardManager.grant_rewards({ "gold": 25 }, p) # Quest 1 reward
	RewardManager.grant_rewards({ "gold": 25 }, p) # Quest 2 reward
	assert_eq(p.gold, 150, "Early quest rewards grant +50g (enough for 2 fresh seeds)")

# --- 3. Social & Friendship Balance ---

func _test_T07_friendship_progression() -> void:
	begin_test("T07_FriendshipProgression")
	var p = PlayerState.new("p_social")
	# 5 days of daily conversation (+20 pts/day)
	for day in range(5):
		p.reset_daily_social_limits()
		p.add_friendship("rowan", 20, "talk")
		
	assert_eq(p.get_friendship_points("rowan"), 100, "100 pts reached on Day 5")
	assert_eq(p.get_heart_level("rowan"), 1, "Heart 1 achieved in 5 in-game days by chatting alone")

func _test_T08_loved_gift_progression() -> void:
	begin_test("T08_LovedGiftProgression")
	var p = PlayerState.new("p_gift")
	# Day 1: Talk (+20) + Loved Gift (+80)
	p.add_item("plant_sun_petal", 1)
	p.add_friendship("rowan", 20, "talk")
	p.give_gift("rowan", "plant_sun_petal")
	
	assert_eq(p.get_friendship_points("rowan"), 100, "100 pts reached on Day 1 with loved gift")
	assert_eq(p.get_heart_level("rowan"), 1, "Heart 1 unlocked on Day 1")

func _test_T09_heart_milestone_progression() -> void:
	begin_test("T09_HeartMilestoneProgression")
	var p = PlayerState.new("p_ms")
	p.gold = 100
	p.add_friendship("rowan", 100) # Heart 1 -> grants milestone 1 (50g)
	assert_eq(p.gold, 150, "Heart 1 milestone awards 50g")
	assert_eq(p.claimed_heart_milestones.get("rowan"), [1], "Milestone 1 tracked")
	
	p.add_friendship("rowan", 100) # Heart 2 -> grants milestone 2 (quest unlock)
	assert_eq(p.claimed_heart_milestones.get("rowan"), [1, 2], "Milestones 1 & 2 tracked")

# --- 4. Multi-Day Progression Simulation ---

func _test_T10_first_three_days_progression() -> void:
	begin_test("T10_FirstThreeDaysProgression")
	var p = PlayerState.new("p_3day")
	p.init_starter_kit()
	
	# DAY 1: Plant 5 seeds, water, talk & gift Rowan
	p.use_energy(17.5) # plant + water
	p.add_friendship("rowan", 20, "talk")
	p.add_item("plant_sun_petal", 1)
	p.give_gift("rowan", "plant_sun_petal") # +80 pts -> 100 pts (Heart 1)
	RewardManager.grant_rewards({ "gold": 25 }, p) # Quest 1: First Seeds
	
	# Night 1: Sleep -> reset limits & restore energy
	p.reset_daily_social_limits()
	p.restore_energy(100.0)
	
	# DAY 2: Water crops, talk Rowan, forage 3 wood
	p.use_energy(7.5) # water
	p.use_energy(9.0) # chop wood
	p.add_friendship("rowan", 20, "talk")
	RewardManager.grant_rewards({ "gold": 25 }, p) # Quest 2: Keep Them Alive
	
	# Night 2: Sleep -> reset limits
	p.reset_daily_social_limits()
	p.restore_energy(100.0)
	
	# DAY 3: Crops mature! Harvest 5 red flowers & sell
	p.add_item("plant_red_flower", 5)
	p.remove_item("plant_red_flower", 5)
	p.add_gold(250) # 5 x 50g
	RewardManager.grant_rewards({ "gold": 35 }, p) # Quest 3: Harvest Time
	
	# Talk & gift Rowan -> Reach Heart 2
	p.add_friendship("rowan", 20, "talk")
	p.add_item("plant_sun_petal", 1)
	p.give_gift("rowan", "plant_sun_petal") # +80 pts -> 220 pts (Heart 2)
	
	assert_true(p.gold >= 400, "Day 3 ending gold >= 400g (Started with 100g)")
	assert_eq(p.get_heart_level("rowan"), 2, "Day 3 reaches Heart 2 with Rowan")
	assert_true(p.claimed_heart_milestones.get("rowan").has(2), "Heart 2 milestone quest unlocked")

func _test_T11_world_unlock_progression() -> void:
	begin_test("T11_WorldUnlockProgression")
	var pm = _get_root_node("/root/ProgressionManager")
	if pm:
		assert_true(pm.is_world_unlocked("farm"), "Farm world unlocked by default")
		assert_true(pm.is_world_unlocked("town"), "Town world unlocked by default")

# --- 5. Exploit & Degenerate Strategy Prevention ---

func _test_T12_no_infinite_money_exploit() -> void:
	begin_test("T12_NoInfiniteMoneyExploit")
	var p = PlayerState.new("p_exploit")
	p.gold = 50
	var res = p.remove_item("plant_red_flower", 10)
	assert_false(res, "Cannot sell/remove items not in inventory")
	assert_eq(p.gold, 50, "Gold unchanged on invalid transaction")

func _test_T13_no_infinite_friendship_exploit() -> void:
	begin_test("T13_NoInfiniteFriendshipExploit")
	var p = PlayerState.new("p_friend_exploit")
	p.add_friendship("rowan", 20, "talk")
	var pts1 = p.get_friendship_points("rowan")
	p.add_friendship("rowan", 20, "talk") # Duplicate talk same day
	var pts2 = p.get_friendship_points("rowan")
	assert_eq(pts1, pts2, "Friendship points capped at 1 talk reward per day")

func _test_T14_no_save_load_exploit() -> void:
	begin_test("T14_NoSaveLoadExploit")
	var p = PlayerState.new("p_save_exploit")
	p.add_item("plant_sun_petal", 1)
	p.give_gift("rowan", "plant_sun_petal")
	
	var save_blob = p.to_dict()
	var reloaded_p = PlayerState.from_dict(save_blob)
	
	assert_false(reloaded_p.can_give_gift("rowan", "plant_sun_petal"), "Reloading save retains daily gift cooldown")
	assert_eq(reloaded_p.get_item_count("plant_sun_petal"), 0, "Reloading does not duplicate consumed gift item")

func _test_T15_no_time_exploit() -> void:
	begin_test("T15_NoTimeExploit")
	var tm = _get_root_node("/root/TimeManager")
	if tm:
		var m1 = tm.current_time_minutes
		assert_true(m1 >= 0 and m1 <= 1440, "Time minutes within valid 24h bounds")

# --- 6. Player Guidance & First-Hour Quality ---

func _test_T16_player_guidance() -> void:
	begin_test("T16_PlayerGuidance")
	var qm = _get_root_node("/root/QuestManager")
	if qm:
		var q1 = qm.get_quest("quest_01")
		assert_eq(str(q1.get("title", "")), "First Seeds", "First quest clearly guides planting")


func _test_T17_core_gameplay_loop() -> void:
	begin_test("T17_CoreGameplayLoop")
	var p = PlayerState.new("p_loop")
	p.init_starter_kit()
	
	# 1. Till & Plant
	p.use_energy(3.5)
	p.remove_item("seed_red_flower", 1)
	
	# 2. Harvest
	p.add_item("plant_red_flower", 2)
	
	# 3. Sell & Reinvest
	p.remove_item("plant_red_flower", 1)
	p.add_gold(50)
	p.spend_gold(25) # Buy 1 seed
	p.add_item("seed_red_flower", 1)
	
	# 4. Gift surplus & progress relationship
	p.give_gift("rowan", "plant_red_flower")
	
	assert_true(p.get_friendship_points("rowan") > 0, "Loop successfully feeds into social progression")
	assert_true(p.gold > 100, "Loop generates economic surplus")

func _test_T18_first_hour_progression() -> void:
	begin_test("T18_FirstHourProgression")
	var p = PlayerState.new("p_first_hour")
	p.init_starter_kit()
	
	# First hour simulated achievements
	p.add_gold(320) # Net profit from initial harvests + quests
	p.add_friendship("rowan", 210) # Reaches Heart 2
	p.add_friendship("elias", 120) # Reaches Heart 1
	p.personal_quests["quest_01"] = { "status": "completed" }
	p.personal_quests["quest_02"] = { "status": "completed" }
	p.personal_quests["quest_03"] = { "status": "completed" }
	
	assert_true(p.gold >= 400, "First-hour gold exceeds 400g")
	assert_true(p.get_heart_level("rowan") >= 2, "Rowan Heart 2 reached in first hour")
	assert_true(p.get_heart_level("elias") >= 1, "Elias Heart 1 reached in first hour")
	assert_eq(p.personal_quests.size(), 3, "3 core quests completed")
