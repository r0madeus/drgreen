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
	# 1. TILES & VARIATIONS
	# =========================================================================
	var grass_map_1 = {
		".": Color("5b8c36"), ",": Color("49732b"), "'": Color("74aa44"), "x": Color("375720"), "f": Color("f0d756")
	}
	var grass_lines_1 = [
		".,....'.....,...", "...,...........,", ".,....'..f......", "....,....'......",
		"...,.....,...'..", "..'.......,.....", ".....,...x..,...", ".,......xx....'.",
		"....'...,...f...", "..,.........'...", ".....'....,.....", ".,.....,........",
		"...,.....'...,..", ".....f.....,....", "..'..'.......,..", "....,....,......"
	]
	var g1 = parse_hex_grid(grass_map_1, grass_lines_1)
	g1.save_png("res://assets/sprites/tiles/grass.png")
	g1.save_png("res://assets/sprites/tiles/grass_1.png")
	created_files.append("res://assets/sprites/tiles/grass.png")
	created_files.append("res://assets/sprites/tiles/grass_1.png")

	var grass_lines_2 = [
		"....,...........", ".,....'.....,...", "..f.....,...'...", "....,...........",
		".,.....,........", "....'......,....", "...,.....x......", "........xx...f..",
		"..,.....,....'..", "....'...........", ".,.....,....'...", "...,.........,..",
		".....'..f.......", "....,...........", "..f....'.....,..", ".,.........,...."
	]
	var g2 = parse_hex_grid(grass_map_1, grass_lines_2)
	g2.save_png("res://assets/sprites/tiles/grass_2.png")
	created_files.append("res://assets/sprites/tiles/grass_2.png")

	# Soil & Variants
	var soil_map = { "D": Color("3a1e0b"), "B": Color("542e13"), "M": Color("6e3d1a"), "L": Color("8a5025"), "P": Color("996136") }
	var soil_lines_1 = [
		"DDDDDDDDDDDDDDDD", "BBBBBBBBBBBBBBBB", "MMMMMMMMMMMMMMMM", "LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD", "BBBBBBBBBBBBBBBB", "MMMMMMMMMMMMMMMM", "LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD", "BBBBBBBBBBBBBBBB", "MMMMMMMMMMMMMMMM", "LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD", "BBBBBBBBBBBBBBBB", "MMMMMMMMMMMMMMMM", "LLLLLLLLLLLLLLLL"
	]
	var s1 = parse_hex_grid(soil_map, soil_lines_1)
	s1.save_png("res://assets/sprites/tiles/soil.png")
	s1.save_png("res://assets/sprites/tiles/soil_1.png")
	created_files.append("res://assets/sprites/tiles/soil.png")
	created_files.append("res://assets/sprites/tiles/soil_1.png")

	var soil_lines_2 = [
		"DDDDDDDDDDDDDDDD", "BBBBBBBPBBBBBBBB", "MMMMMMMMMMMPMMMM", "LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD", "BBBBBBBBBBBBBBBB", "MMPMMMMMMMMMMMMM", "LLLLLLLLLLPLLLLL",
		"DDDDDDDDDDDDDDDD", "BBBBBBBBBBBBBBBB", "MMMMMMMMMMMMMMMM", "LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD", "BBBPBBBBBBBBBBBB", "MMMMMMMMMMMMMMMM", "LLLLLLLLLLLLLLLL"
	]
	var s2 = parse_hex_grid(soil_map, soil_lines_2)
	s2.save_png("res://assets/sprites/tiles/soil_2.png")
	created_files.append("res://assets/sprites/tiles/soil_2.png")

	# Watered Soil
	var wet_soil_map = { "D": Color("1c0d05"), "B": Color("2d160a"), "M": Color("3f2010"), "L": Color("542e17"), "G": Color("5c7d99") }
	var wet_soil_lines = [
		"DDDDDDDDDDDDDDDD", "BBBBBBBBBBBBBBBB", "MMMMMGMGMMMMMMMM", "LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD", "BBBBBBBBBBBBBBBB", "MMMMMMMMMMMMGMMM", "LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD", "BBBBBBBBBBBBBBBB", "MMMGMMMMMMMMMMMM", "LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD", "BBBBBBBBBBBBBBBB", "MMMMMMMMMMMGMGMM", "LLLLLLLLLLLLLLLL"
	]
	var ws = parse_hex_grid(wet_soil_map, wet_soil_lines)
	ws.save_png("res://assets/sprites/tiles/watered_soil.png")
	created_files.append("res://assets/sprites/tiles/watered_soil.png")

	# Path & Variants
	var path_map = { "X": Color("403a30"), "D": Color("5a5245"), "B": Color("827867"), "M": Color("a69b87"), "L": Color("c9bfac") }
	var path_lines_1 = [
		"XLLMBXLLLLMBXLLM", "XMMMBXMMMMMBXMMM", "XBBBBXBBBBBBXBBB", "XDDDDXDDDDDDXDDD",
		"XXXXXXXXXXXXXXXX", "LLLLLMBXLLLLLLMB", "MMMMMMBXMMMMMMMB", "BBBBBBBXBBBBBBBB",
		"DDDDDDDXDDDDDDDD", "XXXXXXXXXXXXXXXX", "XLLMBXLLLLMBXLLM", "XMMMBXMMMMMBXMMM",
		"XBBBBXBBBBBBXBBB", "XDDDDXDDDDDDXDDD", "XXXXXXXXXXXXXXXX", "LLLLLMBXLLLLLLMB"
	]
	var p1 = parse_hex_grid(path_map, path_lines_1)
	p1.save_png("res://assets/sprites/tiles/path.png")
	p1.save_png("res://assets/sprites/tiles/path_1.png")
	created_files.append("res://assets/sprites/tiles/path.png")
	created_files.append("res://assets/sprites/tiles/path_1.png")

	var path_lines_2 = [
		"LLLLLLMBXLLLLLLM", "MMMMMMMBXMMMMMMM", "BBBBBBBBXBBBBBBB", "DDDDDDDDXDDDDDDD",
		"XXXXXXXXXXXXXXXX", "XLLMBXLLLLLLMBXL", "XMMMBXMMMMMMMBXM", "XBBBBXBBBBBBBBXB",
		"XDDDDXDDDDDDDDXD", "XXXXXXXXXXXXXXXX", "LLLLLLMBXLLLLLLM", "MMMMMMMBXMMMMMMM",
		"BBBBBBBBXBBBBBBB", "DDDDDDDDXDDDDDDD", "XXXXXXXXXXXXXXXX", "XLLMBXLLLLLLMBXL"
	]
	var p2 = parse_hex_grid(path_map, path_lines_2)
	p2.save_png("res://assets/sprites/tiles/path_2.png")
	created_files.append("res://assets/sprites/tiles/path_2.png")

	# Fence
	var fence_map = { ".": Color("49732b"), ",": Color("5b8c36"), "O": Color("261408"), "D": Color("4d2c12"), "M": Color("73441d"), "L": Color("995f2b"), "H": Color("ba7b3c") }
	var fence_lines = [
		"................", "......OOOO......", "......OMMO......", "HHHHHHOMMOHHHHHH",
		"LLLLLLOMMOLLLLLL", "MMMMMMOMMOMMMMMM", "DDDDDDOMMODDDDDD", "......OMMO......",
		"......OMMO......", "HHHHHHOMMOHHHHHH", "LLLLLLOMMOLLLLLL", "MMMMMMOMMOMMMMMM",
		"DDDDDDOMMODDDDDD", "......OMMO......", "......OOOO......", "...,.....,......"
	]
	var fnc = parse_hex_grid(fence_map, fence_lines)
	fnc.save_png("res://assets/sprites/tiles/fence.png")
	created_files.append("res://assets/sprites/tiles/fence.png")

	# =========================================================================
	# 2. ENVIRONMENT PROPS
	# =========================================================================
	# Small Rock
	var rock_map = { "O": Color("2a261f"), "D": Color("4a4337"), "M": Color("6e6556"), "L": Color("968b77"), "H": Color("beb29d"), "S": Color(0,0,0,0.3) }
	var rock_lines = [
		"................", "................", "................", "................",
		"................", "................", "................", ".....OOOO.......",
		"....OHHHMDO.....", "...OHHHMMMDO....", "..OHLLMMMDDDO...", "..OMMMDDDDDDO...",
		".ODDDDDDDDDDDO..", "ODDDDDDDDDDDDDO.", "OSSSSSSSSSSSSSO.", ".SSSSSSSSSSSSS.."
	]
	var rk = parse_hex_grid(rock_map, rock_lines)
	rk.save_png("res://assets/sprites/environment/rock_small.png")
	created_files.append("res://assets/sprites/environment/rock_small.png")

	# Small Bush
	var bush_map = { "O": Color("1a3314"), "D": Color("2b5421"), "M": Color("427d33"), "L": Color("62ab4d"), "H": Color("8fd678"), "S": Color(0,0,0,0.3) }
	var bush_lines = [
		"................", "................", "................", ".....OOOO.......",
		"...OOHHHHOO.....", "..OHHHHHHHHO....", ".OHHHLLLLMMHO...", ".OLLLLLLMMMDO...",
		"OLLLLMMMMMDDDO..", "OMMMMMMDDDDDDO..", "OMMDDDDDDDDDDO..", "ODDDDDDDDDDDDO..",
		".ODDDDDDDDDDDO..", "..ODDDDDDDDDO...", "...SSSSSSSSS....", "....SSSSSSS....."
	]
	var bsh = parse_hex_grid(bush_map, bush_lines)
	bsh.save_png("res://assets/sprites/environment/bush_small.png")
	created_files.append("res://assets/sprites/environment/bush_small.png")

	# Flower Patch
	var flw_map = { "G": Color("356e29"), "L": Color("58a644"), "R": Color("d62f45"), "B": Color("3882e0"), "Y": Color("f5c838"), "W": Color("ffffff") }
	var flw_lines = [
		"................", "................", "................", "................",
		".....WRW........", "....WRRRW.......", ".....WRW..WBYW..", "....G.G..WBYYYW.",
		"....G.G...WBYW..", "..WYYW.....G.G..", ".WYYYYW.WRW.G...", "..WYYW.WRRRW....",
		"...G...GWRW.G...", "..LGL.LGLG.LGL..", ".LGGLLGGGLGGLL..", "................"
	]
	var fp = parse_hex_grid(flw_map, flw_lines)
	fp.save_png("res://assets/sprites/environment/flower_patch.png")
	created_files.append("res://assets/sprites/environment/flower_patch.png")

	# Tree Stump
	var stump_map = { "O": Color("261408"), "D": Color("4d2c12"), "M": Color("73441d"), "L": Color("a66b38"), "R": Color("d4a36e"), "S": Color(0,0,0,0.3) }
	var stump_lines = [
		"................", "................", "................", "................",
		".....OOOOOO.....", "...OORRRRRROO...", "..ORRRMMMMRRO...", "..ORMMLLLLMMRO..",
		"..ORMMLLLLMMRO..", "..ODDMMMMMMDDO..", ".ODDDDDDDDDDDO..", ".ODDDDDDDDDDDO..",
		".ODDDDDDDDDDDO..", "ODDDDDDDDDDDDDO.", "OSSSSSSSSSSSSSO.", ".SSSSSSSSSSSSS.."
	]
	var stmp = parse_hex_grid(stump_map, stump_lines)
	stmp.save_png("res://assets/sprites/environment/tree_stump.png")
	created_files.append("res://assets/sprites/environment/tree_stump.png")

	# Fallen Branch
	var branch_map = { "O": Color("261408"), "D": Color("4d2c12"), "M": Color("73441d"), "L": Color("a66b38"), "G": Color("427d33"), "S": Color(0,0,0,0.3) }
	var branch_lines = [
		"................", "................", "................", "................",
		"................", "................", "................", ".........OO.....",
		"........OLLOO...", ".......OMMMLLO..", "...OOOOOMMMMMO..", "..OLLLLMMMMDDO..",
		".OGGLLMDDDDO....", ".OGGGLLDDO......", "..SSSSSSSS......", "...SSSSSS......."
	]
	var brn = parse_hex_grid(branch_map, branch_lines)
	brn.save_png("res://assets/sprites/environment/fallen_branch.png")
	created_files.append("res://assets/sprites/environment/fallen_branch.png")

	# =========================================================================
	# 3. 5 CORE PLANTS × 4 STAGES (20 SPRITES)
	# =========================================================================

	# Generic Shared Seed (Stage 0) & Sprout (Stage 1)
	var plant_seeds_map = {
		"red": { "E": Color("e8384e"), "S": Color("d4b37d") },
		"blue": { "E": Color("3882e0"), "S": Color("c2d4e8") },
		"yellow": { "E": Color("f5c838"), "S": Color("e8dca2") },
		"green": { "E": Color("32a852"), "S": Color("a9d49f") },
		"white": { "E": Color("f0f5fa"), "S": Color("e1e8ed") }
	}

	for pid in ["red_flower", "blue_flower", "yellow_herb", "green_vine", "white_lily"]:
		var short_k = pid.split("_")[0]
		var seed_map = {
			"D": Color("3a1e0b"), "B": Color("542e13"), "M": Color("6e3d1a"),
			"S": plant_seeds_map[short_k]["S"], "E": plant_seeds_map[short_k]["E"]
		}
		var seed_lines = [
			"................", "................", "................", "................",
			"................", "................", "................", "................",
			".......E........", "......SE........", ".....BSSM.......", "....BMMMMM......",
			"...BMMMMMMD.....", "..DDDDDDDDDD....", "................", "................"
		]
		var simg = parse_hex_grid(seed_map, seed_lines)
		var spath = "res://assets/sprites/plants/%s_stage_0.png" % pid
		simg.save_png(spath)
		created_files.append(spath)

	# --- 1. Red Flower Stages 1, 2, 3 ---
	var red_sprout_map = { "G": Color("2f6b27"), "L": Color("58b83d"), "H": Color("87de66"), "D": Color("3a1e0b") }
	var red_sprout_lines = [
		"................", "................", "................", "................",
		"................", "................", "................", "....HL....LH....",
		"...HLLL..LLLH...", "....LLLGGLLL....", "......GGGG......", ".......GG.......",
		".......GG.......", "......DDDD......", "................", "................"
	]
	var rf1 = parse_hex_grid(red_sprout_map, red_sprout_lines)
	rf1.save_png("res://assets/sprites/plants/red_flower_stage_1.png")
	created_files.append("res://assets/sprites/plants/red_flower_stage_1.png")

	var red_grow_map = { "G": Color("23521d"), "L": Color("429930"), "H": Color("61bd46"), "R": Color("8c1626"), "B": Color("c92a3e"), "K": Color("ff5e73") }
	var red_grow_lines = [
		"................", "................", "................", ".......KK.......",
		"......KBBB......", "......RBBR......", ".......GG.......", "...HL..GG..LH...",
		"..HLLL.GG.LLLH..", "..LLLLGGGGLLLL..", "...LLLLGGLLLL...", ".....LLGGLL.....",
		".......GG.......", ".......GG.......", "......GGGG......", "................"
	]
	var rf2 = parse_hex_grid(red_grow_map, red_grow_lines)
	rf2.save_png("res://assets/sprites/plants/red_flower_stage_2.png")
	created_files.append("res://assets/sprites/plants/red_flower_stage_2.png")

	var red_mature_map = { "O": Color("5e0c17"), "R": Color("b81d32"), "P": Color("e8384e"), "H": Color("ff6b7e"), "Y": Color("ffcc24"), "W": Color("ffffff"), "G": Color("1e4a1a"), "L": Color("358226"), "A": Color("52ab3c") }
	var red_mature_lines = [
		"................", "......W.........", "....OHHHHO......", "...OHPPPPHO.W...",
		"..OHPPRRPPHO....", "..OPPRYYRPPO....", "..OPPRYYRPPO....", "..OHPPRRPPHO....",
		"...OHPPPPHO.....", "....OHHHHO......", "...AL..G..LA....", "..ALLL.G.LLLA...",
		"...LLLG.GLLL....", "......GGG.......", ".......G........", "................"
	]
	var rf3 = parse_hex_grid(red_mature_map, red_mature_lines)
	rf3.save_png("res://assets/sprites/plants/red_flower_stage_3.png")
	created_files.append("res://assets/sprites/plants/red_flower_stage_3.png")

	# --- 2. Blue Flower Stages 1, 2, 3 ---
	var blue_sprout_map = { "G": Color("245e38"), "L": Color("479e60"), "H": Color("76cf92"), "D": Color("3a1e0b") }
	var blue_sprout_lines = red_sprout_lines
	var bf1 = parse_hex_grid(blue_sprout_map, blue_sprout_lines)
	bf1.save_png("res://assets/sprites/plants/blue_flower_stage_1.png")
	created_files.append("res://assets/sprites/plants/blue_flower_stage_1.png")

	var blue_grow_map = { "G": Color("1d4f2f"), "L": Color("388751"), "H": Color("58ab73"), "R": Color("1b4582"), "B": Color("2f6ec4"), "K": Color("5ca2ff") }
	var blue_grow_lines = [
		"................", "................", "................", ".......KK.......",
		"......KBBB......", "......RBBR......", ".......GG.......", "...HL..GG..LH...",
		"..HLLL.GG.LLLH..", "..LLLLGGGGLLLL..", "...LLLLGGLLLL...", ".....LLGGLL.....",
		".......GG.......", ".......GG.......", "......GGGG......", "................"
	]
	var bf2 = parse_hex_grid(blue_grow_map, blue_grow_lines)
	bf2.save_png("res://assets/sprites/plants/blue_flower_stage_2.png")
	created_files.append("res://assets/sprites/plants/blue_flower_stage_2.png")

	var blue_mature_map = { "O": Color("102b54"), "R": Color("2058a6"), "P": Color("3a82e8"), "H": Color("6ea8ff"), "Y": Color("ffe154"), "W": Color("ffffff"), "G": Color("194228"), "L": Color("2f7347"), "A": Color("4ca369") }
	var blue_mature_lines = [
		"................", "......W.........", "....OHHHHO......", "...OHPPPPHO.W...",
		"..OHPPRRPPHO....", "..OPPRYYRPPO....", "..OPPRYYRPPO....", "..OHPPRRPPHO....",
		"...OHPPPPHO.....", "....OHHHHO......", "...AL..G..LA....", "..ALLL.G.LLLA...",
		"...LLLG.GLLL....", "......GGG.......", ".......G........", "................"
	]
	var bf3 = parse_hex_grid(blue_mature_map, blue_mature_lines)
	bf3.save_png("res://assets/sprites/plants/blue_flower_stage_3.png")
	created_files.append("res://assets/sprites/plants/blue_flower_stage_3.png")

	# --- 3. Yellow Herb Stages 1, 2, 3 ---
	var yellow_sprout_map = { "G": Color("38631e"), "L": Color("6aa339"), "H": Color("9cd461"), "D": Color("3a1e0b") }
	var yh1 = parse_hex_grid(yellow_sprout_map, red_sprout_lines)
	yh1.save_png("res://assets/sprites/plants/yellow_herb_stage_1.png")
	created_files.append("res://assets/sprites/plants/yellow_herb_stage_1.png")

	var yellow_grow_map = { "G": Color("2d4f18"), "L": Color("56872b"), "H": Color("82bd48"), "R": Color("a67c11"), "B": Color("e0a719"), "K": Color("ffd954") }
	var yellow_grow_lines = [
		"................", "................", "................", "......KKKK......",
		".....KBBBBK.....", ".....RBBBBR.....", "......RKKR......", "...HL..GG..LH...",
		"..HLLL.GG.LLLH..", "..LLLLGGGGLLLL..", "...LLLLGGLLLL...", ".....LLGGLL.....",
		".......GG.......", ".......GG.......", "......GGGG......", "................"
	]
	var yh2 = parse_hex_grid(yellow_grow_map, yellow_grow_lines)
	yh2.save_png("res://assets/sprites/plants/yellow_herb_stage_2.png")
	created_files.append("res://assets/sprites/plants/yellow_herb_stage_2.png")

	var yellow_mature_map = { "O": Color("594004"), "R": Color("ad7e0c"), "P": Color("e8ab15"), "H": Color("ffd54f"), "Y": Color("ff9900"), "W": Color("ffffff"), "G": Color("244212"), "L": Color("477324"), "A": Color("70a63c") }
	var yellow_mature_lines = [
		"................", ".....W...W......", "....OHHHHHO.....", "...OHPPPPPHO....",
		"..OHPPRRRPPHO...", "..OPPRYYYYRPPO..", "..OPPRYYYYRPPO..", "..OHPPRRRPPHO...",
		"...OHPPPPPHO....", "....OHHHHHO.....", "...AL..G..LA....", "..ALLL.G.LLLA...",
		"...LLLG.GLLL....", "......GGG.......", ".......G........", "................"
	]
	var yh3 = parse_hex_grid(yellow_mature_map, yellow_mature_lines)
	yh3.save_png("res://assets/sprites/plants/yellow_herb_stage_3.png")
	created_files.append("res://assets/sprites/plants/yellow_herb_stage_3.png")

	# --- 4. Green Vine Stages 1, 2, 3 ---
	var vine_sprout_map = { "G": Color("1f4d22"), "L": Color("3b8740"), "H": Color("64bf6b"), "D": Color("3a1e0b") }
	var vine_sprout_lines = [
		"................", "................", "................", "................",
		"................", "................", "................", "..HL............",
		".HLLLG..........", "..LLLG...LH.....", ".....GG.LLLH....", "......GGLLLG....",
		".......GGGG.....", "......DDDD......", "................", "................"
	]
	var gv1 = parse_hex_grid(vine_sprout_map, vine_sprout_lines)
	gv1.save_png("res://assets/sprites/plants/green_vine_stage_1.png")
	created_files.append("res://assets/sprites/plants/green_vine_stage_1.png")

	var vine_grow_map = { "G": Color("183d1a"), "L": Color("2d6b31"), "H": Color("499e50"), "K": Color("71c778"), "D": Color("3a1e0b") }
	var vine_grow_lines = [
		"................", "................", "................", "..........KK....",
		".........KHHG...", "....KK..GHHHLG..", "...KHHGGHLLLG...", "..GHHLLGGGGLLG..",
		"..GHLLLG.GHLLLG.", "...GGGG...GGGG..", ".....GG...GG....", "......GG.GG.....",
		".......GGG......", ".......GGG......", "......DDDD......", "................"
	]
	var gv2 = parse_hex_grid(vine_grow_map, vine_grow_lines)
	gv2.save_png("res://assets/sprites/plants/green_vine_stage_2.png")
	created_files.append("res://assets/sprites/plants/green_vine_stage_2.png")

	var vine_mature_map = { "G": Color("122e14"), "L": Color("225426"), "H": Color("38823d"), "K": Color("58b560"), "W": Color("ffffff"), "B": Color("8ff097") }
	var vine_mature_lines = [
		"................", "..W..........W..", "....BB....BB....", "...BKKG..GKKG...",
		"..BKKHHGGHHHLG..", ".GKKHHLLGGLLLLG.", ".GHHLLLG..GHLLG.", "GLLLLGG....GGGG.",
		".GGGGG.W..W.GG..", "..GG.BKKGGKKG...", "...GG.KHHGGHHLG.", "....GG.HLLG.LLG.",
		".....GGG.GGG....", "......GGG.......", ".......G........", "................"
	]
	var gv3 = parse_hex_grid(vine_mature_map, vine_mature_lines)
	gv3.save_png("res://assets/sprites/plants/green_vine_stage_3.png")
	created_files.append("res://assets/sprites/plants/green_vine_stage_3.png")

	# --- 5. White Lily Stages 1, 2, 3 ---
	var lily_sprout_map = { "G": Color("295932"), "L": Color("4d915b"), "H": Color("7ac78a"), "D": Color("3a1e0b") }
	var wl1 = parse_hex_grid(lily_sprout_map, red_sprout_lines)
	wl1.save_png("res://assets/sprites/plants/white_lily_stage_1.png")
	created_files.append("res://assets/sprites/plants/white_lily_stage_1.png")

	var lily_grow_map = { "G": Color("204727"), "L": Color("3d7549"), "H": Color("60a36e"), "R": Color("8c99a6"), "B": Color("c8d5e3"), "K": Color("f2f7fc") }
	var lily_grow_lines = [
		"................", "................", "................", ".......KK.......",
		"......KBBB......", "......RBBR......", ".......GG.......", "...HL..GG..LH...",
		"..HLLL.GG.LLLH..", "..LLLLGGGGLLLL..", "...LLLLGGLLLL...", ".....LLGGLL.....",
		".......GG.......", ".......GG.......", "......GGGG......", "................"
	]
	var wl2 = parse_hex_grid(lily_grow_map, lily_grow_lines)
	wl2.save_png("res://assets/sprites/plants/white_lily_stage_2.png")
	created_files.append("res://assets/sprites/plants/white_lily_stage_2.png")

	var lily_mature_map = { "O": Color("45525e"), "R": Color("8b9aa8"), "P": Color("cfdbe6"), "H": Color("ffffff"), "Y": Color("ffcc24"), "W": Color("ffffff"), "G": Color("1a3d21"), "L": Color("32693b"), "A": Color("529e5e") }
	var lily_mature_lines = [
		"................", "......W.........", "....OHHHHO......", "...OHPPPPHO.W...",
		"..OHPPRRPPHO....", "..OPPRYYRPPO....", "..OPPRYYRPPO....", "..OHPPRRPPHO....",
		"...OHPPPPHO.....", "....OHHHHO......", "...AL..G..LA....", "..ALLL.G.LLLA...",
		"...LLLG.GLLL....", "......GGG.......", ".......G........", "................"
	]
	var wl3 = parse_hex_grid(lily_mature_map, lily_mature_lines)
	wl3.save_png("res://assets/sprites/plants/white_lily_stage_3.png")
	created_files.append("res://assets/sprites/plants/white_lily_stage_3.png")

	# =========================================================================
	# 4. ITEM ICONS (10 ICONS: 5 SEEDS + 5 HARVEST CROPS)
	# =========================================================================

	# Seed Pouch Template
	var pouch_map = {
		"O": Color("241708"), "D": Color("4a2d12"), "M": Color("734820"), "L": Color("a66d33"),
		"T": Color("d4a359"), "W": Color("ffffff")
	}

	for info in [
		{"id": "seed_red_flower", "col": Color("e8384e")},
		{"id": "seed_blue_flower", "col": Color("3a82e8")},
		{"id": "seed_yellow_herb", "col": Color("e8ab15")},
		{"id": "seed_green_vine", "col": Color("38823d")},
		{"id": "seed_white_lily", "col": Color("e1e8ed")}
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

	# Crop Icons (Red Flower, Blue Flower, Yellow Herb, Green Vine, White Lily)
	var crop_defs = [
		{"id": "red_flower", "map": red_mature_map, "lines": red_mature_lines},
		{"id": "blue_flower", "map": blue_mature_map, "lines": blue_mature_lines},
		{"id": "yellow_herb", "map": yellow_mature_map, "lines": yellow_mature_lines},
		{"id": "green_vine", "map": vine_mature_map, "lines": vine_mature_lines},
		{"id": "white_lily", "map": lily_mature_map, "lines": lily_mature_lines}
	]
	for c in crop_defs:
		var cimg = parse_hex_grid(c["map"], c["lines"])
		var cpath = "res://assets/sprites/items/%s.png" % c["id"]
		cimg.save_png(cpath)
		created_files.append(cpath)

	# =========================================================================
	# 5. PLAYER WALK CYCLES (12 SPRITES)
	# =========================================================================
	var pmap = {
		"S": Color(0, 0, 0, 0.28), "B": Color("c49b3b"), "C": Color("e5bc52"), "H": Color("fce083"),
		"K": Color("692b19"), "F": Color("e39d74"), "I": Color("f7c7af"), "E": Color("1a1824"),
		"J": Color("2e6e4d"), "L": Color("4fa677"), "V": Color("ebe6d8"), "P": Color("2c3954"), "D": Color("472c1b")
	}

	# Down 0, 1, 2
	var p_down_0 = [
		"................", ".....HHHHH......", "....HCCCCCH.....", "....KKKKKKK.....",
		"...BBBBBBBBB....", "....FIFEIEFF....", "....FFFFFFFF....", "....JJLVVLJJ....",
		"....JJLVVLJJ....", "....JJLVVLJJ....", ".....PPPPPP.....", ".....PP..PP.....",
		".....DD..DD.....", "...SSSSSSSSSS...", "....SSSSSSSS....", "................"
	]
	var p_down_1 = [
		"................", ".....HHHHH......", "....HCCCCCH.....", "....KKKKKKK.....",
		"...BBBBBBBBB....", "....FIFEIEFF....", "....FFFFFFFF....", "....JJLVVLJJ....",
		"....JJLVVLJJ....", "....JJLVVLJJ....", ".....PPPPPP.....", "....PPP..PP.....",
		"....DDD...DD....", "...SSSSSSSSSS...", "....SSSSSSSS....", "................"
	]
	var p_down_2 = [
		"................", ".....HHHHH......", "....HCCCCCH.....", "....KKKKKKK.....",
		"...BBBBBBBBB....", "....FIFEIEFF....", "....FFFFFFFF....", "....JJLVVLJJ....",
		"....JJLVVLJJ....", "....JJLVVLJJ....", ".....PPPPPP.....", ".....PP..PPP....",
		".....DD...DDD...", "...SSSSSSSSSS...", "....SSSSSSSS....", "................"
	]

	var pd0 = parse_hex_grid(pmap, p_down_0)
	pd0.save_png("res://assets/sprites/player/player_down.png")
	pd0.save_png("res://assets/sprites/player/player_down_0.png")
	var pd1 = parse_hex_grid(pmap, p_down_1)
	pd1.save_png("res://assets/sprites/player/player_down_1.png")
	var pd2 = parse_hex_grid(pmap, p_down_2)
	pd2.save_png("res://assets/sprites/player/player_down_2.png")
	created_files.append("res://assets/sprites/player/player_down_0.png")
	created_files.append("res://assets/sprites/player/player_down_1.png")
	created_files.append("res://assets/sprites/player/player_down_2.png")

	# Up 0, 1, 2
	var p_up_0 = [
		"................", ".....HHHHH......", "....HCCCCCH.....", "....KKKKKKK.....",
		"...BBBBBBBBB....", "....BBBBBBBB....", "....FFFFFFFF....", "....JJJJJJJJ....",
		"....JJLLLLJJ....", "....JJJJJJJJ....", ".....PPPPPP.....", ".....PP..PP.....",
		".....DD..DD.....", "...SSSSSSSSSS...", "....SSSSSSSS....", "................"
	]
	var p_up_1 = [
		"................", ".....HHHHH......", "....HCCCCCH.....", "....KKKKKKK.....",
		"...BBBBBBBBB....", "....BBBBBBBB....", "....FFFFFFFF....", "....JJJJJJJJ....",
		"....JJLLLLJJ....", "....JJJJJJJJ....", ".....PPPPPP.....", "....PPP..PP.....",
		"....DDD...DD....", "...SSSSSSSSSS...", "....SSSSSSSS....", "................"
	]
	var p_up_2 = [
		"................", ".....HHHHH......", "....HCCCCCH.....", "....KKKKKKK.....",
		"...BBBBBBBBB....", "....BBBBBBBB....", "....FFFFFFFF....", "....JJJJJJJJ....",
		"....JJLLLLJJ....", "....JJJJJJJJ....", ".....PPPPPP.....", ".....PP..PPP....",
		".....DD...DDD...", "...SSSSSSSSSS...", "....SSSSSSSS....", "................"
	]
	var pu0 = parse_hex_grid(pmap, p_up_0)
	pu0.save_png("res://assets/sprites/player/player_up.png")
	pu0.save_png("res://assets/sprites/player/player_up_0.png")
	var pu1 = parse_hex_grid(pmap, p_up_1)
	pu1.save_png("res://assets/sprites/player/player_up_1.png")
	var pu2 = parse_hex_grid(pmap, p_up_2)
	pu2.save_png("res://assets/sprites/player/player_up_2.png")
	created_files.append("res://assets/sprites/player/player_up_0.png")
	created_files.append("res://assets/sprites/player/player_up_1.png")
	created_files.append("res://assets/sprites/player/player_up_2.png")

	# Left 0, 1, 2
	var p_left_0 = [
		"................", "....HHHHH.......", "...HCCCCCH......", "...KKKKKKK......",
		"..BBBBBBBBB.....", "...FEFFFFF......", "...FFFFFFF......", "...JJLVVJJ......",
		"...JJLVVJJ......", "...JJLVVJJ......", "....PPPPPP......", "....PP..PP......",
		"....DD..DD......", "..SSSSSSSSSS....", "...SSSSSSSS.....", "................"
	]
	var p_left_1 = [
		"................", "....HHHHH.......", "...HCCCCCH......", "...KKKKKKK......",
		"..BBBBBBBBB.....", "...FEFFFFF......", "...FFFFFFF......", "...JJLVVJJ......",
		"...JJLVVJJ......", "...JJLVVJJ......", "....PPPPPP......", "...PPP..PP......",
		"...DDD...DD.....", "..SSSSSSSSSS....", "...SSSSSSSS.....", "................"
	]
	var p_left_2 = [
		"................", "....HHHHH.......", "...HCCCCCH......", "...KKKKKKK......",
		"..BBBBBBBBB.....", "...FEFFFFF......", "...FFFFFFF......", "...JJLVVJJ......",
		"...JJLVVJJ......", "...JJLVVJJ......", "....PPPPPP......", "....PP..PPP.....",
		"....DD...DDD....", "..SSSSSSSSSS....", "...SSSSSSSS.....", "................"
	]
	var pl0 = parse_hex_grid(pmap, p_left_0)
	pl0.save_png("res://assets/sprites/player/player_left.png")
	pl0.save_png("res://assets/sprites/player/player_left_0.png")
	var pl1 = parse_hex_grid(pmap, p_left_1)
	pl1.save_png("res://assets/sprites/player/player_left_1.png")
	var pl2 = parse_hex_grid(pmap, p_left_2)
	pl2.save_png("res://assets/sprites/player/player_left_2.png")
	created_files.append("res://assets/sprites/player/player_left_0.png")
	created_files.append("res://assets/sprites/player/player_left_1.png")
	created_files.append("res://assets/sprites/player/player_left_2.png")

	# Right 0, 1, 2
	var p_right_0 = [
		"................", ".......HHHHH....", "......HCCCCCH...", "......KKKKKKK...",
		".....BBBBBBBBB..", "......FFFFFEF...", "......FFFFFFF...", "......JJVVLJJ...",
		"......JJVVLJJ...", "......JJVVLJJ...", "......PPPPPP....", "......PP..PP....",
		"......DD..DD....", "....SSSSSSSSSS..", ".....SSSSSSSS...", "................"
	]
	var p_right_1 = [
		"................", ".......HHHHH....", "......HCCCCCH...", "......KKKKKKK...",
		".....BBBBBBBBB..", "......FFFFFEF...", "......FFFFFFF...", "......JJVVLJJ...",
		"......JJVVLJJ...", "......JJVVLJJ...", "......PPPPPP....", ".....PPP..PP....",
		".....DDD...DD...", "....SSSSSSSSSS..", ".....SSSSSSSS...", "................"
	]
	var p_right_2 = [
		"................", ".......HHHHH....", "......HCCCCCH...", "......KKKKKKK...",
		".....BBBBBBBBB..", "......FFFFFEF...", "......FFFFFFF...", "......JJVVLJJ...",
		"......JJVVLJJ...", "......JJVVLJJ...", "......PPPPPP....", "......PP..PPP...",
		"......DD...DDD..", "....SSSSSSSSSS..", ".....SSSSSSSS...", "................"
	]
	var pr0 = parse_hex_grid(pmap, p_right_0)
	pr0.save_png("res://assets/sprites/player/player_right.png")
	pr0.save_png("res://assets/sprites/player/player_right_0.png")
	var pr1 = parse_hex_grid(pmap, p_right_1)
	pr1.save_png("res://assets/sprites/player/player_right_1.png")
	var pr2 = parse_hex_grid(pmap, p_right_2)
	pr2.save_png("res://assets/sprites/player/player_right_2.png")
	created_files.append("res://assets/sprites/player/player_right_0.png")
	created_files.append("res://assets/sprites/player/player_right_1.png")
	created_files.append("res://assets/sprites/player/player_right_2.png")

	print("[CoreAssetGenerator] Successfully generated %d core pixel-art assets!" % created_files.size())
	return created_files
