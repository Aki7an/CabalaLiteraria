class_name ScrollOverflowHint
extends Control

const COLOR_FILL := Color(0.996, 0.941, 0.776, 0.96)
const COLOR_BORDER := Color(0.878, 0.443, 0.102, 1)
const COLOR_ARROW := Color(0.42, 0.18, 0.05, 1)
const CIRCLE := 96.0
const MARGIN := 20.0
const THRESHOLD := 6.0

var _scroll: ScrollContainer
var _up: Button
var _down: Button
var _blink: Tween


static func attach(scroll: ScrollContainer) -> ScrollOverflowHint:
	if not is_instance_valid(scroll):
		return null
	if scroll.has_meta("scroll_overflow_hint"):
		var existing: Variant = scroll.get_meta("scroll_overflow_hint")
		if existing is ScrollOverflowHint and is_instance_valid(existing):
			return existing
	if not _is_player_scroll(scroll):
		return null
	var parent := scroll.get_parent()
	if parent == null:
		return null
	var hint := ScrollOverflowHint.new()
	hint._scroll = scroll
	parent.add_child(hint)
	if parent is Node:
		parent.move_child(hint, parent.get_child_count() - 1)
	scroll.set_meta("scroll_overflow_hint", hint)
	return hint


static func _is_player_scroll(scroll: ScrollContainer) -> bool:
	if scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		return false
	var path := str(scroll.get_path()).to_lower()
	if scroll.owner:
		path += " " + str(scroll.owner.scene_file_path).to_lower()
	if "/addons/" in path or "/tools/" in path or "editor" in path:
		return false
	if "screenshot" in path:
		return false
	return true


func _ready() -> void:
	name = "ScrollOverflowHint"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 45
	_up = _make_circle(-1)
	_down = _make_circle(1)
	add_child(_up)
	add_child(_down)
	if is_instance_valid(_scroll):
		_scroll.tree_exiting.connect(queue_free)
	_start_blink()
	set_process(true)


func _exit_tree() -> void:
	if is_instance_valid(_blink):
		_blink.kill()
	if is_instance_valid(_scroll) and _scroll.has_meta("scroll_overflow_hint"):
		if _scroll.get_meta("scroll_overflow_hint") == self:
			_scroll.remove_meta("scroll_overflow_hint")


func _process(_delta: float) -> void:
	if not is_instance_valid(_scroll):
		queue_free()
		return
	var parent_node := _scroll.get_parent()
	if parent_node != get_parent() and parent_node != null:
		reparent(parent_node)
	var parent_control := get_parent() as Control
	if parent_control == null:
		visible = false
		return
	var scroll_rect := _scroll.get_global_rect()
	var parent_rect := parent_control.get_global_rect()
	position = scroll_rect.position - parent_rect.position
	size = scroll_rect.size
	_layout_buttons()
	_refresh_visibility()


func _circle_size() -> float:
	return clampf(minf(size.x, size.y) * 0.11, 72.0, CIRCLE)


func _layout_buttons() -> void:
	var diameter := _circle_size()
	var circle := Vector2(diameter, diameter)
	for button in [_up, _down]:
		button.custom_minimum_size = circle
		button.size = circle
		button.pivot_offset = circle * 0.5
		var arrow := button.get_child(0) as Polygon2D
		if arrow:
			arrow.position = circle * 0.5
			var tip := diameter * 0.19
			var base := diameter * 0.15
			if button == _up:
				arrow.polygon = PackedVector2Array([
					Vector2(0, -tip),
					Vector2(-base, tip * 0.78),
					Vector2(base, tip * 0.78),
				])
			else:
				arrow.polygon = PackedVector2Array([
					Vector2(-base, -tip * 0.78),
					Vector2(base, -tip * 0.78),
					Vector2(0, tip),
				])
	_up.position = Vector2(size.x - diameter - MARGIN, MARGIN)
	_down.position = Vector2(size.x - diameter - MARGIN, size.y - diameter - MARGIN)


func _max_scroll() -> float:
	var bar := _scroll.get_v_scroll_bar()
	var max_scroll := 0.0
	if bar != null:
		max_scroll = maxf(0.0, bar.max_value - bar.page)
		max_scroll = maxf(max_scroll, bar.max_value - _scroll.size.y)
	for child in _scroll.get_children():
		if not (child is Control) or child is ScrollBar:
			continue
		var control := child as Control
		var height := maxf(control.size.y, control.get_combined_minimum_size().y)
		max_scroll = maxf(max_scroll, height - _scroll.size.y)
	return max_scroll


func _refresh_visibility() -> void:
	var shown := _scroll.visible and _scroll.get_global_rect().size.y > 80.0
	var can_up := false
	var can_down := false
	if shown:
		var max_scroll := _max_scroll()
		if max_scroll > THRESHOLD:
			var current := float(_scroll.scroll_vertical)
			can_up = current > THRESHOLD
			can_down = current < max_scroll - THRESHOLD
	_up.visible = shown and can_up
	_down.visible = shown and can_down
	visible = _up.visible or _down.visible


func _make_circle(direction: int) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(CIRCLE, CIRCLE)
	button.size = Vector2(CIRCLE, CIRCLE)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_stylebox_override("normal", _circle_style(false))
	button.add_theme_stylebox_override("hover", _circle_style(true))
	button.add_theme_stylebox_override("pressed", _circle_style(true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func() -> void:
		_nudge(direction)
	)

	var arrow := Polygon2D.new()
	arrow.color = COLOR_ARROW
	arrow.position = Vector2(CIRCLE * 0.5, CIRCLE * 0.5)
	if direction < 0:
		arrow.polygon = PackedVector2Array([
			Vector2(0, -18),
			Vector2(-18, 14),
			Vector2(18, 14),
		])
	else:
		arrow.polygon = PackedVector2Array([
			Vector2(-18, -14),
			Vector2(18, -14),
			Vector2(0, 18),
		])
	button.add_child(arrow)
	return button


func _circle_style(hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.968, 0.84, 1) if hovered else COLOR_FILL
	style.border_color = COLOR_BORDER
	style.set_border_width_all(5)
	style.set_corner_radius_all(int(CIRCLE))
	style.shadow_color = Color(0.41, 0.22, 0.05, 0.28)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style


func _nudge(direction: int) -> void:
	if not is_instance_valid(_scroll):
		return
	if typeof(SoundManager) != TYPE_NIL:
		SoundManager.play("ButtonClick")
	var bar := _scroll.get_v_scroll_bar()
	var step := 180.0
	if bar != null:
		step = maxf(bar.page * 0.45, 180.0)
	_scroll.scroll_vertical = int(_scroll.scroll_vertical + float(direction) * step)


func _start_blink() -> void:
	if is_instance_valid(_blink):
		_blink.kill()
	_blink = create_tween()
	_blink.set_loops()
	_blink.set_trans(Tween.TRANS_SINE)
	_blink.set_ease(Tween.EASE_IN_OUT)
	_blink.tween_property(self, "modulate", Color(1.12, 1.04, 0.82, 1), 0.42)
	_blink.tween_property(self, "modulate", Color.WHITE, 0.42)
