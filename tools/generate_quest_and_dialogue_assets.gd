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

	# Samples (16-bit PCM)
	for i in range(num_samples):
		var s = clampf(samples[i], -1.0, 1.0)
		var val = int(s * 32767.0)
		bytes.encode_s16(44 + i * 2, val)

	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_buffer(bytes)
		f.close()

static func generate_all() -> Array:
	var created_files = []
	var sr = 22050

	# 1. dialogue_open.wav
	var d_open = PackedFloat32Array()
	var d_open_len = int(sr * 0.15)
	for i in range(d_open_len):
		var t = float(i) / sr
		var env = exp(-t * 22.0)
		var s = (sin(TAU * 523.25 * t) * 0.4 + sin(TAU * 659.25 * t) * 0.4) * env
		d_open.append(s)
	write_wav_file("res://assets/audio/sfx/dialogue_open.wav", d_open, sr)
	created_files.append("res://assets/audio/sfx/dialogue_open.wav")

	# 2. dialogue_next.wav
	var d_next = PackedFloat32Array()
	var d_next_len = int(sr * 0.08)
	for i in range(d_next_len):
		var t = float(i) / sr
		var env = exp(-t * 40.0)
		var s = sin(TAU * 880.0 * t) * env * 0.4
		d_next.append(s)
	write_wav_file("res://assets/audio/sfx/dialogue_next.wav", d_next, sr)
	created_files.append("res://assets/audio/sfx/dialogue_next.wav")

	# 3. quest_accept.wav
	var q_acc = PackedFloat32Array()
	var q_acc_len = int(sr * 0.25)
	for i in range(q_acc_len):
		var t = float(i) / sr
		var env = exp(-t * 12.0)
		var freq = 440.0 if t < 0.08 else (554.37 if t < 0.16 else 659.25)
		var s = sin(TAU * freq * t) * env * 0.5
		q_acc.append(s)
	write_wav_file("res://assets/audio/sfx/quest_accept.wav", q_acc, sr)
	created_files.append("res://assets/audio/sfx/quest_accept.wav")

	# 4. quest_complete.wav
	var q_comp = PackedFloat32Array()
	var q_comp_len = int(sr * 0.45)
	for i in range(q_comp_len):
		var t = float(i) / sr
		var env = exp(-t * 7.0)
		var freq = 523.25 # C5
		if t >= 0.1 and t < 0.2: freq = 659.25 # E5
		elif t >= 0.2 and t < 0.3: freq = 783.99 # G5
		elif t >= 0.3: freq = 1046.50 # C6
		var s = (sin(TAU * freq * t) * 0.6 + sin(TAU * freq * 2.0 * t) * 0.2) * env
		q_comp.append(s)
	write_wav_file("res://assets/audio/sfx/quest_complete.wav", q_comp, sr)
	created_files.append("res://assets/audio/sfx/quest_complete.wav")

	# 5. reward.wav
	var rew = PackedFloat32Array()
	var rew_len = int(sr * 0.35)
	for i in range(rew_len):
		var t = float(i) / sr
		var env = exp(-t * 9.0)
		var s = (sin(TAU * 1318.5 * t) * 0.4 + sin(TAU * 1760.0 * t) * 0.4 + sin(TAU * 2093.0 * t) * 0.3) * env
		rew.append(s)
	write_wav_file("res://assets/audio/sfx/reward.wav", rew, sr)
	created_files.append("res://assets/audio/sfx/reward.wav")

	# 6. 32x32 Portrait of Rowan the Herbalist (merchant_portrait.png)
	var p_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	p_img.fill(Color(0, 0, 0, 0))

	var pmap = {
		"B": Color("241708"), # Deep Outline
		"H": Color("4a7c59"), # Beret Green
		"C": Color("365b40"), # Beret Shadow
		"K": Color("d4a359"), # Gold Pin
		"F": Color("f2c5a0"), # Skin
		"S": Color("e0a87e"), # Skin Shadow
		"W": Color("ebe6d8"), # Collar / White
		"G": Color("543b27"), # Beard / Hair
		"E": Color("1a1824"), # Eyes
		"L": Color("87ceeb"), # Spectacles Glass
		"O": Color("ffcc24")  # Gold Rim
	}

	# Fill decorative background circle
	for y in range(32):
		for x in range(32):
			var dist = Vector2(x - 16, y - 16).length()
			if dist <= 14.5:
				p_img.set_pixel(x, y, Color("2d2218"))
			if dist <= 13.5:
				p_img.set_pixel(x, y, Color("4a3928"))

	# Draw Face & Features in center
	for y in range(8, 26):
		for x in range(9, 24):
			# Base skin
			p_img.set_pixel(x, y, pmap["F"])
			
	# Beret Hat
	for x in range(8, 25):
		for y in range(6, 12):
			p_img.set_pixel(x, y, pmap["H"])
	for x in range(8, 25):
		p_img.set_pixel(x, 11, pmap["C"])
	# Gold Badge
	p_img.set_pixel(11, 8, pmap["K"])
	p_img.set_pixel(12, 8, pmap["K"])
	p_img.set_pixel(11, 9, pmap["K"])

	# Eyes & Spectacles
	# Left eye & rim
	p_img.set_pixel(12, 14, pmap["O"])
	p_img.set_pixel(13, 14, pmap["O"])
	p_img.set_pixel(14, 14, pmap["O"])
	p_img.set_pixel(12, 15, pmap["O"])
	p_img.set_pixel(13, 15, pmap["L"])
	p_img.set_pixel(14, 15, pmap["O"])
	p_img.set_pixel(13, 15, pmap["E"])

	# Right eye & rim
	p_img.set_pixel(18, 14, pmap["O"])
	p_img.set_pixel(19, 14, pmap["O"])
	p_img.set_pixel(20, 14, pmap["O"])
	p_img.set_pixel(18, 15, pmap["O"])
	p_img.set_pixel(19, 15, pmap["L"])
	p_img.set_pixel(20, 15, pmap["O"])
	p_img.set_pixel(19, 15, pmap["E"])

	# Bridge
	p_img.set_pixel(15, 14, pmap["O"])
	p_img.set_pixel(16, 14, pmap["O"])
	p_img.set_pixel(17, 14, pmap["O"])

	# Mustache & Beard
	for y in range(18, 25):
		for x in range(11, 22):
			p_img.set_pixel(x, y, pmap["G"])
			
	# Collar
	for y in range(25, 30):
		for x in range(10, 23):
			p_img.set_pixel(x, y, pmap["W"])

	p_img.save_png("res://assets/sprites/npc/merchant_portrait.png")
	created_files.append("res://assets/sprites/npc/merchant_portrait.png")

	print("[QuestAssetGenerator] Successfully generated %d quest & dialogue assets!" % created_files.size())
	return created_files
