extends SceneTree
## Loads every script under res://scripts and res://tests to catch parse errors.

func _initialize() -> void:
	var bad := 0
	for root in ["res://scripts", "res://tests"]:
		bad += _walk(root)
	print("LOAD ALL: %d scripts failed" % bad)
	quit(1 if bad > 0 else 0)


func _walk(dir: String) -> int:
	var bad := 0
	var d := DirAccess.open(dir)
	if d == null:
		return 0
	for f in d.get_files():
		if f.ends_with(".gd"):
			var s = load(dir + "/" + f)
			if s == null or not (s as Script).can_instantiate():
				print("FAILED: ", dir + "/" + f)
				bad += 1
	for sub in d.get_directories():
		bad += _walk(dir + "/" + sub)
	return bad
