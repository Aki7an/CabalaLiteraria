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
const MUSIC_FADE_OUT_SEC := 2.0
const MUSIC_FADE_IN_SEC := 2.0
const VICTORY_MENU_FADE_IN_SEC := 2.0
const MUSIC_SILENT_DB := -80.0
const GREEN_LETTER_SFX := preload("res://audio/Arcade Click Positive 13.ogg")
const RED_LETTER_SFX := preload("res://audio/Arcade Click Negative 10.ogg")
const GREEN_LETTER_CLICK_GAP := 0.08
const GREEN_PITCH_START_ST := -2.0
const GREEN_PITCH_STEP_ST := 1.0
const GREEN_VOLUME_START_DB := -4.0
const GREEN_VOLUME_END_MULT := 1.5
const GREEN_DELAY_TIME_SEC := 0.7
const GREEN_DELAY_BOUNCES := 3
const GREEN_DELAY_FEEDBACK := 0.7
const GREEN_ALPHABET_FALLBACK := 27

var _registry: Dictionary[String, SoundEntry] = {}
var _music_player: AudioStreamPlayer
var _outgoing_player: AudioStreamPlayer
var _menu_stream: AudioStream
var _celebration_stream: AudioStream
var _game_tracks: Array[AudioStream] = []
var _music_order: Array[int] = []
var _music_index: int = -1
var _music_context: int = -1
var _music_tween: Tween
var _outgoing_tween: Tween
var _music_switch_id := 0
var _switching_music := false
var _awaiting_celebration := false
var _pending_fade_in_sec := MUSIC_FADE_IN_SEC
var _music_duck := 1.0
var _duck_tween: Tween
var _green_click_last_at := -1.0
var _green_pitch_tween: Tween
var _green_seq_index := 0
var _green_delay_token := 0
var _green_voices: Array[AudioStreamPlayer] = []

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
		var music_db := slider_to_db(PlayerPrefs.volumen_musica)
		music_db += linear_to_db(clampf(_music_duck, 0.0001, 1.0))
		AudioServer.set_bus_volume_db(music_idx, music_db)
		AudioServer.set_bus_mute(music_idx, not PlayerPrefs.mute_musica)
	if fx_idx >= 0:
		AudioServer.set_bus_volume_db(fx_idx, slider_to_db(PlayerPrefs.volumen_fx))
		AudioServer.set_bus_mute(fx_idx, not PlayerPrefs.mute_fx)


## Maps a 0–1 fader to dB so loudness changes across the whole slider.
func slider_to_db(slider: float) -> float:
	if slider <= 0.0001:
		return -80.0
	return lerpf(-60.0, 0.0, clampf(slider, 0.0, 1.0))


func duck_music(linear := 0.5, fade_s := 0.08) -> void:
	_tween_music_duck(clampf(linear, 0.0, 1.0), fade_s)


func unduck_music(fade_s := 0.18) -> void:
	_tween_music_duck(1.0, fade_s)


func _tween_music_duck(linear: float, fade_s: float) -> void:
	if _duck_tween:
		_duck_tween.kill()
		_duck_tween = null
	if fade_s <= 0.0 or is_equal_approx(_music_duck, linear):
		_music_duck = linear
		_apply_buses()
		return
	_duck_tween = create_tween()
	_duck_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_duck_tween.tween_method(_set_music_duck, _music_duck, linear, fade_s)


func _set_music_duck(value: float) -> void:
	_music_duck = value
	_apply_buses()


func begin_green_letter_sequence(_count: int = 0) -> void:
	_green_seq_index = 0
	_clear_green_voices()
	if _green_pitch_tween:
		_green_pitch_tween.kill()
		_green_pitch_tween = null
	_stop_transient_sfx()


func _stop_transient_sfx() -> void:
	var prototypes := {}
	for entry in _registry.values():
		var cfg := entry as SoundEntry
		if cfg != null and cfg.prototype != null:
			prototypes[cfg.prototype] = true
	for child in get_children():
		if child is AudioStreamPlayer2D and not prototypes.has(child):
			var sfx := child as AudioStreamPlayer2D
			sfx.stop()
			sfx.queue_free()
		elif child is AudioStreamPlayer and child.name.begins_with("ButtonClick"):
			var click := child as AudioStreamPlayer
			click.stop()
			click.queue_free()


func play_green_letter_click(force := false) -> void:
	var now := Time.get_ticks_msec() * 0.001
	if not force and _green_click_last_at >= 0.0 and now - _green_click_last_at < GREEN_LETTER_CLICK_GAP:
		return
	_green_click_last_at = now
	if _green_pitch_tween:
		_green_pitch_tween.kill()
		_green_pitch_tween = null
	var progress := _green_letter_progress()
	var pitch := _semitone_to_pitch(
		GREEN_PITCH_START_ST + float(_green_seq_index) * GREEN_PITCH_STEP_ST
	)
	var volume_db := _green_letter_volume_db(progress)
	duck_music(0.5)
	_spawn_green_voice(volume_db, pitch)
	_schedule_green_delay(volume_db, pitch, progress)
	_green_seq_index += 1


func _green_letter_progress() -> float:
	var letters := _green_alphabet_count()
	if letters <= 1:
		return 0.0
	return clampf(float(_green_seq_index) / float(letters - 1), 0.0, 1.0)


func _green_alphabet_count() -> int:
	if typeof(GameManager) != TYPE_NIL and GameManager.letters_aphabet_array.size() > 1:
		return GameManager.letters_aphabet_array.size()
	return GREEN_ALPHABET_FALLBACK


func _green_letter_volume_db(progress: float) -> float:
	var linear := db_to_linear(GREEN_VOLUME_START_DB)
	linear *= 1.0 + (GREEN_VOLUME_END_MULT - 1.0) * progress
	return linear_to_db(maxf(linear, 0.0001))


func _schedule_green_delay(volume_db: float, pitch: float, wet: float) -> void:
	if wet <= 0.001:
		return
	var token := _green_delay_token
	var tree := get_tree()
	if tree == null:
		return
	var dry_lin := db_to_linear(volume_db)
	for bounce in range(1, GREEN_DELAY_BOUNCES + 1):
		var bounce_lin := dry_lin * wet * pow(GREEN_DELAY_FEEDBACK, float(bounce))
		if bounce_lin <= 0.0001:
			continue
		var bounce_db := linear_to_db(bounce_lin)
		var delay_sec := GREEN_DELAY_TIME_SEC * float(bounce)
		tree.create_timer(delay_sec).timeout.connect(
			func() -> void:
				if token != _green_delay_token:
					return
				_spawn_green_voice(bounce_db, pitch)
		)


func _spawn_green_voice(volume_db: float, pitch: float) -> void:
	var player := AudioStreamPlayer.new()
	player.name = "GreenLetterClick"
	player.bus = "SoundFx"
	player.stream = GREEN_LETTER_SFX
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.finished.connect(func() -> void:
		_green_voices.erase(player)
		player.queue_free()
		if _green_voices.is_empty():
			unduck_music()
	)
	add_child(player)
	_green_voices.append(player)
	player.play()


func _clear_green_voices() -> void:
	_green_delay_token += 1
	for player in _green_voices:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_green_voices.clear()


func _semitone_to_pitch(semitones: float) -> float:
	return pow(2.0, semitones / 12.0)


func stop_green_letter_clicks() -> void:
	_green_click_last_at = -1.0
	_green_seq_index = 0
	if _green_pitch_tween:
		_green_pitch_tween.kill()
		_green_pitch_tween = null
	_clear_green_voices()
	unduck_music()


func play_red_letter_click() -> void:
	var player := AudioStreamPlayer.new()
	player.name = "RedLetterClick"
	player.bus = "SoundFx"
	player.stream = RED_LETTER_SFX
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

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
	_outgoing_player = AudioStreamPlayer.new()
	_outgoing_player.name = "BackgroundMusicOutgoing"
	_outgoing_player.bus = "Music"
	add_child(_outgoing_player)
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
	_switching_music = false
	_awaiting_celebration = true
	_music_context = MusicContext.MENU
	if _music_tween:
		_music_tween.kill()
		_music_tween = null
	_begin_outgoing_fade(MUSIC_FADE_OUT_SEC)
	if _celebration_stream == null:
		_awaiting_celebration = false
		_pending_fade_in_sec = VICTORY_MENU_FADE_IN_SEC
		_fade_to_context_track()
		return
	_music_player.volume_db = 0.0
	_music_player.stream = _celebration_stream
	_music_player.play()


func _begin_outgoing_fade(duration: float) -> void:
	if _outgoing_player == null or _music_player == null:
		return
	if not _music_player.playing or _music_player.volume_db <= MUSIC_SILENT_DB + 1.0:
		return
	if _outgoing_tween:
		_outgoing_tween.kill()
		_outgoing_tween = null
	var position := _music_player.get_playback_position()
	_outgoing_player.stream = _music_player.stream
	_outgoing_player.volume_db = _music_player.volume_db
	_outgoing_player.play(position)
	_music_player.stop()
	_outgoing_tween = create_tween()
	_outgoing_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_outgoing_tween.tween_property(_outgoing_player, "volume_db", MUSIC_SILENT_DB, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_outgoing_tween.tween_callback(func() -> void:
		if is_instance_valid(_outgoing_player):
			_outgoing_player.stop()
			_outgoing_player.stream = null
		_outgoing_tween = null
	)


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
		return
	_music_switch_id += 1
	var switch_id := _music_switch_id
	_switching_music = true
	if _music_tween:
		_music_tween.kill()
		_music_tween = null
	_music_player.volume_db = MUSIC_SILENT_DB
	_play_next_game_track()
	if not _music_player.playing:
		_music_player.play()
	_music_tween = create_tween()
	_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.tween_property(_music_player, "volume_db", 0.0, MUSIC_FADE_IN_SEC)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _music_tween.finished
	if switch_id != _music_switch_id:
		return
	_switching_music = false
	_music_tween = null


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
