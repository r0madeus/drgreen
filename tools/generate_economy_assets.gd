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
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/items")
	var list = []
	var sr = 22050

	# 1. upgrade_purchase.wav
	var up_samples = PackedFloat32Array()
	var up_len = int(sr * 0.45)
	for i in range(up_len):
		var t = float(i) / sr
		var env = exp(-t * 8.0)
		var freq = 587.33 # D5
		if t >= 0.1 and t < 0.2: freq = 739.99 # F#5
		elif t >= 0.2 and t < 0.3: freq = 880.00 # A5
		elif t >= 0.3: freq = 1174.66 # D6
		var s = (sin(TAU * freq * t) * 0.5 + sin(TAU * freq * 1.5 * t) * 0.3) * env
		up_samples.append(s)
	write_wav_file("res://assets/audio/sfx/upgrade_purchase.wav", up_samples, sr)
	list.append("res://assets/audio/sfx/upgrade_purchase.wav")

	# Helper to create and save 16x16 icon
	var create_icon = func(path: String, draw_func: Callable):
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		draw_func.call(img)
		img.save_png(path)
		list.append(path)

	# 2. fertilizer.png (Compost Bag)
	create_icon.call("res://assets/sprites/items/fertilizer.png", func(img: Image):
		var dark_bag = Color("5c3d24")
		var light_bag = Color("8c5e37")
		var soil = Color("2e1a0e")
		var plant_sprout = Color("55a630")
		for y in range(4, 14):
			for x in range(3, 13):
				img.set_pixel(x, y, light_bag)
		for x in range(3, 13):
			img.set_pixel(x, 13, dark_bag)
			img.set_pixel(x, 4, dark_bag)
		for y in range(4, 14):
			img.set_pixel(3, y, dark_bag)
			img.set_pixel(12, y, dark_bag)
		# Sprout emblem
		img.set_pixel(7, 8, plant_sprout)
		img.set_pixel(8, 8, plant_sprout)
		img.set_pixel(6, 7, plant_sprout)
		img.set_pixel(9, 7, plant_sprout)
		img.set_pixel(7, 9, soil)
		img.set_pixel(8, 9, soil)
	)

	# 3. tonic.png (Herbal Tonic Elixir)
	create_icon.call("res://assets/sprites/items/tonic.png", func(img: Image):
		var cork = Color("9c6644")
		var glass = Color("bde0fe")
		var liquid = Color("06d6a0")
		var shine = Color("ffffff")
		# Cork
		img.set_pixel(7, 2, cork)
		img.set_pixel(8, 2, cork)
		img.set_pixel(7, 3, cork)
		img.set_pixel(8, 3, cork)
		# Neck
		img.set_pixel(7, 4, glass)
		img.set_pixel(8, 4, glass)
		# Bottle body
		for y in range(5, 14):
			for x in range(4, 12):
				img.set_pixel(x, y, liquid)
		# Glass outlines
		for x in range(4, 12):
			img.set_pixel(x, 13, glass)
		for y in range(5, 14):
			img.set_pixel(4, y, glass)
			img.set_pixel(11, y, glass)
		# Highlights
		img.set_pixel(5, 6, shine)
		img.set_pixel(5, 7, shine)
	)

	# 4. better_tools.png (Golden Master Tools)
	create_icon.call("res://assets/sprites/items/better_tools.png", func(img: Image):
		var wood = Color("7f4f24")
		var gold = Color("ffb703")
		var gold_light = Color("ffe169")
		var dark_gold = Color("d48b00")
		# Watering can handle and spout
		for x in range(3, 13):
			img.set_pixel(x, 4, gold)
		for y in range(4, 13):
			img.set_pixel(3, y, dark_gold)
			img.set_pixel(12, y, dark_gold)
		for y in range(5, 12):
			for x in range(4, 12):
				img.set_pixel(x, y, gold)
		for x in range(4, 12):
			img.set_pixel(x, 12, dark_gold)
		# Trowel crossing
		img.set_pixel(7, 7, gold_light)
		img.set_pixel(8, 7, gold_light)
		img.set_pixel(9, 6, wood)
		img.set_pixel(10, 5, wood)
	)

	# 5. expanded_satchel.png (Herbalist Satchel)
	create_icon.call("res://assets/sprites/items/expanded_satchel.png", func(img: Image):
		var strap = Color("43281c")
		var leather = Color("7f4f24")
		var leather_light = Color("936639")
		var buckle = Color("ffd166")
		# Strap
		for i in range(2, 8):
			img.set_pixel(2 + i, 2 + i / 2, strap)
		# Bag pouch
		for y in range(6, 14):
			for x in range(3, 13):
				img.set_pixel(x, y, leather)
		for x in range(4, 12):
			img.set_pixel(x, 6, leather_light)
		# Buckle
		img.set_pixel(7, 9, buckle)
		img.set_pixel(8, 9, buckle)
		img.set_pixel(7, 10, buckle)
		img.set_pixel(8, 10, buckle)
	)

	# 6. botanists_notebook.png (Botanist's Notebook)
	create_icon.call("res://assets/sprites/items/botanists_notebook.png", func(img: Image):
		var cover = Color("2b4162")
		var cover_light = Color("385f71")
		var pages = Color("faedcd")
		var bookmark = Color("55a630")
		var gold_corner = Color("ffb703")
		for y in range(3, 14):
			for x in range(4, 13):
				img.set_pixel(x, y, cover)
		# Page edge
		for y in range(4, 13):
			img.set_pixel(12, y, pages)
		for x in range(5, 12):
			img.set_pixel(x, 13, pages)
		# Gold Corners
		img.set_pixel(4, 3, gold_corner)
		img.set_pixel(12, 3, gold_corner)
		img.set_pixel(4, 13, gold_corner)
		# Ribbon bookmark
		img.set_pixel(7, 3, bookmark)
		img.set_pixel(7, 4, bookmark)
		img.set_pixel(7, 5, bookmark)
		img.set_pixel(7, 14, bookmark)
	)

	print("[EconomyAssetGenerator] Successfully generated %d economy assets!" % list.size())
	return list
