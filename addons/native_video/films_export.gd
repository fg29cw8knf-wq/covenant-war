@tool
extends EditorExportPlugin
## Ships Gary's 4K films loose in the app bundles, where NativeVideoPlayer
## finds them (find_file): the bundle's root on an iPhone, Contents/Resources
## on a Mac. The films are every .mp4 in addons/native_video/films/ at export
## time; the iPhone and Mac workflows download them from the repository's
## "films" release first (tools/fetch_films.sh), and nothing is committed (the
## opening alone is 420 MB). Without a film the app plays the Theora copy in
## the pack instead, so an export never fails for want of one.

const FILMS_DIR := "res://addons/native_video/films"


func _get_name() -> String:
	return "NativeVideoFilms"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform.get_os_name() in ["iOS", "macOS"]


func _export_begin(features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	var dir := DirAccess.open(FILMS_DIR)
	if dir == null:
		print("NativeVideoFilms: no films folder (%s); the apps will play the Theora copies" % FILMS_DIR)
		return
	var shipped := 0
	for f in dir.get_files():
		if not f.ends_with(".mp4"):
			continue
		var film := FILMS_DIR.path_join(f)
		if "ios" in features:
			add_apple_embedded_platform_bundle_file(film)
		elif "macos" in features:
			add_shared_object(film, PackedStringArray(), "Contents/Resources")
		else:
			continue
		shipped += 1
		print("NativeVideoFilms: %s goes in the app (%.0f MB)" % [f, FileAccess.get_size(film) / 1048576.0])
	if shipped == 0:
		print("NativeVideoFilms: no .mp4 in %s; the apps will play the Theora copies" % FILMS_DIR)
