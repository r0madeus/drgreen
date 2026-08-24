@tool
extends SceneTree

func _init() -> void:
	generate_all()
	quit()

static func parse_hex_grid(hex_map: Dictionary, lines: Array) -> Image:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(mini(16, lines.size())):
		var line: String = lines[y]
		for x in range(mini(16, line.length())):
			var ch = line[x]
			if hex_map.has(ch):
				var col = hex_map[ch]
				img.set_pixel(x, y, col)
	return img

static func generate_all() -> Array:
	var created_files = []

	# Base seed template
	var seed_lines = [
		"................", "................", "................", "................",
		"................", "................", "................", "................",
		".......E........", "......SE........", ".....BSSM.......", "....BMMMMM......",
		"...BMMMMMMD.....", "..DDDDDDDDDD....", "................", "................"
	]

	# Standard Flower Sprout (Stage 1)
	var sprout_lines_std = [
		"................", "................", "................", "................",
		"................", "................", "................", "....HL....LH....",
		"...HLLL..LLLH...", "....LLLGGLLL....", "......GGGG......", ".......GG.......",
		".......GG.......", "......DDDD......", "................", "................"
	]

	# Vine Sprout (Stage 1)
	var sprout_lines_vine = [
		"................", "................", "................", "................",
		"................", "................", "................", "..HL............",
		".HLLLG..........", "..LLLG...LH.....", ".....GG.LLLH....", "......GGLLLG....",
		".......GGGG.....", "......DDDD......", "................", "................"
	]

	# Standard Flower Grow (Stage 2)
	var grow_lines_flower = [
		"................", "................", "................", ".......KK.......",
		"......KBBB......", "......RBBR......", ".......GG.......", "...HL..GG..LH...",
		"..HLLL.GG.LLLH..", "..LLLLGGGGLLLL..", "...LLLLGGLLLL...", ".....LLGGLL.....",
		".......GG.......", ".......GG.......", "......GGGG......", "................"
	]

	# Herb Grow (Stage 2)
	var grow_lines_herb = [
		"................", "................", "................", "......KKKK......",
		".....KBBBBK.....", ".....RBBBBR.....", "......RKKR......", "...HL..GG..LH...",
		"..HLLL.GG.LLLH..", "..LLLLGGGGLLLL..", "...LLLLGGLLLL...", ".....LLGGLL.....",
		".......GG.......", ".......GG.......", "......GGGG......", "................"
	]

	# Vine Grow (Stage 2)
	var grow_lines_vine = [
		"................", "................", "................", "..........KK....",
		".........KHHG...", "....KK..GHHHLG..", "...KHHGGHLLLG...", "..GHHLLGGGGLLG..",
		"..GHLLLG.GHLLLG.", "...GGGG...GGGG..", ".....GG...GG....", "......GG.GG.....",
		".......GGG......", ".......GGG......", "......DDDD......", "................"
	]

	# Standard Flower Mature (Stage 3)
	var mature_lines_flower = [
		"................", "......W.........", "....OHHHHO......", "...OHPPPPHO.W...",
		"..OHPPRRPPHO....", "..OPPRYYRPPO....", "..OPPRYYRPPO....", "..OHPPRRPPHO....",
		"...OHPPPPHO.....", "....OHHHHO......", "...AL..G..LA....", "..ALLL.G.LLLA...",
		"...LLLG.GLLL....", "......GGG.......", ".......G........", "................"
	]

	# Herb Mature (Stage 3)
	var mature_lines_herb = [
		"................", ".....W...W......", "....OHHHHHO.....", "...OHPPPPPHO....",
		"..OHPPRRRPPHO...", "..OPPRYYYYRPPO..", "..OPPRYYYYRPPO..", "..OHPPRRRPPHO...",
		"...OHPPPPPHO....", "....OHHHHHO.....", "...AL..G..LA....", "..ALLL.G.LLLA...",
		"...LLLG.GLLL....", "......GGG.......", ".......G........", "................"
	]

	# Vine Mature (Stage 3)
	var mature_lines_vine = [
		"................", "..W..........W..", "....BB....BB....", "...BKKG..GKKG...",
		"..BKKHHGGHHHLG..", ".GKKHHLLGGLLLLG.", ".GHHLLLG..GHLLG.", "GLLLLGG....GGGG.",
		".GGGGG.W..W.GG..", "..GG.BKKGGKKG...", "...GG.KHHGGHHLG.", "....GG.HLLG.LLG.",
		".....GGG.GGG....", "......GGG.......", ".......G........", "................"
	]

	# Lotus / Double Bloom Mature (Stage 3)
	var mature_lines_lotus = [
		"................", "...W........W...", "...OOHHHHHHOO...", "..OHPPPPPPPPHO..",
		".OHPPRRRRRRPPHO.", ".OPPRRYYYYRRPPO.", "OPPRYYYYYYYYRPPO", ".OPPRRYYYYRRPPO.",
		".OHPPRRRRRRPPHO.", "..OHPPPPPPPPHO..", "...ALLLGGLLLA...", "..ALLLLGGLLLLA..",
		"....LLGGGGLL....", ".......GG.......", ".......GG.......", "................"
	]

	# =========================================================================
	# 12 HYBRID SPECIES CONFIGURATIONS
	# =========================================================================
	var hybrid_configs = [
		# 1. Golden Lily (Yellow Herb + White Lily)
		{
			"id": "golden_lily",
			"embryo": Color("ffd166"),
			"type": "flower",
			"sprout_map": { "G": Color("2e591b"), "L": Color("529433"), "H": Color("82cf59"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("244a14"), "L": Color("427d26"), "H": Color("6ab844"), "R": Color("b37d14"), "B": Color("f5be27"), "K": Color("fff3b0") },
			"mature_map": { "O": Color("5c3d04"), "R": Color("c28e10"), "P": Color("ffd166"), "H": Color("fff3b0"), "Y": Color("ffffff"), "W": Color("ffffff"), "G": Color("1a3d0f"), "L": Color("35691e"), "A": Color("579e33") }
		},
		# 2. Crimson Vine (Green Vine + Red Flower)
		{
			"id": "crimson_vine",
			"embryo": Color("d00000"),
			"type": "vine",
			"sprout_map": { "G": Color("3d1418"), "L": Color("73222a"), "H": Color("ad3945"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("2e0c10"), "L": Color("5c1920"), "H": Color("8c2530"), "K": Color("dc2f02"), "D": Color("3a1e0b") },
			"mature_map": { "G": Color("1f060a"), "L": Color("3d0d14"), "H": Color("6a040f"), "K": Color("d00000"), "W": Color("ffffff"), "B": Color("ff6b7e") }
		},
		# 3. Frost Vine (Green Vine + Blue Flower)
		{
			"id": "frost_vine",
			"embryo": Color("90e0ef"),
			"type": "vine",
			"sprout_map": { "G": Color("143d47"), "L": Color("226675"), "H": Color("45a8bd"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("0c272e"), "L": Color("154754"), "H": Color("267a8f"), "K": Color("90e0ef"), "D": Color("3a1e0b") },
			"mature_map": { "G": Color("061a1f"), "L": Color("0f3742"), "H": Color("0077b6"), "K": Color("90e0ef"), "W": Color("ffffff"), "B": Color("caf0f8") }
		},
		# 4. Pink Lily (White Lily + Red Flower)
		{
			"id": "pink_lily",
			"embryo": Color("ff70a6"),
			"type": "flower",
			"sprout_map": { "G": Color("275230"), "L": Color("478754"), "H": Color("73c285"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("1e4226"), "L": Color("366e43"), "H": Color("5aa66e"), "R": Color("9c1f4e"), "B": Color("e0487f"), "K": Color("ff97b7") },
			"mature_map": { "O": Color("590928"), "R": Color("ad2159"), "P": Color("ff70a6"), "H": Color("ffb3cf"), "Y": Color("ffe680"), "W": Color("ffffff"), "G": Color("16361d"), "L": Color("2b5c34"), "A": Color("489456") }
		},
		# 5. Sapphire Lily (White Lily + Blue Flower)
		{
			"id": "sapphire_lily",
			"embryo": Color("00b4d8"),
			"type": "flower",
			"sprout_map": { "G": Color("1f4a3c"), "L": Color("357d67"), "H": Color("5cb89a"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("163b2f"), "L": Color("26614f"), "H": Color("43967d"), "R": Color("03325c"), "B": Color("0077b6"), "K": Color("48cae4") },
			"mature_map": { "O": Color("021e38"), "R": Color("005082"), "P": Color("0077b6"), "H": Color("00b4d8"), "Y": Color("90e0ef"), "W": Color("ffffff"), "G": Color("112e25"), "L": Color("1e5242"), "A": Color("34826a") }
		},
		# 6. Sun Vine (Green Vine + Yellow Herb)
		{
			"id": "sun_vine",
			"embryo": Color("ffb703"),
			"type": "vine",
			"sprout_map": { "G": Color("384714"), "L": Color("607a22"), "H": Color("9cb83e"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("26330b"), "L": Color("475c14"), "H": Color("769623"), "K": Color("ffb703"), "D": Color("3a1e0b") },
			"mature_map": { "G": Color("182105"), "L": Color("2e3d0a"), "H": Color("526e10"), "K": Color("ffb703"), "W": Color("ffffff"), "B": Color("ffe169") }
		},
		# 7. Moon Vine (Green Vine + White Lily)
		{
			"id": "moon_vine",
			"embryo": Color("e2eafc"),
			"type": "vine",
			"sprout_map": { "G": Color("293642"), "L": Color("465c70"), "H": Color("7494b3"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("1b252e"), "L": Color("324352"), "H": Color("55718a"), "K": Color("c1d3fe"), "D": Color("3a1e0b") },
			"mature_map": { "G": Color("10171c"), "L": Color("1f2c36"), "H": Color("3d5466"), "K": Color("e2eafc"), "W": Color("ffffff"), "B": Color("edf2fb") }
		},
		# 8. Deep Crimson Bloom (Red Flower + Red Flower - Epic)
		{
			"id": "deep_crimson_bloom",
			"embryo": Color("6a040f"),
			"type": "lotus",
			"sprout_map": { "G": Color("294725"), "L": Color("4b7a45"), "H": Color("77b36f"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("1c3319"), "L": Color("365c31"), "H": Color("588f50"), "R": Color("400108"), "B": Color("6a040f"), "K": Color("9d0208") },
			"mature_map": { "O": Color("240004"), "R": Color("4a020a"), "P": Color("6a040f"), "H": Color("9d0208"), "Y": Color("dc2f02"), "W": Color("ffffff"), "G": Color("132411"), "L": Color("264222"), "A": Color("416e3b") }
		},
		# 9. Azure Lotus (Blue Flower + Blue Flower - Epic)
		{
			"id": "azure_lotus",
			"embryo": Color("03045e"),
			"type": "lotus",
			"sprout_map": { "G": Color("1a453e"), "L": Color("2e7368"), "H": Color("52ab9c"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("10302b"), "L": Color("1f544c"), "H": Color("3a877b"), "R": Color("010238"), "B": Color("03045e"), "K": Color("0077b6") },
			"mature_map": { "O": Color("010224"), "R": Color("020347"), "P": Color("03045e"), "H": Color("0077b6"), "Y": Color("48cae4"), "W": Color("ffffff"), "G": Color("0d211e"), "L": Color("173d37"), "A": Color("296157") }
		},
		# 10. Radiant Essence Herb (Yellow Herb + Yellow Herb - Epic)
		{
			"id": "radiant_essence_herb",
			"embryo": Color("ffea00"),
			"type": "herb",
			"sprout_map": { "G": Color("475411"), "L": Color("768c1c"), "H": Color("b5d433"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("2f3809"), "L": Color("526112"), "H": Color("82991f"), "R": Color("ad8200"), "B": Color("ffc300"), "K": Color("ffea00") },
			"mature_map": { "O": Color("5c4500"), "R": Color("b88b02"), "P": Color("ffc300"), "H": Color("ffea00"), "Y": Color("ffffff"), "W": Color("ffffff"), "G": Color("212904"), "L": Color("3c4a09"), "A": Color("657a12") }
		},
		# 11. Celestial Lily (White Lily + White Lily - Legendary)
		{
			"id": "celestial_lily",
			"embryo": Color("ffd700"),
			"type": "lotus",
			"sprout_map": { "G": Color("334d47"), "L": Color("577a72"), "H": Color("8ab8ad"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("223631"), "L": Color("3d5751"), "H": Color("64877f"), "R": Color("8c9496"), "B": Color("d0d6d9"), "K": Color("ffffff") },
			"mature_map": { "O": Color("424f54"), "R": Color("82949c"), "P": Color("c8d5db"), "H": Color("ffffff"), "Y": Color("ffd700"), "W": Color("ffffff"), "G": Color("162420"), "L": Color("283d37"), "A": Color("44635a") }
		},
		# 12. Ancient Evergreen Tendril (Green Vine + Green Vine - Epic)
		{
			"id": "ancient_evergreen_tendril",
			"embryo": Color("1b4332"),
			"type": "vine",
			"sprout_map": { "G": Color("081c15"), "L": Color("1b4332"), "H": Color("40916c"), "D": Color("3a1e0b") },
			"grow_map": { "G": Color("05120d"), "L": Color("133024"), "H": Color("2d664c"), "K": Color("74c69d"), "D": Color("3a1e0b") },
			"mature_map": { "G": Color("030a07"), "L": Color("0b1f17"), "H": Color("1b4332"), "K": Color("40916c"), "W": Color("ffffff"), "B": Color("74c69d") }
		}
	]

	# =========================================================================
	# GENERATION LOOP
	# =========================================================================
	var pouch_map_base = {
		"O": Color("241708"), "D": Color("4a2d12"), "M": Color("734820"), "L": Color("a66d33"),
		"T": Color("d4a359"), "W": Color("ffffff")
	}

	for cfg in hybrid_configs:
		var pid = cfg["id"]
		var embryo_col = cfg["embryo"]
		var ptype = cfg["type"]

		# 1. Stage 0: Seed
		var s_map = {
			"D": Color("3a1e0b"), "B": Color("542e13"), "M": Color("6e3d1a"),
			"S": Color("d4b37d"), "E": embryo_col
		}
		var img_s0 = parse_hex_grid(s_map, seed_lines)
		var p_s0 = "res://assets/sprites/plants/%s_stage_0.png" % pid
		img_s0.save_png(p_s0)
		created_files.append(p_s0)

		# 2. Stage 1: Sprout
		var sp_lines = sprout_lines_vine if ptype == "vine" else sprout_lines_std
		var img_s1 = parse_hex_grid(cfg["sprout_map"], sp_lines)
		var p_s1 = "res://assets/sprites/plants/%s_stage_1.png" % pid
		img_s1.save_png(p_s1)
		created_files.append(p_s1)

		# 3. Stage 2: Growing
		var gr_lines = grow_lines_vine if ptype == "vine" else (grow_lines_herb if ptype == "herb" else grow_lines_flower)
		var img_s2 = parse_hex_grid(cfg["grow_map"], gr_lines)
		var p_s2 = "res://assets/sprites/plants/%s_stage_2.png" % pid
		img_s2.save_png(p_s2)
		created_files.append(p_s2)

		# 4. Stage 3: Mature
		var mat_lines = mature_lines_vine if ptype == "vine" else (mature_lines_herb if ptype == "herb" else (mature_lines_lotus if ptype == "lotus" else mature_lines_flower))
		var img_s3 = parse_hex_grid(cfg["mature_map"], mat_lines)
		var p_s3 = "res://assets/sprites/plants/%s_stage_3.png" % pid
		img_s3.save_png(p_s3)
		created_files.append(p_s3)

		# 5. Item Icon: Seed Pouch
		var smap = pouch_map_base.duplicate()
		smap["E"] = embryo_col
		var pouch_lines = [
			"................", "................", "......OOOO......", ".....OTTTTO.....",
			"....OTEEEEETO...", "...OMEEEEEEEMO..", "..OMEEEEEEEEEEO.", ".OLEEEEEEEEEEEEO",
			".OLEEEEEEEEEEEEO", ".OMEEEEEEEEEEMO.", ".OMMEEEEEEEEMMO.", "..OMMDDDDMMDO...",
			"...ODDDDDDDDO...", "....OOOOOOOO....", "................", "................"
		]
		var img_seed = parse_hex_grid(smap, pouch_lines)
		var p_seed = "res://assets/sprites/items/seed_%s.png" % pid
		img_seed.save_png(p_seed)
		created_files.append(p_seed)

		# 6. Item Icon: Crop Icon
		var img_crop = parse_hex_grid(cfg["mature_map"], mat_lines)
		var p_crop = "res://assets/sprites/items/%s.png" % pid
		img_crop.save_png(p_crop)
		created_files.append(p_crop)

	print("[HybridSet2Generator] Successfully created %d hybrid pixel-art assets!" % created_files.size())
	return created_files
