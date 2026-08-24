@tool
extends SceneTree

func _init() -> void:
	generate_all_sfx()
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
	bytes.encode_u32(16, 16) # Subchunk1Size (16 for PCM)
	bytes.encode_u16(20, 1)  # AudioFormat (1 for PCM)
	bytes.encode_u16(22, 1)  # NumChannels (1 for Mono)
	bytes.encode_u32(24, sample_rate)
	bytes.encode_u32(28, byte_rate)
	bytes.encode_u16(32, block_align)
	bytes.encode_u16(34, bits_per_sample)

	# "data" chunk
	bytes.set(36, 0x64); bytes.set(37, 0x61); bytes.set(38, 0x74); bytes.set(39, 0x61) # "data"
	bytes.encode_u32(40, data_size)

	# Samples (16-bit signed PCM)
	for i in range(num_samples):
		var s = clampf(samples[i], -1.0, 1.0)
		var val = int(s * 32767.0)
		bytes.encode_s16(44 + i * 2, val)

	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_buffer(bytes)
		f.close()

static func generate_all_sfx() -> Array:
	var created_files = []
	var sr = 22050

	# 1. plant.wav: Soft earthy pop (descending pitch with subtle low-pass warmth)
	var plant_samples = PackedFloat32Array()
	var plant_len = int(sr * 0.15)
	for i in range(plant_len):
		var t = float(i) / sr
		var env = exp(-t * 28.0)
		var freq = 220.0 - t * 600.0
		var s = sin(TAU * freq * t) * 0.7 + (randf() * 2.0 - 1.0) * 0.15 * env
		plant_samples.append(s * env)
	write_wav_file("res://assets/audio/sfx/plant.wav", plant_samples, sr)
	created_files.append("res://assets/audio/sfx/plant.wav")

	# 2. water.wav: Gentle water droplet / splash (fast upward pitch sweep & bubble resonance)
	var water_samples = PackedFloat32Array()
	var water_len = int(sr * 0.22)
	for i in range(water_len):
		var t = float(i) / sr
		var env = exp(-t * 18.0)
		var freq = 450.0 + sin(t * 120.0) * 350.0 + t * 400.0
		var s = sin(TAU * freq * t) * 0.6 + sin(TAU * freq * 1.5 * t) * 0.3
		water_samples.append(s * env)
	write_wav_file("res://assets/audio/sfx/water.wav", water_samples, sr)
	created_files.append("res://assets/audio/sfx/water.wav")

	# 3. harvest.wav: Crisp uplifting botanical chime (arpeggiated major chord C5-E5-G5-C6)
	var harvest_samples = PackedFloat32Array()
	var harvest_len = int(sr * 0.35)
	var notes = [523.25, 659.25, 783.99, 1046.50]
	for i in range(harvest_len):
		var t = float(i) / sr
		var s = 0.0
		for n_idx in range(notes.size()):
			var note_start = n_idx * 0.05
			if t >= note_start:
				var nt = t - note_start
				var env = exp(-nt * 14.0)
				s += sin(TAU * notes[n_idx] * nt) * env * 0.25
		harvest_samples.append(s)
	write_wav_file("res://assets/audio/sfx/harvest.wav", harvest_samples, sr)
	created_files.append("res://assets/audio/sfx/harvest.wav")

	# 4. combine.wav: Mystical synthesis shimmer (dual harmonic sweep)
	var combine_samples = PackedFloat32Array()
	var combine_len = int(sr * 0.45)
	for i in range(combine_len):
		var t = float(i) / sr
		var env = exp(-t * 7.0)
		var freq1 = 330.0 + t * 400.0
		var freq2 = 495.0 + sin(t * 40.0) * 60.0 + t * 600.0
		var s = sin(TAU * freq1 * t) * 0.4 + sin(TAU * freq2 * t) * 0.4 + sin(TAU * freq1 * 2.0 * t) * 0.2
		combine_samples.append(s * env)
	write_wav_file("res://assets/audio/sfx/combine.wav", combine_samples, sr)
	created_files.append("res://assets/audio/sfx/combine.wav")

	# 5. discovery.wav: Triumphant botanical discovery fanfare (E5 - G#5 - B5 - E6 sparkle)
	var disc_samples = PackedFloat32Array()
	var disc_len = int(sr * 0.65)
	var d_notes = [659.25, 830.61, 987.77, 1318.51]
	for i in range(disc_len):
		var t = float(i) / sr
		var s = 0.0
		for n_idx in range(d_notes.size()):
			var note_start = n_idx * 0.08
			if t >= note_start:
				var nt = t - note_start
				var env = exp(-nt * 8.0)
				s += (sin(TAU * d_notes[n_idx] * nt) + sin(TAU * d_notes[n_idx] * 2.0 * nt) * 0.3) * env * 0.25
		disc_samples.append(s)
	write_wav_file("res://assets/audio/sfx/discovery.wav", disc_samples, sr)
	created_files.append("res://assets/audio/sfx/discovery.wav")

	# 6. ui_open.wav: Soft crisp whoosh / open tab
	var uio_samples = PackedFloat32Array()
	var uio_len = int(sr * 0.12)
	for i in range(uio_len):
		var t = float(i) / sr
		var env = exp(-t * 30.0)
		var freq = 400.0 + t * 600.0
		var s = sin(TAU * freq * t) * 0.5
		uio_samples.append(s * env)
	write_wav_file("res://assets/audio/sfx/ui_open.wav", uio_samples, sr)
	created_files.append("res://assets/audio/sfx/ui_open.wav")

	# 7. ui_close.wav: Soft downward tick / close modal
	var uic_samples = PackedFloat32Array()
	var uic_len = int(sr * 0.10)
	for i in range(uic_len):
		var t = float(i) / sr
		var env = exp(-t * 35.0)
		var freq = 600.0 - t * 400.0
		var s = sin(TAU * freq * t) * 0.4
		uic_samples.append(s * env)
	write_wav_file("res://assets/audio/sfx/ui_close.wav", uic_samples, sr)
	created_files.append("res://assets/audio/sfx/ui_close.wav")

	# 8. ui_select.wav: Clean wooden button click
	var uis_samples = PackedFloat32Array()
	var uis_len = int(sr * 0.06)
	for i in range(uis_len):
		var t = float(i) / sr
		var env = exp(-t * 60.0)
		var s = (randf() * 2.0 - 1.0) * 0.6 * env + sin(TAU * 800.0 * t) * 0.3 * env
		uis_samples.append(s)
	write_wav_file("res://assets/audio/sfx/ui_select.wav", uis_samples, sr)
	created_files.append("res://assets/audio/sfx/ui_select.wav")

	print("[SFXGenerator] Successfully generated %d audio effects!" % created_files.size())
	return created_files
