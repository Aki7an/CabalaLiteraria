extends Node

const _SCRIPTS := {
	"mobile_store": "res://distribution/adapters/mobile_store_adapter.gd",
	"web_demo": "res://distribution/adapters/web_demo_adapter.gd",
	"crazygames": "res://distribution/adapters/crazygames_adapter.gd",
}

var _adapter: RefCounted


func save_progress() -> void:
	_service().save_progress()


func show_interstitial_after_puzzle() -> void:
	await _service().show_interstitial_after_puzzle()


func show_rewarded() -> bool:
	return await _service().show_rewarded()


func _service() -> RefCounted:
	if _adapter == null:
		var path: String = _SCRIPTS.get(Distribution.current(), _SCRIPTS[Distribution.MOBILE])
		var script := load(path) as Script
		_adapter = script.new()
	return _adapter
