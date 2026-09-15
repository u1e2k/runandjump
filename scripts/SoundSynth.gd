extends RefCounted

# 外部音声ファイル不要のプロシージャル音源生成（8bit/Synthwave風）

static func create_jump_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.15
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames)
	
	var start_freq: float = 280.0
	var end_freq: float = 680.0
	var phase: float = 0.0
	
	for i in range(total_frames):
		var t: float = float(i) / float(total_frames)
		var freq: float = lerp(start_freq, end_freq, t)
		phase += (freq * TAU) / float(sample_rate)
		var sq: float = 1.0 if sin(phase) > 0.0 else -1.0
		var sample: float = sin(phase) * 0.6 + sq * 0.4
		var env: float = (1.0 - t) * (1.0 - t)
		var val: int = int(clamp((sample * env * 0.5) * 127.0 + 128.0, 0.0, 255.0))
		byte_array[i] = val
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

static func create_bounce_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.22
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames)
	
	var phase: float = 0.0
	for i in range(total_frames):
		var t: float = float(i) / float(total_frames)
		var freq: float = 450.0 + sin(t * PI * 3.0) * 350.0
		phase += (freq * TAU) / float(sample_rate)
		var sq: float = 1.0 if sin(phase * 0.5) > 0.0 else -1.0
		var sample: float = sin(phase) * 0.7 + sq * 0.3
		var env: float = sin(t * PI) if t < 0.2 else (1.0 - (t - 0.2) / 0.8)
		var val: int = int(clamp((sample * env * 0.6) * 127.0 + 128.0, 0.0, 255.0))
		byte_array[i] = val
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

static func create_shoot_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.09
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames)
	
	var phase: float = 0.0
	for i in range(total_frames):
		var t: float = float(i) / float(total_frames)
		var freq: float = lerp(880.0, 320.0, t)
		phase += (freq * TAU) / float(sample_rate)
		var sq: float = 1.0 if sin(phase) > 0.0 else -1.0
		var sample: float = sq * 0.5
		var env: float = 1.0 - t
		var val: int = int(clamp((sample * env * 0.4) * 127.0 + 128.0, 0.0, 255.0))
		byte_array[i] = val
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

static func create_hit_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.18
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames)
	
	var phase: float = 0.0
	for i in range(total_frames):
		var t: float = float(i) / float(total_frames)
		var freq: float = lerp(220.0, 80.0, t)
		phase += (freq * TAU) / float(sample_rate)
		var noise: float = (randf() * 2.0 - 1.0) * 0.7
		var sample: float = sin(phase) * 0.4 + noise * 0.6
		var env: float = 1.0 - t
		var val: int = int(clamp((sample * env * 0.6) * 127.0 + 128.0, 0.0, 255.0))
		byte_array[i] = val
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

static func create_exp_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.08
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames)
	
	var phase: float = 0.0
	for i in range(total_frames):
		var t: float = float(i) / float(total_frames)
		var freq: float = lerp(600.0, 1200.0, t)
		phase += (freq * TAU) / float(sample_rate)
		var sample: float = sin(phase)
		var env: float = 1.0 - t * 0.8
		var val: int = int(clamp((sample * env * 0.35) * 127.0 + 128.0, 0.0, 255.0))
		byte_array[i] = val
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

static func create_levelup_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.4
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames)
	
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
	var phase: float = 0.0
	
	for i in range(total_frames):
		var t: float = float(i) / float(total_frames)
		var note_idx: int = int(t * 4.0)
		note_idx = clamp(note_idx, 0, 3)
		var freq: float = notes[note_idx]
		phase += (freq * TAU) / float(sample_rate)
		var sample: float = sin(phase) * 0.7 + (1.0 if sin(phase * 0.5) > 0.0 else -1.0) * 0.3
		var env: float = 1.0 - fmod(t * 4.0, 1.0) * 0.4
		var val: int = int(clamp((sample * env * 0.6) * 127.0 + 128.0, 0.0, 255.0))
		byte_array[i] = val
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

static func create_death_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.35
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames)
	
	var phase: float = 0.0
	for i in range(total_frames):
		var t: float = float(i) / float(total_frames)
		var freq: float = lerp(320.0, 60.0, t)
		phase += (freq * TAU) / float(sample_rate)
		var noise: float = (randf() * 2.0 - 1.0) * 0.6
		var saw: float = (fmod(phase, TAU) / PI - 1.0) * 0.4
		var sample: float = noise + saw
		var env: float = 1.0 - t
		var val: int = int(clamp((sample * env * 0.7) * 127.0 + 128.0, 0.0, 255.0))
		byte_array[i] = val
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

static func create_land_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.08
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames)
	
	for i in range(total_frames):
		var t: float = float(i) / float(total_frames)
		var noise: float = (randf() * 2.0 - 1.0) * 0.8
		var env: float = (1.0 - t) * (1.0 - t)
		var val: int = int(clamp((noise * env * 0.4) * 127.0 + 128.0, 0.0, 255.0))
		byte_array[i] = val
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

static func create_coin_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.14
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames)
	
	var phase1: float = 0.0
	var phase2: float = 0.0
	for i in range(total_frames):
		var t: float = float(i) / float(total_frames)
		var freq: float = 987.77 if t < 0.5 else 1318.51 # B5 -> E6
		phase1 += (freq * TAU) / float(sample_rate)
		phase2 += ((freq * 2.0) * TAU) / float(sample_rate)
		var sample: float = sin(phase1) * 0.7 + sin(phase2) * 0.3
		var env: float = 1.0 - t
		var val: int = int(clamp((sample * env * 0.45) * 127.0 + 128.0, 0.0, 255.0))
		byte_array[i] = val
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream
