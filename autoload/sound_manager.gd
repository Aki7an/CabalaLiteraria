# res://singletons/SoundManager.gd
extends Node

class SoundEntry:
	var prototype: AudioStreamPlayer2D
	var poly: bool

enum MusicContext { MENU, GAME }

const MENU_MUSIC_PATH := "res://audio/music/menus_flying_by.ogg"
const CELEBRATION_MUSIC_PATH := "res://audio/music/celebration.ogg"
const GAME_MUSIC_PATHS: PackedStringArray = [
	"res://audio/music/01_quiet_contemplation.ogg",
	"res://audio/music/02_revelation.ogg",
	"res://audio/music/03_suspended_space.ogg",
	"res://audio/music/04_quiet_space.ogg",
	"res://audio/music/05_looking_for.ogg",
	"res://audio/music/06_space_over_time.ogg",
	"res://audio/music/07_exploration.ogg",
	"res://audio/music/08_inside.ogg",
	"res://audio/music/09_outer_stars.ogg",
	"res://audio/music/10_between_the_echoes.ogg",
	"res://audio/music/11_Suspended Space — Flute Version.ogg",
	"res://audio/music/12_Espacio Silencioso v2.ogg",
	"res://audio/music/13_Espacio Silencioso.ogg",
]
const GAMEPLAY_SCENE_PATHS: PackedStringArray = [
	"res://scenes/App.tscn",
	"res://scenes/main/MainPortrait.tscn",
]
const MUSIC_FADE_OUT_SEC := 0.35
const MUSIC_FADE_IN_SEC := 1.5
const VICTORY_MENU_FADE_IN_SEC := 5.0
const MUSIC_SILENT_DB := -80.0

var _registry: Dictionary[String, SoundEntry] = {}
var _music_player: AudioStreamPlayer
var _menu_stream: AudioStream
var _celebration_stream: AudioStream
var _game_tracks: Array[AudioStream] = []
var _music_order: Array[int] = []
var _music_index: int = -1
var _music_context: int = -1
var _music_tween: Tween
var _music_switch_id := 0
var _switching_music := false
var _awaiting_celebration := false
var _pending_fade_in_sec := MUSIC_FADE_IN_SEC

func _ready() -> void:
	_build_registry()
	_apply_buses()
	_setup_background_music()
	call_deferred("apply_audio_prefs")
	call_deferred("_watch_scene_changes")

func _build_registry() -> void:
	_registry.clear()
	for child in get_children():
		if child is AudioStreamPlayer2D:
			var name_key: String = child.name
			var poly: bool = true
			var custom_name :String = child.get("sound_name")
			if custom_name != null and String(custom_name) != "":
				name_key = String(custom_name)
			var custom_poly :bool = child.get("polyphonic")
			if custom_poly != null:
				poly = bool(custom_poly)
			var entry := SoundEntry.new()
			entry.prototype = child
			entry.poly = poly
			_registry[name_key] = entry

func play(name: String, override_bus: String = "") -> void:
	var cfg := _registry.get(name) as SoundEntry
	if cfg == null:
		push_warning("Sonido no registrado: %s" % name); return

	var proto := cfg.prototype
	if cfg.poly:
		var p := proto.duplicate(DUPLICATE_SCRIPTS) as AudioStreamPlayer2D
		add_child(p)
		if override_bus != "":
			p.bus = override_bus
		p.play()
		p.finished.connect(func(): p.queue_free())
	else:
		if override_bus != "" and proto.bus != override_bus:
			proto.bus = override_bus
		proto.play()

func stop(name: String) -> void:
	var cfg := _registry.get(name) as SoundEntry
	if cfg == null: return
	var proto := cfg.prototype
	if proto.playing:
		proto.stop()

func set_polyphonic(name: String, value: bool) -> void:
	var cfg := _registry.get(name) as SoundEntry
	if cfg != null:
		cfg.poly = value

func set_bus_default(name: String, new_bus: String) -> void:
	var cfg := _registry.get(name) as SoundEntry
	if cfg != null:
		cfg.prototype.bus = new_bus

func apply_audio_prefs() -> void:
	_apply_buses()
	if _music_player and not _music_player.playing and not _switching_music:
		_resume_current_music()
	if Engine.get_main_loop() != null:
		SignalManager.audio_prefs_changed.emit()


func _apply_buses() -> void:
	var music_idx := AudioServer.get_bus_index("Music")
	var fx_idx := AudioServer.get_bus_index("SoundFx")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, slider_to_db(PlayerPrefs.volumen_musica))
		AudioServer.set_bus_mute(music_idx, not PlayerPrefs.mute_musica)
	if fx_idx >= 0:
		AudioServer.set_bus_volume_db(fx_idx, slider_to_db(PlayerPrefs.volumen_fx))
		AudioServer.set_bus_mute(fx_idx, not PlayerPrefs.mute_fx)


## Maps a 0–1 fader to dB so loudness changes across the whole slider.
func slider_to_db(slider: float) -> float:
	if slider <= 0.0001:
		return -80.0
	return lerpf(-60.0, 0.0, clampf(slider, 0.0, 1.0))

func is_music_enabled() -> bool:
	return PlayerPrefs.mute_musica

func is_fx_enabled() -> bool:
	return PlayerPrefs.mute_fx

func set_music_enabled(enabled: bool) -> void:
	if PlayerPrefs.mute_musica == enabled:
		return
	PlayerPrefs.mute_musica = enabled
	apply_audio_prefs()
	PlayerPrefs.save_prefs()

func set_fx_enabled(enabled: bool) -> void:
	if PlayerPrefs.mute_fx == enabled:
		return
	PlayerPrefs.mute_fx = enabled
	apply_audio_prefs()
	PlayerPrefs.save_prefs()

func toggle_music_enabled() -> void:
	set_music_enabled(not is_music_enabled())

func toggle_fx_enabled() -> void:
	set_fx_enabled(not is_fx_enabled())

func _setup_background_music() -> void:
	_menu_stream = _load_audio_stream(MENU_MUSIC_PATH)
	_set_stream_loop(_menu_stream, true)
	_celebration_stream = _load_audio_stream(CELEBRATION_MUSIC_PATH)
	_set_stream_loop(_celebration_stream, false)
	for path in GAME_MUSIC_PATHS:
		var stream := _load_audio_stream(path)
		if stream == null:
			continue
		_set_stream_loop(stream, false)
		_game_tracks.append(stream)
	if _menu_stream == null and _game_tracks.is_empty():
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "BackgroundMusic"
	_music_player.bus = "Music"
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	_reshuffle_game_music()


func _watch_scene_changes() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if not tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.connect(_on_tree_node_added)
	_sync_music_to_current_scene()


func _on_tree_node_added(node: Node) -> void:
	var tree := get_tree()
	if tree == null:
		return
	if node == tree.current_scene:
		call_deferred("_sync_music_to_current_scene")


func _sync_music_to_current_scene() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var scene := tree.current_scene
	var path := scene.scene_file_path if scene != null else ""
	if _is_gameplay_scene(path):
		_set_music_context(MusicContext.GAME)
	else:
		_set_music_context(MusicContext.MENU)


func _is_gameplay_scene(path: String) -> bool:
	return path in GAMEPLAY_SCENE_PATHS


func fade_to_menu_music() -> void:
	_awaiting_celebration = false
	_pending_fade_in_sec = MUSIC_FADE_IN_SEC
	_set_music_context(MusicContext.MENU)


func fade_to_game_music() -> void:
	_awaiting_celebration = false
	_pending_fade_in_sec = MUSIC_FADE_IN_SEC
	_set_music_context(MusicContext.GAME)


func play_victory_then_menu_music() -> void:
	if _music_player == null:
		return
	_music_switch_id += 1
	var switch_id := _music_switch_id
	_switching_music = true
	_awaiting_celebration = true
	_music_context = MusicContext.MENU
	if _music_tween:
		_music_tween.kill()
		_music_tween = null
	var should_fade_out := _music_player.playing and _music_player.volume_db > MUSIC_SILENT_DB + 1.0
	if should_fade_out:
		_music_tween = create_tween()
		_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_music_tween.tween_property(_music_player, "volume_db", MUSIC_SILENT_DB, MUSIC_FADE_OUT_SEC)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await _music_tween.finished
		if switch_id != _music_switch_id:
			return
	if switch_id != _music_switch_id:
		return
	if _celebration_stream == null:
		_awaiting_celebration = false
		_pending_fade_in_sec = VICTORY_MENU_FADE_IN_SEC
		_switching_music = false
		_fade_to_context_track()
		return
	_music_player.volume_db = 0.0
	_music_player.stream = _celebration_stream
	_music_player.play()
	_switching_music = false
	_music_tween = null


func _set_music_context(context: MusicContext) -> void:
	if _music_player == null:
		return
	if _music_context == context and (
		_awaiting_celebration or _switching_music or _music_player.playing
	):
		return
	var entering_game := context == MusicContext.GAME and _music_context != context
	_music_context = context
	if entering_game and _music_order.is_empty():
		_reshuffle_game_music()
	_fade_to_context_track()


func _fade_to_context_track() -> void:
	_music_switch_id += 1
	var switch_id := _music_switch_id
	var fade_in_sec := _pending_fade_in_sec
	_pending_fade_in_sec = MUSIC_FADE_IN_SEC
	_switching_music = true
	if _music_tween:
		_music_tween.kill()
		_music_tween = null
	var should_fade_out := _music_player.playing and _music_player.volume_db > MUSIC_SILENT_DB + 1.0
	if should_fade_out:
		_music_tween = create_tween()
		_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_music_tween.tween_property(_music_player, "volume_db", MUSIC_SILENT_DB, MUSIC_FADE_OUT_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await _music_tween.finished
		if switch_id != _music_switch_id:
			return
	if switch_id != _music_switch_id:
		return
	_music_player.volume_db = MUSIC_SILENT_DB
	_start_context_track()
	if not _music_player.playing:
		_music_player.play()
	_music_tween = create_tween()
	_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_in_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _music_tween.finished
	if switch_id != _music_switch_id:
		return
	_switching_music = false
	_music_tween = null


func _start_context_track() -> void:
	if _music_context == MusicContext.GAME:
		if _music_index >= 0 and _music_index < _music_order.size():
			_music_player.stream = _game_tracks[_music_order[_music_index]]
			_music_player.play()
		else:
			_play_next_game_track()
	else:
		_play_menu_music()


func _resume_current_music() -> void:
	if _music_context == MusicContext.GAME:
		_play_next_game_track()
	else:
		_play_menu_music()


func _play_menu_music() -> void:
	if _music_player == null or _menu_stream == null:
		return
	_music_player.stream = _menu_stream
	_music_player.play()


func _on_music_finished() -> void:
	if _switching_music:
		return
	if _awaiting_celebration:
		_awaiting_celebration = false
		_pending_fade_in_sec = VICTORY_MENU_FADE_IN_SEC
		_fade_to_context_track()
		return
	if _music_context == MusicContext.MENU:
		_play_menu_music()
	else:
		_play_next_game_track()


func _reshuffle_game_music() -> void:
	_music_order.clear()
	for i in _game_tracks.size():
		_music_order.append(i)
	_music_order.shuffle()
	_music_index = -1


func _play_next_game_track() -> void:
	if _music_player == null or _game_tracks.is_empty():
		return
	_music_index += 1
	if _music_order.is_empty() or _music_index >= _music_order.size():
		var last_track := _music_order[_music_order.size() - 1] if not _music_order.is_empty() else -1
		_reshuffle_game_music()
		if _music_order.size() > 1 and _music_order[0] == last_track:
			_music_order.remove_at(0)
			_music_order.append(last_track)
		_music_index = 0
	_music_player.stream = _game_tracks[_music_order[_music_index]]
	_music_player.play()


func _load_audio_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path)
	return stream as AudioStream


func _set_stream_loop(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = enabled
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = enabled
