extends Node
# AutoLoad — procedural music via AudioStreamGenerator

enum Track { NONE, MENU, IDLE, COMBAT, BOSS, INVENTORY }
var current_track: Track = Track.NONE

const SAMPLE_RATE := 22050.0

# Per-track BPM
const TRACK_BPM: Dictionary = {
	Track.MENU:      90.0,
	Track.IDLE:      80.0,
	Track.COMBAT:   140.0,
	Track.BOSS:     120.0,
	Track.INVENTORY: 70.0,
}
var _beat: float = 60.0 / 90.0

# Frequency table (0 = rest)
const F := {
	"r":  0.0,
	"A2":110.0, "B2":123.5, "C3":130.8, "D3":146.8, "E3":164.8, "F3":174.6, "G3":196.0,
	"A3":220.0, "B3":246.9, "C4":261.6, "D4":293.7, "E4":329.6, "F4":349.2, "G4":392.0,
	"A4":440.0, "B4":493.9, "C5":523.3, "D5":587.3, "E5":659.3,
	"E2": 82.4, "B2h":123.5,
}

# [note_name, beats]
const SONGS: Dictionary = {
	Track.MENU: [
		["E4",1.0],["G4",0.5],["A4",1.0],["G4",0.5],["E4",0.5],["D4",0.5],["C4",2.0],["r",0.5],
		["A3",1.0],["B3",0.5],["C4",1.0],["E4",0.75],["D4",0.25],["C4",0.5],["B3",0.5],["A3",2.0],["r",1.0],
	],
	Track.IDLE: [
		["A3",2.5],["r",0.5],["G3",1.5],["A3",1.5],["B3",1.0],
		["A3",2.0],["r",1.0],["E3",1.5],["G3",1.0],["A3",2.0],["r",2.0],
	],
	Track.COMBAT: [
		["E4",0.25],["E4",0.25],["G4",0.25],["A4",0.5],["G4",0.25],["E4",0.5],["r",0.25],
		["D4",0.25],["E4",0.25],["G4",0.5],["E4",0.5],["D4",0.25],["C4",0.25],["D4",0.5],["r",0.25],
		["E4",0.25],["G4",0.25],["A4",0.25],["B4",0.25],["A4",0.5],["G4",0.25],["E4",0.75],["r",0.5],
	],
	Track.BOSS: [
		["A3",0.5],["r",0.25],["A3",0.25],["C4",0.5],["B3",0.5],
		["A3",0.5],["G3",0.25],["A3",0.25],["E3",1.0],["r",0.5],
		["F3",0.5],["G3",0.5],["A3",0.5],["G3",0.25],["F3",0.25],["E3",0.75],["r",0.25],
		["D3",0.5],["E3",0.25],["F3",0.25],["E3",0.5],["D3",0.5],["A2",1.5],["r",0.5],
	],
	Track.INVENTORY: [
		["C4",2.0],["E4",1.5],["G4",2.0],["E4",1.0],["D4",1.5],
		["C4",1.0],["A3",3.0],["r",1.0],
		["G3",2.0],["A3",1.5],["C4",2.0],["B3",1.5],["A3",3.0],["r",2.0],
	],
}

# Tracks that get a harmony voice (perfect fifth)
const HARMONY_TRACKS: Array[Track] = [Track.COMBAT, Track.BOSS]
# Tracks that get a snare on the half-beat
const SNARE_TRACKS: Array[Track] = [Track.COMBAT, Track.BOSS]

var _asp: AudioStreamPlayer
var _pb:  AudioStreamGeneratorPlayback

var _song:      Array  = []
var _note_i:    int    = 0
var _note_t:    float  = 0.0
var _note_dur:  float  = 0.5
var _freq:      float  = 0.0

# Oscillator phases
var _ph:        float  = 0.0
var _bass_ph:   float  = 0.0
var _harm_ph:   float  = 0.0

# Percussion state
var _beat_clock: float = 0.0
var _kick_t:     float = 0.0   # time since last kick (seconds)
var _snare_t:    float = 0.0   # time since last snare

const KICK_DUR  := 0.04        # kick envelope duration (seconds)
const SNARE_DUR := 0.03

func _ready() -> void:
	var sg := AudioStreamGenerator.new()
	sg.mix_rate      = SAMPLE_RATE
	sg.buffer_length = 0.12
	_asp             = AudioStreamPlayer.new()
	_asp.stream      = sg
	_asp.volume_db   = -80.0
	add_child(_asp)
	_asp.play()
	_pb = _asp.get_stream_playback() as AudioStreamGeneratorPlayback

func play_track(t: Track) -> void:
	if current_track == t:
		return
	current_track = t
	_beat   = 60.0 / TRACK_BPM.get(t, 90.0)
	_song   = SONGS.get(t, [])
	_note_i = 0
	_note_t = 0.0
	_ph     = 0.0
	_bass_ph  = 0.0
	_harm_ph  = 0.0
	_beat_clock = 0.0
	_kick_t = 0.0
	_snare_t = _beat * 0.5
	if not _song.is_empty():
		_load_note()

func set_volume(percent: float) -> void:
	if percent <= 0.0:
		_asp.volume_db = -80.0
	else:
		_asp.volume_db = linear_to_db(percent / 100.0)

func get_volume() -> float:
	if _asp.volume_db <= -80.0:
		return 0.0
	return db_to_linear(_asp.volume_db) * 100.0

func stop() -> void:
	current_track = Track.NONE
	_song  = []
	_freq  = 0.0

func _load_note() -> void:
	var nd      = _song[_note_i % _song.size()]
	_freq       = F.get(nd[0], 0.0)
	_note_dur   = float(nd[1]) * _beat
	_note_t     = 0.0

func _process(delta: float) -> void:
	if _pb == null:
		return
	_note_t     += delta
	_beat_clock += delta
	_kick_t     += delta
	_snare_t    += delta
	if not _song.is_empty() and _note_t >= _note_dur:
		_note_i = (_note_i + 1) % _song.size()
		_load_note()
	if _beat_clock >= _beat:
		_beat_clock -= _beat
		_kick_t  = 0.0
	if _snare_t >= _beat:
		_snare_t -= _beat
	_push()

func _push() -> void:
	var n          := _pb.get_frames_available()
	var dt         := 1.0 / SAMPLE_RATE
	var use_harmony: bool = current_track in HARMONY_TRACKS
	var use_snare:   bool = current_track in SNARE_TRACKS
	var env: float = clamp((_note_dur - _note_t) / 0.05, 0.0, 1.0)

	for _i in n:
		var s := 0.0

		if _freq > 0.0:
			# Melody voice
			s += sin(_ph * TAU) * 0.30 * env
			s += sin(_ph * TAU * 2.0) * 0.12 * env
			# Bass voice (octave below)
			s += sin(_bass_ph * TAU) * 0.20 * env
			# Harmony voice (perfect fifth above, combat/boss only)
			if use_harmony:
				s += sin(_harm_ph * TAU) * 0.10 * env

			_ph      += _freq / SAMPLE_RATE
			_bass_ph += (_freq * 0.5) / SAMPLE_RATE
			_harm_ph += (_freq * 1.5) / SAMPLE_RATE
			if _ph      >= 1.0: _ph      -= 1.0
			if _bass_ph >= 1.0: _bass_ph -= 1.0
			if _harm_ph >= 1.0: _harm_ph -= 1.0

		# Kick drum (every beat)
		if _kick_t < KICK_DUR:
			var kenv: float = 1.0 - (_kick_t / KICK_DUR)
			var noise: float = randf_range(-1.0, 1.0)
			s += noise * kenv * 0.08
		_kick_t += dt

		# Snare (half-beat, combat/boss only)
		if use_snare and _snare_t < SNARE_DUR:
			var senv: float = 1.0 - (_snare_t / SNARE_DUR)
			s += randf_range(-1.0, 1.0) * senv * 0.04
		_snare_t += dt

		s = clampf(s, -1.0, 1.0)
		_pb.push_frame(Vector2(s, s))
