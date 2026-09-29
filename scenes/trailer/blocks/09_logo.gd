extends Control

const FX = preload("res://scenes/trailer/trailer_anim.gd")
const T = preload("res://scenes/trailer/trailer_timing.gd")
const STYLE = preload("res://scenes/trailer/trailer_style.gd")
const COPY = preload("res://scenes/trailer/trailer_copy.gd")


func _enter_tree() -> void:
	if owner == null:
		FX.apply_fullhd(self)


func _ready() -> void:
	if owner == null:
		FX.apply_fullhd(self)
		await play_block()


func play_block() -> void:
	var started := Time.get_ticks_msec()
	FX.cue("logo")
	var sm: Node = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("trailer_music_close"):
		sm.trailer_music_close(1.1)
	_style_cta()
	var root := %LogoRoot
	root.modulate.a = 0.0
	root.scale = %LogoStart.scale
	root.pivot_offset = Vector2(960, 540)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(root, "modulate:a", 1.0, T.BANNER_IN)
	tw.tween_property(root, "scale", %LogoShown.scale, T.BANNER_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await FX.wait_remaining(self, started, T.SEC_09)


func _style_cta() -> void:
	var name_label := %LogoRoot.get_node_or_null("Name") as Label
	var tagline := %LogoRoot.get_node_or_null("Tagline") as Label
	var available := %LogoRoot.get_node_or_null("Available") as Label
	var stores := %LogoRoot.get_node_or_null("Stores") as Label
	if name_label:
		STYLE.apply_title(name_label, 86)
		name_label.text = "CifraLetra"
	if tagline:
		STYLE.apply_body(tagline, STYLE.SIZE_BODY, STYLE.ACCENT)
		tagline.text = COPY.text("TRAILER_TAGLINE")
	if available:
		STYLE.apply_title(available, STYLE.SIZE_CTA)
		available.text = COPY.text("TRAILER_AVAILABLE")
	if stores:
		STYLE.apply_body(stores, STYLE.SIZE_FEATURE)
		stores.text = COPY.text("TRAILER_STORES")
	_mask_icon()


func _mask_icon() -> void:
	var icon := %LogoRoot.get_node_or_null("IconClip/Icon") as TextureRect
	if icon == null:
		icon = %LogoRoot.get_node_or_null("Icon") as TextureRect
	if icon == null:
		return
	if icon.get_parent() and icon.get_parent().name == "IconClip":
		return
	var host := icon.get_parent() as Control
	if host == null:
		return
	var clip := host.get_node_or_null("IconClip") as Panel
	if clip == null:
		clip = Panel.new()
		clip.name = "IconClip"
		clip.position = Vector2(810, 96)
		clip.size = Vector2(300, 300)
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip.clip_contents = true
		var style := StyleBoxFlat.new()
		style.bg_color = STYLE.ACCENT
		style.corner_radius_top_left = 68
		style.corner_radius_top_right = 68
		style.corner_radius_bottom_right = 68
		style.corner_radius_bottom_left = 68
		clip.add_theme_stylebox_override("panel", style)
		host.add_child(clip)
		host.move_child(clip, icon.get_index())
	icon.reparent(clip)
	icon.position = Vector2.ZERO
	icon.size = clip.size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
