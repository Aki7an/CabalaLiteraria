extends Control

const FX = preload("res://scenes/trailer_reboot/reboot_fx.gd")
const T = preload("res://scenes/trailer_reboot/reboot_timing.gd")
const STYLE = preload("res://scenes/trailer_reboot/reboot_style.gd")
const COPY = preload("res://scenes/trailer_reboot/reboot_copy.gd")
const VIDEO := Vector2(1920, 1080)
const BOARD_SIZE := Vector2(1269, 560)

const MOSAIC_PATHS := [
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

const FLASH_PATHS := [
	"res://data/images/image3085.png",
	"res://data/images/image1060.png",
	"res://data/images/image5.png",
	"res://data/images/image3058.png",
	"res://data/images/image1022.png",
	"res://data/images/image1070.png",
	"res://data/images/image4001.png",
	"res://data/images/image4015.png",
	"res://data/images/image3075.png",
	"res://data/images/image3049.png",
]


func _enter_tree() -> void:
	FX.apply_fullhd(self)


func _ready() -> void:
	FX.apply_fullhd(self)
	_hide_overlays()
	_prepare_stage()
	await play()
	if OS.has_feature("movie"):
		await FX.wait(self, T.MOVIE_TAIL)
		get_tree().quit()


func play() -> void:
	await _beat_reto()
	await _beat_mira()
	await _beat_descifra()
	await _beat_deduce()
	await _beat_descubre()
	await _beat_variety()
	await _beat_mosaic()
	await _beat_cta()


func _beat_reto() -> void:
	var clock := FX.beat_timer(self, T.SEC_RETO)
	_show_only(["Backdrop", "BoardRig", "Title"])
	_clear_board()
	_fit_board(0.80)
	%BoardRig.scale = %BoardRig.scale * 0.92
	%BoardRig.modulate.a = 0.0
	_set_title(COPY.text("TRAILER_QUESTION"), STYLE.SIZE_QUESTION, Vector2(80, 900), Vector2(1760, 130))
	%Title.modulate.a = 0.0
	FX.cue("hook")
	var inn := create_tween()
	inn.set_parallel(true)
	inn.tween_property(%BoardRig, "modulate:a", 1.0, T.HOOK_ZOOM)
	inn.tween_property(%BoardRig, "scale", _board_scale(0.80), T.HOOK_ZOOM).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await inn.finished
	await FX.fade(self, %Title, 1.0, T.TITLE_IN)
	await FX.wait_remaining(self, clock)


func _beat_mira() -> void:
	var clock := FX.beat_timer(self, T.SEC_MIRA)
	await FX.fade(self, %Title, 0.0, T.TITLE_OUT)
	_show_only(["Backdrop", "ImageLayer", "Title"])
	var moon := %Moon as TextureRect
	moon.scale = Vector2(1.04, 1.04)
	moon.position = Vector2(-40, -20)
	%ImageLayer.modulate.a = 0.0
	%ImageLayer.visible = true
	%FootMark.modulate.a = 0.0
	_set_title(COPY.text("TRAILER_MIRA"), STYLE.SIZE_BEAT, Vector2(80, 40), Vector2(1760, 120))
	%Title.modulate.a = 0.0
	FX.cue("moon")
	await FX.fade(self, %ImageLayer, 1.0, T.IMAGE_IN)
	await FX.fade(self, %Title, 1.0, T.TITLE_IN)
	var zoom := create_tween()
	zoom.set_parallel(true)
	zoom.tween_property(moon, "scale", Vector2(1.22, 1.22), T.FOOT_ZOOM).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	zoom.tween_property(moon, "position", Vector2(-180, -210), T.FOOT_ZOOM).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await FX.fade(self, %FootMark, 1.0, 0.25)
	var pulse := create_tween()
	pulse.tween_property(%FootMark, "modulate:a", 0.45, 0.18)
	pulse.tween_property(%FootMark, "modulate:a", 1.0, 0.18)
	await zoom.finished
	FX.cue("moon")
	await FX.wait_remaining(self, clock)


func _beat_descifra() -> void:
	var clock := FX.beat_timer(self, T.SEC_DESCIFRA)
	await FX.fade(self, %Title, 0.0, T.TITLE_OUT)
	_show_only(["Backdrop", "BoardRig", "Title"])
	_fit_board(0.84)
	%BoardRig.modulate.a = 1.0
	_set_title(COPY.text("TRAILER_DESCIFRA"), STYLE.SIZE_BEAT, Vector2(80, 24), Vector2(1760, 110))
	%Title.modulate.a = 0.0
	await FX.fade(self, %Title, 1.0, T.TITLE_IN)
	for letter in ["H", "U", "L", "A"]:
		await _reveal_letter(letter)
		await FX.wait(self, T.LETTER)
	await _zoom_word("HUELLA", 1.16, T.WORD_ZOOM)
	await _reveal_letter("E")
	FX.cue("huella")
	await _flash_word("HUELLA")
	await _show_link_inset()
	await FX.wait_remaining(self, clock)


func _beat_deduce() -> void:
	var clock := FX.beat_timer(self, T.SEC_DEDUCE)
	_fit_board(0.84)
	_set_title(COPY.text("TRAILER_TRY"), STYLE.SIZE_BEAT, Vector2(80, 24), Vector2(1760, 110))
	await FX.fade(self, %Title, 1.0, T.TITLE_IN)
	await _show_hypothesis("D", "B", STYLE.MARK)
	await FX.wait(self, 0.55)
	_set_title(COPY.text("TRAILER_MARK"), STYLE.SIZE_BEAT, Vector2(80, 24), Vector2(1760, 110))
	await FX.wait(self, 0.7)
	_set_title(COPY.text("TRAILER_FIX"), STYLE.SIZE_BEAT, Vector2(80, 24), Vector2(1760, 110))
	await _mark_wrong("D")
	FX.cue("error")
	await FX.wait(self, 0.45)
	_clear_letter("D")
	await _reveal_letter("D")
	FX.cue("correct")
	await _reveal_letter("O")
	await FX.wait(self, 0.2)
	await _reveal_letter("I")
	_set_title(COPY.text("TRAILER_DEDUCE"), STYLE.SIZE_BEAT, Vector2(80, 24), Vector2(1760, 110))
	await FX.wait_remaining(self, clock)


func _beat_descubre() -> void:
	var clock := FX.beat_timer(self, T.SEC_DESCUBRE)
	_fit_board(0.84)
	for letter in ["J", "S", "N", "P"]:
		await _reveal_letter(letter)
		await FX.wait(self, 0.12)
	_reveal_remaining()
	FX.cue("discover")
	await FX.wait(self, 0.45)
	await FX.fade(self, %Title, 0.0, T.TITLE_OUT)
	_show_only(["Backdrop", "Title", "Subtitle"])
	_set_title(COPY.text("TRAILER_DESCUBRE"), STYLE.SIZE_BEAT, Vector2(80, 220), Vector2(1760, 140))
	STYLE.apply_body(%Subtitle, STYLE.SIZE_QUOTE, STYLE.INK)
	%Subtitle.text = COPY.text("TRAILER_QUOTE")
	%Subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%Subtitle.position = Vector2(160, 420)
	%Subtitle.size = Vector2(1600, 220)
	%Subtitle.visible = true
	%Subtitle.modulate.a = 0.0
	await FX.fade(self, %Title, 1.0, T.TITLE_IN)
	await FX.fade(self, %Subtitle, 1.0, T.TITLE_IN)
	await FX.wait(self, T.QUOTE_HOLD)
	await FX.fade(self, %Title, 0.0, T.TITLE_OUT)
	await FX.fade(self, %Subtitle, 0.0, T.TITLE_OUT)
	_show_only(["Backdrop", "ImageLayer"])
	%Moon.scale = Vector2(1.0, 1.0)
	%Moon.position = Vector2.ZERO
	%FootMark.modulate.a = 0.0
	%ImageLayer.modulate.a = 0.0
	await FX.fade(self, %ImageLayer, 1.0, 0.2)
	await FX.wait(self, T.MOON_REWARD)
	await FX.wait_remaining(self, clock)


func _beat_variety() -> void:
	var clock := FX.beat_timer(self, T.SEC_VARIEDAD)
	_show_only(["Backdrop", "Flash", "Title", "BoardRig"])
	%BoardRig.modulate.a = 0.0
	%Flash.modulate.a = 0.0
	var words := [
		COPY.text("TRAILER_PEOPLE"),
		COPY.text("TRAILER_CURIO"),
		COPY.text("TRAILER_DATES"),
		COPY.text("TRAILER_BOOKS"),
	]
	FX.cue("categories")
	for i in FLASH_PATHS.size():
		if clock and clock.time_left < 0.35:
			break
		_set_title(words[i % words.size()], STYLE.SIZE_BEAT, Vector2(80, 36), Vector2(1760, 110))
		%Title.modulate.a = 1.0
		if i % 3 == 2:
			_fit_board(0.86)
			%BoardRig.visible = true
			%BoardRig.modulate.a = 1.0
			%Flash.visible = false
			await FX.wait(self, T.FLASH)
			%BoardRig.modulate.a = 0.0
		else:
			_show_flash(FLASH_PATHS[i])
			await FX.wait(self, T.FLASH)
	%Flash.visible = false
	%BoardRig.visible = false
	await FX.wait_remaining(self, clock)


func _beat_mosaic() -> void:
	var clock := FX.beat_timer(self, T.SEC_MOSAIC)
	_show_only(["Backdrop", "Mosaic", "Title", "Subtitle"])
	_build_mosaic()
	%Mosaic.modulate.a = 0.0
	FX.cue("mosaic")
	await FX.fade(self, %Mosaic, 1.0, T.TITLE_IN)
	_set_title(COPY.text("TRAILER_PUZZLES"), STYLE.SIZE_BEAT, Vector2(80, 40), Vector2(1760, 110))
	%Title.modulate.a = 0.0
	await FX.fade(self, %Title, 1.0, T.TITLE_IN)
	await FX.wait(self, 1.35)
	_set_title(COPY.text("TRAILER_SIX_LANGS"), STYLE.SIZE_BEAT, Vector2(80, 40), Vector2(1760, 110))
	STYLE.apply_body(%Subtitle, STYLE.SIZE_FEATURE, STYLE.INK)
	%Subtitle.text = COPY.text("TRAILER_LANGS")
	%Subtitle.position = Vector2(160, 160)
	%Subtitle.size = Vector2(1600, 70)
	%Subtitle.modulate.a = 0.0
	%Subtitle.visible = true
	await FX.fade(self, %Subtitle, 1.0, T.TITLE_IN)
	await FX.wait(self, 1.2)
	_set_title(COPY.text("TRAILER_MINUTES"), STYLE.SIZE_FEATURE, Vector2(80, 880), Vector2(1760, 70))
	%Subtitle.text = COPY.text("TRAILER_RANK")
	%Subtitle.position = Vector2(160, 960)
	STYLE.apply_body(%Subtitle, STYLE.SIZE_FEATURE, STYLE.INK)
	await FX.wait_remaining(self, clock)


func _beat_cta() -> void:
	var clock := FX.beat_timer(self, T.SEC_CTA)
	_show_only(["Backdrop", "LogoRoot"])
	_style_cta()
	%LogoRoot.modulate.a = 0.0
	%LogoRoot.scale = Vector2(0.94, 0.94)
	%LogoRoot.pivot_offset = Vector2(960, 540)
	FX.cue("logo")
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(%LogoRoot, "modulate:a", 1.0, T.CTA_IN)
	tw.tween_property(%LogoRoot, "scale", Vector2.ONE, T.CTA_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	await FX.wait(self, T.CTA_HOLD)
	await FX.wait_remaining(self, clock)


func _prepare_stage() -> void:
	_clear_board()
	%Title.visible = false
	%Subtitle.visible = false
	%ImageLayer.visible = false
	%ImageLayer.modulate.a = 0.0
	%Flash.visible = false
	%Mosaic.visible = false
	%LogoRoot.visible = false
	%BoardRig.visible = false
	%BoardRig.modulate.a = 0.0
	_fit_board(0.80)


func _clear_board() -> void:
	var board := %Board
	if board.has_method("apply_start_letters"):
		board.apply_start_letters("")


func _board_scale(fill: float) -> Vector2:
	var s := minf(VIDEO.x * fill / BOARD_SIZE.x, VIDEO.y * (fill * 0.82) / BOARD_SIZE.y)
	return Vector2(s, s)


func _fit_board(fill: float) -> void:
	var s := _board_scale(fill)
	%BoardRig.scale = s
	var on := BOARD_SIZE * s.x
	%BoardRig.position = (VIDEO - on) / 2.0 - Vector2(0, 18)
	%BoardRig.visible = true


func _set_title(text: String, size: int, pos: Vector2, box: Vector2) -> void:
	STYLE.apply_title(%Title, size)
	%Title.text = text
	%Title.position = pos
	%Title.size = box
	%Title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	%Title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	%Title.visible = true
	%Title.z_as_relative = false
	%Title.z_index = 30


func _reveal_letter(letter: String) -> void:
	var board := %Board
	if not board.has_method("cells_for"):
		return
	var found: Array = board.cells_for(letter)
	var first := true
	for cell in found:
		if cell.has_method("show_letter"):
			cell.show_letter(letter, STYLE.LETTER, STYLE.FILL if not first else Color(0.93, 0.90, 0.82, 1))
			if cell is Control and (cell as Control).size.x > 1.0:
				(cell as Control).pivot_offset = (cell as Control).size * 0.5
				var tw := create_tween()
				tw.tween_property(cell, "scale", Vector2(1.12, 1.12), 0.08)
				tw.tween_property(cell, "scale", Vector2.ONE, 0.1)
		first = false
	FX.cue("letter")


func _show_hypothesis(real_letter: String, guessed: String, bg: Color) -> void:
	var board := %Board
	for cell in board.cells_for(real_letter):
		if cell.has_method("show_letter"):
			cell.show_letter(guessed, STYLE.LETTER, bg)


func _mark_wrong(letter: String) -> void:
	var board := %Board
	var first: Control = board.first_cell(letter)
	if first and first.has_method("show_letter"):
		first.show_letter("B", STYLE.WRONG, Color(1.0, 0.82, 0.82, 1))


func _clear_letter(letter: String) -> void:
	var board := %Board
	for cell in board.cells_for(letter):
		if cell.has_method("clear_letter"):
			cell.clear_letter()


func _reveal_remaining() -> void:
	var board := %Board
	var seen := {}
	for cell in board.cells():
		if bool(cell.get("is_space")) or bool(cell.get("is_fixed")):
			continue
		var key := str(cell.get("cipher_letter"))
		if key == "" or seen.has(key):
			continue
		var letter_node := cell.get_node_or_null("Letter") as Label
		if letter_node and letter_node.visible and letter_node.text != "":
			continue
		seen[key] = true
		for same in board.cells_for(key):
			if same.has_method("show_letter"):
				same.show_letter(key, STYLE.LETTER, STYLE.FILL)


func _zoom_word(word: String, zoom: float, sec: float) -> void:
	var board := %Board
	var found: Array = board.cells_spelling(word)
	if found.is_empty():
		return
	var acc := Vector2.ZERO
	var count := 0
	for cell in found:
		if cell is Control:
			acc += (cell as Control).position + (cell as Control).size * 0.5
			count += 1
	if count == 0:
		return
	var local := acc / float(count)
	var rest_scale: Vector2 = %BoardRig.scale
	var rest_pos: Vector2 = %BoardRig.position
	var new_scale := rest_scale * zoom
	var dest := Vector2(960, 500) - local * new_scale.x
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(%BoardRig, "scale", new_scale, sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(%BoardRig, "position", dest, sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	%BoardRig.set_meta("rest_scale", rest_scale)
	%BoardRig.set_meta("rest_pos", rest_pos)


func _flash_word(word: String) -> void:
	var board := %Board
	for cell in board.cells_spelling(word):
		if cell.has_method("set_bg"):
			cell.set_bg(Color(1.0, 0.90, 0.72, 1))
		if cell is Control:
			(cell as Control).pivot_offset = (cell as Control).size * 0.5
			var tw := create_tween()
			tw.tween_property(cell, "scale", Vector2(1.1, 1.1), 0.12)
			tw.tween_property(cell, "scale", Vector2.ONE, 0.14)
	await FX.wait(self, 0.28)


func _show_link_inset() -> void:
	var inset := %LinkInset as TextureRect
	if inset == null:
		return
	inset.visible = true
	inset.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(inset, "modulate:a", 1.0, 0.18)
	tw.tween_interval(0.55)
	tw.tween_property(inset, "modulate:a", 0.0, 0.18)
	await tw.finished
	inset.visible = false


func _show_flash(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	if tex == null:
		return
	%Flash.texture = tex
	%Flash.visible = true
	%Flash.modulate.a = 1.0
	%BoardRig.visible = false


func _build_mosaic() -> void:
	var root := %Mosaic
	for child in root.get_children():
		child.queue_free()
	var cols := 4
	var rows := 3
	var margin := Vector2(48, 48)
	var gap := 14.0
	var cell := Vector2((VIDEO.x - margin.x * 2.0 - gap * (cols - 1)) / cols, (VIDEO.y - margin.y * 2.0 - gap * (rows - 1)) / rows)
	for i in MOSAIC_PATHS.size():
		if not ResourceLoader.exists(MOSAIC_PATHS[i]):
			continue
		var tex := load(MOSAIC_PATHS[i]) as Texture2D
		if tex == null:
			continue
		var image := TextureRect.new()
		image.texture = tex
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var col := i % cols
		var row := i / cols
		image.position = margin + Vector2(col * (cell.x + gap), row * (cell.y + gap))
		image.size = cell
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(image)
	root.visible = true


func _style_cta() -> void:
	STYLE.apply_title(%Name, 86)
	%Name.text = "CifraLetra"
	STYLE.apply_body(%Tagline, STYLE.SIZE_FEATURE, STYLE.ACCENT)
	%Tagline.text = COPY.text("TRAILER_TAGLINE")
	STYLE.apply_title(%Available, STYLE.SIZE_CTA)
	%Available.text = COPY.text("TRAILER_AVAILABLE")
	STYLE.apply_body(%Stores, STYLE.SIZE_FEATURE)
	%Stores.text = COPY.text("TRAILER_STORES")
	_mask_icon()


func _mask_icon() -> void:
	var icon := %Icon as TextureRect
	var clip := %IconClip as Panel
	if icon == null or clip == null:
		return
	if icon.get_parent() != clip:
		icon.reparent(clip)
	icon.position = Vector2.ZERO
	icon.size = clip.size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


func _show_only(names: PackedStringArray) -> void:
	var keep := {}
	for n in names:
		keep[n] = true
	keep["Backdrop"] = true
	for child in get_children():
		if child is CanvasItem and child.name != "Backdrop":
			(child as CanvasItem).visible = keep.has(child.name)


func _hide_overlays() -> void:
	for path in ["/root/TransitionScreen", "/root/StarCollectOverlay"]:
		var node := get_node_or_null(path)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		if node is Node:
			node.process_mode = Node.PROCESS_MODE_DISABLED
