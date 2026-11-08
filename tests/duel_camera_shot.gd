extends Node
## The moving duel camera (8 November, Gary: "During battle can we have the
## camera pan around the playing board so we can watch whats happening from
## all angles and have a button at the top if players would rather have it
## locked like it is now"). Plays the parts on the 3D field with both rows
## full and checks them:
##   path     the camera travelling round the Circle while nothing's asked of
##            the player: stills every `every` seconds over a lap; it must
##            turn, stay within its heights, keep off every Totem's body and
##            above the mat, and never jump between frames
##   choose   the player's turn to choose: it must settle exactly home (the
##            locked camera's view), and quickly
##   call     a Totem called on each side: it swings round in front of it
##   attack   an attack's shots, then on round from where they left it
##            (not back home), keeping clear as it goes
##   button   the Camera button: Locked goes home and stays, the setting is
##            saved as "locked"; Moving again sets off
##   all      every part (the default)
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
##       res://tests/duel_camera_shot.tscn -- <out_dir> [path] [choose] [call] [attack] [button] [every=12] [nostills]
## Nothing is drawn between the stills (as duel_cine_shot), so the frames
## between come quickly on a slow software renderer; the waits are game time.

var out := "user://"
var ds: DuelScreen
var parts: Array = []
var problems: Array = []
var every := 12.0
var stills := true
var _watch := false
var _last := Vector3.INF
var _worst_jump := 0.0
var _closest := INF
var _lowest := INF
var _frames := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	for a in args.slice(1):
		if a.begins_with("every="):
			every = float(a.substr(6))
		elif a == "nostills":
			stills = false
		else:
			parts.append(a)
	if parts.is_empty() or "all" in parts:
		parts = ["path", "choose", "call", "attack", "button"]
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["duel_3d"] = true
	Game.settings["duel_camera"] = "moving"
	SummonVideo.set_mode("off")
	RenderingServer.render_loop_enabled = false
	ds = DuelScreen.new().configure({"decks": ["emberstorm", "tidegrove"], "names": ["You", "Rival"],
		"profiles": [Lore.new_profile("You", "", 4), Lore.new_profile("Rival", "", 4)], "arena": "ashford",
		"ai": [false, false], "seed": 7, "speed": 1.0, "first": 0, "no_arena_events": true, "field3d": true})
	add_child(ds)
	var t := 0.0
	while (ds.game == null or ds.game.turn < 1 or ds.mode != "main") and t < 40.0:
		await _wait(0.2)
		t += 0.2
		if ds.banner_waiting:
			ds.tap_banner()
	var f := ds.field
	if not f.roam_on:
		problems.append("the camera wasn't moving with duel_camera \"moving\"")
	if ds.cam_btn == null or ds.cam_btn.text != "Camera: Moving":
		problems.append("no Camera button at the top saying Moving (%s)" % (ds.cam_btn.text if ds.cam_btn != null else "none"))
	await _board(["cinderpup", "ashen_drake", "brookfin"], ["mossling", "elderbark", "pebblit"])
	if "path" in parts:
		await _path()
	if "choose" in parts:
		await _choose()
	if "call" in parts:
		await _call()
	if "attack" in parts:
		await _attack()
	if "button" in parts:
		await _button()
	RenderingServer.render_loop_enabled = true
	print("CAMERA SHOT: problems: ", problems if not problems.is_empty() else "none")
	print("CAMERA SHOT: done")
	get_tree().quit()


func _process(_delta: float) -> void:
	if not _watch or ds == null or ds.field == null or ds.field.cam == null:
		return
	var f := ds.field
	var p := f.cam.global_position
	_frames += 1
	# (the path's own step: the drift, the shake and a blow's kick are laid
	# over it on purpose, as on the locked camera)
	var q := f.cam_pos + f._clearance(f.cam_pos) * f._follow_k
	if f._following and _last != Vector3.INF:
		_worst_jump = maxf(_worst_jump, q.distance_to(_last))
	_last = q if f._following else Vector3.INF
	if f._following:
		_lowest = minf(_lowest, p.y)
		for side in 2:
			for i in 3:
				var s = f.slots[side][i]
				if s.card_id == "" or s.shattered:
					continue
				var foot: Vector3 = f.foot_world(side, i)
				var h: float = s.creature_h
				# inside the body: within its radius and below its head
				var hd := Vector2(p.x - foot.x, p.z - foot.z).length()
				if p.y < foot.y + h:
					_closest = minf(_closest, hd)


func _wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, false).timeout


func _shot(name: String) -> void:
	var f := ds.field
	var s := DuelField3D._sph(f.cam_pos - f.cam_look)
	print("CAMERA SHOT: %s  yaw %.0f pitch %.0f dist %.1f look %s fov %.0f following %s home %s" % [name,
		rad_to_deg(wrapf(float(s[0]), -PI, PI)), rad_to_deg(float(s[1])), float(s[2]), f.cam_look, f.cam_fov, f._following, f.roam_home()])
	if not stills:
		return
	RenderingServer.render_loop_enabled = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/cam_%s.png" % [out, name])
	RenderingServer.render_loop_enabled = false


func _board(mine: Array, theirs: Array) -> Array:
	var g := ds.game
	var made := [[], []]
	var uid := 9500 + randi() % 300 * 3
	for side in 2:
		var ids: Array = mine if side == 0 else theirs
		g.players[side].slots = [null, null, null]
		for i in 3:
			if i < ids.size() and ids[i] != null:
				var tt := g._new_totem(DuelCard.new(uid, String(ids[i]), side), side, i, 0)
				uid += 1
				g.players[side].slots[i] = tt
				made[side].append(tt)
			else:
				made[side].append(null)
	g._changed()
	ds._refresh()
	await _wait(1.2)
	return made


func _watching_start() -> void:
	_watch = true
	_last = Vector3.INF
	_worst_jump = 0.0
	_closest = INF
	_lowest = INF
	_frames = 0


func _watching_end(tag: String, most := 0.3) -> void:
	_watch = false
	print("CAMERA SHOT: %s: %d frames, worst step between frames %.3f m, nearest a Totem's body %.2f m (below its head), lowest %.2f m" % [tag, _frames, _worst_jump, _closest, _lowest])
	# (a frame at 30 fps. On the path: steady, a few metres a second at most.
	# Out of a shot: no quicker than the locked camera's own way home, whose
	# cubic ease peaks at three times its average, about 1.7 m a frame)
	if _worst_jump > most:
		problems.append("%s: the camera jumped %.2f m between frames" % [tag, _worst_jump])
	if _closest < DuelField3D.CLEAR_R * 0.9:
		problems.append("%s: the camera came within %.2f m of a Totem's body" % [tag, _closest])
	if _lowest < DuelField3D.MAT_CLEAR - 0.05:
		problems.append("%s: the camera went down to %.2f m over the mat" % [tag, _lowest])


## Round the Circle while the rival plays (nothing asked of the player).
func _path() -> void:
	ds.mode = "busy"
	ds._set_hint("")
	_watching_start()
	var f := ds.field
	var yaw0: float = f._r_yaw
	var lap := 360.0 / DuelField3D.ROAM_SPEED
	var n := int(ceil(lap / every))
	var pmin := INF
	var pmax := -INF
	for k in n + 1:
		await _shot("path_%02d" % k)
		pmin = minf(pmin, rad_to_deg(f._r_pitch))
		pmax = maxf(pmax, rad_to_deg(f._r_pitch))
		if k < n:
			await _wait(every)
	_watching_end("path")
	var turned := rad_to_deg(f._r_yaw - yaw0)
	print("CAMERA SHOT: path: turned %.0f degrees in %.0f s, looked down from %.0f to %.0f degrees" % [turned, every * n, pmin, pmax])
	if absf(turned) < 200.0:
		problems.append("path: it only turned %.0f degrees round the Circle" % turned)
	if pmin < DuelField3D.ROAM_PITCH_MIN - 1.0 or pmax > DuelField3D.ROAM_PITCH_MAX + 1.0:
		problems.append("path: its height went outside its limits (%.0f to %.0f degrees)" % [pmin, pmax])


## The player's turn to choose: exactly home, and quickly.
func _choose() -> void:
	var f := ds.field
	ds.mode = "busy"
	await _wait(3.0)   # (out on the path somewhere)
	var away := f.cam_pos.distance_to(f._home_pos)
	ds.mode = "main"
	var t := 0.0
	while not f.roam_home() and t < 6.0:
		await _wait(0.1)
		t += 0.1
	await _shot("choose_home")
	print("CAMERA SHOT: choose: %.1f m from home, settled home in %.1f s" % [away, t])
	if not f.roam_home():
		problems.append("choose: the camera didn't settle home for the player (%.2f m off)" % f.cam_pos.distance_to(f._home_pos))
	elif f.cam_pos.distance_to(f._home_pos) > 0.001 or f.cam_look.distance_to(f._home_look) > 0.001 or absf(f.cam_fov - f._home_fov) > 0.01:
		problems.append("choose: settled, but not exactly home")
	if t > 3.0:
		problems.append("choose: it took %.1f s to come home" % t)
	# the slots' tap targets where the locked camera has them
	var v = ds.views[0][1]
	var want: Vector2 = f.foot_stage(0, 1) - Vector2(v.size.x * 0.5, v.size.y * 0.6)
	await _wait(0.1)
	if v.position.distance_to(want) > 1.0:
		problems.append("choose: your middle slot's view isn't on its slot")
	await _wait(1.0)
	if not f.roam_home():
		problems.append("choose: it wandered off home while the player was choosing")


## A Totem called on each side: round in front of it as it arrives.
func _call() -> void:
	var f := ds.field
	for who in [[0, "mine"], [1, "theirs"]]:
		var side: int = who[0]
		var ids_mine: Array = ["cinderpup", null, "brookfin"]
		var ids_theirs: Array = ["mossling", null, "pebblit"]
		var made: Array = await _board(ids_mine, ids_theirs)
		ds.mode = "busy"
		await _wait(2.0)
		var g := ds.game
		var uid := 9900 + side * 10 + randi() % 50
		var t := g._new_totem(DuelCard.new(uid, "blazehound" if side == 0 else "thornwarden", side), side, 1, 0)
		g.players[side].slots[1] = t
		var look := f.foot_world(side, 1)
		var front := f.ahead_of(side)
		var face := atan2(front.x, front.z)
		var off0 := rad_to_deg(absf(wrapf(float(DuelField3D._sph(f.cam_pos - look)[0]) - face, -PI, PI)))
		_watching_start()
		ds.fx_call(t)
		await _wait(0.5)
		await _shot("call_%s_1_lands" % who[1])
		await _wait(0.8)
		await _shot("call_%s_2_watched" % who[1])
		var yaw := float(DuelField3D._sph(f.cam_pos - look)[0])
		var off := rad_to_deg(absf(wrapf(yaw - face, -PI, PI)))
		print("CAMERA SHOT: call %s: %.0f degrees round from straight in front of it (was %.0f)" % [who[1], off, off0])
		# (round towards its front by most of a swing, or as far as it needed)
		if off > DuelField3D.VIEW_ROUND + 5.0 and off0 - off < DuelField3D.VIEW_SWING * 0.6:
			problems.append("call %s: the camera didn't come round towards its front (%.0f degrees off, was %.0f)" % [who[1], off, off0])
		await _wait(2.4)
		await _shot("call_%s_3_on" % who[1])
		_watching_end("call " + String(who[1]), 0.5)
		if made.is_empty():
			pass


## An attack's shots, then on round from where they left it.
func _attack() -> void:
	var f := ds.field
	var made: Array = await _board([null, "cinderpup", null], ["mossling", "elderbark", "pebblit"])
	var att: DuelTotem = made[0][1]
	var tg: DuelTotem = made[1][1]
	ds.mode = "busy"
	await _wait(2.0)
	_watching_start()
	await ds.fx_attack(att, 0, tg)
	await _wait(0.1)
	await _shot("attack_1_pushin")
	if DuelRules.cinematic and f._following:
		problems.append("attack: the attack's shot didn't take the camera off the path")
	ds.fx_totem_hit(tg, 40, {"attacker": att, "element": att.element()})
	await _wait(0.3)
	await _shot("attack_2_land")
	ds._strike = {}
	await _wait(1.0)
	await _shot("attack_3_after")
	await _wait(1.5)
	await _shot("attack_4_on")
	_watching_end("attack", 1.2)
	if not f._following:
		problems.append("attack: the camera didn't go back onto its path")
	if f.roam_home():
		problems.append("attack: it went home with nothing for the player to choose")


## The button: Locked goes home and stays; Moving sets off again.
func _button() -> void:
	var f := ds.field
	ds.mode = "busy"
	await _wait(3.0)
	ds.cam_btn.pressed.emit()
	await _wait(1.2)
	await _shot("button_locked")
	if String(Game.settings.get("duel_camera", "")) != "locked":
		problems.append("button: the setting wasn't saved as locked")
	if f.roam_on or ds.cam_btn.text != "Camera: Locked":
		problems.append("button: still moving after Locked (%s)" % ds.cam_btn.text)
	if f.cam_pos.distance_to(f._home_pos) > 0.05:
		problems.append("button: locked, but not home (%.2f m off)" % f.cam_pos.distance_to(f._home_pos))
	await _wait(3.0)
	if f.cam_pos.distance_to(f._home_pos) > 0.05:
		problems.append("button: locked, and it moved off home")
	ds.cam_btn.pressed.emit()
	await _wait(3.0)
	await _shot("button_moving")
	if not f.roam_on or String(Game.settings.get("duel_camera", "")) != "moving":
		problems.append("button: Moving again didn't take")
	if f.cam_pos.distance_to(f._home_pos) < 0.3:
		problems.append("button: moving again, but it hadn't set off")
