extends Node

const SILENT_DB := -80.0

var _tracks: Dictionary = {
	"title": preload("res://sounds/Music/H3LIX_PROTOC0L Title Scene.mp3"),
	"protocol2": preload("res://sounds/Music/H3lix_Protoc0l 2.mp3"),
	"protocol": preload("res://sounds/Music/H3lix_Protoc0l.mp3"),
}

var _target_volume_db: float = -6.0
var _current_track_id: String = ""

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _inactive: AudioStreamPlayer

var _fade_tween: Tween = null

func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_b = AudioStreamPlayer.new()

	_player_a.name = "PlayerA"
	_player_b.name = "PlayerB"

	add_child(_player_a)
	add_child(_player_b)

	_player_a.volume_db = SILENT_DB
	_player_b.volume_db = SILENT_DB

	_active = _player_a
	_inactive = _player_b

func set_volume_db(db: float) -> void:
	_target_volume_db = db
	# If something is currently playing, adjust the active target immediately.
	if _active and _active.playing:
		_active.volume_db = _target_volume_db

func play(track_id: String, fade_time: float = 1.0) -> void:
	if not _tracks.has(track_id):
		push_warning("Music.play: unknown track_id: %s" % track_id)
		return

	if track_id == _current_track_id and _active and _active.playing:
		return

	_current_track_id = track_id

	var stream: AudioStream = _tracks[track_id]
	_set_stream_loop(stream, true)

	if _fade_tween and is_instance_valid(_fade_tween):
		_fade_tween.kill()
		_fade_tween = null

	_inactive.stop()
	_inactive.stream = stream
	_inactive.volume_db = SILENT_DB
	_inactive.play()

	_fade_tween = create_tween()
	_fade_tween.tween_property(_inactive, "volume_db", _target_volume_db, fade_time)
	_fade_tween.parallel().tween_property(_active, "volume_db", SILENT_DB, fade_time)
	_fade_tween.finished.connect(func():
		_active.stop()
		_swap_players()
	)

func stop(fade_time: float = 0.5) -> void:
	if _fade_tween and is_instance_valid(_fade_tween):
		_fade_tween.kill()
		_fade_tween = null

	if _active and _active.playing:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_active, "volume_db", SILENT_DB, fade_time)
		_fade_tween.finished.connect(func():
			_active.stop()
			_active.volume_db = SILENT_DB
			_current_track_id = ""
		)
	else:
		_current_track_id = ""

func _swap_players() -> void:
	var tmp := _active
	_active = _inactive
	_inactive = tmp

func _set_stream_loop(stream: AudioStream, loop_enabled: bool) -> void:
	# Different stream types expose looping differently.
	# This covers MP3 import settings that expose a `loop`/`looping` property.
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = loop_enabled
	if "looping" in stream:
		stream.looping = loop_enabled
