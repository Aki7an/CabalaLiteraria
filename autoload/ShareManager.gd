extends Node

const ShareConfig := preload("res://store/share_config.gd")
const SHARE_CARD := preload("res://scenes/ShareCard.tscn")
const X_PASTE_DIALOG := preload("res://scenes/share_x_paste_dialog.gd")

var _busy := false


func is_busy() -> bool:
	return _busy


func share_current_result() -> bool:
	return await _share_result("")


func share_current_result_to_x() -> bool:
	return await _share_result("x")


func share_current_result_to_network(network: String) -> bool:
	return await _share_result(network)


func _share_result(target: String) -> bool:
	if _busy:
		return false
	_busy = true
	if _needs_paste_dialog(target) and not await _confirm_paste(target):
		_busy = false
		return false
	var payload := build_payload()
	var png_path := await render_png(payload)
	var text := _social_share_text(payload)
	var ok := false
	if png_path != "":
		ok = await _present_share(png_path, text, target)
	_busy = false
	return ok


func build_payload() -> Dictionary:
	var is_daily := GameManager.session_source == GameManager.SOURCE_DAILY
	var mode_key := "DailyChallenge" if is_daily else ("Cryptogram" if GameManager.is_cryptogram_mode() else "Quick")
	var hints_used := int(GameManager.pista_1) + int(GameManager.pista_2) + int(GameManager.pista_3)
	var stars_max := GameManager.get_puzzle_difficulty_stars()
	var stars_earned: int = clampi(GameManager.puzzle_stars, 0, stars_max)
	if GameManager.is_practice_session() and GameManager.locked_record_stars >= 0:
		stars_earned = clampi(GameManager.locked_record_stars, 0, stars_max)
	var puzzle_id := int(GameManager.id_frase)
	return {
		"brand": "CifraLetra",
		"mode": _t(mode_key, mode_key),
		"category": GameManager.category_display_name(),
		"puzzle_id": puzzle_id,
		"puzzle_id_text": "ID %d" % puzzle_id,
		"image_path": GameManager.find_level_image_path(GameManager.id_image),
		"stars_earned": stars_earned,
		"stars_max": stars_max,
		"star_color": GameManager.star_fill_color(),
		"time_text": _t("TimeTaken", "Tiempo: %s") % _format_time(int(GameManager.tiempo_partida)),
		"hints_text": _t("ShareHintsUsed", "Pistas: %s") % str(hints_used),
		"challenge": _t("ShareResultChallenge", "¿Puedes descifrarlo mejor que yo?"),
		"studio": ShareConfig.STUDIO,
	}


func render_png(payload: Dictionary) -> String:
	var host := CanvasLayer.new()
	host.layer = 80
	add_child(host)
	var vp := SubViewport.new()
	vp.size = Vector2i(ShareConfig.CARD_WIDTH, ShareConfig.CARD_HEIGHT)
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(vp)
	var card := SHARE_CARD.instantiate()
	card.size = Vector2(ShareConfig.CARD_WIDTH, ShareConfig.CARD_HEIGHT)
	vp.add_child(card)
	if card.has_method("apply_payload"):
		card.call("apply_payload", payload)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = vp.get_texture().get_image()
	host.queue_free()
	if image == null:
		push_error("ShareManager: could not render share card.")
		return ""
	var path := OS.get_user_data_dir().path_join(ShareConfig.PNG_NAME)
	var err := image.save_png(path)
	if err != OK:
		push_error("ShareManager: could not save PNG (%s)." % err)
		return ""
	print("[Share] wrote ", path)
	return path


func _present_share(image_path: String, text: String, target := "") -> bool:
	if OS.get_name() == "iOS":
		return _share_ios(image_path, text, target)
	if OS.get_name() == "Android":
		if target == "x":
			return _share_android_clipboard_then_open(
				image_path,
				text,
				ShareConfig.TWITTER_PACKAGE_ANDROID,
				"twitter://post?message=",
				"https://x.com/compose/post"
			)
		if target == "facebook":
			return _share_android_clipboard_then_open(
				image_path,
				text,
				ShareConfig.FACEBOOK_PACKAGE_ANDROID,
				"fb://",
				"https://www.facebook.com/sharer/sharer.php?u=%s" % ShareConfig.store_url().uri_encode()
			)
		return _share_android(image_path, text, target)
	DisplayServer.clipboard_set(text)
	OS.shell_open(image_path)
	if target == "x":
		OS.shell_open("https://x.com/compose/post")
	elif target == "facebook":
		OS.shell_open("https://www.facebook.com/sharer/sharer.php?u=%s" % ShareConfig.store_url().uri_encode())
	return true


func _share_ios(image_path: String, text: String, target := "") -> bool:
	var dirs: PackedStringArray = [
		str(OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)).strip_edges(),
		OS.get_user_data_dir(),
	]
	var payload := JSON.stringify({
		"image": image_path,
		"text": text,
		"target": target,
		"url": ShareConfig.store_url(),
	})
	var wrote := false
	for dir in dirs:
		if dir.is_empty():
			continue
		var file := FileAccess.open(dir.path_join(ShareConfig.IOS_INBOX), FileAccess.WRITE)
		if file == null:
			continue
		file.store_string(payload)
		wrote = true
	if not wrote:
		push_error("ShareManager: iOS share inbox missing.")
		return false
	print("[Share] iOS inbox written")
	return true


func _needs_paste_dialog(target: String) -> bool:
	return target == "x" or target == "facebook" or target == "more" or target == ""


func _confirm_paste(target: String) -> bool:
	var layer := CanvasLayer.new()
	layer.layer = 320
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var dialog := X_PASTE_DIALOG.new()
	dialog.kind = "more" if target == "" else target
	var host: Node = get_tree().current_scene
	if host == null:
		host = self
	host.add_child(layer)
	layer.add_child(dialog)
	var confirmed: Variant = await dialog.finished
	if is_instance_valid(layer):
		layer.queue_free()
	return bool(confirmed)


func _share_android_clipboard_then_open(
	image_path: String,
	text: String,
	package_name: String,
	app_url: String,
	web_url: String
) -> bool:
	DisplayServer.clipboard_set(text)
	if not Engine.has_singleton("AndroidRuntime"):
		OS.shell_open(web_url)
		return true
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	var activity: Variant = android_runtime.getActivity()
	if activity == null:
		OS.shell_open(web_url)
		return true
	var share_path := _android_share_copy(image_path)
	var Intent := JavaClassWrapper.wrap("android.content.Intent")
	var Uri := JavaClassWrapper.wrap("android.net.Uri")
	var File := JavaClassWrapper.wrap("java.io.File")
	var FileProvider := JavaClassWrapper.wrap("androidx.core.content.FileProvider")
	var ClipData := JavaClassWrapper.wrap("android.content.ClipData")
	var file: Variant = File.File(share_path)
	var uri: Variant = null
	if FileProvider != null:
		uri = FileProvider.getUriForFile(
			activity,
			str(activity.getPackageName()) + ShareConfig.FILE_PROVIDER_SUFFIX,
			file
		)
		if JavaClassWrapper.get_exception() != null:
			uri = null
	var open_app := func() -> void:
		_copy_android_clip(activity, uri, text, package_name, Intent, ClipData)
		var view_intent: Variant = Intent.Intent(Intent.ACTION_VIEW, Uri.parse(app_url))
		if package_name != "":
			view_intent.setPackage(package_name)
		activity.startActivity(view_intent)
		if JavaClassWrapper.get_exception() != null:
			view_intent.setPackage("")
			view_intent.setData(Uri.parse(web_url))
			activity.startActivity(view_intent)
	activity.runOnUiThread(android_runtime.createRunnableFromGodotCallable(open_app))
	return true


func _copy_android_clip(
	activity: Variant,
	uri: Variant,
	text: String,
	package_name: String,
	Intent: Variant,
	ClipData: Variant
) -> void:
	if uri == null or ClipData == null or activity == null:
		return
	if package_name != "":
		activity.grantUriPermission(package_name, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
	var clip: Variant = ClipData.newUri(activity.getContentResolver(), "CifraLetra", uri)
	if JavaClassWrapper.get_exception() != null or clip == null:
		return
	if text != "":
		var ClipItem := JavaClassWrapper.wrap("android.content.ClipData$Item")
		if ClipItem != null:
			clip.addItem(ClipItem.Item(text))
	var clipboard: Variant = activity.getSystemService("clipboard")
	if clipboard != null and JavaClassWrapper.get_exception() == null:
		clipboard.setPrimaryClip(clip)


func _share_android(image_path: String, text: String, target := "") -> bool:
	if not Engine.has_singleton("AndroidRuntime"):
		push_error("ShareManager: AndroidRuntime is not available.")
		return false
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	var activity: Variant = android_runtime.getActivity()
	if activity == null:
		return false
	var share_path := _android_share_copy(image_path)
	var Intent := JavaClassWrapper.wrap("android.content.Intent")
	var File := JavaClassWrapper.wrap("java.io.File")
	var FileProvider := JavaClassWrapper.wrap("androidx.core.content.FileProvider")
	var ClipData := JavaClassWrapper.wrap("android.content.ClipData")
	var file: Variant = File.File(share_path)
	var uri: Variant = null
	if FileProvider != null:
		uri = FileProvider.getUriForFile(
			activity,
			str(activity.getPackageName()) + ShareConfig.FILE_PROVIDER_SUFFIX,
			file
		)
		var exception: Variant = JavaClassWrapper.get_exception()
		if exception != null:
			push_warning("ShareManager: FileProvider failed, sharing text only.")
			uri = null
	DisplayServer.clipboard_set(text)
	var share := func() -> void:
		_copy_android_clip(activity, uri, text, ShareConfig.android_package(target), Intent, ClipData)
		var intent: Variant = Intent.Intent()
		intent.setAction(Intent.ACTION_SEND)
		if uri != null:
			intent.setType("image/png")
			intent.putExtra(Intent.EXTRA_STREAM, uri)
			if ClipData != null:
				var clip: Variant = ClipData.newRawUri("CifraLetra", uri)
				if JavaClassWrapper.get_exception() == null and clip != null:
					intent.setClipData(clip)
			intent.putExtra(Intent.EXTRA_TEXT, text)
			intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
		else:
			intent.setType("text/plain")
			intent.putExtra(Intent.EXTRA_TEXT, text)
		var pkg := ShareConfig.android_package(target)
		if pkg != "" and uri != null:
			activity.grantUriPermission(pkg, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
			intent.setPackage(pkg)
			activity.startActivity(intent)
			var pkg_err: Variant = JavaClassWrapper.get_exception()
			if pkg_err != null:
				intent.setPackage("")
				activity.startActivity(Intent.createChooser(intent, "CifraLetra"))
		else:
			activity.startActivity(Intent.createChooser(intent, "CifraLetra"))
	activity.runOnUiThread(android_runtime.createRunnableFromGodotCallable(share))
	return true


func _android_share_copy(image_path: String) -> String:
	# Godot already exposes getFilesDir() via FileProvider (@xml/godot_provider_paths).
	# Keep the PNG there; cache-path is not in Godot's provider XML.
	var files_path := OS.get_user_data_dir().path_join(ShareConfig.PNG_NAME)
	if image_path == files_path or not FileAccess.file_exists(image_path):
		return image_path
	if DirAccess.copy_absolute(image_path, files_path) == OK:
		return files_path
	return image_path


func _share_text(payload: Dictionary) -> String:
	var template := _t(
		"ShareResultText",
		"He resuelto el puzle %s en CifraLetra. ¿Puedes descifrarlo mejor que yo? %s"
	)
	return template % [str(payload.get("puzzle_id_text", "")), ShareConfig.store_url()]


func _social_share_text(payload: Dictionary) -> String:
	var stars := _star_glyphs(int(payload.get("stars_earned", 0)))
	var is_daily := GameManager.session_source == GameManager.SOURCE_DAILY
	var line := _t(
		"ShareTwitterDaily" if is_daily else "ShareTwitterPuzzle",
		"He resuelto el criptograma de hoy en CifraLetra %s" if is_daily else "He resuelto un criptograma en CifraLetra %s"
	) % stars
	var beat := _t("ShareTwitterBeatMe", "¿Puedes superarme?")
	return "%s\n%s\n#CifraLetra #Criptogramas\n%s" % [line, beat, ShareConfig.store_url()]


func _star_glyphs(count: int) -> String:
	var n := clampi(count, 0, 5)
	if n <= 0:
		return "⭐"
	return "⭐".repeat(n)


func _tweet_intent_url(text: String) -> String:
	return "https://twitter.com/intent/tweet?text=%s" % text.uri_encode()


func _format_time(total_sec: int) -> String:
	var seconds := maxi(total_sec, 0)
	var hours := seconds / 3600
	var minutes := (seconds % 3600) / 60
	var rest := seconds % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, rest]
	return "%d:%02d" % [minutes, rest]


func _t(key: String, fallback: String) -> String:
	var value := tr(key)
	return fallback if value == key or value.is_empty() else value
