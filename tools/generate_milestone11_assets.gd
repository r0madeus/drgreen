@tool
extends SceneTree

func _init() -> void:
	generate_all()
	quit()

static func write_wav_file(path: String, samples: PackedFloat32Array, sample_rate: int = 22050) -> void:
	var num_samples = samples.size()
	var byte_rate = sample_rate * 2
	var block_align = 2
	var bits_per_sample = 16
	var data_size = num_samples * 2
	var chunk_size = 36 + data_size

	var bytes = PackedByteArray()
	bytes.resize(44 + data_size)

	# RIFF Header
	bytes.set(0, 0x52); bytes.set(1, 0x49); bytes.set(2, 0x46); bytes.set(3, 0x46) # "RIFF"
	bytes.encode_u32(4, chunk_size)
	bytes.set(8, 0x57); bytes.set(9, 0x41); bytes.set(10, 0x56); bytes.set(11, 0x45) # "WAVE"

	# "fmt " chunk
	bytes.set(12, 0x66); bytes.set(13, 0x6d); bytes.set(14, 0x74); bytes.set(15, 0x20) # "fmt "
	bytes.encode_u32(16, 16)
	bytes.encode_u16(20, 1)
	bytes.encode_u16(22, 1)
	bytes.encode_u32(24, sample_rate)
	bytes.encode_u32(28, byte_rate)
	bytes.encode_u16(32, block_align)
	bytes.encode_u16(34, bits_per_sample)

	# "data" chunk
	bytes.set(36, 0x64); bytes.set(37, 0x61); bytes.set(38, 0x74); bytes.set(39, 0x61) # "data"
	bytes.encode_u32(40, data_size)

	for i in range(num_samples):
		var s = clampf(samples[i], -1.0, 1.0)
		var val = int(s * 32767.0)
		bytes.encode_s16(44 + i * 2, val)

	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_buffer(bytes)
		f.close()

static func generate_all() -> Array:
	var list = []
	var sr = 22050

	# 1. SFX: greenhouse_repair.wav
	var repair_samples = PackedFloat32Array()
	var r_len = int(sr * 0.5)
	for i in range(r_len):
		var t = float(i) / sr
		var env = exp(-t * 6.0)
		var freq = 440.0 if t < 0.1 else (659.25 if t < 0.2 else (880.0 if t < 0.3 else 1318.5))
		var s = (sin(TAU * freq * t) * 0.5 + sin(TAU * freq * 2.0 * t) * 0.3) * env
		repair_samples.append(s)
	write_wav_file("res://assets/audio/sfx/greenhouse_repair.wav", repair_samples, sr)
	list.append("res://assets/audio/sfx/greenhouse_repair.wav")

	# 2. SFX: gate_open.wav
	var gate_samples = PackedFloat32Array()
	var g_len = int(sr * 0.25)
	for i in range(g_len):
		var t = float(i) / sr
		var env = exp(-t * 10.0)
		var s = (sin(TAU * (220.0 + t * 150.0) * t) * 0.4 + sin(TAU * 110.0 * t) * 0.3) * env
		gate_samples.append(s)
	write_wav_file("res://assets/audio/sfx/gate_open.wav", gate_samples, sr)
	list.append("res://assets/audio/sfx/gate_open.wav")

	# Plants specs: 8 species
	var plant_defs = [
		{ "id": "moon_orchid", "main": Color("b8c0ff"), "accent": Color("e7c6ff"), "stem": Color("4a7c59") },
		{ "id": "glass_fern", "main": Color("c8e7ff"), "accent": Color("a0c4ff"), "stem": Color("38b000") },
		{ "id": "star_moss", "main": Color("fdffb6"), "accent": Color("caffbf"), "stem": Color("70e000") },
		{ "id": "lunar_bloom", "main": Color("d0d1ff"), "accent": Color("7073e8"), "stem": Color("2d6a4f") },
		{ "id": "crystal_fern", "main": Color("9bf6ff"), "accent": Color("a0c4ff"), "stem": Color("0077b6") },
		{ "id": "astral_moss", "main": Color("5a189a"), "accent": Color("7b2cbf"), "stem": Color("3c096c") },
		{ "id": "twilight_orchid", "main": Color("9d4edd"), "accent": Color("c77dff"), "stem": Color("5a189a") },
		{ "id": "solar_moss", "main": Color("ffb703"), "accent": Color("fb8500"), "stem": Color("d48b00") }
	]

	for p in plant_defs:
		var pid = p["id"]
		var c_main: Color = p["main"]
		var c_acc: Color = p["accent"]
		var c_stem: Color = p["stem"]
		var c_soil = Color("4a2810")

		# Stage 0: Sprout in mound
		var s0 = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		s0.fill(Color(0, 0, 0, 0))
		for x in range(5, 11): s0.set_pixel(x, 14, c_soil)
		for x in range(6, 10): s0.set_pixel(x, 13, c_soil)
		s0.set_pixel(7, 12, c_stem); s0.set_pixel(8, 12, c_stem)
		s0.set_pixel(7, 11, c_main); s0.set_pixel(8, 11, c_acc)
		var p0_path = "res://assets/sprites/plants/%s_stage_0.png" % pid
		s0.save_png(p0_path); list.append(p0_path)

		# Stage 1: Small growing seedling
		var s1 = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		s1.fill(Color(0, 0, 0, 0))
		for y in range(10, 15):
			s1.set_pixel(7, y, c_stem); s1.set_pixel(8, y, c_stem)
		s1.set_pixel(6, 11, c_stem); s1.set_pixel(9, 11, c_stem)
		s1.set_pixel(5, 10, c_main); s1.set_pixel(10, 10, c_acc)
		s1.set_pixel(7, 9, c_main); s1.set_pixel(8, 9, c_main)
		var p1_path = "res://assets/sprites/plants/%s_stage_1.png" % pid
		s1.save_png(p1_path); list.append(p1_path)

		# Stage 2: Budding plant
		var s2 = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		s2.fill(Color(0, 0, 0, 0))
		for y in range(7, 15):
			s2.set_pixel(7, y, c_stem); s2.set_pixel(8, y, c_stem)
		s2.set_pixel(5, 10, c_stem); s2.set_pixel(6, 9, c_stem)
		s2.set_pixel(9, 10, c_stem); s2.set_pixel(10, 9, c_stem)
		for y in range(5, 8):
			for x in range(6, 10):
				s2.set_pixel(x, y, c_main)
		s2.set_pixel(7, 6, c_acc); s2.set_pixel(8, 6, c_acc)
		var p2_path = "res://assets/sprites/plants/%s_stage_2.png" % pid
		s2.save_png(p2_path); list.append(p2_path)

		# Stage 3: Fully mature blooming flora
		var s3 = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		s3.fill(Color(0, 0, 0, 0))
		for y in range(6, 15):
			s3.set_pixel(7, y, c_stem); s3.set_pixel(8, y, c_stem)
		s3.set_pixel(4, 11, c_stem); s3.set_pixel(5, 10, c_stem)
		s3.set_pixel(10, 10, c_stem); s3.set_pixel(11, 11, c_stem)
		for y in range(3, 8):
			for x in range(5, 11):
				s3.set_pixel(x, y, c_main)
		for y in range(4, 7):
			for x in range(6, 10):
				s3.set_pixel(x, y, c_acc)
		s3.set_pixel(7, 5, Color.WHITE); s3.set_pixel(8, 5, Color.WHITE)
		var p3_path = "res://assets/sprites/plants/%s_stage_3.png" % pid
		s3.save_png(p3_path); list.append(p3_path)

		# Seed pouch icon
		var seed_img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		seed_img.fill(Color(0, 0, 0, 0))
		var pouch_c = Color("8c5e37")
		var tie_c = Color("d4a359")
		for y in range(6, 14):
			for x in range(4, 12):
				seed_img.set_pixel(x, y, pouch_c)
		for x in range(5, 11):
			seed_img.set_pixel(x, 6, tie_c)
		seed_img.set_pixel(7, 9, c_main); seed_img.set_pixel(8, 9, c_acc)
		seed_img.set_pixel(7, 10, c_main); seed_img.set_pixel(8, 10, c_acc)
		var s_path = "res://assets/sprites/items/seed_%s.png" % pid
		seed_img.save_png(s_path); list.append(s_path)

		# Crop harvest icon
		var crop_img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		crop_img.fill(Color(0, 0, 0, 0))
		for y in range(4, 12):
			for x in range(4, 12):
				crop_img.set_pixel(x, y, c_main)
		for y in range(5, 11):
			for x in range(5, 11):
				crop_img.set_pixel(x, y, c_acc)
		crop_img.set_pixel(7, 7, Color.WHITE); crop_img.set_pixel(8, 7, Color.WHITE)
		crop_img.set_pixel(7, 13, c_stem); crop_img.set_pixel(8, 13, c_stem)
		var c_path = "res://assets/sprites/items/%s.png" % pid
		crop_img.save_png(c_path); list.append(c_path)

	# 3. Environment: greenhouse_ruined.png (32x32)
	var g_ruined = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	g_ruined.fill(Color(0, 0, 0, 0))
	var wood_dark = Color("382214")
	var wood_med = Color("5e3c23")
	var moss = Color("4b6043")
	var broken_glass = Color(0.4, 0.6, 0.7, 0.4)
	# Frame
	for y in range(4, 28):
		for x in range(4, 28):
			if x == 4 or x == 27 or y == 4 or y == 27 or x == 15 or x == 16:
				g_ruined.set_pixel(x, y, wood_dark)
			elif (x + y) % 5 == 0:
				g_ruined.set_pixel(x, y, broken_glass)
			elif (x * y) % 7 == 0:
				g_ruined.set_pixel(x, y, moss)
	# Roof peak
	for i in range(12):
		g_ruined.set_pixel(4 + i, 4 - i / 3, wood_med)
		g_ruined.set_pixel(27 - i, 4 - i / 3, wood_med)
	g_ruined.save_png("res://assets/sprites/environment/greenhouse_ruined.png")
	list.append("res://assets/sprites/environment/greenhouse_ruined.png")

	# 4. Environment: greenhouse_repaired.png (32x32)
	var g_rep = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	g_rep.fill(Color(0, 0, 0, 0))
	var glass_clean = Color("80bfff")
	var glass_shine = Color(0.9, 0.95, 1.0, 0.8)
	var wood_clean = Color("7f4f24")
	for y in range(4, 28):
		for x in range(4, 28):
			if x == 4 or x == 27 or y == 4 or y == 27 or x == 15 or x == 16 or y == 16:
				g_rep.set_pixel(x, y, wood_clean)
			else:
				g_rep.set_pixel(x, y, glass_clean)
				if (x - y) == 2 or (x - y) == 3:
					g_rep.set_pixel(x, y, glass_shine)
	for i in range(12):
		g_rep.set_pixel(4 + i, 4 - i / 3, wood_clean)
		g_rep.set_pixel(27 - i, 4 - i / 3, wood_clean)
	g_rep.save_png("res://assets/sprites/environment/greenhouse_repaired.png")
	list.append("res://assets/sprites/environment/greenhouse_repaired.png")

	# 5. Environment: wooden_gate.png (16x16)
	var gate = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	gate.fill(Color(0, 0, 0, 0))
	for y in range(2, 15):
		gate.set_pixel(2, y, wood_clean); gate.set_pixel(3, y, wood_clean)
		gate.set_pixel(12, y, wood_clean); gate.set_pixel(13, y, wood_clean)
	for x in range(2, 14):
		gate.set_pixel(x, 2, wood_clean); gate.set_pixel(x, 3, wood_clean)
		gate.set_pixel(x, 9, wood_med)
	gate.save_png("res://assets/sprites/environment/wooden_gate.png")
	list.append("res://assets/sprites/environment/wooden_gate.png")

	print("[Milestone11AssetGenerator] Generated %d plant and environment assets!" % list.size())
	return list
