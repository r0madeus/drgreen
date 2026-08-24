@tool
extends SceneTree

func _init() -> void:
	generate_sfx()
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

static func generate_sfx() -> void:
	var sr = 22050

	# 1. rain_ambient.wav (0.8s looping texture)
	var rain_samples = PackedFloat32Array()
	var rain_len = int(sr * 0.8)
	for i in range(rain_len):
		var t = float(i) / sr
		# Soft filtered noise with gentle rhythm
		var noise = (randf() * 2.0 - 1.0) * 0.15
		var hum = sin(TAU * 120.0 * t) * 0.05
		var pat = sin(TAU * 4.0 * t) * 0.03
		rain_samples.append(noise + hum + pat)
	write_wav_file("res://assets/audio/sfx/rain_ambient.wav", rain_samples, sr)

	# 2. snow_wind.wav (0.8s gentle winter wind)
	var snow_samples = PackedFloat32Array()
	var snow_len = int(sr * 0.8)
	for i in range(snow_len):
		var t = float(i) / sr
		var wind = sin(TAU * (80.0 + sin(TAU * 1.5 * t) * 25.0) * t) * 0.2
		var hiss = (randf() * 2.0 - 1.0) * 0.08
		snow_samples.append(wind + hiss)
	write_wav_file("res://assets/audio/sfx/snow_wind.wav", snow_samples, sr)

	# 3. season_transition.wav (0.6s uplifting seasonal chime)
	var chime_samples = PackedFloat32Array()
	var chime_len = int(sr * 0.6)
	for i in range(chime_len):
		var t = float(i) / sr
		var env = exp(-t * 5.0)
		var freq = 523.25 if t < 0.15 else (659.25 if t < 0.3 else (783.99 if t < 0.45 else 1046.50))
		var s = (sin(TAU * freq * t) * 0.4 + sin(TAU * freq * 2.0 * t) * 0.25) * env
		chime_samples.append(s)
	write_wav_file("res://assets/audio/sfx/season_transition.wav", chime_samples, sr)

	print("[Milestone12SFXGenerator] Seasonal audio generated successfully!")
