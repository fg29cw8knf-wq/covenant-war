extends Node
## The hillside of the look back (AshfordNight._hillside: Gary's tunnel
## mouth and thorn bushes, 18 November) without playing the film. The
## village is built on its own, as tests/look_shot.gd builds it, and the
## hillside photographed at night from the film's own three cameras (down
## the hill from over the bank's shoulder; over his shoulder at Ashford;
## back up the hill at the mouth, as Corin's talk is filmed) and by day from
## close by, in front, from each side and from above.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 30 res://tests/hillside_shot.tscn -- <out_dir> [nostills]
## (Forward+: --rendering-driver vulkan --rendering-method forward_plus, with
## VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json where there's no graphics card.)
## And it measures: nothing of either model within LENS_CLEAR of the first
## two lenses or close in front of them; every bush's foot on the ground
## where it stands; the walk's blocks (the room the look back hands
## AshfordP1.walk_room) keeping a walker out of the bank and of every bush,
## and off neither of the two who stand there as it begins. Ends
## "HILLSIDE: ok" or the problems. "nostills" only measures (headless).

const LENS_CLEAR := 0.25    # nothing of a model nearer a lens than this (m), in its picture or not
const LENS_AHEAD := 1.6     # nor this near in front of it, inside its picture

var out := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var stills := not ("nostills" in args)
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	var v := AshfordVillage.new()
	add_child(v)
	var cam := Camera3D.new()
	cam.near = 0.1
	cam.far = 400.0
	add_child(cam)
	cam.current = true
	await _frames(10)
	var problems: Array = []
	var mouth := AshfordNight.MOUTH
	mouth.y = v.height(mouth.x, mouth.z)
	var to_v := AshfordNight.VILLAGE_LOOK - mouth
	to_v.y = 0.0
	to_v = to_v.normalized()
	var side := to_v.cross(Vector3.UP)
	var hill: Node3D = AshfordNight._hillside(v, mouth, to_v)
	var start := mouth + to_v * 1.2
	start.y = v.height(start.x, start.z)
	var bram := mouth + to_v * 0.4 + side * 0.9
	await _frames(4)
	var models := ResourceLoader.exists(AshfordNight.TUNNEL_MODEL) and ResourceLoader.exists(AshfordNight.THORN_MODEL)
	print("HILLSIDE: Gary's models %s; the mouth at %s, the village %s away down the hill" % [
		"in" if models else "not both there (the drawn bank or bushes)", mouth, to_v])
	var bank_n := hill.get_node_or_null("Bank") as Node3D
	if bank_n != null:
		# the bank seated: turned to the fall of the ground, no corner of its
		# foot in the air (its foot's four sides against the grass under them)
		var worst := -INF
		var r := AshfordNight.MOUTH_SIZE.x * 0.5
		for a in 8:
			var p := bank_n.global_position + Vector3(cos(a * TAU / 8.0), 0, sin(a * TAU / 8.0)) * r
			worst = maxf(worst, bank_n.global_position.y - v.height(p.x, p.z))
		print("HILLSIDE: the bank turned %.0f degrees to face down the hill; the highest its foot's edge stands over the grass %.2f m" % [
			rad_to_deg(bank_n.rotation.y), worst])
		if worst > 0.06:
			problems.append("the bank's foot stands %.2f m over the grass at one side" % worst)
	# the film's cameras (AshfordNight.look_back)
	var first: Array = AshfordNight.first_shot(hill, start, to_v)
	var shots := [
		["1_first", first[0], first[1], float(first[2])],
		["2_over_shoulder", start - to_v * 1.4 + Vector3(0, 1.75, 0) + side * 0.45, AshfordNight.VILLAGE_LOOK, 38.0],
		["3_back_up_the_hill", start + to_v * 3.0 + side * 1.4 + Vector3(0, 1.55, 0), mouth + Vector3(0, 1.0, 0), 34.0],
	]
	# --- measured -----------------------------------------------------------
	var pts: Array = []   # every corner of every triangle of the models, in the world
	for mi: MeshInstance3D in hill.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.mesh is PrimitiveMesh:
			continue
		var xf := mi.global_transform
		var f := mi.mesh.get_faces()
		for i in range(0, f.size(), 2):   # (every other corner: plenty to find what's near)
			pts.append(xf * f[i])
	print("HILLSIDE: %d points of the models measured" % pts.size())
	for s in shots.slice(0, 2):
		var at: Vector3 = s[1]
		var fwd: Vector3 = ((s[2] as Vector3) - at).normalized()
		var half := deg_to_rad(float(s[3]) * 0.5) * 1.8   # (the picture is wider than it's high)
		var nearest := INF
		var ahead := INF
		for p: Vector3 in pts:
			var d := p - at
			var l := d.length()
			nearest = minf(nearest, l)
			if l < LENS_AHEAD and l > 0.001 and d.normalized().angle_to(fwd) < half:
				ahead = minf(ahead, l)
		print("HILLSIDE: shot %s: the nearest of the models %.2f m from the lens; the nearest inside its picture %s" % [
			s[0], nearest, ("%.2f m" % ahead) if ahead < INF else "none within %.1f m" % LENS_AHEAD])
		if nearest < LENS_CLEAR:
			problems.append("shot %s: a model %.2f m from the lens" % [s[0], nearest])
		if ahead < INF:
			problems.append("shot %s: a model %.2f m in front of the lens, in the picture" % [s[0], ahead])
	# each bush on the ground where it stands
	var n_bush := 0
	for h in hill.get_children():
		if not (h is Node3D) or (h as Node3D).get_child_count() == 0 or String(h.name) == "Bank":
			continue
		if h is MeshInstance3D:
			continue
		n_bush += 1
		var gp := (h as Node3D).global_position
		var off := gp.y - v.height(gp.x, gp.z)
		if off > 0.02 or off < -0.25:
			problems.append("a bush at %s stands %.2f m off the ground" % [(h as Node3D).position, off])
	if models and n_bush != AshfordNight.THORNS.size():
		problems.append("%d bushes stand there, %d listed" % [n_bush, AshfordNight.THORNS.size()])
	# the walk kept out of them, and not onto the two who stand there
	var solid: Array = hill.get_meta("solid", [])
	var room := {"root": hill, "floor_y": start.y, "walk": Rect2(-3.0, -2.0, 6.0, 12.0), "blocks": solid}
	if models:
		var inside := 0
		for b in solid:
			var c: Vector2 = b[0]
			var w := hill.to_global(Vector3(c.x, 0.0, c.y))
			var np := AshfordP1.room_clamp(room, w)
			var lp := hill.to_local(np)
			if Vector2(lp.x, lp.z).distance_to(c) < float(b[1]) - 0.01:
				inside += 1
		if inside > 0 or solid.size() != 1 + AshfordNight.THORNS.size():
			problems.append("the walk's blocks: %d of %d, %d of them walked into" % [solid.size(), 1 + AshfordNight.THORNS.size(), inside])
		for who in [["the player", start], ["Bram", bram]]:
			var np := AshfordP1.room_clamp(room, who[1])
			var moved := Vector2(np.x - (who[1] as Vector3).x, np.z - (who[1] as Vector3).z).length()
			if moved > 0.02:
				problems.append("%s starts inside something solid (moved %.2f m by the walk's blocks)" % [who[0], moved])
		print("HILLSIDE: %d bushes on the ground; %d things solid to the walk, none walked into; the two start clear of them" % [n_bush, solid.size()])
	# --- photographed ---------------------------------------------------------
	if stills:
		# the two who stand there, as plain shapes their size (the film's
		# own people aren't built here)
		for who in [[start, Color(0.75, 0.75, 0.8), 1.75], [Vector3(bram.x, v.height(bram.x, bram.z), bram.z), Color(0.6, 0.45, 0.35), 1.8]]:
			var body := MeshInstance3D.new()
			var cm := CapsuleMesh.new()
			cm.radius = 0.22
			cm.height = float(who[2])
			body.mesh = cm
			var bm := StandardMaterial3D.new()
			bm.albedo_color = who[1]
			body.material_override = bm
			add_child(body)
			body.global_position = (who[0] as Vector3) + Vector3(0, float(who[2]) * 0.5, 0)
		v.set_daylight(0.0)
		await _frames(6)
		for s in shots:
			cam.fov = float(s[3])
			cam.global_position = s[1]
			cam.look_at(s[2])
			await _frames(6)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join("night_%s.png" % s[0]))
		v.set_daylight(1.0)
		await _frames(6)
		var mid := mouth - to_v * 1.0 + Vector3(0, 0.9, 0)
		var days := [
			["front", mid + to_v * 6.5 + Vector3(0, 1.0, 0), mid, 40.0],
			["left", mid + to_v * 3.0 + side * 6.0 + Vector3(0, 1.6, 0), mid, 40.0],
			["right", mid + to_v * 3.0 - side * 6.0 + Vector3(0, 1.6, 0), mid, 40.0],
			["above", mid + to_v * 3.5 + Vector3(0, 8.0, 0), mid, 44.0],
			["mouth", mouth + to_v * 2.6 + Vector3(0, 0.9, 0), mouth - to_v * 0.6 + Vector3(0, 0.5, 0), 40.0],
		]
		for s in days:
			cam.fov = float(s[3])
			cam.global_position = s[1]
			cam.look_at(s[2])
			await _frames(6)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join("day_%s.png" % s[0]))
	if problems.is_empty():
		print("HILLSIDE: ok")
	else:
		for p in problems:
			print("  problem: ", p)
		print("HILLSIDE: %d problems" % problems.size())
	get_tree().quit(0 if problems.is_empty() else 1)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
