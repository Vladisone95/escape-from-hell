extends Node
# AutoLoad — pre-generated procedural SFX via AudioStreamWAV

const SAMPLE_RATE := 22050
const POOL_SIZE   := 8

var _sounds: Dictionary = {}
var _pool:   Array[AudioStreamPlayer] = []

func _ready() -> void:
	for i in POOL_SIZE:
		var asp := AudioStreamPlayer.new()
		asp.volume_db = -4.0
		add_child(asp)
		_pool.append(asp)
	_build_sounds()

# ── Public API ──────────────────────────────────────────────────────────────

func play(sfx: String, pitch: float = 1.0) -> void:
	if not _sounds.has(sfx):
		return
	var asp: AudioStreamPlayer = _free_player()
	if asp == null:
		return
	asp.stream      = _sounds[sfx]
	asp.pitch_scale = pitch
	asp.play()

# ── Internal ────────────────────────────────────────────────────────────────

func _free_player() -> AudioStreamPlayer:
	for asp in _pool:
		if not asp.playing:
			return asp
	# All busy — steal the quietest (first in list)
	return _pool[0]

func _gen_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format   = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo   = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	wav.data = bytes
	return wav

func _build_sounds() -> void:
	_sounds["attack"]       = _mk_attack()
	_sounds["dash"]         = _mk_dash()
	_sounds["hurt_p"]       = _mk_hurt_player()
	_sounds["die_p"]        = _mk_die_player()
	_sounds["hurt_e"]       = _mk_hurt_enemy()
	_sounds["die_e"]        = _mk_die_enemy()
	_sounds["proj_hit"]     = _mk_proj_hit()
	_sounds["chest_appear"] = _mk_chest_appear()
	_sounds["chest_open"]   = _mk_chest_open()
	_sounds["item_reveal"]  = _mk_item_reveal()
	_sounds["item_loot"]    = _mk_item_loot()
	_sounds["wave_done"]    = _mk_wave_done()
	_sounds["wave_start"]   = _mk_wave_start()
	_sounds["boss_enter"]   = _mk_boss_enter()
	_sounds["ui_click"]        = _mk_ui_click()
	_sounds["teleport_out"]    = _mk_teleport_out()
	_sounds["teleport_in"]     = _mk_teleport_in()
	_sounds["meteor_incoming"] = _mk_meteor_incoming()
	_sounds["meteor_crash"]    = _mk_meteor_crash()

# ── SFX generators ───────────────────────────────────────────────────────────

func _mk_attack() -> AudioStreamWAV:
	var n   := int(SAMPLE_RATE * 0.12)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t    := float(i) / SAMPLE_RATE
		var env  := pow(1.0 - t / 0.12, 2.0)
		var freq := 600.0 - t * (320.0 / 0.12)
		out[i] = (sin(TAU * freq * t) * 0.55 + sin(TAU * freq * 2.2 * t) * 0.25) * env
	return _gen_wav(out)

func _mk_dash() -> AudioStreamWAV:
	var n   := int(SAMPLE_RATE * 0.16)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var t    := float(i) / SAMPLE_RATE
		var prog := t / 0.16
		var env  := sin(prog * PI)
		var freq := 200.0 + prog * 700.0
		ph += freq / SAMPLE_RATE
		out[i] = sin(ph * TAU) * env * 0.6
	return _gen_wav(out)

func _mk_hurt_player() -> AudioStreamWAV:
	var n   := int(SAMPLE_RATE * 0.22)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t   := float(i) / SAMPLE_RATE
		var env := pow(1.0 - t / 0.22, 1.5)
		var freq := 300.0 - t * (150.0 / 0.22)
		var noise := randf_range(-1.0, 1.0)
		out[i] = (noise * 0.45 + sin(TAU * freq * t) * 0.55) * env
	return _gen_wav(out)

func _mk_die_player() -> AudioStreamWAV:
	# 4 descending notes: A4, E4, C4, A3
	var freqs   := [440.0, 329.6, 261.6, 220.0]
	var durs    := [0.10,  0.10,  0.15,  0.25]
	var samples := PackedFloat32Array()
	for ni in 4:
		var cnt := int(SAMPLE_RATE * durs[ni])
		var ph  := 0.0
		for i in cnt:
			var t   := float(i) / SAMPLE_RATE
			var env := pow(1.0 - t / durs[ni], 1.2)
			ph += freqs[ni] / SAMPLE_RATE
			samples.append(sin(ph * TAU) * env * 0.55)
	return _gen_wav(samples)

func _mk_hurt_enemy() -> AudioStreamWAV:
	var n   := int(SAMPLE_RATE * 0.10)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t   := float(i) / SAMPLE_RATE
		var env := pow(1.0 - t / 0.10, 2.0)
		var freq := 450.0 - t * (230.0 / 0.10)
		out[i] = sin(TAU * freq * t) * env * 0.5
	return _gen_wav(out)

func _mk_die_enemy() -> AudioStreamWAV:
	var n   := int(SAMPLE_RATE * 0.28)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t    := float(i) / SAMPLE_RATE
		var env  := pow(1.0 - t / 0.28, 1.3)
		var freq := 380.0 - t * (290.0 / 0.28)
		out[i] = sin(TAU * freq * t) * env * 0.5
	return _gen_wav(out)

func _mk_proj_hit() -> AudioStreamWAV:
	var n   := int(SAMPLE_RATE * 0.09)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t   := float(i) / SAMPLE_RATE
		var env := pow(1.0 - t / 0.09, 3.0)
		out[i] = sin(TAU * 900.0 * t) * env * 0.5
	return _gen_wav(out)

func _mk_chest_appear() -> AudioStreamWAV:
	# 3-note ascending bell: C5, E5, G5
	var freqs := [523.3, 659.3, 784.0]
	var durs  := [0.07,  0.07,  0.08]
	var out   := PackedFloat32Array()
	for ni in 3:
		var cnt := int(SAMPLE_RATE * durs[ni])
		var ph  := 0.0
		for i in cnt:
			var t   := float(i) / SAMPLE_RATE
			var env := sin((t / durs[ni]) * PI)
			ph += freqs[ni] / SAMPLE_RATE
			out.append((sin(ph * TAU) * 0.5 + sin(ph * TAU * 2.0) * 0.2) * env * 0.55)
	return _gen_wav(out)

func _mk_chest_open() -> AudioStreamWAV:
	var out := PackedFloat32Array()
	# Phase 1: accelerating noise clicks (0–350ms)
	var p1_n  := int(SAMPLE_RATE * 0.35)
	var click_rate := 10.0
	var click_acc  := 0.0
	var click_t    := 0.0
	for i in p1_n:
		var t   := float(i) / SAMPLE_RATE
		var env := t / 0.35
		click_rate = 10.0 + env * 30.0
		click_t += 1.0 / SAMPLE_RATE
		click_acc += click_rate / SAMPLE_RATE
		var s := 0.0
		if click_acc >= 1.0:
			click_acc -= 1.0
			s = randf_range(-1.0, 1.0) * 0.35
		else:
			s = randf_range(-1.0, 1.0) * 0.04 * env
		out.append(s)
	# Phase 2: brief silence (350–400ms)
	var p2_n := int(SAMPLE_RATE * 0.05)
	for _i in p2_n:
		out.append(0.0)
	# Phase 3: ascending sweep 200→1200Hz (400–900ms)
	var p3_n := int(SAMPLE_RATE * 0.50)
	var ph   := 0.0
	var ph2  := 0.0
	for i in p3_n:
		var t    := float(i) / SAMPLE_RATE
		var prog := t / 0.50
		var env  := sin(prog * PI)
		var freq := 200.0 + prog * 1000.0
		ph  += freq / SAMPLE_RATE
		ph2 += (freq * 2.0) / SAMPLE_RATE
		out.append((sin(ph * TAU) * 0.45 + sin(ph2 * TAU) * 0.20) * env)
	return _gen_wav(out)

func _mk_item_reveal() -> AudioStreamWAV:
	# Bell tone at 880Hz, 80ms sustain, 240ms decay
	var n   := int(SAMPLE_RATE * 0.32)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var t   := float(i) / SAMPLE_RATE
		var env: float
		if t < 0.08:
			env = t / 0.08
		else:
			env = 1.0 - ((t - 0.08) / 0.24)
		env = clampf(env, 0.0, 1.0)
		ph += 880.0 / SAMPLE_RATE
		out[i] = (sin(ph * TAU) * 0.55 + sin(ph * TAU * 2.0) * 0.30) * env
	return _gen_wav(out)

func _mk_item_loot() -> AudioStreamWAV:
	# C5+E5+G5 chord — mix 3 sine voices
	var freqs := [523.3, 659.3, 784.0]
	var n     := int(SAMPLE_RATE * 0.52)
	var out   := PackedFloat32Array()
	out.resize(n)
	var phs := [0.0, 0.0, 0.0]
	for i in n:
		var t   := float(i) / SAMPLE_RATE
		var env: float
		if t < 0.06:
			env = t / 0.06
		elif t < 0.20:
			env = 1.0
		else:
			env = 1.0 - ((t - 0.20) / 0.32)
		env = clampf(env, 0.0, 1.0)
		var s := 0.0
		for vi in 3:
			phs[vi] += freqs[vi] / SAMPLE_RATE
			s += sin(phs[vi] * TAU) * 0.22
		out[i] = s * env
	return _gen_wav(out)

func _mk_wave_done() -> AudioStreamWAV:
	# Rising fanfare: C4, E4, G4, C5
	var freqs := [261.6, 329.6, 392.0, 523.3]
	var durs  := [0.15,  0.15,  0.20,  0.45]
	var out   := PackedFloat32Array()
	for ni in 4:
		var cnt := int(SAMPLE_RATE * durs[ni])
		var ph  := 0.0
		for i in cnt:
			var t   := float(i) / SAMPLE_RATE
			var env: float
			if t < 0.03:
				env = t / 0.03
			else:
				env = 1.0 - ((t - 0.03) / (durs[ni] - 0.03)) * 0.6
			env = clampf(env, 0.0, 1.0)
			ph += freqs[ni] / SAMPLE_RATE
			out.append((sin(ph * TAU) * 0.5 + sin(ph * TAU * 2.0) * 0.15) * env)
	return _gen_wav(out)

func _mk_wave_start() -> AudioStreamWAV:
	# 3-strike ascending: E2→E3→E4, each louder
	var freqs := [82.4, 164.8, 329.6]
	var durs  := [0.15, 0.15,  0.25]
	var amps  := [0.35, 0.50,  0.65]
	var out   := PackedFloat32Array()
	for ni in 3:
		var cnt := int(SAMPLE_RATE * durs[ni])
		var ph  := 0.0
		for i in cnt:
			var t   := float(i) / SAMPLE_RATE
			var env := pow(1.0 - t / durs[ni], 0.8)
			ph += freqs[ni] / SAMPLE_RATE
			out.append(sin(ph * TAU) * env * amps[ni])
	return _gen_wav(out)

func _mk_boss_enter() -> AudioStreamWAV:
	# E2+B2 power fifth, noise layer, swell 0→600ms, hold 800ms
	var n   := int(SAMPLE_RATE * 1.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph1 := 0.0
	var ph2 := 0.0
	for i in n:
		var t   := float(i) / SAMPLE_RATE
		var env: float
		if t < 0.6:
			env = t / 0.6
		else:
			env = 1.0 - ((t - 0.6) / 0.8) * 0.5
		env = clampf(env, 0.0, 1.0)
		ph1 += 82.4  / SAMPLE_RATE
		ph2 += 123.5 / SAMPLE_RATE
		var noise := randf_range(-1.0, 1.0)
		out[i] = (sin(ph1 * TAU) * 0.35 + sin(ph2 * TAU) * 0.25 + noise * 0.12) * env
	return _gen_wav(out)

func _mk_teleport_out() -> AudioStreamWAV:
	# Rising ethereal whoosh: 150→900Hz over 500ms, shimmer harmonics
	var n   := int(SAMPLE_RATE * 0.50)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph  := 0.0
	var ph2 := 0.0
	var ph3 := 0.0
	for i in n:
		var t    := float(i) / SAMPLE_RATE
		var prog := t / 0.50
		var env: float
		if t < 0.05:
			env = t / 0.05
		elif t < 0.35:
			env = 1.0
		else:
			env = 1.0 - ((t - 0.35) / 0.15)
		env = clampf(env, 0.0, 1.0)
		var freq := 150.0 + prog * prog * 750.0   # accelerating sweep
		ph  += freq / SAMPLE_RATE
		ph2 += (freq * 2.0) / SAMPLE_RATE
		ph3 += (freq * 3.0) / SAMPLE_RATE
		var shimmer := sin(_time_phase(ph3) * TAU) * 0.12 * sin(TAU * prog * 8.0)
		out[i] = (sin(ph * TAU) * 0.45 + sin(ph2 * TAU) * 0.22 + shimmer) * env
	return _gen_wav(out)

func _mk_teleport_in() -> AudioStreamWAV:
	# Descending arrival: 900→200Hz over 350ms, with a bright pop at start
	var n   := int(SAMPLE_RATE * 0.35)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph  := 0.0
	var ph2 := 0.0
	for i in n:
		var t    := float(i) / SAMPLE_RATE
		var prog := t / 0.35
		var env: float
		if t < 0.02:
			env = t / 0.02   # sharp pop at landing
		else:
			env = 1.0 - ((t - 0.02) / 0.33)
		env = clampf(env, 0.0, 1.0) * (1.5 - prog * 0.5)  # slightly louder pop
		var freq := 900.0 - prog * prog * 700.0   # decelerating descent
		ph  += freq / SAMPLE_RATE
		ph2 += (freq * 1.5) / SAMPLE_RATE
		out[i] = clampf((sin(ph * TAU) * 0.50 + sin(ph2 * TAU) * 0.18) * env, -1.0, 1.0)
	return _gen_wav(out)

func _mk_meteor_incoming() -> AudioStreamWAV:
	# High-pitched whistle descending 1200→300Hz over 0.35s — shrieking inbound rock
	var n   := int(SAMPLE_RATE * 0.35)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph  := 0.0
	var ph2 := 0.0
	for i in n:
		var t    := float(i) / SAMPLE_RATE
		var prog := t / 0.35
		var env  := sin(prog * PI) * (1.0 - prog * 0.3)
		var freq := 1200.0 - prog * prog * 900.0
		ph  += freq / SAMPLE_RATE
		ph2 += (freq * 1.5) / SAMPLE_RATE
		var noise := randf_range(-1.0, 1.0) * 0.08
		out[i] = clampf((sin(ph * TAU) * 0.50 + sin(ph2 * TAU) * 0.20 + noise) * env, -1.0, 1.0)
	return _gen_wav(out)

func _mk_meteor_crash() -> AudioStreamWAV:
	# Deep explosion boom: noise burst + low thud (80Hz) + rumble tail, ~0.75s
	var n   := int(SAMPLE_RATE * 0.75)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph1 := 0.0
	var ph2 := 0.0
	for i in n:
		var t   := float(i) / SAMPLE_RATE
		var env_boom: float
		if t < 0.02:
			env_boom = t / 0.02
		else:
			env_boom = pow(1.0 - (t - 0.02) / 0.73, 1.8)
		env_boom = clampf(env_boom, 0.0, 1.0)
		ph1 += 75.0  / SAMPLE_RATE
		ph2 += 45.0  / SAMPLE_RATE
		var noise := randf_range(-1.0, 1.0)
		var noise_env := pow(maxf(0.0, 1.0 - t / 0.18), 2.0)
		out[i] = clampf(
			(sin(ph1 * TAU) * 0.45 + sin(ph2 * TAU) * 0.30) * env_boom +
			noise * noise_env * 0.55,
			-1.0, 1.0)
	return _gen_wav(out)

func _time_phase(ph: float) -> float:
	return fmod(ph, 1.0)

func _mk_ui_click() -> AudioStreamWAV:
	var n   := int(SAMPLE_RATE * 0.055)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t   := float(i) / SAMPLE_RATE
		var env := 1.0 - t / 0.055
		out[i] = sin(TAU * 650.0 * t) * env * 0.45
	return _gen_wav(out)
