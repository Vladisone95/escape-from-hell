extends Node
# AutoLoad — procedural music via AudioStreamGenerator

enum Track { NONE, MENU, IDLE, COMBAT }
var current_track: Track = Track.NONE

const SAMPLE_RATE := 22050.0
const BPM        := 72.0
var   _beat      := 60.0 / BPM

# Frequency table (0 = rest)
const F := {
	"r":0.0,
	"A2":110.0,"B2":123.5,"C3":130.8,"D3":146.8,"E3":164.8,"F3":174.6,"G3":196.0,
	"A3":220.0,"B3":246.9,"C4":261.6,"D4":293.7,"E4":329.6,"F4":349.2,"G4":392.0,
	"A4":440.0,"B4":493.9,"C5":523.3,"D5":587.3,"E5":659.3,
}

# [note_name, beats]
const SONGS: Dictionary = {
	Track.MENU: [
		["E3",2.0],["r",0.5],["D3",1.5],["C3",2.0],["A2",2.5],
		["G3",1.0],["A3",1.0],["B3",2.5],["r",1.5],
		["E3",1.5],["F3",0.5],["E3",1.0],["D3",3.0],["r",2.0],
	],
	Track.IDLE: [
		["A2",3.0],["r",0.5],["B2",2.0],["A2",2.5],
		["r",0.5],["G3",1.5],["A3",2.5],["r",1.0],
		["E3",2.0],["D3",1.5],["E3",3.0],["r",2.0],
	],
	Track.COMBAT: [
		["E4",0.25],["G4",0.25],["A4",0.25],["r",0.25],
		["A4",0.25],["G4",0.25],["E4",0.5],
		["D4",0.25],["E4",0.25],["G4",0.5],["r",0.25],
		["A4",0.75],["r",0.25],
		["E4",0.25],["F4",0.25],["G4",0.25],["E4",0.25],
		["D4",0.5],["E4",0.5],["r",0.5],
	],
}

var _asp: AudioStreamPlayer
var _pb:  AudioStreamGeneratorPlayback

var _song:     Array  = []
var _note_i:   int    = 0
var _note_t:   float  = 0.0
var _note_dur: float  = 0.5
var _freq:     float  = 0.0
var _ph:       float  = 0.0
const AMP := 0.18

func _ready() -> void:
	var sg := AudioStreamGenerator.new()
	sg.mix_rate     = SAMPLE_RATE
	sg.buffer_length = 0.12
	_asp            = AudioStreamPlayer.new()
	_asp.stream     = sg
	_asp.volume_db  = -6.0
	add_child(_asp)
	_asp.play()
	_pb = _asp.get_stream_playback() as AudioStreamGeneratorPlayback

func play_track(t: Track) -> void:
	if current_track == t:
		return
	current_track = t
	_song   = SONGS.get(t, [])
	_note_i = 0
	_note_t = 0.0
	_ph     = 0.0
	if not _song.is_empty():
		_load_note()

## Set volume from a 0–100 linear scale. 0 = mute, 100 = full volume (0 dB).
func set_volume(percent: float) -> void:
	if percent <= 0.0:
		_asp.volume_db = -80.0
	else:
		_asp.volume_db = linear_to_db(percent / 100.0)

## Return current volume as 0–100.
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
	_note_t += delta
	if not _song.is_empty() and _note_t >= _note_dur:
		_note_i = (_note_i + 1) % _song.size()
		_load_note()
	_push()

func _push() -> void:
	var n   := _pb.get_frames_available()
	var env: float = clamp((_note_dur - _note_t) / 0.05, 0.0, 1.0)
	for _i in n:
		var s := 0.0
		if _freq > 0.0:
			s  = sin(_ph * TAU) * AMP * env
			s += sin(_ph * TAU * 2.0) * AMP * 0.22 * env
			_ph += _freq / SAMPLE_RATE
			if _ph >= 1.0:
				_ph -= 1.0
		_pb.push_frame(Vector2(s, s))
