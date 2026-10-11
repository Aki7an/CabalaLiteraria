extends RefCounted


func save_progress() -> void:
	PuzzleSaveManager.request_autosave()


func show_interstitial_after_puzzle() -> void:
	await AdManager.show_interstitial_after_puzzle()


func show_rewarded() -> bool:
	return await AdManager.show_rewarded()
