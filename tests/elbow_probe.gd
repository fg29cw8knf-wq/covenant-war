extends Node3D
## Reaches staged on a model, the elbow measured as the body check measures
## it (tests/body_check.gd: how far it bends out of its hinge, "side"), with
## the IK's pole direction left free (the old way) and set to the back of the
## elbow (12 November). Stills of each in <out> when drawn.
##   [xvfb-run ... --rendering-driver opengl3] godot --path . res://tests/elbow_probe.tscn -- <out> [model]

const BC := preload("res://tests/body_check.gd")
var out := "/tmp/elbow"
var model := "player_a"

# reach targets in their own frame (x to their left, y up, z ahead), by name
const TARGETS := {
	"ahead_chest": [Vector3(-0.05, 1.25, 0.42), Vector3(0.05, 1.25, 0.42)],
	"across": [Vector3(-0.25, 1.15, 0.4), Vector3(0.25, 1.15, 0.4)],
	"low_ahead": [Vector3(0.2, 0.85, 0.45), Vector3(-0.2, 0.85, 0.45)],
	"high": [Vector3(0.3, 1.75, 0.35), Vector3(-0.3, 1.75, 0.35)],
	"side": [Vector3(0.55, 1.2, 0.15), Vector3(-0.55, 1.2, 0.15)],
	"mouth": [Vector3(0.03, 1.5, 0.15), Vector3(-0.03, 1.5, 0.15)],
	"out_low": [Vector3(0.35, 0.95, 0.25), Vector3(-0.35, 0.95, 0.25)],
}

var bc
var _got := {}
var _want := false


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1:
		model = a[1]
	DirAccess.make_dir_recursive_absolute(out)
	var cam := Camera3D.new()
	add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.35, 0.38, 0.42)
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	add_child(env)
	bc = BC.new()
	bc.root = self
	for mode in ["free", "hinge"]:
		Figure3D.pole_hinge = mode == "hinge"
		var f := Figure3D.new().setup(model) as Figure3D
		add_child(f)
		await _frames(3)
		var d: Dictionary = bc._build(f)
		f._skel.skeleton_updated.connect(_on_skel.bind(f, d))
		var marks := [Node3D.new(), Node3D.new()]
		for m in marks:
			add_child(m)
		for tn in TARGETS:
			var tl: Array = TARGETS[tn]
			var s := f.stature()
			(marks[0] as Node3D).global_position = f.to_world(tl[0] * s)
			(marks[1] as Node3D).global_position = f.to_world(tl[1] * s)
			f.reach(marks[0], marks[1], 0.01)
			await _frames(6)
			_got = {}
			_want = true
			await _frames(2)
			_want = false
			print("ELBOW %s %s %s: %s" % [model, mode, tn, _got.get("text", "(no reading)")])
			if DisplayServer.get_name() != "headless":
				cam.global_position = f.to_world(Vector3(-0.2, 1.35, 1.3) * s)
				cam.look_at(f.to_world(Vector3(0, 1.15, 0.2) * s), Vector3.UP)
				cam.fov = 45
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(out.path_join("%s_%s_%s.png" % [model, tn, mode]))
			f.let_go(0.01)
			await _frames(4)
		f.queue_free()
		for m in marks:
			m.queue_free()
		await _frames(2)
	get_tree().quit()


func _on_skel(f: Figure3D, d: Dictionary) -> void:
	if not _want or not _got.is_empty():
		return
	var sk := f._skel
	var bits := []
	for jd in d.joints:
		if jd.kind != "elbow" and jd.kind != "ball":
			continue
		var gp := sk.get_bone_global_pose(jd.p)
		var gb := sk.get_bone_global_pose(jd.b)
		var q := (gp.basis.orthonormalized().inverse() * gb.basis.orthonormalized()).get_rotation_quaternion()
		var m: Dictionary = bc._measure(jd, q)
		if jd.kind == "elbow":
			bits.append("%s bend %.0f side %.0f back %.0f" % [jd.label, m.swing, m.side, m.back])
		else:
			bits.append("%s twist %.0f" % [jd.label, m.twist])
	_got = {"text": "; ".join(bits)}


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
