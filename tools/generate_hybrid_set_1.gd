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

	# =========================================================================
	# 1. PURPLE FLOWER (Red Flower + Blue Flower)
	# =========================================================================
	# Stage 0: Seed
	var p_seed_map = {
		"D": Color("3a1e0b"), "B": Color("542e13"), "M": Color("6e3d1a"),
		"S": Color("d4b37d"), "E": Color("9d4edd") # Purple embryo
	}
	var seed_lines = [
		"................", "................", "................", "................",
		"................", "................", "................", "................",
		".......E........", "......SE........", ".....BSSM.......", "....BMMMMM......",
		"...BMMMMMMD.....", "..DDDDDDDDDD....", "................", "................"
	]
	var pf0 = parse_hex_grid(p_seed_map, seed_lines)
	pf0.save_png("res://assets/sprites/plants/purple_flower_stage_0.png")
	created_files.append("res://assets/sprites/plants/purple_flower_stage_0.png")

	# Stage 1: Sprout
	var p_sprout_map = { "G": Color("23522f"), "L": Color("489958"), "H": Color("76cf87"), "D": Color("3a1e0b") }
	var sprout_lines = [
		"................", "................", "................", "................",
		"................", "................", "................", "....HL....LH....",
		"...HLLL..LLLH...", "....LLLGGLLL....", "......GGGG......", ".......GG.......",
		".......GG.......", "......DDDD......", "................", "................"
	]
	var pf1 = parse_hex_grid(p_sprout_map, sprout_lines)
	pf1.save_png("res://assets/sprites/plants/purple_flower_stage_1.png")
	created_files.append("res://assets/sprites/plants/purple_flower_stage_1.png")

	# Stage 2: Growing Violet Bud
	var p_grow_map = {
		"G": Color("1a4524"), "L": Color("327a42"), "H": Color("56ab67"),
		"R": Color("47126b"), "B": Color("7b2cbf"), "K": Color("c77dff")
	}
	var p_grow_lines = [
		"................", "................", "................", ".......KK.......",
		"......KBBB......", "......RBBR......", ".......GG.......", "...HL..GG..LH...",
		"..HLLL.GG.LLLH..", "..LLLLGGGGLLLL..", "...LLLLGGLLLL...", ".....LLGGLL.....",
		".......GG.......", ".......GG.......", "......GGGG......", "................"
	]
	var pf2 = parse_hex_grid(p_grow_map, p_grow_lines)
	pf2.save_png("res://assets/sprites/plants/purple_flower_stage_2.png")
	created_files.append("res://assets/sprites/plants/purple_flower_stage_2.png")

	# Stage 3: Mature Royal Purple Bloom
	var p_mature_map = {
		"O": Color("3c096c"), "R": Color("5a189a"), "P": Color("7b2cbf"), "H": Color("c77dff"),
		"Y": Color("ffcc24"), "W": Color("ffffff"), "G": Color("15381d"), "L": Color("276635"), "A": Color("469958")
	}
	var p_mature_lines = [
		"................", "......W.........", "....OHHHHO......", "...OHPPPPHO.W...",
		"..OHPPRRPPHO....", "..OPPRYYRPPO....", "..OPPRYYRPPO....", "..OHPPRRPPHO....",
		"...OHPPPPHO.....", "....OHHHHO......", "...AL..G..LA....", "..ALLL.G.LLLA...",
		"...LLLG.GLLL....", "......GGG.......", ".......G........", "................"
	]
	var pf3 = parse_hex_grid(p_mature_map, p_mature_lines)
	pf3.save_png("res://assets/sprites/plants/purple_flower_stage_3.png")
	created_files.append("res://assets/sprites/plants/purple_flower_stage_3.png")

	# =========================================================================
	# 2. ORANGE HERB (Red Flower + Yellow Herb)
	# =========================================================================
	# Stage 0: Seed
	var o_seed_map = {
		"D": Color("3a1e0b"), "B": Color("542e13"), "M": Color("6e3d1a"),
		"S": Color("d4b37d"), "E": Color("fb5607") # Amber orange embryo
	}
	var of0 = parse_hex_grid(o_seed_map, seed_lines)
	of0.save_png("res://assets/sprites/plants/orange_herb_stage_0.png")
	created_files.append("res://assets/sprites/plants/orange_herb_stage_0.png")

	# Stage 1: Sprout
	var o_sprout_map = { "G": Color("335c17"), "L": Color("5a9431"), "H": Color("8bc75c"), "D": Color("3a1e0b") }
	var of1 = parse_hex_grid(o_sprout_map, sprout_lines)
	of1.save_png("res://assets/sprites/plants/orange_herb_stage_1.png")
	created_files.append("res://assets/sprites/plants/orange_herb_stage_1.png")

	# Stage 2: Growing Amber Herb
	var o_grow_map = {
		"G": Color("24470f"), "L": Color("477824"), "H": Color("73ab44"),
		"R": Color("9e2a2b"), "B": Color("e85d04"), "K": Color("ffba08")
	}
	var o_grow_lines = [
		"................", "................", "................", "......KKKK......",
		".....KBBBBK.....", ".....RBBBBR.....", "......RKKR......", "...HL..GG..LH...",
		"..HLLL.GG.LLLH..", "..LLLLGGGGLLLL..", "...LLLLGGLLLL...", ".....LLGGLL.....",
		".......GG.......", ".......GG.......", "......GGGG......", "................"
	]
	var of2 = parse_hex_grid(o_grow_map, o_grow_lines)
	of2.save_png("res://assets/sprites/plants/orange_herb_stage_2.png")
	created_files.append("res://assets/sprites/plants/orange_herb_stage_2.png")

	# Stage 3: Mature Sunset Orange Herb Head
	var o_mature_map = {
		"O": Color("6a040f"), "R": Color("dc2f02"), "P": Color("f48c06"), "H": Color("ffba08"),
		"Y": Color("ffe169"), "W": Color("ffffff"), "G": Color("1e3d0c"), "L": Color("3b661d"), "A": Color("649938")
	}
	var o_mature_lines = [
		"................", ".....W...W......", "....OHHHHHO.....", "...OHPPPPPHO....",
		"..OHPPRRRPPHO...", "..OPPRYYYYRPPO..", "..OPPRYYYYRPPO..", "..OHPPRRRPPHO...",
		"...OHPPPPPHO....", "....OHHHHHO.....", "...AL..G..LA....", "..ALLL.G.LLLA...",
		"...LLLG.GLLL....", "......GGG.......", ".......G........", "................"
	]
	var of3 = parse_hex_grid(o_mature_map, o_mature_lines)
	of3.save_png("res://assets/sprites/plants/orange_herb_stage_3.png")
	created_files.append("res://assets/sprites/plants/orange_herb_stage_3.png")

	# =========================================================================
	# 3. GREEN HERB (Blue Flower + Yellow Herb) - Cooling Mint Seafoam Herb
	# =========================================================================
	# Stage 0: Seed
	var g_seed_map = {
		"D": Color("3a1e0b"), "B": Color("542e13"), "M": Color("6e3d1a"),
		"S": Color("d4b37d"), "E": Color("06d6a0") # Seafoam mint embryo
	}
	var gf0 = parse_hex_grid(g_seed_map, seed_lines)
	gf0.save_png("res://assets/sprites/plants/green_herb_stage_0.png")
	created_files.append("res://assets/sprites/plants/green_herb_stage_0.png")

	# Stage 1: Sprout
	var g_sprout_map = { "G": Color("175442"), "L": Color("2a8f72"), "H": Color("57c4a5"), "D": Color("3a1e0b") }
	var gf1 = parse_hex_grid(g_sprout_map, sprout_lines)
	gf1.save_png("res://assets/sprites/plants/green_herb_stage_1.png")
	created_files.append("res://assets/sprites/plants/green_herb_stage_1.png")

	# Stage 2: Growing Mint Shoot
	var g_grow_map = {
		"G": Color("103d30"), "L": Color("1e6e58"), "H": Color("3ab08f"),
		"R": Color("0d5c75"), "B": Color("118ab2"), "K": Color("06d6a0")
	}
	var g_grow_lines = [
		"................", "................", "................", "......KKKK......",
		".....KBBBBK.....", ".....RBBBBR.....", "......RKKR......", "...HL..GG..LH...",
		"..HLLL.GG.LLLH..", "..LLLLGGGGLLLL..", "...LLLLGGLLLL...", ".....LLGGLL.....",
		".......GG.......", ".......GG.......", "......GGGG......", "................"
	]
	var gf2 = parse_hex_grid(g_grow_map, g_grow_lines)
	gf2.save_png("res://assets/sprites/plants/green_herb_stage_2.png")
	created_files.append("res://assets/sprites/plants/green_herb_stage_2.png")

	# Stage 3: Mature Refreshing Seafoam Mint Herb
	var g_mature_map = {
		"O": Color("073b4c"), "R": Color("118ab2"), "P": Color("06d6a0"), "H": Color("70f8d2"),
		"Y": Color("e2fcf4"), "W": Color("ffffff"), "G": Color("0d3327"), "L": Color("195c47"), "A": Color("329e7c")
	}
	var g_mature_lines = [
		"................", ".....W...W......", "....OHHHHHO.....", "...OHPPPPPHO....",
		"..OHPPRRRPPHO...", "..OPPRYYYYRPPO..", "..OPPRYYYYRPPO..", "..OHPPRRRPPHO...",
		"...OHPPPPPHO....", "....OHHHHHO.....", "...AL..G..LA....", "..ALLL.G.LLLA...",
		"...LLLG.GLLL....", "......GGG.......", ".......G........", "................"
	]
	var gf3 = parse_hex_grid(g_mature_map, g_mature_lines)
	gf3.save_png("res://assets/sprites/plants/green_herb_stage_3.png")
	created_files.append("res://assets/sprites/plants/green_herb_stage_3.png")

	# =========================================================================
	# 4. ITEM ICONS (6 ICONS: 3 SEEDS + 3 HARVEST CROPS)
	# =========================================================================
	var pouch_map = {
		"O": Color("241708"), "D": Color("4a2d12"), "M": Color("734820"), "L": Color("a66d33"),
		"T": Color("d4a359"), "W": Color("ffffff")
	}

	for info in [
		{"id": "seed_purple_flower", "col": Color("c77dff")},
		{"id": "seed_orange_herb", "col": Color("f48c06")},
		{"id": "seed_green_herb", "col": Color("06d6a0")}
	]:
		var smap = pouch_map.duplicate()
		smap["E"] = info["col"]
		var pouch_lines = [
			"................", "................", "......OOOO......", ".....OTTTTO.....",
			"....OTEEEEETO...", "...OMEEEEEEEMO..", "..OMEEEEEEEEEEO.", ".OLEEEEEEEEEEEEO",
			".OLEEEEEEEEEEEEO", ".OMEEEEEEEEEEMO.", ".OMMEEEEEEEEMMO.", "..OMMDDDDMMDO...",
			"...ODDDDDDDDO...", "....OOOOOOOO....", "................", "................"
		]
		var pimg = parse_hex_grid(smap, pouch_lines)
		var ppath = "res://assets/sprites/items/%s.png" % info["id"]
		pimg.save_png(ppath)
		created_files.append(ppath)

	# Crop Icons
	var crop_defs = [
		{"id": "purple_flower", "map": p_mature_map, "lines": p_mature_lines},
		{"id": "orange_herb", "map": o_mature_map, "lines": o_mature_lines},
		{"id": "green_herb", "map": g_mature_map, "lines": g_mature_lines}
	]
	for c in crop_defs:
		var cimg = parse_hex_grid(c["map"], c["lines"])
		var cpath = "res://assets/sprites/items/%s.png" % c["id"]
		cimg.save_png(cpath)
		created_files.append(cpath)

	print("[HybridSet1Generator] Successfully generated %d hybrid pixel-art assets!" % created_files.size())
	return created_files
