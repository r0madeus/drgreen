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

	# ----------------------------------------------------
	# 1. TILES
	# ----------------------------------------------------
	var grass_map = {
		".": Color("5b8c36"),
		",": Color("49732b"),
		"'": Color("74aa44"),
		"x": Color("375720"),
		"f": Color("f0d756")
	}
	var grass_lines = [
		".,....'.....,...",
		"...,...........,",
		".,....'..f......",
		"....,....'......",
		"...,.....,...'..",
		"..'.......,.....",
		".....,...x..,...",
		".,......xx....'.",
		"....'...,...f...",
		"..,.........'...",
		".....'....,.....",
		".,.....,........",
		"...,.....'...,..",
		".....f.....,....",
		"..'..'.......,..",
		"....,....,......"
	]
	var grass_img = parse_hex_grid(grass_map, grass_lines)
	grass_img.save_png("res://assets/sprites/tiles/grass.png")
	created_files.append("res://assets/sprites/tiles/grass.png")

	var soil_map = {
		"D": Color("3a1e0b"),
		"B": Color("542e13"),
		"M": Color("6e3d1a"),
		"L": Color("8a5025")
	}
	var soil_lines = [
		"DDDDDDDDDDDDDDDD",
		"BBBBBBBBBBBBBBBB",
		"MMMMMMMMMMMMMMMM",
		"LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD",
		"BBBBBBBBBBBBBBBB",
		"MMMMMMMMMMMMMMMM",
		"LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD",
		"BBBBBBBBBBBBBBBB",
		"MMMMMMMMMMMMMMMM",
		"LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD",
		"BBBBBBBBBBBBBBBB",
		"MMMMMMMMMMMMMMMM",
		"LLLLLLLLLLLLLLLL"
	]
	var soil_img = parse_hex_grid(soil_map, soil_lines)
	soil_img.save_png("res://assets/sprites/tiles/soil.png")
	created_files.append("res://assets/sprites/tiles/soil.png")

	var wet_soil_map = {
		"D": Color("1c0d05"),
		"B": Color("2d160a"),
		"M": Color("3f2010"),
		"L": Color("542e17"),
		"G": Color("5c7d99")
	}
	var wet_soil_lines = [
		"DDDDDDDDDDDDDDDD",
		"BBBBBBBBBBBBBBBB",
		"MMMMMGMGMMMMMMMM",
		"LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD",
		"BBBBBBBBBBBBBBBB",
		"MMMMMMMMMMMMGMMM",
		"LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD",
		"BBBBBBBBBBBBBBBB",
		"MMMGMMMMMMMMMMMM",
		"LLLLLLLLLLLLLLLL",
		"DDDDDDDDDDDDDDDD",
		"BBBBBBBBBBBBBBBB",
		"MMMMMMMMMMMGMGMM",
		"LLLLLLLLLLLLLLLL"
	]
	var wet_soil_img = parse_hex_grid(wet_soil_map, wet_soil_lines)
	wet_soil_img.save_png("res://assets/sprites/tiles/watered_soil.png")
	created_files.append("res://assets/sprites/tiles/watered_soil.png")

	var path_map = {
		"X": Color("403a30"),
		"D": Color("5a5245"),
		"B": Color("827867"),
		"M": Color("a69b87"),
		"L": Color("c9bfac")
	}
	var path_lines = [
		"XLLMBXLLLLMBXLLM",
		"XMMMBXMMMMMBXMMM",
		"XBBBBXBBBBBBXBBB",
		"XDDDDXDDDDDDXDDD",
		"XXXXXXXXXXXXXXXX",
		"LLLLLMBXLLLLLLMB",
		"MMMMMMBXMMMMMMMB",
		"BBBBBBBXBBBBBBBB",
		"DDDDDDDXDDDDDDDD",
		"XXXXXXXXXXXXXXXX",
		"XLLMBXLLLLMBXLLM",
		"XMMMBXMMMMMBXMMM",
		"XBBBBXBBBBBBXBBB",
		"XDDDDXDDDDDDXDDD",
		"XXXXXXXXXXXXXXXX",
		"LLLLLMBXLLLLLLMB"
	]
	var path_img = parse_hex_grid(path_map, path_lines)
	path_img.save_png("res://assets/sprites/tiles/path.png")
	created_files.append("res://assets/sprites/tiles/path.png")

	var fence_map = {
		".": Color("49732b"),
		",": Color("5b8c36"),
		"O": Color("261408"),
		"D": Color("4d2c12"),
		"M": Color("73441d"),
		"L": Color("995f2b"),
		"H": Color("ba7b3c")
	}
	var fence_lines = [
		"................",
		"......OOOO......",
		"......OMMO......",
		"HHHHHHOMMOHHHHHH",
		"LLLLLLOMMOLLLLLL",
		"MMMMMMOMMOMMMMMM",
		"DDDDDDOMMODDDDDD",
		"......OMMO......",
		"......OMMO......",
		"HHHHHHOMMOHHHHHH",
		"LLLLLLOMMOLLLLLL",
		"MMMMMMOMMOMMMMMM",
		"DDDDDDOMMODDDDDD",
		"......OMMO......",
		"......OOOO......",
		"...,.....,......"
	]
	var fence_img = parse_hex_grid(fence_map, fence_lines)
	fence_img.save_png("res://assets/sprites/tiles/fence.png")
	created_files.append("res://assets/sprites/tiles/fence.png")

	# ----------------------------------------------------
	# 2. PLANT: RED FLOWER (4 STAGES)
	# ----------------------------------------------------
	var seed_map = {
		"D": Color("3a1e0b"),
		"B": Color("542e13"),
		"M": Color("6e3d1a"),
		"S": Color("d4b37d"),
		"E": Color("85d65c")
	}
	var seed_lines = [
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		".......E........",
		"......SE........",
		".....BSSM.......",
		"....BMMMMM......",
		"...BMMMMMMD.....",
		"..DDDDDDDDDD....",
		"................",
		"................"
	]
	var seed_img = parse_hex_grid(seed_map, seed_lines)
	seed_img.save_png("res://assets/sprites/plants/red_flower_stage_0.png")
	created_files.append("res://assets/sprites/plants/red_flower_stage_0.png")

	var sprout_map = {
		"G": Color("2f6b27"),
		"L": Color("58b83d"),
		"H": Color("87de66"),
		"D": Color("3a1e0b")
	}
	var sprout_lines = [
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"....HL....LH....",
		"...HLLL..LLLH...",
		"....LLLGGLLL....",
		"......GGGG......",
		".......GG.......",
		".......GG.......",
		"......DDDD......",
		"................",
		"................"
	]
	var sprout_img = parse_hex_grid(sprout_map, sprout_lines)
	sprout_img.save_png("res://assets/sprites/plants/red_flower_stage_1.png")
	created_files.append("res://assets/sprites/plants/red_flower_stage_1.png")

	var grow_map = {
		"G": Color("23521d"),
		"L": Color("429930"),
		"H": Color("61bd46"),
		"R": Color("8c1626"),
		"B": Color("c92a3e"),
		"K": Color("ff5e73")
	}
	var grow_lines = [
		"................",
		"................",
		"................",
		".......KK.......",
		"......KBBB......",
		"......RBBR......",
		".......GG.......",
		"...HL..GG..LH...",
		"..HLLL.GG.LLLH..",
		"..LLLLGGGGLLLL..",
		"...LLLLGGLLLL...",
		".....LLGGLL.....",
		".......GG.......",
		".......GG.......",
		"......GGGG......",
		"................"
	]
	var grow_img = parse_hex_grid(grow_map, grow_lines)
	grow_img.save_png("res://assets/sprites/plants/red_flower_stage_2.png")
	created_files.append("res://assets/sprites/plants/red_flower_stage_2.png")

	var mature_map = {
		"O": Color("5e0c17"),
		"R": Color("b81d32"),
		"P": Color("e8384e"),
		"H": Color("ff6b7e"),
		"Y": Color("ffcc24"),
		"C": Color("fff07a"),
		"W": Color("ffffff"),
		"G": Color("1e4a1a"),
		"L": Color("358226"),
		"A": Color("52ab3c")
	}
	var mature_lines = [
		"................",
		"......W.........",
		"....OHHHHO......",
		"...OHPPPPHO.W...",
		"..OHPPRRPPHO....",
		"..OPPRYYRPPO....",
		"..OPPRYYRPPO....",
		"..OHPPRRPPHO....",
		"...OHPPPPHO.....",
		"....OHHHHO......",
		"...AL..G..LA....",
		"..ALLL.G.LLLA...",
		"...LLLG.GLLL....",
		"......GGG.......",
		".......G........",
		"................"
	]
	var mature_img = parse_hex_grid(mature_map, mature_lines)
	mature_img.save_png("res://assets/sprites/plants/red_flower_stage_3.png")
	created_files.append("res://assets/sprites/plants/red_flower_stage_3.png")

	# ----------------------------------------------------
	# 3. PLAYER (4 DIRECTIONS)
	# ----------------------------------------------------
	var player_map = {
		"S": Color(0, 0, 0, 0.28),
		"B": Color("c49b3b"),
		"C": Color("e5bc52"),
		"H": Color("fce083"),
		"K": Color("692b19"),
		"F": Color("e39d74"),
		"I": Color("f7c7af"),
		"E": Color("1a1824"),
		"J": Color("2e6e4d"),
		"L": Color("4fa677"),
		"V": Color("ebe6d8"),
		"P": Color("2c3954"),
		"D": Color("472c1b")
	}

	var p_down = [
		"................",
		".....HHHHH......",
		"....HCCCCCH.....",
		"....KKKKKKK.....",
		"...BBBBBBBBB....",
		"....FIFEIEFF....",
		"....FFFFFFFF....",
		"....JJLVVLJJ....",
		"....JJLVVLJJ....",
		"....JJLVVLJJ....",
		".....PPPPPP.....",
		".....PP..PP.....",
		".....DD..DD.....",
		"...SSSSSSSSSS...",
		"....SSSSSSSS....",
		"................"
	]
	var p_down_img = parse_hex_grid(player_map, p_down)
	p_down_img.save_png("res://assets/sprites/player/player_down.png")
	created_files.append("res://assets/sprites/player/player_down.png")

	var p_up = [
		"................",
		".....HHHHH......",
		"....HCCCCCH.....",
		"....KKKKKKK.....",
		"...BBBBBBBBB....",
		"....BBBBBBBB....",
		"....FFFFFFFF....",
		"....JJJJJJJJ....",
		"....JJLLLLJJ....",
		"....JJJJJJJJ....",
		".....PPPPPP.....",
		".....PP..PP.....",
		".....DD..DD.....",
		"...SSSSSSSSSS...",
		"....SSSSSSSS....",
		"................"
	]
	var p_up_img = parse_hex_grid(player_map, p_up)
	p_up_img.save_png("res://assets/sprites/player/player_up.png")
	created_files.append("res://assets/sprites/player/player_up.png")

	var p_left = [
		"................",
		"....HHHHH.......",
		"...HCCCCCH......",
		"...KKKKKKK......",
		"..BBBBBBBBB.....",
		"...FEFFFFF......",
		"...FFFFFFF......",
		"...JJLVVJJ......",
		"...JJLVVJJ......",
		"...JJLVVJJ......",
		"....PPPPPP......",
		"....PP..PP......",
		"....DD..DD......",
		"..SSSSSSSSSS....",
		"...SSSSSSSS.....",
		"................"
	]
	var p_left_img = parse_hex_grid(player_map, p_left)
	p_left_img.save_png("res://assets/sprites/player/player_left.png")
	created_files.append("res://assets/sprites/player/player_left.png")

	var p_right = [
		"................",
		".......HHHHH....",
		"......HCCCCCH...",
		"......KKKKKKK...",
		".....BBBBBBBBB..",
		"......FFFFFEF...",
		"......FFFFFFF...",
		"......JJVVLJJ...",
		"......JJVVLJJ...",
		"......JJVVLJJ...",
		"......PPPPPP....",
		"......PP..PP....",
		"......DD..DD....",
		"....SSSSSSSSSS..",
		".....SSSSSSSS...",
		"................"
	]
	var p_right_img = parse_hex_grid(player_map, p_right)
	p_right_img.save_png("res://assets/sprites/player/player_right.png")
	created_files.append("res://assets/sprites/player/player_right.png")

	print("[SpriteGenerator] Successfully created %d pixel-art prototype PNG sprites!" % created_files.size())
	return created_files
