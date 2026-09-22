@tool
extends EditorPlugin

# A class member to hold the editor export plugin during its lifecycle.
var export_plugin : BillingPluginExportPlugin


func _enter_tree():
	# Initialization of the plugin goes here.
	export_plugin = BillingPluginExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_export_plugin(export_plugin)
	export_plugin = null


class BillingPluginExportPlugin extends EditorExportPlugin:
	const PLUGIN_NAME := "GodotGooglePlayBilling"
	const LIB_DEBUG := "res://addons/GodotGooglePlayBilling/bin/debug/GodotGooglePlayBilling-debug.aar"
	const LIB_RELEASE := "res://addons/GodotGooglePlayBilling/bin/release/GodotGooglePlayBilling-release.aar"
	const BILLING_DEP := "com.android.billingclient:billing-ktx:8.3.0"

	func _supports_platform(platform):
		if platform is EditorExportPlatformAndroid:
			return true
		return false

	func _get_android_libraries(_platform, debug):
		if debug:
			return PackedStringArray([LIB_DEBUG])
		return PackedStringArray([LIB_RELEASE])

	func _get_android_dependencies(_platform, _debug):
		return PackedStringArray([BILLING_DEP])

	func _get_android_manifest_element_contents(_platform, _debug) -> String:
		# Ensure Play Console always sees BILLING even if a merge step drops the AAR meta.
		return """
	<uses-permission android:name="com.android.vending.BILLING"/>
	"""

	func _get_name():
		return PLUGIN_NAME
