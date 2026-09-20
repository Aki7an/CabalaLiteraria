@tool
extends EditorExportPlugin

const SRC_IAP_MM := "res://ios/plugins/cifraletra_iap/CifraLetraIAP.mm"
const SRC_IAP_H := "res://ios/plugins/cifraletra_iap/cifraletra_iap.h"
const SRC_SHARE_MM := "res://ios/plugins/cifraletra_iap/CifraLetraShare.mm"
const SRC_SHARE_H := "res://ios/plugins/cifraletra_iap/cifraletra_share.h"
const SRC_FILE_PATHS := "res://addons/cifraletra_iap/android/cifraletra_file_paths.xml"
const BUILD_IAP := "C1F4A1EA0000000000000001"
const FILE_IAP := "C1F4A1EA0000000000000002"
const FILE_IAP_H := "C1F4A1EA0000000000000004"
const BUILD_SHARE := "C1F4A1EA0000000000000011"
const FILE_SHARE := "C1F4A1EA0000000000000012"
const FILE_SHARE_H := "C1F4A1EA0000000000000014"

var _pending_export_path := ""


func _get_name() -> String:
	return "CifraLetraIAP"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformIOS or platform is EditorExportPlatformAndroid


func _export_begin(features: PackedStringArray, _is_debug: bool, path: String, _flags: int) -> void:
	_pending_export_path = path
	if features.has("ios"):
		_add_framework("StoreKit.framework")
		_add_linker_flags("-ObjC")
		_add_linker_flags("-framework StoreKit")
		_add_linker_flags("-framework UIKit")
	if features.has("android"):
		_install_android_file_paths()


func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
	return """
<provider
	android:name="androidx.core.content.FileProvider"
	android:authorities="${applicationId}.fileprovider"
	android:exported="false"
	android:grantUriPermissions="true">
	<meta-data
		android:name="android.support.FILE_PROVIDER_PATHS"
		android:resource="@xml/cifraletra_file_paths" />
</provider>
"""


func _end_generate_apple_embedded_project(path: String, _will_build_archive: bool) -> void:
	_install_native_sources(path)


func _export_end() -> void:
	var path := _pending_export_path
	_pending_export_path = ""
	if path.ends_with(".xcodeproj") or path.get_extension() == "ipa":
		_install_native_sources(path)


func _install_android_file_paths() -> void:
	var src := ProjectSettings.globalize_path(SRC_FILE_PATHS)
	if not FileAccess.file_exists(src):
		return
	var dest_dir := ProjectSettings.globalize_path("res://android/build/res/xml")
	DirAccess.make_dir_recursive_absolute(dest_dir)
	DirAccess.copy_absolute(src, dest_dir.path_join("cifraletra_file_paths.xml"))


func _install_native_sources(path: String) -> void:
	if path.is_empty():
		return
	var export_dir := path.get_base_dir()
	var project_name := path.get_file().get_basename()
	if project_name.is_empty():
		return
	var source_dir := export_dir.path_join(project_name)
	if not DirAccess.dir_exists_absolute(source_dir):
		source_dir = export_dir
	DirAccess.make_dir_recursive_absolute(source_dir)
	_copy_if_exists(SRC_IAP_MM, source_dir.path_join("CifraLetraIAP.mm"))
	_copy_if_exists(SRC_IAP_H, source_dir.path_join("cifraletra_iap.h"))
	_copy_if_exists(SRC_SHARE_MM, source_dir.path_join("CifraLetraShare.mm"))
	_copy_if_exists(SRC_SHARE_H, source_dir.path_join("cifraletra_share.h"))
	var pbx := export_dir.path_join(project_name + ".xcodeproj/project.pbxproj")
	if not FileAccess.file_exists(pbx) and path.ends_with(".xcodeproj"):
		pbx = path.path_join("project.pbxproj")
	if FileAccess.file_exists(pbx):
		_patch_pbxproj(pbx)
	_strip_unused_ios_privacy(source_dir, pbx if FileAccess.file_exists(pbx) else "")


func _copy_if_exists(src_res: String, dst: String) -> void:
	var src := ProjectSettings.globalize_path(src_res)
	if FileAccess.file_exists(src):
		DirAccess.copy_absolute(src, dst)


func _patch_pbxproj(pbx_path: String) -> void:
	var content := FileAccess.get_file_as_string(pbx_path)
	if content.is_empty():
		return
	content = _ensure_source(
		content,
		"CifraLetraIAP.mm",
		BUILD_IAP,
		FILE_IAP,
		FILE_IAP_H,
		"cifraletra_iap.h"
	)
	content = _ensure_source(
		content,
		"CifraLetraShare.mm",
		BUILD_SHARE,
		FILE_SHARE,
		FILE_SHARE_H,
		"cifraletra_share.h"
	)
	content = _with_storekit_ldflags(content)
	var file := FileAccess.open(pbx_path, FileAccess.WRITE)
	if file:
		file.store_string(content)


func _ensure_source(content: String, mm_name: String, build_id: String, file_id: String, header_id: String, header_name: String) -> String:
	if content.contains("%s in Sources" % mm_name):
		return content
	content = content.replace(
		"/* End PBXBuildFile section */",
		"\t\t%s /* %s in Sources */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };\n/* End PBXBuildFile section */" % [build_id, mm_name, file_id, mm_name]
	)
	content = content.replace(
		"/* End PBXFileReference section */",
		"\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.cpp.objcpp; path = %s; sourceTree = \"<group>\"; };\n\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.h; path = %s; sourceTree = \"<group>\"; };\n/* End PBXFileReference section */" % [file_id, mm_name, mm_name, header_id, header_name, header_name]
	)
	content = content.replace(
		"1FF8DBB01FBA9DE1009DE660 /* dummy.cpp */,",
		"1FF8DBB01FBA9DE1009DE660 /* dummy.cpp */,\n\t\t\t\t%s /* %s */,\n\t\t\t\t%s /* %s */," % [file_id, mm_name, header_id, header_name]
	)
	content = content.replace(
		"1FF8DBB11FBA9DE1009DE660 /* dummy.cpp in Sources */,",
		"1FF8DBB11FBA9DE1009DE660 /* dummy.cpp in Sources */,\n\t\t\t\t%s /* %s in Sources */," % [build_id, mm_name]
	)
	return content


func _with_storekit_ldflags(content: String) -> String:
	if content.contains("StoreKit"):
		return content
	return content.replace(
		"\t\t\t\t\tJavaScriptCore,\n\t\t\t\t);",
		"\t\t\t\t\tJavaScriptCore,\n\t\t\t\t\t\"-framework\",\n\t\t\t\t\tStoreKit,\n\t\t\t\t);"
	)


func _strip_unused_ios_privacy(source_dir: String, pbx_path: String) -> void:
	var plist_names: Array[String] = []
	var dir := DirAccess.open(source_dir)
	if dir:
		dir.list_dir_begin()
		var name := dir.get_next()
		while name != "":
			if name.ends_with("-Info.plist") or name == "Info.plist":
				plist_names.append(source_dir.path_join(name))
			name = dir.get_next()
		dir.list_dir_end()
	for plist_path in plist_names:
		_strip_privacy_keys_from_plist(plist_path)
	if pbx_path != "" and FileAccess.file_exists(pbx_path):
		_strip_privacy_keys_from_pbx(pbx_path)


func _strip_privacy_keys_from_plist(path: String) -> void:
	var content := FileAccess.get_file_as_string(path)
	if content.is_empty():
		return
	var keys := [
		"NSCameraUsageDescription",
		"NSMicrophoneUsageDescription",
		"NSPhotoLibraryUsageDescription",
		"NSPhotoLibraryAddUsageDescription",
	]
	var next := content
	for key in keys:
		var pattern := "(?s)[ \t]*<key>%s</key>\\s*<string>[^<]*</string>\\s*" % key
		var regex := RegEx.new()
		if regex.compile(pattern) == OK:
			next = regex.sub(next, "", true)
	if next == content:
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(next)
		print("[IAP] stripped unused iOS privacy keys from ", path)


func _strip_privacy_keys_from_pbx(path: String) -> void:
	var content := FileAccess.get_file_as_string(path)
	if content.is_empty():
		return
	var next := content
	var regex := RegEx.new()
	if regex.compile("\\s*INFOPLIST_KEY_NS(Camera|Microphone|PhotoLibraryAdd|PhotoLibrary)UsageDescription = .*?;") == OK:
		next = regex.sub(next, "", true)
	if next == content:
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(next)
		print("[IAP] stripped unused iOS privacy keys from ", path)


func _add_framework(path: String) -> void:
	if has_method("add_apple_embedded_platform_framework"):
		call("add_apple_embedded_platform_framework", path)
	elif has_method("add_ios_framework"):
		call("add_ios_framework", path)


func _add_linker_flags(flags: String) -> void:
	if has_method("add_apple_embedded_platform_linker_flags"):
		call("add_apple_embedded_platform_linker_flags", flags)
	elif has_method("add_ios_linker_flags"):
		call("add_ios_linker_flags", flags)
