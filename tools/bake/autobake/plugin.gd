@tool
extends EditorPlugin

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

func _go(scene: String) -> void:
	for i in 30:
		await get_tree().process_frame
	EditorInterface.open_scene_from_path(scene)
	for i in 10:
		await get_tree().process_frame
	var root := EditorInterface.get_edited_scene_root()
	var lm: LightmapGI = root.find_children("*", "LightmapGI", true, false)[0] if root else null
	print("AUTOBAKE: scene ", scene, " lightmap ", lm)
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(lm)
	EditorInterface.edit_node(lm)
	for i in 10:
		await get_tree().process_frame
	var b := _find_button(EditorInterface.get_base_control(), "Bake Lightmaps")
	print("AUTOBAKE: button ", b)
	if b == null:
		get_tree().quit(2)
		return
	var t := Time.get_ticks_msec()
	b.pressed.emit()
	print("AUTOBAKE: pressed, returned after %.1f s, data %s" % [(Time.get_ticks_msec() - t) / 1000.0, lm.light_data])
	for i in 5:
		await get_tree().process_frame
	for w in EditorInterface.get_base_control().get_tree().root.find_children("*", "AcceptDialog", true, false):
		if (w as Window).visible:
			print("AUTOBAKE: dialog '%s': %s" % [(w as Window).title, (w as AcceptDialog).dialog_text])
			if w is EditorFileDialog and (w as Window).title.to_lower().contains("lightmap"):
				var out := scene.get_basename() + ".lmbake"
				(w as Window).hide()
				print("AUTOBAKE: answering the file dialog with ", out)
				t = Time.get_ticks_msec()
				(w as EditorFileDialog).file_selected.emit(out)
				print("AUTOBAKE: bake returned after %.1f s, data %s" % [(Time.get_ticks_msec() - t) / 1000.0, lm.light_data])
	for w in EditorInterface.get_base_control().get_tree().root.find_children("*", "Label", true, false):
		var tx: String = (w as Label).text
		if (w as Label).is_visible_in_tree() and (tx.to_lower().contains("lightmap") or tx.to_lower().contains("bake")):
			print("AUTOBAKE: label: ", tx)
	var limit := float(OS.get_environment("BAKE_WAIT")) if OS.get_environment("BAKE_WAIT") != "" else 600.0
	while lm.light_data == null and (Time.get_ticks_msec() - t) / 1000.0 < limit:
		await get_tree().create_timer(2.0).timeout
	print("AUTOBAKE: after %.1f s, data %s" % [(Time.get_ticks_msec() - t) / 1000.0, lm.light_data])
	for i in 5:
		await get_tree().process_frame
	EditorInterface.save_scene()
	print("AUTOBAKE: saved")
	for i in 5:
		await get_tree().process_frame
	get_tree().quit(0 if lm.light_data != null else 3)
