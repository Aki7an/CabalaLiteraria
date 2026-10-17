extends Control

const FX = preload("res://scenes/trailer/trailer_anim.gd")
const T = preload("res://scenes/trailer/trailer_timing.gd")


func _enter_tree() -> void:
	FX.apply_fullhd(self)
	_start_music()


func _ready() -> void:
	FX.apply_fullhd(self)
	_start_music()
	_hide_overlays()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var blocks := $Blocks.get_children()
	for child in blocks:
		child.visible = false
	for i in blocks.size():
		var child: Node = blocks[i]
		child.visible = true
		if child.has_method("play_block"):
			await child.play_block()
		if i < blocks.size() - 1:
			_dismiss_block(child, blocks[i + 1])
	if OS.has_feature("movie"):
		await FX.wait(self, T.MOVIE_TAIL)
		get_tree().quit()


func _uses_previous_board(node: Node) -> bool:
	return node != null and node.has_method("uses_previous_board") and bool(node.uses_previous_board())


func _keeps_on_stage(node: Node) -> bool:
	return node != null and node.has_method("keep_on_stage") and bool(node.keep_on_stage())


func _dismiss_block(done: Node, next: Node) -> void:
	if _keeps_on_stage(done) and _uses_previous_board(next):
		return
	if done:
		done.visible = false
	if _uses_previous_board(next):
		return
	var host := done.get_parent() if done else null
	if host == null:
		return
	for sibling in host.get_children():
		if _keeps_on_stage(sibling):
			sibling.visible = false


func _start_music() -> void:
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_trailer_music"):
		sm.play_trailer_music()


func _hide_overlays() -> void:
	for path in ["/root/TransitionScreen", "/root/StarCollectOverlay"]:
		var node := get_node_or_null(path)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		if node is Node:
			node.process_mode = Node.PROCESS_MODE_DISABLED
