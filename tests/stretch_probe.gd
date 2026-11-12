extends Node
## The attic's waking stretch (Figure3D.stretch) tried in several shapes on
## a model: each held at its full, its joints measured the way the body
## check measures them, and a still from the front and the side
## (12 November, Gary's yes to a gentler stretch: STRETCH twisted the
## shoulders 150 to 160 degrees, past any body's 110).
##
##   xvfb-run -a godot --rendering-driver opengl3 --path . res://tests/stretch_probe.tscn -- <dir> [model]

const BC := preload("res://tests/body_check.gd")

const SHAPES := {
	"now": Figure3D.STRETCH,
	"a": {"LeftArm": Vector3(-130, 0, 25), "RightArm": Vector3(-130, 0, -25),
		"LeftForeArm": Vector3(35, 0, 0), "RightForeArm": Vector3(35, 0, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
	"b": {"LeftArm": Vector3(-120, 0, 35), "RightArm": Vector3(-120, 0, -35),
		"LeftForeArm": Vector3(55, 0, 0), "RightForeArm": Vector3(55, 0, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
	"c": {"LeftArm": Vector3(-140, 0, 20), "RightArm": Vector3(-140, 0, -20),
		"LeftForeArm": Vector3(40, 0, 0), "RightForeArm": Vector3(40, 0, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
	"d": {"LeftArm": Vector3(-110, 0, 40), "RightArm": Vector3(-110, 0, -40),
		"LeftForeArm": Vector3(70, 0, 0), "RightForeArm": Vector3(70, 0, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
	"e": {"LeftArm": Vector3(-135, 0, 22), "RightArm": Vector3(-135, 0, -22),
		"LeftForeArm": Vector3(-25, 0, 0), "RightForeArm": Vector3(-25, 0, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
	"f": {"LeftArm": Vector3(-125, 0, 30), "RightArm": Vector3(-125, 0, -30),
		"LeftForeArm": Vector3(-35, 0, 0), "RightForeArm": Vector3(-35, 0, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
	"g": {"LeftArm": Vector3(-145, 0, 18), "RightArm": Vector3(-145, 0, -18),
		"LeftForeArm": Vector3(-20, 0, 0), "RightForeArm": Vector3(-20, 0, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
	"j": {"LeftArm": Vector3(-135, 0, 22), "RightArm": Vector3(-135, 0, -22),
		"LeftForeArm": Vector3(-25, 60, 0), "RightForeArm": Vector3(-25, -60, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
	"k": {"LeftArm": Vector3(-135, 0, 22), "RightArm": Vector3(-135, 0, -22),
		"LeftForeArm": Vector3(-25, -60, 0), "RightForeArm": Vector3(-25, 60, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
	"h": {"LeftArm": Vector3(-135, 0, 22), "RightArm": Vector3(-135, 0, -22),
		"LeftForeArm": Vector3(-25, 0, 0), "RightForeArm": Vector3(-25, 0, 0),
		"LeftHand": Vector3(-35, 0, 0), "RightHand": Vector3(-35, 0, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
	"m": {"LeftArm": Vector3(-135, 0, 22), "RightArm": Vector3(-135, 0, -22),
		"LeftForeArm": Vector3(-40, 55, 0), "RightForeArm": Vector3(-40, -55, 0),
		"Spine1": Vector3(-8, 0, 0), "Spine2": Vector3(-8, 0, 0), "Head": Vector3(-14, 0, 0)},
}

var bc
var _want := false
var _got := {}


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var dir: String = a[0] if a.size() > 0 else "/tmp/sp"
	var model: String = a[1] if a.size() > 1 else "player_a"
	var only: Array = []
	for s in a:
		if String(s).begins_with("shapes="):
			only = Array(String(s).substr(7).split(","))
	bc = BC.new()
	bc.root = self
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.27, 0.3)
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sun)
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	var f := Figure3D.new().setup(model) as Figure3D
	add_child(f)
	await _frames(3)
	var d: Dictionary = bc._build(f)
	f._skel.skeleton_updated.connect(_on_skel.bind(f, d))
	var fwd := f.facing()
	var side := fwd.cross(Vector3.UP)
	var h := 1.0 * f.stature() / 1.8
	for key in SHAPES:
		if not only.is_empty() and not (key in only):
			continue
		var nm := "stretch_try_%s" % key
		f.stretch(2.0, SHAPES[key], nm)
		await _frames(2)
		var worst := 0.0
		var lines: Array = []
		for at in [0.3, 0.45, 0.55, 0.65]:
			f.pose(nm, at, 0.0)
			await _frames(2)
			_got = {}
			_want = true
			await _frames(2)
			_want = false
			if _got.is_empty():
				_want = true
				_on_skel(f, d)
				_want = false
			for row in _got.get("joints", []):
				lines.append("t%.2f %s" % [at, row[0]])
				worst = maxf(worst, float(row[1]))
			if is_equal_approx(at, 0.55):
				for view in [["front", fwd * 3.0], ["side", side * 3.0 + fwd * 0.8]]:
					cam.position = f.global_position + view[1] + Vector3(0, h * 1.2, 0)
					cam.look_at(f.global_position + Vector3(0, h * 1.15, 0), Vector3.UP)
					cam.fov = 50.0
					await _frames(3)
					get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [dir, key, view[0]])
		print("STRETCH %s: worst %.0f deg over; %s" % [key, worst, "; ".join(lines) if not lines.is_empty() else "clean"])
	get_tree().quit()


func _on_skel(f: Figure3D, d: Dictionary) -> void:
	if not _want or not _got.is_empty():
		return
	var sk := f._skel
	var joints: Array = []
	for jd in d.joints:
		var gp := sk.get_bone_global_pose(jd.p)
		var gb := sk.get_bone_global_pose(jd.b)
		var q := (gp.basis.orthonormalized().inverse() * gb.basis.orthonormalized()).get_rotation_quaternion()
		var m: Dictionary = bc._measure(jd, q)
		var base: Dictionary = BC.LIMITS[jd.kind]
		for k in ["twist", "swing", "back", "side", "fold"]:
			if not base.has(k):
				continue
			var val: float = float(m.swing) if k == "fold" else float(m[k])
			if val > float(base[k]):
				joints.append(["%s %s %.0f (body %.0f)" % [jd.label, k, val, float(base[k])], val - float(base[k])])
	_got = {"joints": joints}


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
