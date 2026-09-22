extends Node

const Hint := preload("res://scenes/ScrollOverflowHint.gd")


func _ready() -> void:
	var tree := get_tree()
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)
	call_deferred("_attach_existing")


func _attach_existing() -> void:
	_walk(get_tree().root)


func _walk(node: Node) -> void:
	if node is ScrollContainer:
		Hint.attach(node)
	for child in node.get_children():
		_walk(child)


func _on_node_added(node: Node) -> void:
	if node is ScrollContainer:
		Hint.attach.bind(node).call_deferred()
