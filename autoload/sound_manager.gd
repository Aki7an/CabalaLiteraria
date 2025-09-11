# res://singletons/SoundManager.gd
extends Node

class SoundEntry:
	var prototype: AudioStreamPlayer2D
	var poly: bool

# name -> SoundEntry
var _registry: Dictionary[String, SoundEntry] = {}

func _ready() -> void:
	_build_registry()

func _build_registry() -> void:
	_registry.clear()
	for child in get_children():
		if child is AudioStreamPlayer2D:
			var name_key: String = child.name
			var poly: bool = true

			# Si el player tiene exports (p. ej. SfxPlayerConfig.gd)
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
