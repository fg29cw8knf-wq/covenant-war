class_name Cine
extends RefCounted
## Staging for the story's cutscenes in the 3D world: the camera's shots,
## people walking and running to their marks, subtitles and choices with the
## movie bars (CineOverlay). Everything takes the World it's played in.
##
## People are named the way dialogue names them: "player", an NPC's id
## ("bram", "corin"), or an extra the scene added with spawn() ("krell").
##
##   await Cine.begin(w)
##   Cine.shot(w, Vector3(4, 2, 9), Vector3(0, 1.5, 0))          # cut
##   await Cine.move(w, Vector3(6, 3, 12), Vector3(0, 2, 0), 3.0) # glide
##   await Cine.walk(w, "bram", Vector3(1, 0, 4))
##   await Cine.say(w, "bram", "Inside! All of you, inside!")
##   await Cine.end(w)


# ------------------------------------------------------------------ frame ---

## The movie bars and subtitles for this world (made on first use).
static func overlay(w: World) -> CineOverlay:
	if w.has_meta("cine_overlay"):
		var o = w.get_meta("cine_overlay")
		if is_instance_valid(o):
			return o
	var ov := CineOverlay.new()
	w.add_child(ov)
	w.set_meta("cine_overlay", ov)
	return ov


## Takes the world over for a cutscene: no walking, no buttons, bars in.
static func begin(w: World) -> void:
	w.busy = true
	w.cine = true
	if w.hud != null:
		w.hud.set_controls_visible(false)
		w.hud.dialogue.close()
		for n in w.npcs:
			n.doll.set_marker("")
	await overlay(w).bars(true)


## Gives the world back to the player.
static func end(w: World, cam_home := true) -> void:
	await overlay(w).bars(false)
	if cam_home:
		await w.cine_home(0.8)
	w.end_cine()
	if w.hud != null:
		w.hud.set_controls_visible(true)
	w.busy = false


static func fade(w: World, to_alpha: float, secs := 0.8) -> void:
	await overlay(w).fade(to_alpha, secs)


static func caption(w: World, text: String, sub := "", secs := 2.6) -> void:
	await overlay(w).caption(text, sub, secs)


## A subtitle from `who` (or narration with who = ""). Their figure talks
## while it's up. `hold` sets how long it stays.
static func say(w: World, who: String, text: String, hold := -1.0) -> void:
	var f = fig(w, who) if who != "" else null
	if f is Figure3D:
		(f as Figure3D).talking = true
	var nm := ""
	if who != "":
		nm = String(w.get_meta("extra_names", {}).get(who, "")) if w.has_meta("extra_names") else ""
		if nm == "":
			nm = w._speaker(who)
	await overlay(w).say(nm, w._fmt(text), hold)
	if f is Figure3D:
		(f as Figure3D).talking = false


static func choose(w: World, options: Array) -> int:
	return await overlay(w).choose(options)


## Where the camera is now.
static func cam_pos(w: World) -> Vector3:
	return w.cam.global_position


static func wait(w: World, secs: float) -> void:
	await w.get_tree().create_timer(secs).timeout


# ---------------------------------------------------------------- camera ---

## Cuts the camera straight to a shot. fov < 0 keeps the lens.
static func shot(w: World, pos: Vector3, look: Vector3, fov := -1.0) -> void:
	w.cine = true
	w.cam.global_position = pos
	w.cam.look_at(look, Vector3.UP)
	if fov > 0.0:
		w.cam.fov = fov


## Glides the camera to a shot over `secs`, easing in and out.
static func move(w: World, pos: Vector3, look: Vector3, secs: float, fov := -1.0) -> void:
	w.cine = true
	var from_pos := w.cam.global_position
	var from_look := from_pos + (-w.cam.global_transform.basis.z) * from_pos.distance_to(look)
	var f0 := w.cam.fov
	var f1 := fov if fov > 0.0 else f0
	var tw := w.create_tween()
	tw.tween_method(func(u: float) -> void:
		var e := u * u * (3.0 - 2.0 * u)
		w.cam.global_position = from_pos.lerp(pos, e)
		w.cam.look_at(from_look.lerp(look, e), Vector3.UP)
		w.cam.fov = lerpf(f0, f1, e), 0.0, 1.0, maxf(secs, 0.01))
	await tw.finished


## A slow, steady camera move (no easing): a push-in, a crane, a pan.
static func drift(w: World, pos_a: Vector3, pos_b: Vector3, look_a: Vector3, look_b: Vector3, secs: float, fov := -1.0) -> void:
	w.cine = true
	if fov > 0.0:
		w.cam.fov = fov
	var tw := w.create_tween()
	tw.tween_method(func(u: float) -> void:
		w.cam.global_position = pos_a.lerp(pos_b, u)
		w.cam.look_at(look_a.lerp(look_b, u), Vector3.UP), 0.0, 1.0, maxf(secs, 0.01))
	await tw.finished


## Keeps the camera with someone moving for `secs`: it sits at `offset` from
## them and looks at them (plus `look_off`), catching up smoothly.
static func follow(w: World, who: String, offset: Vector3, look_off: Vector3, secs: float, lag := 4.0) -> void:
	w.cine = true
	var b := body(w, who)
	if b == null:
		await wait(w, secs)
		return
	var t := 0.0
	var look := b.global_position + look_off
	while t < secs and is_instance_valid(b):
		var dt := w.get_process_delta_time()
		t += dt
		var k := minf(1.0, dt * lag)
		w.cam.global_position = w.cam.global_position.lerp(b.global_position + offset, k)
		look = look.lerp(b.global_position + look_off, minf(1.0, dt * lag * 1.5))
		w.cam.look_at(look, Vector3.UP)
		await w.get_tree().process_frame


# ---------------------------------------------------------------- people ---

## The node that stands for someone (moved to move them).
static func body(w: World, who: String) -> Node3D:
	if who == "player":
		return w.player
	var n = w._npc_by_id(who)
	if n != null:
		return n.body
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	return ex.get(who, {}).get("body", null)


## Their figure (cut-out or 3D model).
static func fig(w: World, who: String):
	if who == "player":
		return w.player_doll
	var n = w._npc_by_id(who)
	if n != null:
		return n.doll
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	return ex.get(who, {}).get("doll", null)


## Adds someone to the scene who isn't one of the area's NPCs (Krell, the
## Herald, villagers in a crowd). `name` is what their subtitles say.
static func spawn(w: World, id: String, look: String, pos: Vector3, name := "") -> PaperDoll:
	var b := Node3D.new()
	b.name = "Extra_" + id
	w.add_child(b)
	b.global_position = pos
	var d := Figure3D.make(look, id)
	b.add_child(d)
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	ex[id] = {"body": b, "doll": d}
	w.set_meta("extras", ex)
	if name != "":
		var nm: Dictionary = w.get_meta("extra_names", {}) if w.has_meta("extra_names") else {}
		nm[id] = name
		w.set_meta("extra_names", nm)
	return d


## The name someone's subtitles carry ("The Pale Herald").
static func call_by(w: World, id: String, name: String) -> void:
	var nm: Dictionary = w.get_meta("extra_names", {}) if w.has_meta("extra_names") else {}
	nm[id] = name
	w.set_meta("extra_names", nm)


static func despawn(w: World, id: String) -> void:
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	if ex.has(id):
		var b: Node3D = ex[id].body
		if is_instance_valid(b):
			b.queue_free()
		ex.erase(id)


## Puts someone on a spot at once, facing `face_to` if given.
## The ground's height under a point, where the set has a terrain (else p.y).
static func ground(w: World, p: Vector3) -> float:
	if w.has_meta("village"):
		var v = w.get_meta("village")
		if is_instance_valid(v) and v.has_method("height"):
			return float(v.height(p.x, p.z))
	return p.y


## Is this body standing on the set's terrain (not in a room built below it)?
static func _on_terrain(w: World, b: Node3D) -> bool:
	if not w.has_meta("village"):
		return false
	var g := ground(w, b.global_position)
	return absf(b.global_position.y - g) < 3.0


static func place(w: World, who: String, at: Vector3, face_to = null) -> void:
	var b := body(w, who)
	if b == null:
		return
	if b.get_meta("cine_path", 0) != 0:
		# stop any walk they were on
		b.set_meta("cine_path", 0)
		var wf = fig(w, who)
		if wf != null:
			wf.walking = false
			if wf is Figure3D:
				(wf as Figure3D).pace = 0.0
				(wf as Figure3D).gait = "walk"
	var y := at.y
	if at.y == 0.0:
		y = ground(w, at) if _on_terrain(w, b) else b.global_position.y
	b.global_position = Vector3(at.x, y, at.z)
	if face_to != null:
		var f = fig(w, who)
		var d: Vector3 = (face_to as Vector3) - b.global_position
		d.y = 0.0
		if f is Figure3D:
			(f as Figure3D).snap_face(d)
		elif f != null:
			f.face(d, w.cam)


## Turns someone to look at a point (or at someone, by name).
static func look(w: World, who: String, at) -> void:
	var f = fig(w, who)
	if f == null:
		return
	var p: Vector3 = at if at is Vector3 else body(w, String(at)).global_position
	f.look_toward(p, w.cam)


## Walks (or runs, gait "run") someone to `to` at `speed` m/s.
static func walk(w: World, who: String, to: Vector3, speed := 1.5, gait := "walk") -> void:
	await path(w, who, [to], speed, gait)


## Walks someone through a list of points.
static func path(w: World, who: String, points: Array, speed := 1.5, gait := "walk") -> void:
	var b := body(w, who)
	var f = fig(w, who)
	if b != null and f == null and b.has_meta("beast"):
		await _beast_path(w, b, points, speed)
		return
	if b == null or f == null:
		return
	if f is Figure3D:
		(f as Figure3D).gait = gait
		(f as Figure3D).pace = speed
	f.walking = true
	# a later walk, or place(), takes over from this one
	var token := Time.get_ticks_usec()
	b.set_meta("cine_path", token)
	# over the village's slopes, feet stay on the grass
	var follow := _on_terrain(w, b)
	for p in points:
		var to: Vector3 = p
		var from := b.global_position
		to.y = from.y
		var dist := Vector2(to.x - from.x, to.z - from.z).length()
		if dist < 0.05:
			continue
		f.face(to - from, w.cam)
		var tw := w.create_tween()
		tw.tween_method(func(u: float) -> void:
			if is_instance_valid(b) and b.get_meta("cine_path", 0) == token:
				var at := from.lerp(to, u)
				if follow:
					at.y = ground(w, at)
				b.global_position = at, 0.0, 1.0, dist / maxf(speed, 0.1))
		await tw.finished
		if not is_instance_valid(b) or b.get_meta("cine_path", 0) != token:
			return
	if is_instance_valid(f):
		f.walking = false
		if f is Figure3D:
			(f as Figure3D).pace = 0.0
			(f as Figure3D).gait = "walk"


## Plays a clip on a 3D figure (cut-outs give a little hop instead).
static func act(w: World, who: String, clip: String, speed := 1.0) -> void:
	var f = fig(w, who)
	if f is Figure3D:
		await (f as Figure3D).act(clip, speed)
	elif f != null:
		await hop(w, who)


## Two people hand in hand (Corin leading Tilly off): `a`'s hand on `b`'s
## side and `b`'s hand on `a`'s side meet between them, and stay together
## as `a` moves (if `b` falls behind, their arm stretches after). Only for
## 3D figures; let_go_hands() parts them.
static func hold_hands(w: World, a: String, b: String, secs := 0.3) -> void:
	var fa = fig(w, a)
	var fb = fig(w, b)
	if not (fa is Figure3D and fb is Figure3D):
		return
	var big := fa as Figure3D
	var small := fb as Figure3D
	var to_b := body(w, b).global_position - body(w, a).global_position
	to_b.y = 0.0
	# which hand: whichever is on the other's side (a figure's right is
	# its facing turned clockwise; in its own frame left is +x)
	var a_right := to_b.dot(big.facing().cross(Vector3.UP)) > 0.0
	var b_right := (-to_b).dot(small.facing().cross(Vector3.UP)) > 0.0
	var meet := Node3D.new()
	meet.name = "HandInHand"
	# beside the bigger one's hip, at a height both can reach
	var x := 0.3 * big.stature() * (-1.0 if a_right else 1.0)
	big.carry(meet, Vector3(x, 0.46 * (big.stature() + small.stature()), 0.1))
	big.reach(null if a_right else meet, meet if a_right else null, secs)
	small.reach(null if b_right else meet, meet if b_right else null, secs)
	w.set_meta("hands_" + a + "_" + b, meet)


static func let_go_hands(w: World, a: String, b: String, secs := 0.25) -> void:
	var key := "hands_" + a + "_" + b
	var meet = w.get_meta(key, null)
	if w.has_meta(key):
		w.remove_meta(key)
	for who in [a, b]:
		var f = fig(w, who)
		if f is Figure3D:
			(f as Figure3D).let_go(secs)
	if meet != null and is_instance_valid(meet):
		await wait(w, secs + 0.05)
		if is_instance_valid(meet):
			(meet as Node).queue_free()


## A cut-out's way of showing a feeling: a quick hop on the spot.
static func hop(w: World, who: String, height := 0.18) -> void:
	var b := body(w, who)
	if b == null:
		return
	var y := b.global_position.y
	var tw := w.create_tween()
	tw.tween_property(b, "global_position:y", y + height, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(b, "global_position:y", y, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


## Where to look to see someone's face.
static func head(w: World, who: String) -> Vector3:
	var f = fig(w, who)
	if f is Figure3D:
		return (f as Figure3D).bone_pos("Head") + Vector3(0, 0.08, 0)
	var b := body(w, who)
	return (b.global_position if b != null else Vector3.ZERO) + Vector3(0, 1.55, 0)


## A shot over `from`'s shoulder onto `to`'s face (a conversation).
static func over_shoulder(w: World, from: String, to: String, side := 1.0, fov := 30.0) -> void:
	var a := body(w, from).global_position
	var b := body(w, to).global_position
	var d := b - a
	d.y = 0.0
	d = d.normalized()
	var right := d.cross(Vector3.UP).normalized() * side
	shot(w, a - d * 1.6 + right * 0.75 + Vector3(0, 1.75, 0), head(w, to) - Vector3(0, 0.08, 0), fov)


## A two-shot from the side of a pair facing each other.
static func two_shot(w: World, a_who: String, b_who: String, dist := 4.2, height := 1.55, side := 1.0, fov := 32.0) -> void:
	var a := body(w, a_who).global_position
	var b := body(w, b_who).global_position
	var mid := (a + b) * 0.5
	var d := b - a
	d.y = 0.0
	var perp := d.normalized().cross(Vector3.UP).normalized() * side
	shot(w, mid + perp * dist + Vector3(0, height, 0), mid + Vector3(0, 1.3, 0), fov)


## A light that only exists for a shot (a face lit by a lantern, a rim light).
static func light(w: World, at: Vector3, col: Color, energy: float, rng := 6.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = false
	w.add_child(l)
	l.global_position = at
	return l


# ---------------------------------------------------------------- beasts ---

## Adds a creature to the scene (a Shieldhound at a hunter's heel), from
## assets/models/creatures/<model_id>.glb. `eyes` lights its eyes (a hound's
## lantern-light) when it isn't clear.
static func beast(w: World, id: String, model_id: String, pos: Vector3, eyes := Color(0, 0, 0, 0)) -> Node3D:
	var root := Node3D.new()
	root.name = "Beast_" + id
	root.set_meta("beast", true)
	w.add_child(root)
	root.global_position = pos
	var path := "res://assets/models/creatures/%s.glb" % model_id
	if ResourceLoader.exists(path):
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		root.add_child(inst)
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap != null:
			for c in ["idle", "run"]:
				if ap.has_animation(c):
					ap.get_animation(c).loop_mode = Animation.LOOP_LINEAR
			if ap.has_animation("idle"):
				ap.play("idle")
				ap.seek(randf(), true)
			root.set_meta("anim", ap)
	if eyes.a > 0.0:
		var l := OmniLight3D.new()
		l.light_color = Color(eyes.r, eyes.g, eyes.b)
		l.light_energy = 1.6
		l.omni_range = 3.0
		l.position = Vector3(0, 0.95, 0.75)
		root.add_child(l)
		for sx in [-1, 1]:
			var g := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.035
			sm.height = 0.07
			g.mesh = sm
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(eyes.r, eyes.g, eyes.b) * 4.0
			g.material_override = m
			g.position = Vector3(0.09 * sx, 0.9, 0.7)
			root.add_child(g)
	var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
	ex[id] = {"body": root, "doll": null}
	w.set_meta("extras", ex)
	return root


## Plays one of a creature's clips ("attack", "run", "idle"...); waits for a
## one-off clip to finish.
static func beast_play(w: World, id: String, clip: String, speed := 1.0) -> void:
	var b := body(w, id)
	if b == null or not b.has_meta("anim"):
		return
	var ap: AnimationPlayer = b.get_meta("anim")
	if not ap.has_animation(clip):
		return
	ap.speed_scale = speed
	ap.play(clip, 0.15)
	var a := ap.get_animation(clip)
	if a.loop_mode == Animation.LOOP_NONE:
		await w.get_tree().create_timer(a.length / maxf(speed, 0.01)).timeout
		if ap.has_animation("idle") and ap.current_animation == clip:
			ap.play("idle", 0.25)


static func _beast_path(w: World, b: Node3D, points: Array, speed: float) -> void:
	var ap: AnimationPlayer = b.get_meta("anim") if b.has_meta("anim") else null
	if ap != null and ap.has_animation("run"):
		ap.play("run", 0.15)
		ap.speed_scale = clampf(speed / 5.0, 0.6, 1.6)
	for p in points:
		var to: Vector3 = p
		var from := b.global_position
		to.y = from.y
		var dist := from.distance_to(to)
		if dist < 0.05:
			continue
		var d := to - from
		b.rotation.y = atan2(d.x, d.z)
		var tw := w.create_tween()
		tw.tween_method(func(u: float) -> void:
			if is_instance_valid(b):
				b.global_position = from.lerp(to, u), 0.0, 1.0, dist / maxf(speed, 0.1))
		await tw.finished
	if ap != null and ap.has_animation("idle"):
		ap.speed_scale = 1.0
		ap.play("idle", 0.25)


## A gift of cards shown big over everything (DeckReveal); waits for the tap.
static func reveal(w: World, cards: Array, title: String, subtitle := "") -> void:
	var layer := CanvasLayer.new()
	layer.layer = 16
	w.add_child(layer)
	var r := DeckReveal.new()
	r.cards = cards
	r.title = title
	r.subtitle = subtitle
	r.theme = UITheme.make()
	layer.add_child(r)
	await r.closed
	layer.queue_free()
