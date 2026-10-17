extends RefCounted

## Puzzles downloaded from the public R2 catalog.
## On the server the file name is the same 6-character code as the deeplink.
## On the device they are stored as user://remote_puzzles/{id}.json and {id}.webp.

const DIR_NAME := "remote_puzzles"
const MAX_JSON_BYTES := 1024 * 1024
const MAX_IMAGE_BYTES := 8 * 1024 * 1024


static func json_path(puzzle_id: int) -> String:
	return "user://%s/%d.json" % [DIR_NAME, puzzle_id]


static func image_path(puzzle_id: int) -> String:
	return "user://%s/%d.webp" % [DIR_NAME, puzzle_id]


static func has_files(puzzle_id: int) -> bool:
	return FileAccess.file_exists(json_path(puzzle_id)) and FileAccess.file_exists(image_path(puzzle_id))


static func ensure_dir() -> bool:
	var root := DirAccess.open("user://")
	if root == null:
		return false
	if root.dir_exists(DIR_NAME):
		return true
	return root.make_dir_recursive(DIR_NAME) == OK


static func save_json(puzzle_id: int, raw: String) -> bool:
	if raw.length() > MAX_JSON_BYTES or not pack_is_playable(_parse_pack(raw), puzzle_id):
		return false
	if not ensure_dir():
		return false
	var file := FileAccess.open(json_path(puzzle_id), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(raw)
	file.close()
	return true


static func save_webp(puzzle_id: int, bytes: PackedByteArray) -> bool:
	if bytes.is_empty() or bytes.size() > MAX_IMAGE_BYTES:
		return false
	if not ensure_dir():
		return false
	var file := FileAccess.open(image_path(puzzle_id), FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(bytes)
	file.close()
	return image_decodes(puzzle_id)


static func image_decodes(puzzle_id: int) -> bool:
	var image := Image.new()
	return image.load(image_path(puzzle_id)) == OK


static func read_pack(puzzle_id: int) -> Dictionary:
	if not FileAccess.file_exists(json_path(puzzle_id)):
		return {}
	return _parse_pack(FileAccess.get_file_as_string(json_path(puzzle_id)))


static func saved_ids() -> Array[int]:
	var ids: Array[int] = []
	var folder := DirAccess.open("user://%s" % DIR_NAME)
	if folder == null:
		return ids
	folder.list_dir_begin()
	var file_name := folder.get_next()
	while file_name != "":
		if not folder.current_is_dir() and file_name.ends_with(".json"):
			var puzzle_id := int(file_name.get_basename())
			if puzzle_id >= 0 and has_files(puzzle_id):
				ids.append(puzzle_id)
		file_name = folder.get_next()
	folder.list_dir_end()
	return ids


static func discard(puzzle_id: int) -> void:
	if puzzle_id < 0:
		return
	var folder := DirAccess.open("user://")
	if folder == null:
		return
	folder.remove(json_path(puzzle_id).trim_prefix("user://"))
	folder.remove(image_path(puzzle_id).trim_prefix("user://"))


static func pack_is_playable(pack: Dictionary, puzzle_id: int) -> bool:
	if pack.is_empty() or int(pack.get("id", -1)) != puzzle_id:
		return false
	var languages: Variant = pack.get("languages", {})
	if not languages is Dictionary:
		return false
	for key in (languages as Dictionary).keys():
		var block: Variant = (languages as Dictionary)[key]
		if block is Dictionary and str((block as Dictionary).get("phrase", "")).strip_edges() != "":
			return true
	return false


static func _parse_pack(raw: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		return parsed
	return {}
