extends Control

const FX = preload("res://scenes/trailer/trailer_anim.gd")
const T = preload("res://scenes/trailer/trailer_timing.gd")
const STYLE = preload("res://scenes/trailer/trailer_style.gd")
const COPY = preload("res://scenes/trailer/trailer_copy.gd")

const MOSAIC := [
	"res://data/images/image1060.png",
	"res://data/images/image3085.png",
	"res://data/images/image3058.png",
	"res://data/images/image1022.png",
	"res://data/images/image1070.png",
	"res://data/images/image3049.png",
	"res://data/images/image4001.png",
	"res://data/images/image4015.png",
	"res://data/images/image3075.png",
	"res://data/images/image1081.png",
	"res://data/images/image3100.png",
	"res://data/images/image4003.png",
]

const LANGS := [
	["ES", "res://images/onboarding/theme_es.png"],
	["EN", "res://images/onboarding/theme_en.png"],
	["FR", "res://images/onboarding/theme_fr.png"],
	["DE", "res://images/onboarding/theme_de.png"],
	["PT", "res://images/onboarding/theme_pt.png"],
	["EU", "res://images/onboarding/theme_eu.png"],
]


func _enter_tree() -> void:
	if owner == null:
		FX.apply_fullhd(self)


func _ready() -> void:
	if owner == null:
		FX.apply_fullhd(self)
		await play_block()


func play_block() -> void:
	var started := Time.get_ticks_msec()
	if has_node("%Cards"):
		%Cards.visible = false
	var mosaic := _ensure_mosaic()
	var features := _ensure_features()
	mosaic.modulate.a = 0.0
	mosaic.visible = true
	features.visible = false
	features.modulate.a = 0.0
	await FX.fade_in(self, mosaic, T.CAPTION_IN)
	await FX.wait(self, T.MOSAIC_HOLD)
	await FX.fade_out(self, mosaic, T.CAPTION_IN)
	mosaic.visible = false
	features.visible = true
	await FX.fade_in(self, features, T.CAPTION_IN)
	await FX.wait(self, T.FEATURES_HOLD)
	await FX.fade_out(self, features, T.CAPTION_IN)
	await FX.wait_remaining(self, started, T.SEC_08)


func _ensure_mosaic() -> Control:
	var root := get_node_or_null("%Mosaic") as Control
	if root == null:
		root = Control.new()
		root.name = "Mosaic"
		root.unique_name_in_owner = true
		root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(root)
	if root.get_child_count() > 0:
		return root
	var cols := 4
	var rows := 3
	var margin := Vector2(72, 90)
	var gap := 18.0
	var cell := Vector2((1920.0 - margin.x * 2.0 - gap * (cols - 1)) / cols, (1080.0 - margin.y * 2.0 - gap * (rows - 1)) / rows)
	for i in MOSAIC.size():
		if not ResourceLoader.exists(MOSAIC[i]):
			continue
		var loaded: Resource = load(MOSAIC[i])
		if loaded == null or not (loaded is Texture2D):
			continue
		var tex := loaded as Texture2D
		var col := i % cols
		var row := i / cols
		var panel := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = STYLE.CREAM
		style.corner_radius_top_left = 18
		style.corner_radius_top_right = 18
		style.corner_radius_bottom_right = 18
		style.corner_radius_bottom_left = 18
		style.shadow_color = Color(0, 0, 0, 0.18)
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 6)
		panel.add_theme_stylebox_override("panel", style)
		panel.position = margin + Vector2(col * (cell.x + gap), row * (cell.y + gap))
		panel.size = cell
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var image := TextureRect.new()
		image.texture = tex
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.position = Vector2(10, 10)
		image.size = cell - Vector2(20, 20)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(image)
		root.add_child(panel)
	return root


func _ensure_features() -> Control:
	var root := get_node_or_null("%Features") as Control
	if root == null:
		root = Control.new()
		root.name = "Features"
		root.unique_name_in_owner = true
		root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(root)
	if root.get_child_count() > 0:
		return root
	var line := Label.new()
	line.text = COPY.text("TRAILER_FEATURES")
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.position = Vector2(80, 300)
	line.size = Vector2(1760, 90)
	STYLE.apply_body(line, STYLE.SIZE_FEATURE, STYLE.INK)
	root.add_child(line)
	var langs_title := Label.new()
	langs_title.text = COPY.text("TRAILER_SIX_LANGS")
	langs_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	langs_title.position = Vector2(80, 430)
	langs_title.size = Vector2(1760, 56)
	STYLE.apply_body(langs_title, STYLE.SIZE_BODY, STYLE.ACCENT)
	root.add_child(langs_title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.position = Vector2(160, 520)
	row.size = Vector2(1600, 90)
	row.add_theme_constant_override("separation", 36)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for pair in LANGS:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 10)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(pair[1]):
			var flag := TextureRect.new()
			flag.texture = load(pair[1]) as Texture2D
			flag.custom_minimum_size = Vector2(52, 36)
			flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			item.add_child(flag)
		var code := Label.new()
		code.text = pair[0]
		STYLE.apply_body(code, STYLE.SIZE_SMALL, STYLE.INK)
		code.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item.add_child(code)
		row.add_child(item)
	root.add_child(row)
	return root
