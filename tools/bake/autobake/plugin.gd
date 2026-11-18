@tool
extends EditorPlugin
# Presses the LightmapGI's Bake button in the scene named by BAKE_SCENE, answers
# the "where to save" dialog with BAKE_OUT, saves the scene and quits (exit
# code 0 when the light was baked). If the editor was busy re-importing a
# texture when the bake tried to import its own light image (it fails with
# "Failed creating lightmap images"), it waits for the editor to settle and
# bakes again, up to three times.

func _enter_tree() -> void:
	var scene := OS.get_environment("BAKE_SCENE")
	if scene == "":
		return
	_go.call_deferred(scene)

func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text:
		return n
	for c in n.get_children():
		var b := _find_button(c, text)
		if b != null:
			return b
	return null

func _settle(seconds: float) -> void:
	var fs := EditorInterface.get_resource_filesystem()
	var t := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - t) / 1000.0 < seconds or fs.is_scanning():
		await get_tree().create_timer(1.0).timeout

func _bake_once(lm: LightmapGI, out: String) -> void:
	var b := _find_button(EditorInterface.get_base_control(), "Bake Lightmaps")
	print("AUTOBAKE: button ", b)
	if b == null:
		return
	b.pressed.emit()
	for i in 5:
		await get_tree().process_frame
	for w in EditorInterface.get_base_control().get_tree().root.find_children("*", "AcceptDialog", true, false):
		if (w as Window).visible:
			print("AUTOBAKE: dialog '%s': %s" % [(w as Window).title, (w as AcceptDialog).dialog_text])
			if w is EditorFileDialog and (w as Window).title.to_lower().contains("lightmap"):
				(w as Window).hide()
				print("AUTOBAKE: answering the file dialog with ", out)
				var t := Time.get_ticks_msec()
				(w as EditorFileDialog).file_selected.emit(out)
				print("AUTOBAKE: bake returned after %.1f s, data %s" % [(Time.get_ticks_msec() - t) / 1000.0, lm.light_data])
			elif (w as Window).title.to_lower().contains("lightmap") or (w as AcceptDialog).dialog_text.to_lower().contains("lightmap"):
				(w as Window).hide()

func _go(scene: String) -> void:
	for i in 30:
		await get_tree().process_frame
	EditorInterface.open_scene_from_path(scene)
	for i in 10:
		await get_tree().process_frame
	var root := EditorInterface.get_edited_scene_root()
	var lm: LightmapGI = root.find_children("*", "LightmapGI", true, false)[0] if root else null
	print("AUTOBAKE: scene ", scene, " lightmap ", lm)
	if lm == null:
		get_tree().quit(2)
		return
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(lm)
	EditorInterface.edit_node(lm)
	await _settle(5.0)
	var out := OS.get_environment("BAKE_OUT") if OS.get_environment("BAKE_OUT") != "" else scene.get_basename() + ".lmbake"
	for attempt in 3:
		await _bake_once(lm, out)
		if lm.light_data != null:
			break
		print("AUTOBAKE: no light yet (try %d), letting the editor settle" % (attempt + 1))
		await _settle(20.0)
	print("AUTOBAKE: data %s" % lm.light_data)
	for i in 5:
		await get_tree().process_frame
	EditorInterface.save_scene()
	print("AUTOBAKE: saved")
	for i in 5:
		await get_tree().process_frame
	get_tree().quit(0 if lm.light_data != null else 3)
