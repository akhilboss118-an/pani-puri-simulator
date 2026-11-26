extends Node
## Tiny procedural sound engine. Every effect is synthesised at load time, so
## the web build stays under a few megabytes and nothing is licensed.

const RATE := 22050
const PLAYER_COUNT := 8

var volume: float = 0.75
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _ambience: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in PLAYER_COUNT:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_build_streams()
	_ambience = AudioStreamPlayer.new()
	_ambience.stream = _streams["ambience"]
	_ambience.volume_db = -22.0
	add_child(_ambience)


func play(id: String, pitch: float = 1.0, db: float = -6.0) -> void:
	if not _streams.has(id):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _streams[id]
	p.pitch_scale = clampf(pitch, 0.4, 2.4)
	p.volume_db = db
	p.play()


func start_ambience() -> void:
	if _ambience and not _ambience.playing:
		_ambience.play()


func stop_ambience() -> void:
	if _ambience:
		_ambience.stop()


func apply_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume)))


# ------------------------------------------------------------------ synthesis

func _build_streams() -> void:
	_streams["click"] = _tone(0.05, 880.0, 0.5, 40.0)
	_streams["crack"] = _noise(0.16, 55.0, 0.8, 6.0)
	_streams["scoop"] = _noise(0.2, 22.0, 0.55, 4.0)
	_streams["pour"] = _pour()
	_streams["coin"] = _chime([1046.5, 1568.0], 0.1)
	_streams["good"] = _chime([523.25, 659.25, 783.99], 0.11)
	_streams["bad"] = _descend()
	_streams["serve"] = _chime([392.0, 523.25, 659.25, 784.0], 0.09)
	_streams["waste"] = _noise(0.3, 14.0, 0.4, 3.0)
	_streams["dayend"] = _chime([261.63, 329.63, 392.0, 523.25], 0.18)
	_streams["bell"] = _tone(0.5, 1318.5, 0.35, 5.0)
	_streams["ambience"] = _ambience_loop()


func _tone(duration: float, freq: float, amp: float, decay: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / RATE
		var env := exp(-decay * t)
		samples[i] = sin(TAU * freq * t) * amp * env
	return _wav(samples)


func _noise(duration: float, decay: float, amp: float, smooth: float) -> AudioStreamWAV:
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var prev := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in count:
		var t := float(i) / RATE
		var raw := rng.randf_range(-1.0, 1.0)
		prev = lerpf(prev, raw, 0.35)
		var env := exp(-decay * t)
		samples[i] = prev * amp * env
	return _wav(samples)


func _pour() -> AudioStreamWAV:
	var duration := 0.55
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var prev := 0.0
	for i in count:
		var t := float(i) / RATE
		var wobble := 0.6 + 0.4 * sin(TAU * 7.0 * t)
		var raw := rng.randf_range(-1.0, 1.0)
		prev = lerpf(prev, raw, 0.5)
		var env := minf(1.0, t * 12.0) * exp(-2.4 * t)
		samples[i] = prev * 0.5 * wobble * env
	return _wav(samples)


func _chime(freqs: Array, step: float) -> AudioStreamWAV:
	var duration := step * freqs.size() + 0.25
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / RATE
		var value := 0.0
		for n in freqs.size():
			var start := n * step
			if t >= start:
				var local := t - start
				value += sin(TAU * float(freqs[n]) * local) * exp(-6.0 * local) * 0.28
		samples[i] = value
	return _wav(samples)


func _descend() -> AudioStreamWAV:
	var duration := 0.4
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / RATE
		var freq := lerpf(300.0, 150.0, t / duration)
		samples[i] = sin(TAU * freq * t) * 0.35 * exp(-4.0 * t)
	return _wav(samples)


func _ambience_loop() -> AudioStreamWAV:
	var duration := 4.0
	var count := int(RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var brown := 0.0
	for i in count:
		var t := float(i) / RATE
		brown = clampf(brown + rng.randf_range(-0.08, 0.08), -1.0, 1.0) * 0.995
		var swell := 0.55 + 0.45 * sin(TAU * 0.12 * t)
		samples[i] = brown * 0.32 * swell
	return _wav(samples, true)


func _wav(samples: PackedFloat32Array, looped: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream
