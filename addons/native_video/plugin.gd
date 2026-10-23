@tool
extends EditorPlugin
## Editor side of the native video player: an export plugin that puts the 4K
## films into the iPhone and Mac app bundles (films_export.gd). Enabled in
## project.godot, so the headless exports in the workflows run it too.

var _films: EditorExportPlugin


func _enter_tree() -> void:
	_films = preload("res://addons/native_video/films_export.gd").new()
	add_export_plugin(_films)


func _exit_tree() -> void:
	if _films != null:
		remove_export_plugin(_films)
		_films = null
