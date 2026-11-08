class_name AshfordNight
extends RefCounted
## Prologue P3 and P4 as Master Script v7 has them (docs/script/v7_prologue.md),
## from after the Sigilfall to the hill above Ashford: the awakening in the
## attic before sunrise (Bram's confession, the player's own feeling, the two
## hubs), That Day in the cellar (twenty-two Ward marks), the Reckoning at
## dusk (Krell hours early, Tam's challenge, the cellar, the tunnel, Tam's
## duel to the death, the restraint magic on the green) and the look back from
## the hill (Gary's moment: Ashford still standing, the bell, Nell, Bram's
## hand, Corin's farewell). The dawn and the Pale Herald stay in ashford.gd
## (_dawn), changed to v7 there.
##
## Every part is a film: the words are subtitles between the bars and every
## line waits for a tap (Cine). The tunnel and the look back are walked.

const TUNNEL_AT := Vector3(60.0, -40.0, 0.0)
const TUNNEL_LEN := 24.0
## The tunnel's mouth on the hill above Ashford, under the thorn trees (on the
## far side of the rise south-west of the village), and where the village
## lies from there.
const MOUTH := Vector3(-41.0, 0, 43.0)
const VILLAGE_LOOK := Vector3(-2.0, 2.0, 2.0)
## How long the player can stand at the look back before he steps down on his
## own (s), and how far down the hill counts as walking towards the village.
const LOOK_WAIT := 11.0
const LOOK_STEP := 1.4
## The greys on the green while Ashford is held (pairs walking; the rest at
## the well and the inn) and the kneeling line by the well.
const GREYS := [
	["g1", Vector3(-3.0, 0, 6.0), Vector3(4.0, 0, 6.5)], ["g2", Vector3(-2.2, 0, 6.8), Vector3(4.6, 0, 7.4)],
	["g3", Vector3(6.0, 0, -4.0), Vector3(-5.0, 0, -5.0)], ["g4", Vector3(6.6, 0, -3.2), Vector3(-4.4, 0, -4.2)],
]
const KNEELING := [Vector3(-8.0, 0, 6.2), Vector3(-7.0, 0, 6.6), Vector3(-6.0, 0, 6.9), Vector3(-5.0, 0, 7.0)]


static func village(w: World) -> AshfordVillage:
	return w.get_meta("village") as AshfordVillage


static func _area(w: World) -> Object:
	return w.area


## One of ashford.gd's constants (the area is a script, not an instance).
static func _c(w: World, name: String) -> Variant:
	return (w.area as Script).get_script_constant_map().get(name)


# ========================================================== the awakening ===

## Where the player sits on the bed's edge, from the bed's own spot
## (`edge_at`), a little towards its head, and how far along it from them
## Bram sits (hip to hip: room for his shoulders and his arm); how much of a
## head turn he takes sat there (Figure3D.look_turn).
const WAKE_EDGE := Vector3(-0.18, 0, 0)
const WAKE_BESIDE := 0.72
const WAKE_LOOK_TURN := 0.3
## Where his reaching arm's elbow is drawn to, sat there (his own frame: x
## to his left, y up from the floor, z ahead; Figure3D.elbow): back and down,
## so his arm goes round behind them and his hand comes down on the shoulder
## from behind, palm flat on its top, the fingers forward over its front
## (8 November, Gary: "When Bram puts his hand on player shoulder it goes
## through it when you're both sitting on the bed": with the elbow in front
## the hand came up on its edge from the side to a point inside the
## shoulder, the fingers pointing into their neck).
const WAKE_ELBOW := Vector3(-0.3, 0.8, -0.35)
## How far his palm on their shoulder is rolled in towards their neck (the
## palm facing down and a little inwards: the pinky's edge up off the slope
## to the neck, the thumb's edge down over the outside; laid flat, the
## pinky's knuckle was 3 cm in the slope).
const WAKE_ROLL := deg_to_rad(25.0)
## And stood at the window, turned to them: down and in front, the hand
## coming up onto the shoulder from the front, the fingers over its top.
const WIN_ELBOW := Vector3(-0.25, 1.0, 0.3)
## How far apart the two of them stand at the window (hip to hip, m): shoulder
## to shoulder, so that turned to them his hand reaches their near shoulder
## with his arm bent (8 November, Gary: "After it mentions about the Herald,
## Bram's arm distorts": they stood 0.64 m apart, and the shoulder picked for
## his hand before either had turned was the far one, 0.67 m from his own
## against an arm of 0.57: it locked straight and twisted to point at it).
## Turned square to each other their near shoulders (his right, their left)
## are still further apart than their hips, by 0.12 (both idles hold the
## shoulders back of the hips): 0.63 m against his arm's 0.56. So as he
## turns he steps in to them WIN_STEP, and turns WIN_OPEN past them to his
## left (his right shoulder swings forward to them, his eyes stay on their
## face): the shoulder 0.41 m from his, the elbow bent.
const WIN_APART := 0.46
const WIN_STEP := 0.12
const WIN_OPEN := deg_to_rad(30.0)


## Bram's hand off the player's shoulder (or the timber), the arm given back
## to his clip: the reach and the elbow first, the hand's turn only once the
## arm is mostly back (let go together, the hand turned back to the clip's
## while the reach still held it close, and the fingers swung into what it
## had been on: 8 November, the cellar's timber).
static func _bram_hand_back(f: Figure3D) -> void:
	f.let_go(0.4)
	f.elbow("right", Vector3.INF, 0.4)
	if f.is_inside_tree():
		await f.get_tree().create_timer(0.3).timeout
	if is_instance_valid(f):
		f.palm("right", Vector3.ZERO, 0.3)


## P3 · The Awakening (v7): the attic, the sun not quite up; Bram on a stool
## beside the cot with a damp cloth. "Thank the Courts." His confession; how
## the player takes it (remembered: temper_angry / temper_afraid /
## temper_resolved); the Betrayal and the Artifact hubs; the mark; the bell,
## and the mist: a Herald.
static func awakening(w: World) -> void:
	var v := village(w)
	var a := InnRooms.attic(v)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.01)
	AshfordP1.undress(w)
	AshfordP1.go_inside(v)
	# before sunrise: the window grey-blue and low, the candle burning down
	var L: Dictionary = a.get("lights", {})
	if not L.is_empty():
		(L.window as Light3D).light_color = Color(0.56, 0.62, 0.92)
		(L.window as Light3D).light_energy = 1.1
		(L.candle as Light3D).light_energy = 1.5
		(L.fill as Light3D).light_energy = 0.6
		if L.has("bounce"):
			(L.bounce as Light3D).light_energy = 0.35
	if a.has("fog_mat"):
		(a.fog_mat as StandardMaterial3D).albedo_color.a = 0.6
	if a.has("writing"):
		(a.writing as Label3D).modulate.a = 0.0
	AshfordP1.asleep(w)
	var root: Node3D = a.root
	# (1 November, Gary: "the whole conversation between Bram and the player
	# after passing out needs redoing and animating so it's a movie, not just
	# a conversation", "characters going through the items", and Bram's eyes
	# "look mental" when you wake). The same words, staged: Bram watching
	# over the bed on his stool, the player sitting up, then on the bed's
	# edge; Bram on his feet and at the window with his back to them for the
	# hard part, turning to face them for the rest; the bell, the two of
	# them at the window together, his hand on their shoulder, and down the
	# hatch. Every shot moves a little; nothing is shot from the pillow up
	# into his face; nobody's walk crosses the bed, the crate, the desk or
	# the stool (each walk's points are picked clear of them).
	var lie: Vector3 = a.lie_at
	var fy := (a.bed_side as Vector3).y
	var stool := lie + Vector3(0.15, 0, 1.0)
	stool.y = fy
	var st: Node3D = AshfordP1.meta(v, "wake_stool")
	if st == null:
		st = Node3D.new()
		st.name = "WakeStool"
		v.add_child(st)
		v.cyl(st, 0.19, 0.16, 0.44, Vector3(0, 0.22, 0), v.mats.wood, 12)
		v.set_meta("wake_stool", st)
	st.global_position = stool
	Cine.place(w, "bram", stool + Vector3(0, 0, 0.0001), lie)
	AshfordP1.sit_down(w, "bram", stool, (lie - stool).normalized(), 0.46, 0.0)
	var cloth := Node3D.new()
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.82, 0.8, 0.74)
	cm.roughness = 1.0
	v.box(cloth, Vector3(0.14, 0.02, 0.1), Vector3.ZERO, cm)
	cloth.set_meta("p1_prop", true)
	w.add_child(cloth)
	var bf = Cine.fig(w, "bram")
	var pf = w.player_doll
	if bf is Figure3D:
		(bf as Figure3D).attach(cloth, "palm", "right", 0.012)
	Music.play(["dawn_after"], 2.0, true)
	# the window: where Bram stands to look out (clear of the candle's crate
	# and the desk), and where the player comes to stand beside him
	var win: Vector3 = a.window
	var me_win := root.to_global(Vector3(-2.15, 0, 0.3))
	var bram_win := root.to_global(Vector3(-2.15, 0, 0.3) + Vector3(-0.2, 0, -0.6).normalized() * WIN_APART)
	bram_win.y = fy
	me_win.y = fy
	var into := (lie - stool).normalized()
	var side := into.cross(Vector3.UP)
	# the beams overhead, as his eyes open (twice: a blink, then awake)
	var up := lie + Vector3(0, 0.55, 0)
	Cine.shot(w, up, up + Vector3(0.3, 1.0, -0.2), 60.0)
	await Cine.fade(w, 0.35, 0.8)
	await Cine.fade(w, 0.9, 0.4)
	await Cine.fade(w, 0.0, 1.1)
	await Cine.wait(w, 0.6)
	# from the foot of the bed: the sleeper, and Bram bent forward on his
	# stool, elbows on his knees, the cloth in his hands; a slow push in
	var bh := Cine.head(w, "bram")
	var foot_a := lie + Vector3(2.0, 1.15, 0.85)
	Cine.drift(w, foot_a, foot_a + Vector3(-0.45, -0.08, -0.12), (bh + lie + Vector3(0, 0.6, 0)) * 0.5, bh + Vector3(0, -0.08, 0), 5.0, 40.0)
	await Cine.say(w, "bram", "Thank the Courts. You gave me quite a scare out there, Sprout.")
	# the blanket thrown back (his own hand takes its hem and throws it to
	# the wall), and up onto an elbow, sat up in the bed, Bram leaning in
	# (6 November, Gary: "When you wake up in bed after the white card you're
	# not under the covers, your body is half way through them": he sat up,
	# and later swung his legs out, through a blanket that never moved)
	if pf is Figure3D:
		var bhand := Node3D.new()
		bhand.name = "WakeHand"
		w.add_child(bhand)
		await AshfordP1.throw_blanket(w, pf as Figure3D, a, bhand, 0.7)
		(pf as Figure3D).let_go(0.4)
		(pf as Figure3D).sit_long(a.lie_top, 1.2)
		bhand.queue_free()
	await Cine.wait(w, 1.0)
	var mid := (lie + stool) * 0.5
	Cine.drift(w, mid + side * 2.0 + Vector3(0, 1.2, 0), mid + side * 1.75 + Vector3(0.0, 1.15, 0) - into * 0.1, mid + Vector3(0, 0.85, 0), mid + Vector3(0, 0.88, 0), 7.0, 40.0)
	if bf is Figure3D:
		(bf as Figure3D).act("talk", 0.6)
	await Cine.say(w, "bram", "Listen to me carefully. I wanted to break this to you slowly, but the turning of the Age just tore up that timeline.")
	# he gets up off the stool (it scrapes back) and goes to the window
	if bf is Figure3D:
		(bf as Figure3D).detach(cloth)
	if is_instance_valid(cloth):
		cloth.queue_free()
	await AshfordP1.stand_up(w, "bram", 0.5)
	var push := w.create_tween()
	push.tween_property(st, "global_position", stool + side * 0.7 + into * -0.3, 0.5).set_trans(Tween.TRANS_SINE)
	Cine.drift(w, lie + Vector3(1.2, 1.3, 1.6), lie + Vector3(0.9, 1.35, 1.9), (stool + bram_win) * 0.5 + Vector3(0, 1.3, 0), bram_win + Vector3(0, 1.45, 0), 3.4, 44.0)
	await Cine.path(w, "bram", [root.to_global(Vector3(-1.4, 0, -0.55)), bram_win], 1.05)
	Cine.look(w, "bram", win)
	# his back to the room, the grey light on him
	Cine.drift(w, root.to_global(Vector3(-1.05, 1.6, 0.85)), root.to_global(Vector3(-1.25, 1.62, 0.6)), bram_win + Vector3(0, 1.55, 0), bram_win + Vector3(0, 1.5, 0), 6.5, 36.0)
	await Cine.say(w, "bram", "I'm not who you think I am, and you aren't who you think you are.")
	# the player swings their legs out and sits on the bed's edge
	if pf is Figure3D:
		var fig := pf as Figure3D
		await fig.shift_seat(a.edge_at + WAKE_EDGE, Vector3.BACK, 0.9, 0.05)
		fig.sit(a.edge_top, 0.6)
		await Cine.wait(w, 0.4)
		fig.look_toward(bram_win, w.cam)
	await Cine.say(w, "bram", "Everything I've done has been to protect you. To protect what you are... and what you're going to become.")
	# how the player takes it (v7, Gary's note: the protagonist's own feeling):
	# close on them, sat on the bed's edge, from the hatch side
	var ph := Cine.head(w, "player")
	Cine.drift(w, ph + Vector3(1.3, -0.05, 0.75), ph + Vector3(1.15, -0.03, 0.62), ph + Vector3(0, -0.05, 0), ph + Vector3(0, -0.04, 0), 6.0, 34.0)
	var feel := await Cine.choose(w, ["Twenty years, Bram. You lied to me for twenty years.", "What's happening to me?", "Then stop protecting me and tell me what I'm up against."])
	# he turns from the window to them
	Cine.look(w, "bram", w.player.global_position)
	var bh2 := Cine.head(w, "bram")
	match feel:
		0:
			Game.set_flag("temper_angry")
			Cine.drift(w, (ph + bh2) * 0.5 + side * 1.6 + Vector3(0, 0.1, 0), (ph + bh2) * 0.5 + side * 1.45 + Vector3(0, 0.12, 0), bh2, bh2 + Vector3(0, -0.05, 0), 5.0, 38.0)
			await Cine.say(w, "bram", "Every day of them. Be as angry as you like. Just be angry and listening.")
		1:
			Game.set_flag("temper_afraid")
			# he comes across and takes your wrist, the way he did when you
			# were small and had a fever
			var by := w.player.global_position + Vector3(-0.45, 0, 0.6)
			by.y = fy
			await Cine.path(w, "bram", [root.to_global(Vector3(-1.6, 0, 0.1)), by], 1.1)
			Cine.look(w, "bram", w.player.global_position)
			if bf is Figure3D and pf is Figure3D:
				var wrist := Node3D.new()
				w.add_child(wrist)
				wrist.global_position = (pf as Figure3D).bone_pos("LeftHand")
				(bf as Figure3D).reach(null, wrist, 0.5)
				await Cine.wait(w, 0.6)
				wrist.set_meta("p1_prop", true)
				w.set_meta("wake_wrist", wrist)
			var mm := (w.player.global_position + by) * 0.5
			Cine.drift(w, mm + Vector3(0.9, 1.25, 1.5), mm + Vector3(0.75, 1.2, 1.35), mm + Vector3(0, 0.9, 0), mm + Vector3(0, 0.95, 0), 5.0, 38.0)
			await Cine.say(w, "bram", "Nothing I'll let finish you. Breathe.")
		_:
			Game.set_flag("temper_resolved")
			Cine.drift(w, (ph + bh2) * 0.5 + side * 1.6 + Vector3(0, 0.1, 0), (ph + bh2) * 0.5 + side * 1.45 + Vector3(0, 0.12, 0), bh2, bh2 + Vector3(0, -0.05, 0), 5.0, 38.0)
			await Cine.say(w, "bram", "Twenty years I've waited to hear you say something like that. I'd hoped it'd be about the inn.")
	if bf is Figure3D:
		(bf as Figure3D).let_go(0.4)
	var wr = AshfordP1.meta(w, "wake_wrist")
	if wr != null and is_instance_valid(wr):
		(wr as Node).queue_free()
	# the Betrayal: the player, on the bed's edge, over Bram's shoulder
	var bp := Cine.body(w, "bram").global_position
	var to_me := w.player.global_position - bp
	to_me.y = 0.0
	to_me = to_me.normalized()
	var across := to_me.cross(Vector3.UP)
	var over := bp + to_me * 0.35 + across * 0.75 + Vector3(0, 1.55, 0)
	Cine.drift(w, over, over + to_me * 0.15, ph + Vector3(0, -0.05, 0), ph, 7.0, 36.0)
	await Cine.say(w, "player", "Protect me from what? What do you mean you aren't who I think you are? Bram, you're not making any sense.")
	await Cine.say(w, "player", "And last night... the sky tore open. I remember the cart, and then that light... what happened to me out there? What was that card?")
	# Bram, from behind the player's shoulder, the window's grey light on him
	bh2 = Cine.head(w, "bram")
	var behind := w.player.global_position + (w.player.global_position - bp).normalized() * 0.5 + Vector3(0, 1.25, 0) - side * 0.3
	Cine.drift(w, behind, behind + (bp - w.player.global_position).normalized() * 0.15, bh2 + Vector3(0, -0.06, 0), bh2 + Vector3(0, -0.04, 0), 8.0, 34.0)
	await Cine.say(w, "bram", "The inn was a lie. My name is a lie. But keeping you safe... that was the truest thing I've ever done.")
	await Cine.say(w, "bram", "I can't tell you everything yet. I've seen too many kingdoms burn because of the powers I used to serve. I just wanted to stop. I wanted you to just be a boy.")
	# he looks down at his scarred hands
	if bf is Figure3D:
		(bf as Figure3D).pose("play_card", 0.35, 0.5)
	var hands := (bf as Figure3D).bone_pos("RightHand") if bf is Figure3D else bp + Vector3(0, 1.0, 0)
	Cine.drift(w, hands + side * 0.75 + Vector3(0, 0.22, 0) + (w.player.global_position - bp).normalized() * 0.35, hands + side * 0.65 + Vector3(0, 0.26, 0) + (w.player.global_position - bp).normalized() * 0.3,
		hands, (hands + Cine.head(w, "bram")) * 0.5, 2.4, 32.0)
	await Cine.wait(w, 1.6)
	if bf is Figure3D:
		(bf as Figure3D).release(0.5)
	# he comes back to the bed and sits on its end, by them: a body's width
	# off (6 November, Gary: "When Bram sits down on the bed his arm goes
	# through the player and his eyes are weird": he sat 0.62 m from them,
	# his talking arm in their lap, and turned his head half round to them,
	# where his painted eyes read as smears from the side)
	var bed_end := w.player.global_position + Vector3(WAKE_BESIDE, 0, 0.0)
	bed_end.y = fy
	var end_way := root.to_global(Vector3(-1.2, 0, 0.1))
	var two := (w.player.global_position + bed_end) * 0.5
	Cine.drift(w, two + side * 2.3 + Vector3(0, 1.3, 0) + into * -0.4, two + side * 2.0 + Vector3(0, 1.22, 0) + into * -0.3, two + Vector3(0, 0.95, 0), two + Vector3(0, 0.9, 0), 8.0, 40.0)
	if Cine.body(w, "bram").global_position.distance_to(bed_end) > 0.3:
		await Cine.path(w, "bram", [end_way, bed_end + Vector3(0, 0, 0.35)], 1.05)
	await AshfordP1.sit_down(w, "bram", bed_end, Vector3.BACK, a.edge_top, 0.5)
	# his face kept to the room (a glance their way, not his head turned
	# round to them), and his near hand comes to rest on their shoulder
	if bf is Figure3D:
		(bf as Figure3D).look_turn = WAKE_LOOK_TURN
	var bed_sh = w.area.call("_shoulder_point", w, "player", Cine.body(w, "bram").global_position, "", "bram", "right")
	if bf is Figure3D and bed_sh != null:
		# (his arm round behind them, the elbow back and down: WAKE_ELBOW)
		(bf as Figure3D).elbow("right", WAKE_ELBOW * (bf as Figure3D).stature(), 0.01)
		(bf as Figure3D).reach(null, bed_sh, 0.6)
		# palm flat on top of the shoulder, the fingers forward over its front
		# (8 November: left along the forearm they pointed into their neck)
		var fwd_p: Vector3 = (pf as Figure3D).facing() if pf is Figure3D else Vector3.BACK
		var out_p := Vector3.UP.cross(fwd_p).normalized()   # (their left: the shoulder's outer side, his side)
		(bf as Figure3D).palm("right", (Vector3.DOWN * cos(WAKE_ROLL) - out_p * sin(WAKE_ROLL)).normalized(), 0.6, 0.5, false, fwd_p)
	await Cine.say(w, "bram", "I kept you away from magic because magic [i]wants[/i] you. A deck in the cellar, Sparks so spent they'd barely answer, and my hand over yours. Never the deep draw.")
	await Cine.say(w, "bram", "Channelling Essence properly would wake you up and light a beacon for every god in Veyl.")
	# side by side on the bed's edge, from in front, a slow drift
	var front := two + Vector3(0, 0, 1.0)
	Cine.drift(w, front + Vector3(0.2, 1.05, 0.95), front + Vector3(-0.1, 1.08, 0.75), two + Vector3(0, 0.95, 0), two + Vector3(0, 0.98, 0), 9.0, 40.0)
	await Cine.say(w, "bram", "But the dreams started again. Visions from an old master I haven't heard from in a very long time. I was going to train you slowly, but that card falling forced my hand.")
	# the Artifact
	var asked := [false]
	await Cine.ask(w, ["What exactly did I catch out there? What is that card?"], func(_q: int) -> void:
		var bh3 := Cine.head(w, "bram")
		Cine.drift(w, bh3 + Vector3(-0.35, -0.05, 1.25), bh3 + Vector3(-0.3, -0.04, 1.1), bh3, bh3, 6.0, 34.0)
		await Cine.say(w, "bram", "The most dangerous thing in Veyl. A blank space at the bottom of the Covenant. The Last Seal.")
		await Cine.say(w, "bram", "The gods didn't create this world, they borrowed it, and the Covenant is the loan agreement.")
		asked[0] = true, "")
	if asked[0]:
		var more := await Cine.choose(w, ["And what does a blank space at the bottom of a loan do?", "But my chest was on fire. I thought it was going to kill me."])
		if more == 0:
			# he looks at you a moment too long (sat as he is, his hand on
			# their shoulder: turning his whole body round to them on the
			# bed took his hand off it and left his arm held out in the air)
			await Cine.wait(w, 1.2)
			await Cine.say(w, "bram", "Enough that every god in Veyl will want it, and every bank that lends to them. That's all you need tonight.")
			Game.set_flag("bram_holds_back")
			await Cine.say(w, "", "[i](Morrowen's Ledger: Bram knows more than he is saying.)[/i]")
			await Cine.say(w, "player", "But my chest was on fire. I thought it was going to kill me.")
	else:
		await Cine.say(w, "player", "But my chest was on fire. I thought it was going to kill me.")
	Cine.drift(w, front + Vector3(0.2, 1.05, 0.95), front + Vector3(0.35, 1.0, 0.85), two + Vector3(0, 0.95, 0), two + Vector3(0, 0.95, 0), 6.0, 40.0)
	await Cine.say(w, "bram", "I thought so too. The resonance should have stopped your heart, but it didn't. Tell me, how do you feel now? Is the mark burning?")
	await Cine.say(w, "player", "No... I feel fine. Actually... I feel better than I ever have.")
	# they look at their hands: the exhaustion gone, a strange vitality, the
	# mark under the collar (his hand comes off their shoulder, up and out
	# the way it came, back to his knee, as they lean forward over their
	# hands)
	if bed_sh != null:
		w.area.call("_shoulder_leave", bed_sh)
		await Cine.wait(w, 0.45)
	if bf is Figure3D:
		_bram_hand_back(bf as Figure3D)
	if pf is Figure3D:
		(pf as Figure3D).pose("play_card", 0.4, 0.6)
	var neck: Vector3 = (pf as Figure3D).bone_pos("Neck") if pf is Figure3D else w.player.global_position + Vector3(0, 1.0, 0)
	Cine.drift(w, neck + Vector3(0.15, 0.05, 0.75), neck + Vector3(0.1, 0.0, 0.6), neck + Vector3(0, -0.12, 0), neck + Vector3(0, -0.15, 0), 3.0, 32.0)
	SealMark.show_on(w, true)
	await Cine.wait(w, 2.0)
	if pf is Figure3D:
		(pf as Figure3D).release(0.5)
	# (from in front of the two of them, a little to his side: from along
	# the bed's edge he hid the player and showed his painted eyes side on)
	Cine.drift(w, two + Vector3(0.55, 1.12, 2.05), two + Vector3(0.35, 1.08, 1.85), two + Vector3(0, 0.95, 0), two + Vector3(0, 0.93, 0), 6.0, 40.0)
	await Cine.say(w, "bram", "I was afraid of that. The seal isn't just a piece of paper, Sprout. It's a lock. And last night something turned the key.")
	# the chapel bell, frantic, through the cold morning air: both up, and to
	# the window
	Music.stop(1.0)
	w.area.call("_bell", w, 6)
	if bf is Figure3D:
		_bram_hand_back(bf as Figure3D)
		(bf as Figure3D).look_turn = 1.0
	if bed_sh != null:
		w.area.call("_free_tracker", bed_sh)
	await Cine.wait(w, 0.6)
	Cine.look(w, "bram", win)
	Cine.look(w, "player", win)
	await AshfordP1.stand_up(w, "bram", 0.45)
	await AshfordP1.stand_up(w, "player", 0.45)
	Cine.drift(w, root.to_global(Vector3(0.6, 1.7, 1.3)), root.to_global(Vector3(0.2, 1.65, 1.0)), (bram_win + me_win) * 0.5 + Vector3(0, 1.4, 0), win, 4.0, 46.0)
	Cine.path(w, "bram", [root.to_global(Vector3(-1.5, 0, -0.2)), bram_win], 1.3)
	await Cine.path(w, "player", [root.to_global(Vector3(-1.3, 0, 0.45)), me_win], 1.2)
	Cine.look(w, "bram", win)
	Cine.look(w, "player", win)
	# the two of them at the little window, the grey light on their faces
	var wm := (bram_win + me_win) * 0.5 + Vector3(0, 1.5, 0)
	Cine.drift(w, wm + Vector3(1.25, 0.0, 0.35), wm + Vector3(1.05, 0.02, 0.25), wm + Vector3(-0.4, 0.0, 0.0), wm + Vector3(-0.5, 0.0, 0.0), 6.0, 38.0)
	await Cine.say(w, "", "[i]Villagers, outside:[/i] \"Look at the mist! A Herald! A Herald is approaching!\"")
	# he turns to them, and once he has, his hand comes up onto their near
	# shoulder (8 November, Gary: "After it mentions about the Herald, Bram's
	# arm distorts": the shoulder was picked before either had turned, the
	# far one, and out of his reach: see WIN_APART)
	var bb := Cine.body(w, "bram")
	var to_them := w.player.global_position - bb.global_position
	to_them.y = 0.0
	to_them = to_them.normalized()
	# (he turns WIN_OPEN past them to his left, and steps in WIN_STEP as he
	# turns: his right shoulder comes forward to their left one; his eyes on
	# their face)
	Cine.look(w, "bram", bb.global_position + to_them.rotated(Vector3.UP, WIN_OPEN) * 2.0)
	Cine.look(w, "player", bb.global_position)
	if bf is Figure3D:
		(bf as Figure3D).eyes_on(Cine.head(w, "player"))
	var step := w.create_tween()
	step.tween_property(bb, "global_position", bb.global_position + to_them * WIN_STEP, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var bh4 := Cine.head(w, "bram")
	Cine.drift(w, bh4 + Vector3(1.0, -0.08, 0.9), bh4 + Vector3(0.85, -0.06, 0.78), (bh4 + Cine.head(w, "player")) * 0.5, (bh4 + Cine.head(w, "player")) * 0.5, 5.0, 38.0)
	await Cine.wait(w, 0.45)
	# (face to face, his right hand goes to their left shoulder)
	var sh = w.area.call("_shoulder_point", w, "player", Vector3.INF, "left", "bram", "right")
	if bf is Figure3D and sh != null:
		(bf as Figure3D).elbow("right", WIN_ELBOW * (bf as Figure3D).stature(), 0.01)
		(bf as Figure3D).reach(null, sh, 0.5)
		var out_w := Vector3.UP.cross((pf as Figure3D).facing()).normalized() if pf is Figure3D else Vector3.RIGHT
		(bf as Figure3D).palm("right", (Vector3.DOWN * cos(WAKE_ROLL) - out_w * sin(WAKE_ROLL)).normalized(), 0.5, 0.5)
	await Cine.say(w, "bram", "We're out of time. Keep your head down, and whatever happens out there, do not draw your deck.")
	SealMark.show_on(w, false)
	# down the hatch: his hand off their shoulder, his arm his own again, and
	# then he goes first (walked with the hand still coming off, the arm
	# bent to a point that was going)
	if sh != null:
		w.area.call("_shoulder_leave", sh)
		await Cine.wait(w, 0.45)
	if bf is Figure3D:
		_bram_hand_back(bf as Figure3D)
		(bf as Figure3D).eyes_on(null)
		await Cine.wait(w, 0.45)
	if sh != null:
		w.area.call("_free_tracker", sh)
	var hatch: Vector3 = a.hatch
	hatch.y = fy
	Cine.path(w, "bram", [root.to_global(Vector3(-0.6, 0, 0.6)), root.to_global(Vector3(1.2, 0, 0.75)), hatch + Vector3(-0.3, 0, 0)], 1.4)
	await Cine.wait(w, 0.8)
	Cine.path(w, "player", [root.to_global(Vector3(-0.9, 0, 0.9)), root.to_global(Vector3(1.0, 0, 0.95))], 1.3)
	await Cine.wait(w, 0.6)
	await Cine.fade(w, 1.0, 1.0)
	if bf is Figure3D:
		(bf as Figure3D).stand(0.0)
	if pf is Figure3D:
		(pf as Figure3D).stand(0.0)
	if is_instance_valid(st):
		st.global_position = Vector3(0, -200, 0)
	InnRooms.outside(v)
	Game.set_flag("ash_woke")


# ============================================================== that day ===

## That Day's places (8 November, Gary: "his body is going through the
## stairs"). The cellar's `stairs` point is the middle of the staircase (its
## steps run across the room's x 2.1 to 3.2, the point at 2.65), and the
## player packed 0.5 m west of it: at x 2.15, stood in the bottom two steps,
## the satchel under the third. From that point now: where the player
## kneels to pack, beside the steps' foot and clear of them (on their knees
## their feet lie 0.85 m out behind them: at 1.1 m west the left foot was in
## the bottom step, at 1.3 the toes), and the satchel in front of them. From `marks_at` (the timber's foot by the
## cask): where Bram kneels to the marks, on both knees (Figure3D.kneel with
## `both`: v7 has him "on his knees at the back wall"; the one-knee kneel
## plants a foot a stride ahead, into the timber, and a squat 0.6 m off put
## the marks at his arm's full length), beside the cask, his knees a hand
## off the timber and his shoulders a forearm's length from it, among the
## marks (he knelt a metre off the marks with the cask between, and reached
## for them through it; kneeling 0.42 m off the timber his shoulder was
## still 0.52 m off the marks, the nearest 0.50 to 0.63 m from it); how far
## he leans to them; where his elbow is drawn to; how many marks he presses
## before the line, the last one kept for after it (the nearest to his
## hand: 0.32 to 0.44 m from his shoulder; the reach aims the forearm's line
## 7.5 cm past the wrist, which with the palm flat on the timber is 3 cm
## inside it, so the arm's 0.56 is used up at a mark 0.49 from the shoulder:
## at 0.46 it was straight; kneeling nearer, his face was on the timber); and
## how far round he turns on his knees for "Twenty-two
## marks" (to his right, towards the camera in the north-west corner: his
## feet, out behind him on the floor, swung into the timber when he turned
## right round to the player).
const MARKS_TURN := deg_to_rad(45.0)
const PACK_AT := Vector3(-1.5, 0, 0.25)
const SATCHEL_AT := Vector3(-1.8, 0, 0.25)
## Packing: the player on both knees over the satchel (Figure3D.kneel with
## `both`), bent over it PACK_LEAN, both hands flat on its flap, the fingers
## out along it (PACK_HANDS: where each forearm's line ends, in the satchel's
## own frame, which lies across in front of them, either side of its middle;
## the palms' middles are held down to the flap's top, PACK_FLAP over the
## satchel's spot, Figure3D.press: the fingers forward hung over its far
## edge onto the floor, the bag being a hand deep), the elbows out
## (PACK_ELBOW, their own frame). They stood over it bent a little at the
## waist, the hands at their hips, the satchel on the floor 0.4 m off.
const PACK_LEAN := 1.0
const PACK_HANDS := [Vector3(0.06, 0.3, 0.0), Vector3(-0.06, 0.3, 0.0)]
const PACK_FLAP := 0.30
const PACK_ELBOW := Vector3(0.42, 0.55, 0.25)
const MARKS_KNEEL := Vector3(-0.17, 0, 0.55)
const MARKS_LEAN := 0.25
const MARKS_ELBOW := Vector3(-0.3, 0.75, 0.25)
const MARKS_PRESSED := 3
## How far off the timber's face his palm's middle stops (m): the palm's own
## half thickness and a little; how far off it his hand starts for the first
## mark (the reach blending in from his side swings the fingers round
## towards the timber half way, and from 15 cm off their tips went 3 cm
## into it); how long the hand settles on each mark after the glide (s), and
## the most the point is moved to bring the palm onto it. The palm faces the
## timber tipped MARKS_TIP up, the heel of the hand on it and the fingers
## off it (his fingers rest a little curled, the little finger most: flat to
## it, their tips were 2 to 3 cm in, and tipped 20 degrees the little
## finger's still 1.5).
const MARKS_OFF := 0.035
const MARKS_IN := 0.25
const MARKS_BLEND := 0.3
const MARKS_SETTLE := 0.25
const MARKS_CORR_MAX := 0.15
const MARKS_TIP := deg_to_rad(30.0)


## His hand to a mark: the palm's middle MARKS_OFF off the timber in front
## of it, glided there from the last mark over `secs` (one point his hand
## follows, under the world's "mark_hand": a reach given a new point snaps
## the hand to it in a frame), held a moment. The reach puts the end of his
## forearm on the point, and the hand turned palm to the timber swings the
## palm off it: so the point is moved each frame by where the palm's middle
## was drawn against the mark (Ashford._palm_watch: read as the skeleton
## finishes its frame; between frames a bone has only the clip's pose), the
## difference kept from mark to mark ("mark_corr"), so the palm itself comes
## to rest on each. _marks_done() takes his hand back and the point away.
static func _press_mark(w: World, f: Figure3D, m: MeshInstance3D, secs: float) -> void:
	var want := m.global_position + Vector3(MARKS_OFF, 0, 0)
	var to: Node3D = w.get_meta("mark_hand") if w.has_meta("mark_hand") else null
	var corr: Vector3 = w.get_meta("mark_corr") if w.has_meta("mark_corr") else Vector3.ZERO
	if to == null or not is_instance_valid(to):
		to = Node3D.new()
		w.add_child(to)
		to.global_position = want + corr + Vector3(MARKS_IN, 0, 0)
		w.set_meta("mark_hand", to)
		# (the reach is on the point well before the point is on the timber:
		# blended in and glided in together, the hand's way between the clip
		# and the point swung through the timber)
		f.reach(null, to, minf(secs, MARKS_BLEND))
	var from := to.global_position
	var seen: Array = w.area.call("_palm_watch", f, "right")
	var t := 0.0
	while t < secs + MARKS_SETTLE and is_instance_valid(to) and is_instance_valid(f):
		await w.get_tree().process_frame
		t += w.get_process_delta_time()
		var k := clampf(t / maxf(secs, 0.01), 0.0, 1.0)
		k = 0.5 - 0.5 * cos(k * PI)
		if k >= 1.0 and seen[0] != Vector3.INF:
			corr = (corr + (want - (seen[0] as Vector3)) * 0.7).limit_length(MARKS_CORR_MAX)
		to.global_position = from.lerp(want + corr, k)
	w.area.call("_palm_unwatch", seen)
	w.set_meta("mark_corr", corr)


## His hand off the marks (the point glides MARKS_IN off the timber first,
## his hand with it, so the arm goes back to the clip from clear of it), his
## arm his own again, and the point gone once it's off.
static func _marks_done(w: World, f: Figure3D) -> void:
	var old = w.get_meta("mark_hand") if w.has_meta("mark_hand") else null
	if old != null and is_instance_valid(old):
		var off := w.create_tween()
		off.tween_property(old, "global_position", (old as Node3D).global_position + Vector3(MARKS_IN, 0, 0), 0.3).set_trans(Tween.TRANS_SINE)
		await off.finished
	_bram_hand_back(f)
	await Cine.wait(w, 0.45)
	if old != null and is_instance_valid(old):
		(old as Node).queue_free()
	w.remove_meta("mark_hand")
	w.remove_meta("mark_corr")


## P3b · That Day (v7): the cellar, the lamp low. Bram at the back wall behind
## the ale casks, cutting marks into the old timber and pressing his thumb
## into each (each glows and goes dark); the player packing a satchel by the
## steps: bread, a flint, a spare shirt, the white card in a handkerchief.
static func that_day(w: World) -> void:
	var v := village(w)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.01)
	var r := cellar(v)
	InnRooms.inside(v)
	_only(w, ["bram", "player"])
	var wall: Vector3 = r.marks_at
	# (8 November, Gary: "his body is going through the stairs": the
	# cellar's `stairs` point is the staircase's middle, and the player
	# packed half a metre west of it, stood in its bottom steps. PACK_AT,
	# SATCHEL_AT: beside the steps' foot. And Bram: at the timber beside the
	# cask, MARKS_KNEEL, not a metre off the marks with the cask between.)
	var kneel_at := wall + MARKS_KNEEL
	Cine.place(w, "bram", kneel_at, kneel_at + Vector3(-1, 0, 0))
	var pack: Vector3 = (r.stairs as Vector3) + PACK_AT
	Cine.place(w, "player", pack, pack + Vector3(-1, 0, 0))
	# down on his knees at the wall (both knees: MARKS_KNEEL), behind the
	# caption's black
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).kneel(0.8, MARKS_LEAN, true)
	await Cine.caption(w, "That day")
	Cine.shot(w, r.stairs + Vector3(-1.6, 1.6, 1.0), wall + Vector3(0, 0.8, 0.3), 44.0)
	Cine.fade(w, 0.0, 1.0)
	var marks: Array = r.marks
	# from the north-west corner, down the timber past the cask: Bram at the
	# marks side on, his face and his hand on them (from the north-east the
	# cask hid him; from behind, all you saw was his back)
	Cine.shot(w, wall + Vector3(-0.15, 1.3, -1.15), wall + Vector3(-0.3, 1.0, 0.5), 42.0)
	await Cine.wait(w, 1.1)   # (down on his knees: where his shoulder is then)
	# the marks nearest his hand (MARKS_PRESSED), pressed in turn, his palm
	# flat to the timber (8 November: he reached for the last five cut, a
	# metre off, through the cask, his arm locked straight at them). The
	# palm's way is the timber's own (the world's -x), not his: turning on
	# his knees, a palm set in his own frame turned with him and the fingers
	# went into the timber.
	var press: Array = marks.slice(0, marks.size() - 1)   # (the last is pressed after the line)
	if bf is Figure3D:
		var from: Vector3 = (bf as Figure3D).bone_pos("RightArm")
		press.sort_custom(func(a: MeshInstance3D, b: MeshInstance3D) -> bool:
			return a.global_position.distance_to(from) < b.global_position.distance_to(from))
		(bf as Figure3D).elbow("right", MARKS_ELBOW * (bf as Figure3D).stature(), 0.01)
		(bf as Figure3D).palm("right", Vector3(-cos(MARKS_TIP), sin(MARKS_TIP), 0), 0.3, 1.0, false, Vector3.UP)
	press = press.slice(0, MARKS_PRESSED)
	var first := true
	for m: MeshInstance3D in press:
		if bf is Figure3D:
			await _press_mark(w, bf as Figure3D, m, 0.7 if first else 0.3)
		first = false
		_mark_glow(w, m, 0.9)
		await Cine.wait(w, 0.5)
	if bf is Figure3D:
		await _marks_done(w, bf as Figure3D)
	# the satchel by the steps: the player down on their knees over it, both
	# hands on its flap (PACK_LEAN, PACK_HANDS); from the south, low, the two
	# of them and the steps' foot behind
	var sat := satchel(v)
	sat.global_position = r.stairs + SATCHEL_AT
	sat.rotation = Vector3(0, PI * 0.5, 0)   # (lying across in front of them, its flap towards them)
	Cine.shot(w, sat.global_position + Vector3(0.95, 0.95, 1.05), sat.global_position + Vector3(0.12, 0.4, 0.0), 38.0)
	var pf = w.player_doll
	var pack_pts: Array = []
	if pf is Figure3D:
		var fig := pf as Figure3D
		fig.kneel(0.6, PACK_LEAN, true)
		for k in 2:
			var pt := Node3D.new()
			sat.add_child(pt)
			pt.position = PACK_HANDS[k]
			pack_pts.append(pt)
		fig.elbow("left", PACK_ELBOW * fig.stature(), 0.01)
		fig.elbow("right", PACK_ELBOW * Vector3(-1, 1, 1) * fig.stature(), 0.01)
		# (each hand to the point on its own side)
		var l_first := fig.bone_pos("LeftArm").distance_to((pack_pts[0] as Node3D).global_position) < fig.bone_pos("RightArm").distance_to((pack_pts[0] as Node3D).global_position)
		fig.reach(pack_pts[0] if l_first else pack_pts[1], pack_pts[1] if l_first else pack_pts[0], 0.7)
		var their_left := Vector3.UP.cross(fig.facing()).normalized()
		fig.palm("left", Vector3.DOWN, 0.7, 0.5, false, their_left)
		fig.palm("right", Vector3.DOWN, 0.7, 0.5, false, -their_left)
		await Cine.wait(w, 0.7)
		fig.press("left", sat.global_position.y + PACK_FLAP)
		fig.press("right", sat.global_position.y + PACK_FLAP)
	await Cine.wait(w, 0.7)
	await Cine.say(w, "", "[i]Bread, a flint, a spare shirt. The white card, wrapped in a handkerchief and buttoned into the inside pocket.[/i]")
	if pf is Figure3D:
		var fig := pf as Figure3D
		fig.press("left", NAN)
		fig.press("right", NAN)
		fig.let_go(0.4)
		fig.palm("left", Vector3.ZERO, 0.4)
		fig.palm("right", Vector3.ZERO, 0.4)
		fig.elbow("left", Vector3.INF, 0.4)
		fig.elbow("right", Vector3.INF, 0.4)
		fig.release(0.5)
	# he turns on his knees from the timber for it, MARKS_TURN to his right,
	# and the camera in the north-west corner, past the cask, has his face
	# (from the middle of the room, or behind or beside him, the cask hid it
	# all; turned right round to the player, his feet went into the timber)
	Cine.look(w, "bram", kneel_at + Vector3(-1, 0, 0).rotated(Vector3.UP, -MARKS_TURN))
	Cine.shot(w, wall + Vector3(-0.15, 1.3, -1.3), kneel_at + Vector3(0, 0.9, 0), 36.0)
	await Cine.say(w, "bram", "Twenty-two marks. I cut them the year we came and I've never once had to use them.")
	for pt in pack_pts:   # (the player's hands are off the satchel by now)
		(pt as Node).queue_free()
	# he presses the last
	var last: MeshInstance3D = marks[marks.size() - 1]
	Cine.shot(w, wall + Vector3(-0.15, 1.3, -1.15), wall + Vector3(-0.3, 1.0, 0.5), 42.0)
	if bf is Figure3D:
		# (back round to the timber first: reached for while he turned, the
		# hand came to the mark edge on)
		Cine.look(w, "bram", kneel_at + Vector3(-1, 0, 0))
		await Cine.wait(w, 0.4)
		(bf as Figure3D).elbow("right", MARKS_ELBOW * (bf as Figure3D).stature(), 0.01)
		(bf as Figure3D).palm("right", Vector3(-cos(MARKS_TIP), sin(MARKS_TIP), 0), 0.3, 1.0, false, Vector3.UP)
		await _press_mark(w, bf as Figure3D, last, 0.7)
	_mark_glow(w, last, 1.2)
	await Cine.wait(w, 0.8)
	if bf is Figure3D:
		await _marks_done(w, bf as Figure3D)
	await Cine.say(w, "bram", "Sundown. We go at sundown.")
	var c := await Cine.choose(w, ["Where does it come out?", "Will they be all right? Tam, Nell, Tilly..."])
	if c == 0:
		await Cine.say(w, "bram", "The far side of the hill, under the thorn trees. Nobody's walked that bank in a generation.")
	else:
		# the knife stops
		await Cine.wait(w, 0.9)
		await Cine.say(w, "bram", "Ironvault wants roofs and a card. It doesn't want a village full of corpses: corpses don't pay interest.")
		await Cine.wait(w, 0.6)
		await Cine.say(w, "bram", "They'll be frightened. They'll be all right.")
	await Cine.fade(w, 1.0, 1.0)
	w.area.call("_stand", w, "bram", 0.01)
	await Cine.caption(w, "Dusk")


# ============================================================= the cellar ===

## The Crooked Lantern's cellar as v7 has it: no fire upstairs; the ale casks
## along the west wall; behind the standing casks in the corner, a stretch of
## old timber with Bram's twenty-two Ward marks in it, and the tunnel's mouth
## behind it (a cask rolls aside).
static func cellar(v: AshfordVillage) -> Dictionary:
	var r := InnRooms.cellar(v)
	if r.has("marks"):
		return r
	var root: Node3D = r.root
	# the fire upstairs and its smoke (v3's burning night) are put out
	for c in root.get_children():
		if c is OmniLight3D and (c as OmniLight3D).light_color.g < 0.5:
			(c as OmniLight3D).light_energy = 0.0
			for fl in v.flicker_lights:
				if fl[0] == c:
					fl[1] = 0.0
		elif c is GPUParticles3D:
			(c as GPUParticles3D).emitting = false
			(c as Node3D).visible = false
	# the chest's boxes stay in the shelter in the Thornwood now
	for b in r.boxes:
		(b as Node3D).visible = false
	# the timber at the back wall, south of the barrels, and the marks
	var W := 6.5
	var tx := -W * 0.5 + 0.05
	var timber := Node3D.new()
	timber.name = "WardTimber"
	root.add_child(timber)
	for k in 5:
		v.box(timber, Vector3(0.08, 1.9, 0.26), Vector3(tx, 0.95, 1.05 + k * 0.28), v.mats.beam_v)
	var mark_mat := StandardMaterial3D.new()
	mark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark_mat.albedo_color = Color(0.55, 0.62, 0.9, 0.0)
	mark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mark_mat.albedo_texture = SealMark.texture()
	var marks: Array = []
	for i in 22:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.09, 0.09)
		mi.mesh = q
		mi.material_override = mark_mat.duplicate()
		mi.position = Vector3(tx + 0.05, 0.35 + float(i % 6) * 0.26, 1.05 + float(i / 6) * 0.3 + 0.04 * float(i % 2))
		mi.rotation = Vector3(0, PI * 0.5, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		timber.add_child(mi)
		marks.append(mi)
	# the cask that stands in front of the tunnel's mouth, and the dark behind it
	var cask := v.make_barrel()
	cask.position = Vector3(tx + 0.55, AshfordVillage.BARREL_HALF, 1.6)
	root.add_child(cask)
	var mouth := v.box(root, Vector3(0.06, 1.5, 0.95), Vector3(tx + 0.02, 0.75, 1.6), v.mats.dark)
	mouth.visible = false
	r["marks"] = marks
	r["marks_at"] = root.to_global(Vector3(tx + 0.4, 0, 1.6))
	r["cask"] = cask
	r["mouth"] = mouth
	r["mouth_at"] = root.to_global(Vector3(tx + 0.3, 0, 1.6))
	return r


## A Ward mark lights up and goes dark (`peak` how bright it gets).
static func _mark_glow(w: World, m: MeshInstance3D, peak: float) -> void:
	var mat := m.material_override as StandardMaterial3D
	if mat == null:
		return
	var tw := w.create_tween()
	tw.tween_method(func(k: float) -> void:
		mat.albedo_color = Color(0.55, 0.62, 0.9, k), 0.0, peak, 0.18)
	tw.tween_method(func(k: float) -> void:
		mat.albedo_color = Color(0.55, 0.62, 0.9, k), peak, 0.0, 1.1)


## The satchel the player packs: rough leather, a flap and a strap.
static func satchel(v: AshfordVillage) -> Node3D:
	if v.has_meta("satchel"):
		return v.get_meta("satchel")
	var s := Node3D.new()
	s.name = "Satchel"
	v.add_child(s)
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.36, 0.24, 0.14)
	lm.roughness = 0.85
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.22, 0.14, 0.08)
	dark.roughness = 0.9
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.62, 0.48, 0.22)
	brass.metallic = 0.7
	brass.roughness = 0.4
	# a soft leather bag (a rounded body, not a box), its flap over the
	# top, a buckle, and the strap lying in a loop beside it
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.15
	cm.height = 0.44
	cm.radial_segments = 20
	cm.rings = 8
	body.mesh = cm
	body.material_override = lm
	body.rotation = Vector3(0, 0, PI * 0.5)
	body.scale = Vector3(0.95, 1.0, 0.55)
	body.position = Vector3(0, 0.14, 0)
	s.add_child(body)
	v.box(s, Vector3(0.36, 0.025, 0.2), Vector3(0, 0.27, 0.0), dark, Vector3(0.12, 0, 0))
	v.box(s, Vector3(0.34, 0.16, 0.02), Vector3(0, 0.2, 0.085), dark, Vector3(-0.1, 0, 0))
	v.box(s, Vector3(0.05, 0.04, 0.015), Vector3(0, 0.14, 0.1), brass)
	var strap := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.2
	tm.outer_radius = 0.225
	tm.rings = 24
	tm.ring_segments = 4
	strap.mesh = tm
	strap.material_override = dark
	strap.scale = Vector3(1.0, 0.3, 0.7)
	strap.position = Vector3(0.05, 0.012, -0.14)
	s.add_child(strap)
	v.set_meta("satchel", s)
	return s


## Only these people are seen (the rest are hidden: a room below the village).
static func _only(w: World, keep: Array) -> void:
	for n in w.npcs:
		n.doll.visible = String(n.def.id) in keep


static func _all_seen(w: World) -> void:
	for n in w.npcs:
		n.doll.visible = true


# ========================================================= the Reckoning ===

## P4 · The Ashford Reckoning (v7): dusk, hours early. Krell on the green with
## Ironvault's bailiffs and their torches; her terms; nobody speaks; Tam
## steps between her and the inn and lies; then he challenges the debt, and
## she makes it to the death. In the cellar, Bram stops the player at the
## stairs, and they go through the tunnel. On the green, Tam's River Hound is
## torn apart, and Tam falls. Krell's orders; the restraint magic. No roof
## burns. (No blood is shown: Tam's life is drawn out of him by the duel.)
static func reckoning(w: World) -> void:
	var v := village(w)
	await Packs.need("looks")   # (the bailiffs are Gary's Player D: the web's looks pack)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.01)
	v.set_daylight(0.16)
	v.set_cart_tip(1.0)
	w.area.call("_clear_crowd", w)
	_all_seen(w)
	var A = _area(w)
	A.call("_crowd", w, _c(w, "CROWD_NIGHT"), Vector3(14, 0, 8))
	var night: Dictionary = _c(w, "NIGHT")
	A.call("_stage", w, night, Vector3(14.0, 0, 8.0))
	# Corin's at home with his mam, his knee bound; Tam stands nearest the inn
	var cb := Cine.body(w, "corin")
	if cb != null:
		Cine.fig(w, "corin").visible = false
	var r := cellar(v)
	# ---- in the cellar: hoofbeats overhead
	InnRooms.inside(v)
	Cine.place(w, "bram", r.stairs + Vector3(-0.4, 0, -0.6), r.stairs + Vector3(0, 2.0, -2.0))
	# (beside Bram as the camera sees them, not between: there he hid Bram)
	Cine.place(w, "player", r.stairs + Vector3(-1.85, 0, -0.45), r.stairs)
	Cine.shot(w, r.stairs + Vector3(-2.5, 1.5, 1.2), r.stairs + Vector3(-0.4, 1.55, -0.6), 40.0)
	await Cine.fade(w, 0.0, 0.8)
	_sfx(w, "hooves")
	w.shake(0.05)
	# up at the boards overhead, towards the camera (towards the stairs he
	# turned his back on it, and from the stairs' side they hid his face)
	Cine.look(w, "bram", r.stairs + Vector3(-1.6, 3.2, 0.4))
	await Cine.wait(w, 1.2)
	await Cine.say(w, "bram", "She's early.")
	await Cine.wait(w, 0.7)
	await Cine.say(w, "bram", "She's hours early.")
	await Cine.fade(w, 1.0, 0.5)
	InnRooms.outside(v)
	# ---- the green: Krell and the bailiffs ride in (the reckoning film, or the 3D)
	var hunters := ["h1", "h2", "h3", "h4", "h5", "h6"]
	var KRELL_AT: Vector3 = _c(w, "KRELL_AT")
	# where Tam plants his boots: between her horse and the path up to the inn
	var stand := KRELL_AT + (Vector3(-6.0, 0, 7.0) - KRELL_AT).normalized() * 3.2
	# (from the south-west, between Tam's spot and the Lantern: clear of the crowd)
	var krell_cam := KRELL_AT + Vector3(-4.0, 1.5, -1.6)
	var props := {}
	if StoryFilm.available("reckoning"):
		props = await _krell_film(w, hunters, KRELL_AT, stand)
	if props.is_empty():
		props = await _krell_arrives(w, hunters, KRELL_AT, stand, krell_cam)
	var barrel: Node3D = props.barrel
	var note: Node3D = props.note
	# ---- the cellar: the player for the stairs, Bram's hand on the arm
	await Cine.fade(w, 1.0, 0.4)
	InnRooms.inside(v)
	_only(w, ["bram", "player"])
	Cine.place(w, "player", r.stairs + Vector3(-1.0, 0, 0.0), r.stairs)
	Cine.place(w, "bram", r.stairs + Vector3(-1.8, 0, -0.5), r.stairs)
	Cine.shot(w, r.stairs + Vector3(-2.8, 1.5, 1.6), r.stairs + Vector3(-0.6, 1.2, -0.2), 40.0)
	await Cine.fade(w, 0.0, 0.4)
	Cine.path(w, "player", [r.stairs + Vector3(-0.2, 0, 0.2)], 3.2, "run")
	await Cine.wait(w, 0.3)
	await Cine.say(w, "player", "He's going to get himself killed for me! Bram, we have to help him. We can't just leave him out there!")
	# Bram catches him by the arm before the stairs; for a moment he looks as
	# though he might go back himself
	Cine.place(w, "player", r.stairs + Vector3(-0.4, 0, 0.1), r.stairs)
	await Cine.walk(w, "bram", r.stairs + Vector3(-1.0, 0, -0.1), 3.0)
	var bf = Cine.fig(w, "bram")
	var arm: Node3D = A.call("_shoulder_point", w, "player")
	if bf is Figure3D:
		(bf as Figure3D).reach(null, arm, 0.25)
	Cine.look(w, "player", Cine.body(w, "bram").global_position)
	Cine.look(w, "bram", r.stairs + Vector3(0, 2.4, -1.4))
	Cine.shot(w, r.stairs + Vector3(-1.4, 1.5, 1.4), r.stairs + Vector3(-0.7, 1.45, -0.1), 32.0)
	await Cine.wait(w, 1.4)
	Cine.look(w, "bram", w.player.global_position)
	await Cine.say(w, "bram", "I know, Sprout. And Tam knows what he's sacrificing, and why.")
	await Cine.say(w, "bram", "If you go out there, you won't save him. You'll give Krell exactly what she came for, and his sacrifice will mean nothing.")
	await Cine.say(w, "bram", "He's buying us time. We honour that by using it.")
	# he pulls the player to the casks; the cask rolls aside
	if bf is Figure3D:
		(bf as Figure3D).let_go(0.3)
	A.call("_free_tracker", arm)
	var cask: Node3D = r.cask
	var mouth_at: Vector3 = r.mouth_at
	# Bram on the mouth's south side, the player back on its north, so the
	# camera sees the cask go, the marks light and Bram's face
	Cine.path(w, "bram", [mouth_at + Vector3(0.7, 0, 0.6)], 2.4, "run")
	await Cine.path(w, "player", [mouth_at + Vector3(1.6, 0, -1.1)], 2.4, "run")
	Cine.look(w, "bram", w.player.global_position)
	Cine.shot(w, mouth_at + Vector3(2.65, 1.5, -0.7), mouth_at + Vector3(0.35, 1.0, -0.1), 44.0)
	var roll := w.create_tween()
	roll.tween_property(cask, "position", cask.position + Vector3(0.1, 0, -0.9), 0.8).set_trans(Tween.TRANS_SINE)
	await roll.finished
	(r.mouth as Node3D).visible = true
	for m in r.marks:
		_mark_glow(w, m, 0.5)
	await Cine.say(w, "bram", "Through the tunnel, now. I dug it the year we came to Ashford. Don't let Tam's hand go to waste!")
	await Cine.fade(w, 1.0, 0.6)
	InnRooms.outside(v)
	_all_seen(w)
	# ---- the tunnel, walked (no light but the Ward marks as Bram passes)
	await tunnel(w)
	# ---- the green: Tam's duel, to the death, and Krell's orders (the
	# tams_hand film, or the 3D)
	var filmed := false
	if StoryFilm.available("tams_hand"):
		filmed = await _tam_film(w, KRELL_AT, stand)
	if not filmed:
		await _tam_falls(w, KRELL_AT, stand)
		var kc := _krell_cam(w, KRELL_AT, krell_cam)
		Cine.shot(w, kc[0], kc[1], 34.0)
		await Cine.say(w, "krell", "The debt is settled. Search every building. Start with the inn. Keep the houses intact; they're worth more standing.")
		await Cine.say(w, "krell", "If anyone interferes, subdue them. I want the white card, not a heap of ashes.")
	# ---- the restraint magic, from the distant ridge (the no_roof film, or the 3D)
	var on_black := filmed
	filmed = false
	if StoryFilm.available("no_roof"):
		var nr := await StoryFilm.play(w, "no_roof")
		filmed = bool(nr.get("played", true))
	if not filmed:
		if on_black:
			var kc2 := _krell_cam(w, KRELL_AT, krell_cam)
			Cine.shot(w, kc2[0], kc2[1], 34.0)
			Cine.fade(w, 0.0, 0.6)
		await _restraint(w, hunters)
	await Cine.fade(w, 1.0, 1.0)
	for id in hunters + ["krell", "warhorse", "hound1", "river_hound"]:
		Cine.despawn(w, id)
	if is_instance_valid(barrel):
		barrel.queue_free()
	if is_instance_valid(note):
		note.queue_free()
	A.call("_drop_box", w, "tam")
	if cb != null:
		Cine.fig(w, "corin").visible = true


# ======================================================= Krell's warhorse ===

## Krell's heavy warhorse (Master Script v7: she rides in on it; 5 November,
## Gary's model, assets/models/ashford/warhorse.glb: a black horse in a red
## caparison, Tripo's rig with its own clips: idle, walk, trot, canter, run,
## gallop, rear, paw_ground, tail_swish, attack_kick, hit_react, victory,
## defeat, summon). It was made in a unit box: SCALE makes it a heavy horse,
## 1.75 m at the withers. Its rider's body is put on the saddle every frame
## (following its back as it rises and dips under her) and faces the way it
## faces; she sits astride (Figure3D.ride). A Cine extra, "warhorse":
## Cine.body finds it and Cine.despawn takes it away.
class Warhorse:
	extends Node3D
	const PATH := "res://assets/models/ashford/warhorse.glb"
	## from the model's units to metres (its withers stand 0.6 high in it)
	const SCALE := 2.9
	## the model faces -x: this turns it to face +z, as everyone does
	const TURN := PI * 0.5
	## the saddle: over this bone of its spine (behind the withers), this far
	## above it (m), where the rider's seat is
	const SADDLE_BONE := "tripo__Spine_2"
	const SADDLE_UP := 0.2
	## how much ground each gait covers in a second at the clip's own pace
	## (m/s, from how far a hoof travels on the ground: Tripo's clips are
	## slow, so they're played faster to match the speed asked for)
	const GAIT_PACE := {"walk": 0.65, "trot": 1.55, "canter": 2.3}
	const LOOPS := ["idle", "walk", "trot", "canter", "run", "gallop", "tail_swish"]
	var anim: AnimationPlayer
	var skel: Skeleton3D
	var rider: Node3D
	var rider_fig: Figure3D
	var ground: Callable
	var _bone := -1

	## A warhorse standing at `at` (on the ground `ground` gives: x, z ->
	## height), facing `face`; null if the model isn't there.
	static func make(w: World, at: Vector3, face: Vector3, ground_fn: Callable) -> Warhorse:
		if not ResourceLoader.exists(PATH):
			return null
		var h := Warhorse.new()
		h.name = "Warhorse"
		h.ground = ground_fn
		w.add_child(h)
		var m: Node3D = (load(PATH) as PackedScene).instantiate()
		m.scale = Vector3.ONE * SCALE
		m.rotation.y = TURN
		h.add_child(m)
		for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		h.skel = m.find_child("Skeleton3D", true, false) as Skeleton3D
		h._bone = h.skel.find_bone(SADDLE_BONE) if h.skel != null else -1
		h.anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if h.anim != null:
			for c in LOOPS:
				if h.anim.has_animation(c):
					h.anim.get_animation(c).loop_mode = Animation.LOOP_LINEAR
			h.anim.play("idle")
		h.global_position = Vector3(at.x, h._height(at.x, at.z), at.z)
		h.face(face)
		var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
		ex["warhorse"] = {"body": h, "doll": null}
		w.set_meta("extras", ex)
		h.set_meta("beast", true)
		return h

	func _height(x: float, z: float) -> float:
		return float(ground.call(x, z)) if ground.is_valid() else global_position.y

	## The way it faces, flat.
	func facing() -> Vector3:
		return Vector3(sin(rotation.y), 0.0, cos(rotation.y))

	func face(dir: Vector3) -> void:
		if Vector2(dir.x, dir.z).length() > 0.01:
			rotation.y = atan2(dir.x, dir.z)

	## Turns it to face `dir` over `secs`, stepping round on its walk.
	func turn_to(dir: Vector3, secs := 1.2) -> void:
		if Vector2(dir.x, dir.z).length() < 0.01:
			return
		var to := rotation.y + wrapf(atan2(dir.x, dir.z) - rotation.y, -PI, PI)
		play("walk", 0.25, 0.8)
		var tw := create_tween()
		tw.tween_property(self, "rotation:y", to, secs).set_trans(Tween.TRANS_SINE)
		await tw.finished
		play("idle", 0.4)

	func play(clip: String, blend := 0.3, speed := 1.0) -> void:
		if anim != null and anim.has_animation(clip):
			anim.speed_scale = speed
			anim.play(clip, blend)

	## Plays a one-off clip (paw_ground, rear) through, then stands.
	func act(clip: String) -> void:
		if anim == null or not anim.has_animation(clip):
			return
		play(clip, 0.25)
		await get_tree().create_timer(anim.get_animation(clip).length - 0.2, false).timeout
		if is_instance_valid(self) and anim.current_animation == clip:
			play("idle", 0.35)

	## Walks it (or `gait`: "trot", "canter") through `points` at `speed`
	## m/s (the clip sped up to match), over the ground, easing round into
	## each leg; then it stands.
	func walk_to(points: Array, speed: float, gait := "walk") -> void:
		play(gait, 0.4, clampf(speed / float(GAIT_PACE.get(gait, 0.65)), 0.5, 3.0))
		for p: Vector3 in points:
			var from := global_position
			var flat := Vector3(p.x - from.x, 0.0, p.z - from.z)
			var dist := flat.length()
			if dist < 0.05:
				continue
			var want := rotation.y + wrapf(atan2(flat.x, flat.z) - rotation.y, -PI, PI)
			var t := 0.0
			while t < dist / speed and is_inside_tree():
				await get_tree().process_frame
				var dt := get_process_delta_time()
				t += dt
				var q := from + flat * minf(1.0, t * speed / dist)
				global_position = Vector3(q.x, _height(q.x, q.z), q.z)
				rotation.y = lerpf(rotation.y, want, minf(1.0, dt * 2.5))
		play("idle", 0.5)

	## Puts someone on its back: their body on the saddle from now on, sat
	## astride, facing the way it faces.
	func mount(body: Node3D, fig: Figure3D) -> void:
		rider = body
		rider_fig = fig
		_process(0.0)
		if fig != null:
			fig.ride(0.0)

	func saddle() -> Vector3:
		if skel == null or _bone < 0:
			return global_position + Vector3(0, 1.75, 0)
		return skel.global_transform * skel.get_bone_global_pose(_bone).origin + Vector3.UP * SADDLE_UP

	func _process(_delta: float) -> void:
		if rider == null or not is_instance_valid(rider):
			return
		rider.global_position = saddle()
		if rider_fig != null and is_instance_valid(rider_fig):
			rider_fig.snap_face(facing())

	func _exit_tree() -> void:
		# (Cine.despawn takes the horse: its rider goes with it)
		if rider != null and is_instance_valid(rider) and rider.is_inside_tree():
			rider.visible = false


## Krell's horse, if she's riding it.
static func _warhorse(w: World) -> Warhorse:
	var b := Cine.body(w, "warhorse")
	return b as Warhorse if b is Warhorse else null


## Where to look at Krell from, for her lines: her own camera when she's on
## foot (from among the crowd, a little low); mounted, from the side of her
## horse's head, a little below her, so its head and neck don't stand
## between her and the camera. [camera, the point it looks at]
static func _krell_cam(w: World, KRELL_AT: Vector3, krell_cam: Vector3) -> Array:
	var h := _warhorse(w)
	if h == null:
		return [krell_cam, KRELL_AT + Vector3(0.5, 1.5, 0)]
	var f := h.facing()
	var side := f.cross(Vector3.UP)
	var head := Cine.head(w, "krell")
	# (on the side the crowd is, the green's: towards the Lantern)
	if side.dot(Vector3(-2, 0, 5) - KRELL_AT) < 0.0:
		side = -side
	return [head + f * 2.6 + side * 2.4 - Vector3(0, 0.55, 0), head - Vector3(0, 0.12, 0)]


## Krell on her horse: how far before her spot she drops from a canter to a
## walk (m), and where her ledger is held up there (her own frame: over the
## horse's withers, in front of her chest).
const HORSE_WALK_IN := 4.0
const LEDGER_RIDING := Vector3(0.0, 0.5, 0.34)
## Where the bailiffs stand in a line before the green, torches up.
const BAILIFF_LINE := [Vector3(9.5, 0, 3.4), Vector3(10.2, 0, 5.4), Vector3(10.4, 0, 7.6), Vector3(10.0, 0, 9.8), Vector3(9.2, 0, 11.8), Vector3(11.6, 0, 6.6)]


## Krell rides in with her bailiffs and reads the terms; Tam's note on the
## rain barrel and his lie; her answer; his drawn hand, and her stakes (the
## engine's 3D of what the reckoning film shows). Hands back the barrel and
## the note, for the scene to take away after.
static func _krell_arrives(w: World, hunters: Array, KRELL_AT: Vector3, stand: Vector3, krell_cam: Vector3) -> Dictionary:
	var v := village(w)
	var A = _area(w)
	Music.play(["ashford_burns"], 1.0, true)
	var line := BAILIFF_LINE
	for i in hunters.size():
		var start := Vector3(46.0 + i * 3.0, 0, 10.0 + (i % 3) * 1.2)
		Cine.spawn(w, hunters[i], "hunter", start, "Bailiff")
		A.call("_torch", v, Cine.body(w, hunters[i]))
	Cine.spawn(w, "krell", "krell", Vector3(42.0, 0, 11.0), "Krell")
	# (v7: she rides in on her heavy warhorse, Gary's model: up the road at a
	# canter with her bailiffs, then a walk onto the green, and a halt; she
	# runs in on foot, as before, when it isn't there)
	var horse: Warhorse = null
	var kf = Cine.fig(w, "krell")
	if kf is Figure3D:
		horse = Warhorse.make(w, Vector3(42.0, 0, 11.0), Vector3(-1, 0, 0), v.height)
		if horse != null:
			horse.mount(Cine.body(w, "krell"), kf)
	Cine.beast(w, "hound1", "shieldhound", Vector3(44.0, 0, 13.0), Color(1.0, 0.2, 0.15, 1.0))
	_tint_beast(w, "hound1", Color(0.06, 0.05, 0.08), 1.0)
	var ledger: Node3D = A.call("_ledger", w, "krell")
	if horse != null and ledger != null:
		ledger.position = LEDGER_RIDING   # (held over the horse's withers, not at a standing woman's waist)
	Cine.shot(w, Vector3(3.0, 2.0, 12.5), Vector3(36.0, 1.5, 10.5), 32.0)
	Cine.fade(w, 0.0, 1.0)
	for i in hunters.size():
		Cine.path(w, hunters[i], [Vector3(20.0, 0, 11.0 + (i % 3)), line[i]], 6.0, "run")
	Cine.path(w, "hound1", [Vector3(20.0, 0, 13.0), KRELL_AT + Vector3(1.0, 0, 1.8)], 6.5)
	if horse != null:
		var on := KRELL_AT + (Vector3(20.0, 0, 10.0) - KRELL_AT).normalized() * HORSE_WALK_IN
		await horse.walk_to([Vector3(20.0, 0, 10.0), on], 5.6, "canter")
		await horse.walk_to([KRELL_AT], 1.3, "walk")
		# the halt: she turns it to face the green, and it paws the ground
		await horse.turn_to(Vector3(-2, 0, 5) - KRELL_AT, 0.8)
		horse.act("paw_ground")
	else:
		await Cine.path(w, "krell", [Vector3(20.0, 0, 10.0), KRELL_AT], 5.6, "run")
	for i in hunters.size():
		Cine.look(w, hunters[i], Vector3(-2, 0, 5))
	Cine.look(w, "krell", Vector3(-2, 0, 5))
	await Cine.wait(w, 0.6)
	var kc := _krell_cam(w, KRELL_AT, krell_cam)
	Cine.shot(w, kc[0], kc[1], 34.0)
	await Cine.say(w, "krell", "Good evening. I hold the foreclosure notes for twenty-two properties in this valley.")
	await Cine.say(w, "krell", "By the authority of Caldus Morne and the House of Ironvault, the terms are as follows. Every roof but the inn's is forfeit tonight.")
	await Cine.say(w, "krell", "Alternatively, you may surrender one card, the white one, and the notes are burned. I will wait five minutes.")
	# nobody speaks; the silence stretches
	Music.stop(1.0)
	var np := Cine.body(w, "nell").global_position
	if horse != null:
		# (over her shoulder from the saddle's height, behind her head)
		var hf := horse.facing()
		Cine.shot(w, Cine.head(w, "krell") - hf * 0.9 + hf.cross(Vector3.UP) * 0.5 + Vector3(0, 0.15, 0), Vector3(-1.4, 1.2, 6.2), 42.0)
	else:
		Cine.shot(w, KRELL_AT + Vector3(-1.2, 1.7, 0.6), Vector3(-1.4, 1.2, 6.2), 42.0)
	await Cine.wait(w, 2.0)
	Cine.shot(w, np + Vector3(-1.0, 1.6, -3.2), np + Vector3(0.3, 1.2, 0.2), 34.0)
	await Cine.wait(w, 1.8)
	# Tam steps forward, between her horse and the path up to the inn, and
	# slaps his note on a rain barrel
	Cine.shot(w, Vector3(0.2, 1.7, 3.2), (stand + KRELL_AT) * 0.5 + Vector3(0, 1.2, 0), 38.0)
	await Cine.walk(w, "tam", stand, 1.1)
	Cine.look(w, "tam", KRELL_AT)
	var props := _rain_barrel(w, stand, KRELL_AT)
	_sfx(w, "hit_light", 0.9)
	var tam_cam := stand + (KRELL_AT - stand).normalized().cross(Vector3.UP) * -1.6 + Vector3(0, 1.55, 0) + (KRELL_AT - stand).normalized() * 1.3
	Cine.shot(w, tam_cam, Cine.head(w, "tam"), 30.0)
	await Cine.say(w, "tam", "The note says midnight. Take the mill, Huntmaster. It's yours. But you leave the people out of this.")
	await Cine.say(w, "tam", "The one you're looking for, the Unsworn, they fled over the northern ridge hours ago.")
	# she looks down at the note, then at Tam, and leans forward with a cold,
	# almost sympathetic smile, her eyes on where he's planted his boots
	if horse != null:
		# (her face, up on the horse, from a little below and to its side)
		var kh := Cine.head(w, "krell")
		var hf := horse.facing()
		var hs := hf.cross(Vector3.UP)
		if hs.dot(Vector3(-2, 0, 5) - KRELL_AT) < 0.0:
			hs = -hs
		Cine.shot(w, kh + hf * 1.7 + hs * 2.2 - Vector3(0, 0.35, 0), kh - Vector3(0, 0.08, 0), 26.0)
	else:
		Cine.shot(w, KRELL_AT + Vector3(-3.0, 1.65, -0.9), KRELL_AT + Vector3(0, 1.45, 0), 26.0)
	await Cine.wait(w, 1.6)
	await Cine.say(w, "krell", "A brave lie, Miller. But you're a terrible card player.")
	await Cine.say(w, "krell", "You put your body between my hounds and the inn before you even opened your mouth.")
	await Cine.say(w, "krell", "Guards, search every building. Collect every note. If they don't have the coin, take the property.")
	# he reaches into his coat: not for another note. A worn deck. The crowd gasps.
	Cine.shot(w, tam_cam, Cine.head(w, "tam") - Vector3(0, 0.3, 0), 36.0)   # (his face and the deck)
	var deck: Node3D = A.call("_card_box")
	A.call("_hold_box", w, "tam", deck)
	await Cine.wait(w, 0.8)
	for c in _c(w, "CROWD"):
		Cine.hop(w, String(c[0]), 0.08)
	await Cine.say(w, "tam", "I challenge the debt, Huntmaster! Under the Covenant, you cannot refuse a drawn hand.")
	kc = _krell_cam(w, KRELL_AT, krell_cam)
	Cine.shot(w, kc[0], kc[1], 34.0)
	await Cine.say(w, "krell", "Fair enough, Miller. The law states I cannot refuse a duel. But if you wish to go ahead with this, I have the right to set the stakes.")
	await Cine.say(w, "krell", "And to deter anyone else from trying it... we fight to the death. Draw your Essence.")
	A.call("_close_ledger", w, ledger)
	return props


## The reckoning as Gary's own film (StoryFilm "reckoning": Krell's arrival to
## her stakes), when it's there. It leaves the green as the 3D version does:
## the bailiffs in their line with their torches, Krell and her hound of
## shadow, Tam where he planted his boots with his deck in his hand, his note
## on the rain barrel. Hands back the barrel and the note ({}: the film
## couldn't play, and the 3D version plays instead).
static func _krell_film(w: World, hunters: Array, KRELL_AT: Vector3, stand: Vector3) -> Dictionary:
	var v := village(w)
	var A = _area(w)
	var r := await StoryFilm.play(w, "reckoning")
	if not r.get("played", true):
		return {}
	for i in hunters.size():
		Cine.spawn(w, hunters[i], "hunter", BAILIFF_LINE[i], "Bailiff")
		A.call("_torch", v, Cine.body(w, hunters[i]))
		Cine.look(w, hunters[i], Vector3(-2, 0, 5))
	Cine.spawn(w, "krell", "krell", KRELL_AT, "Krell")
	Cine.look(w, "krell", Vector3(-2, 0, 5))
	# (on her horse, as the film has her)
	var kf = Cine.fig(w, "krell")
	if kf is Figure3D:
		var horse := Warhorse.make(w, KRELL_AT, Vector3(-2, 0, 5) - KRELL_AT, v.height)
		if horse != null:
			horse.mount(Cine.body(w, "krell"), kf)
	Cine.beast(w, "hound1", "shieldhound", KRELL_AT + Vector3(1.0, 0, 1.8), Color(1.0, 0.2, 0.15, 1.0))
	_tint_beast(w, "hound1", Color(0.06, 0.05, 0.08), 1.0)
	Cine.place(w, "tam", stand, KRELL_AT)
	var props := _rain_barrel(w, stand, KRELL_AT)
	A.call("_hold_box", w, "tam", A.call("_card_box"))
	Music.stop(0.5)
	return props


## Tam's rain barrel, beside where he stands, with his note slapped down on it.
static func _rain_barrel(w: World, stand: Vector3, KRELL_AT: Vector3) -> Dictionary:
	var v := village(w)
	var barrel := v.make_barrel()
	v.add_child(barrel)
	var bpos := stand + (KRELL_AT - stand).normalized().cross(Vector3.UP) * 0.9
	barrel.global_position = Vector3(bpos.x, v.height(bpos.x, bpos.z) + AshfordVillage.BARREL_HALF, bpos.z)
	barrel.set_meta("p1_prop", true)
	var note := AshfordP1.letter(v)
	v.add_child(note)
	note.global_position = barrel.global_position + Vector3(0, AshfordVillage.BARREL_HALF + 0.01, 0)
	note.rotation = Vector3(-PI * 0.5, 0.4, 0)
	note.scale = Vector3.ONE * 0.9
	return {"barrel": barrel, "note": note}

## Tam's duel: his River Hound against Krell's hound of shadow, in the
## Circle on the green. It tears through her; the feedback shatters his Ward
## and he goes down, his life drawn out of him. Nell screams and drops to her
## knees.
static func _tam_falls(w: World, krell_at: Vector3, tam_at: Vector3) -> void:
	var v := village(w)
	var A = _area(w)
	A.call("_stage", w, {"tam": tam_at}, krell_at)
	Cine.look(w, "tam", krell_at)
	var mid := (krell_at + tam_at) * 0.5
	var across := (krell_at - tam_at).normalized()
	var side := across.cross(Vector3.UP)
	# the River Hound, called out of his card, and Krell's hound of shadow
	var rh_at := tam_at + across * 1.4
	# (Gary's own River Hound when it's made; until then a Shieldhound tinted river blue)
	var own_hound := ResourceLoader.exists("res://assets/models/creatures/river_hound.glb")
	# (Gary's has its own eyes: the glowing ones are placed for the Shieldhound's
	# head, and would hang in the air in front of hers)
	Cine.beast(w, "river_hound", "river_hound" if own_hound else "shieldhound", rh_at, Color(0, 0, 0, 0) if own_hound else Color(0.7, 0.9, 1.0, 1.0))
	if not own_hound:
		_tint_beast(w, "river_hound", Color(0.3, 0.62, 0.9), 0.75)
	var hp: Node3D = Cine.body(w, "hound1")
	if hp != null:
		Cine.place(w, "hound1", krell_at - across * 1.4, tam_at)
	Cine.look(w, "river_hound", krell_at)
	var ring: MeshInstance3D = _ring(w, mid, 2.6)
	Cine.shot(w, mid + side * 6.0 + Vector3(0, 2.4, 0), mid + Vector3(0, 0.8, 0), 40.0)
	Cine.fade(w, 0.0, 0.8)   # (up out of the tunnel's black)
	Music.play(["sigilfall"], 0.5, true)
	await Cine.wait(w, 1.6)
	# it tears through her
	Cine.beast_play(w, "hound1", "attack", 1.3)
	Cine.path(w, "hound1", [rh_at + across * 0.3], 9.0)
	await Cine.wait(w, 0.45)
	_sfx(w, "hit_heavy", 0.8)
	w.shake(0.4)
	var rhb := Cine.body(w, "river_hound")
	if rhb != null:
		var gone := w.create_tween()
		gone.tween_property(rhb, "scale", Vector3(1.3, 0.05, 1.3), 0.35).set_trans(Tween.TRANS_QUAD)
		gone.tween_callback(func() -> void:
			if is_instance_valid(rhb):
				rhb.visible = false)
		v.glow_sprite(v, rh_at + Vector3(0, 0.6, 0), Color(0.5, 0.8, 1.0), 1.4, 0.7)
	await w.flash(Color(0.6, 0.8, 1.0), 0.06, 0.5)
	# the feedback shatters his Ward; he goes down, clutching his chest
	var tf = Cine.fig(w, "tam")
	Cine.shot(w, tam_at + side * 2.4 + Vector3(0, 1.4, 0) - across * 0.6, tam_at + Vector3(0, 1.1, 0), 40.0)
	if tf is Figure3D:
		(tf as Figure3D).pose("defeat", 0.45, 0.3)
	await Cine.wait(w, 1.0)
	if tf is Figure3D:
		(tf as Figure3D).let_go(0.05)
		A.call("_tam_down", tf, 0.15)
	await Cine.wait(w, 1.6)
	if is_instance_valid(ring):
		var rf := w.create_tween()
		rf.tween_property(ring, "scale", Vector3.ONE * 0.01, 0.8)
		rf.tween_callback(ring.queue_free)
	# Nell screams, and drops to her knees
	var np := Cine.body(w, "nell").global_position
	var to_t := (tam_at - np)
	to_t.y = 0.0
	to_t = to_t.normalized()
	Cine.place(w, "nell", np, tam_at)
	Cine.shot(w, np - to_t * 3.0 - to_t.cross(Vector3.UP) * 1.4 + Vector3(0, 1.5, 0), np + to_t * 1.5 + Vector3(0, 0.8, 0), 32.0)   # (from her left: Hob stood in the way on her right)
	await Cine.say(w, "nell", "Tam!", 2.0)
	A.call("_kneel", w, "nell", 0.6)
	await Cine.wait(w, 1.6)
	Music.stop(2.0)



## Tam's duel as Gary's own film (StoryFilm "tams_hand": the duel, his fall,
## Nell, and Krell's orders), when it's there. It leaves the green as the 3D
## version does: Tam down, Nell on her knees by him, Krell's hound back by
## her. False if the film couldn't play.
static func _tam_film(w: World, krell_at: Vector3, tam_at: Vector3) -> bool:
	var A = _area(w)
	A.call("_stage", w, {"tam": tam_at}, krell_at)
	var r := await StoryFilm.play(w, "tams_hand")
	if not r.get("played", true):
		return false
	var across := (krell_at - tam_at).normalized()
	Cine.place(w, "hound1", krell_at - across * 1.4, tam_at)
	var tf = Cine.fig(w, "tam")
	if tf is Figure3D:
		(tf as Figure3D).let_go(0.0)
		A.call("_tam_down", tf, 0.0)
	var nb := Cine.body(w, "nell")
	if nb != null:
		Cine.place(w, "nell", nb.global_position, tam_at)
		A.call("_kneel", w, "nell", 0.01)
	Music.stop(0.5)
	return true


## From a distant ridge: two enforcers draw cards on the moonlit green. One
## summons a controlled line of fire to stop the villagers passing, touching
## no house; the other binds a resisting villager in glowing strands and
## forces them to their knees. Soldiers search the houses behind. No roof burns.
static func _restraint(w: World, hunters: Array) -> void:
	var v := village(w)
	var A = _area(w)
	var fire_line: Array = []
	var a := Vector3(-3.0, 0, 9.0)
	var b := Vector3(4.0, 0, 9.6)
	Cine.path(w, String(hunters[0]), [a + Vector3(0, 0, -1.4)], 3.0, "run")
	Cine.path(w, String(hunters[1]), [Vector3(-6.4, 0, 5.4)], 3.0, "run")
	for k in range(2, hunters.size()):
		Cine.path(w, String(hunters[k]), [Vector3(-14.0 + k * 6.0, 0, -12.0 + (k % 2) * 4.0)], 2.6, "run")
	await Cine.wait(w, 1.2)
	# the ridge
	Cine.shot(w, Vector3(-26.0, 22.0, 36.0), Vector3(0.0, 0.5, 7.0), 34.0)
	for i in 12:
		var p := a.lerp(b, i / 11.0)
		p.y = v.height(p.x, p.z) + 0.35
		fire_line.append(v.glow_sprite(v, p, Color(1.0, 0.5, 0.15), 0.9, 1.6))
		await Cine.wait(w, 0.06)
	var fl := Cine.light(w, (a + b) * 0.5 + Vector3(0, 1.0, 0), Color(1.0, 0.55, 0.2), 2.2, 9.0)
	# a villager bound in light, forced down
	var bound := String(_c(w, "CROWD")[6][0])
	var bp := Vector3(-7.2, 0, 4.6)
	Cine.place(w, bound, bp, Vector3(-6.4, 0, 5.4))
	var strands := v.glow_sprite(v, bp + Vector3(0, 0.9, 0), Color(0.6, 0.85, 1.0), 1.1, 1.8)
	A.call("_kneel", w, bound, 0.8)
	await Cine.wait(w, 3.2)
	Cine.shot(w, Vector3(-6.0, 1.8, 13.0), (a + b) * 0.5 + Vector3(0, 0.8, 0), 40.0)
	await Cine.wait(w, 2.4)
	for g in fire_line + [strands]:
		if is_instance_valid(g):
			(g as Node).queue_free()
	if is_instance_valid(fl):
		fl.queue_free()


## A ring of light on the ground (the duelling Circle).
static func _ring(w: World, at: Vector3, r: float) -> MeshInstance3D:
	var v := village(w)
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.06
	tm.outer_radius = r
	tm.rings = 48
	tm.ring_segments = 4
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.85, 0.75, 0.45)
	mi.material_override = m
	mi.scale = Vector3(1, 0.05, 1)
	v.add_child(mi)
	mi.global_position = Vector3(at.x, v.height(at.x, at.z) + 0.03, at.z)
	return mi


## A beast's colour: every mesh in it tinted, and see-through when alpha < 1.
static func _tint_beast(w: World, id: String, col: Color, alpha: float) -> void:
	var b := Cine.body(w, id)
	if b == null:
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col, alpha)
	m.roughness = 0.6
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission = col * 0.5
	for mi in b.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = m


static func _sfx(w: World, sound: String, pitch := 1.0) -> void:
	w.area.call("_sfx", w, sound, pitch)


# ============================================================ the tunnel ===

## The tunnel Bram dug the year they came: low, shored with old timber, dark
## but for his Ward marks, each glowing faintly as he passes it. Walked: the
## player follows him to the far end, where the thorn roots let the last of
## the dusk in.
static func tunnel(w: World) -> void:
	var v := village(w)
	var t := _tunnel_room(v)
	InnRooms.inside(v)
	_only(w, ["bram", "player"])
	var start: Vector3 = t.start
	var end: Vector3 = t.end
	Cine.place(w, "bram", start + Vector3(0, 0, -1.6), end)
	Cine.place(w, "player", start, end)
	var cam := (t.root as Node3D).to_global(Vector3(0.0, 1.55, 1.2))
	Cine.shot(w, cam, start + Vector3(0, 1.0, -1.6), 52.0)
	# the camera comes along behind him, low under the timbers
	t["cam_follow"] = func(p: Vector3) -> Vector3: return p + Vector3(0.0, 1.5, 2.3)
	await Cine.fade(w, 0.0, 0.8)
	Game.set_flag("objective", "Follow Bram through the tunnel.")
	w.hud.set_objective("Follow Bram through the tunnel.")
	# Bram goes on ahead at a walk, his marks lighting as he passes them
	var going := [true]
	_bram_ahead(w, t, going)
	AshfordP1.controls_on(w)
	await AshfordP1.walk_room(w, t, cam, func(p: Vector3) -> bool: return p.distance_to(end) < 1.4)
	going[0] = false
	w.hud.set_objective("")
	Game.set_flag("objective", "")
	w.hud.set_controls_visible(false)
	await Cine.fade(w, 1.0, 0.8)
	InnRooms.outside(v)
	_all_seen(w)


## Bram walking on ahead down the tunnel, three steps in front of the player
## at most, his Ward marks glowing faintly as he passes each.
static func _bram_ahead(w: World, t: Dictionary, going: Array) -> void:
	var marks: Array = t.marks
	var lit := {}
	var end: Vector3 = t.end
	while going[0] and is_instance_valid(w):
		var bb := Cine.body(w, "bram")
		var p := w.player.global_position
		if bb != null:
			var lead := bb.global_position.distance_to(end)
			var mine := p.distance_to(end)
			if lead > 0.6 and mine - lead < 3.0:
				var step := bb.global_position.move_toward(end, 1.4 * w.get_process_delta_time())
				bb.global_position = step
				var bf = Cine.fig(w, "bram")
				if bf != null:
					bf.walking = true
					bf.face(end - bb.global_position, w.cam)
			else:
				var bf2 = Cine.fig(w, "bram")
				if bf2 != null:
					bf2.walking = false
			for i in marks.size():
				var m: MeshInstance3D = marks[i]
				if not lit.has(i) and m.global_position.distance_to(bb.global_position) < 1.0:
					lit[i] = true
					_mark_glow(w, m, 0.7)
		await w.get_tree().process_frame
	var bf3 = Cine.fig(w, "bram")
	if bf3 != null:
		bf3.walking = false


## The tunnel itself (built once, well below the village).
static func _tunnel_room(v: AshfordVillage) -> Dictionary:
	if v.has_meta("tunnel"):
		return v.get_meta("tunnel")
	var root := Node3D.new()
	root.name = "Tunnel"
	root.position = TUNNEL_AT
	v.add_child(root)
	var Wd := 1.7
	var H := 2.0
	var Ln := TUNNEL_LEN
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color(0.2, 0.15, 0.1)
	earth.roughness = 1.0
	v.box(root, Vector3(Wd, 0.2, Ln), Vector3(0, -0.1, -Ln * 0.5), earth)
	v.box(root, Vector3(Wd, 0.2, Ln), Vector3(0, H + 0.1, -Ln * 0.5), earth)
	for s in [-1.0, 1.0]:
		v.box(root, Vector3(0.2, H, Ln), Vector3(s * (Wd * 0.5 + 0.1), H * 0.5, -Ln * 0.5), earth)
	# old timber shoring every couple of metres
	var z := -1.0
	while z > -Ln + 1.0:
		for s in [-1.0, 1.0]:
			v.box(root, Vector3(0.14, H, 0.14), Vector3(s * (Wd * 0.5 - 0.07), H * 0.5, z), v.mats.beam_v)
		v.box(root, Vector3(Wd, 0.14, 0.16), Vector3(0, H - 0.07, z), v.mats.beam)
		z -= 2.2
	# Ward marks on the timbers
	var marks: Array = []
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.albedo_color = Color(0.55, 0.62, 0.9, 0.0)
	mm.albedo_texture = SealMark.texture()
	z = -2.0
	var k := 0
	while z > -Ln + 1.5:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.1, 0.1)
		mi.mesh = q
		mi.material_override = mm.duplicate()
		var s2 := -1.0 if k % 2 == 0 else 1.0
		mi.position = Vector3(s2 * (Wd * 0.5 - 0.15), 1.25, z)
		mi.rotation = Vector3(0, -s2 * PI * 0.5, 0)
		root.add_child(mi)
		marks.append(mi)
		z -= 2.2
		k += 1
	# a faint blue fill (the marks' own light), and the dusk at the far end
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.45, 0.52, 0.85)
	fill.light_energy = 0.35
	fill.omni_range = Ln
	fill.position = Vector3(0, 1.6, -Ln * 0.5)
	root.add_child(fill)
	var dusk := OmniLight3D.new()
	dusk.light_color = Color(0.85, 0.62, 0.5)
	dusk.light_energy = 1.4
	dusk.omni_range = 5.0
	dusk.position = Vector3(0, 1.2, -Ln + 0.6)
	root.add_child(dusk)
	var roots := StandardMaterial3D.new()
	roots.albedo_color = Color(0.16, 0.12, 0.08)
	for i in 7:
		var rr := v.box(root, Vector3(0.05, 0.9, 0.05), Vector3(-0.6 + i * 0.2, H - 0.45, -Ln + 0.3), roots, Vector3(0.2 * sin(i), 0, 0.25 * cos(i)))
		rr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var out := {"root": root, "floor_y": TUNNEL_AT.y, "marks": marks,
		"start": root.to_global(Vector3(0, 0, -0.6)), "end": root.to_global(Vector3(0, 0, -Ln + 1.2)),
		"walk": Rect2(-Wd * 0.5 + 0.3, -Ln + 0.6, Wd - 0.6, Ln - 0.8), "blocks": []}
	v.set_meta("tunnel", out)
	return out


# ========================================================= the look back ===

## Gary's moment (v7): the protagonist and Bram climb out of the tunnel's
## mouth under the thorn roots on the hill above Ashford, and he turns.
## Ashford is still there, all of it: the lanterns, the Great Lantern, the
## Crooked Lantern with a light moving from window to window, grey coats on
## the green in pairs, a line of villagers kneeling by the well with their
## hands bound in light. No music, no words: the chapel bell, slow, and Nell
## crying. The player has control and nothing says what to do; if they walk
## towards the village, or stand there long enough, he takes a step down the
## hill on his own, then another; Bram's hand comes down on his shoulder and
## stays until he stops. Then Corin, out of breath, limping on a cart spoke.
static func look_back(w: World) -> void:
	var v := village(w)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.01)
	v.set_daylight(0.0)
	Music.stop(0.5)
	var A = _area(w)
	A.call("_clear_crowd", w)
	# the village held: greys walking the green in pairs, the kneeling line
	_held_village(w)
	# the hillside: the tunnel's mouth under the thorns
	var mouth := MOUTH
	mouth.y = v.height(mouth.x, mouth.z)
	var to_v := VILLAGE_LOOK - mouth
	to_v.y = 0.0
	to_v = to_v.normalized()
	var hill := _hillside(v, mouth, to_v)
	var start := mouth + to_v * 1.2
	start.y = v.height(start.x, start.z)
	AshfordP1.put(w, "player", start, start - to_v)
	AshfordP1.put(w, "bram", mouth + to_v * 0.4 + to_v.cross(Vector3.UP) * 0.9, start)
	for n in w.npcs:
		if not (String(n.def.id) in ["player", "bram", "corin"]):
			n.doll.visible = false
	var cb := Cine.body(w, "corin")
	if cb != null:
		Cine.fig(w, "corin").visible = false
	# out of the dark, and he turns
	Cine.shot(w, start - to_v * 2.6 + Vector3(0, 1.8, 0) + to_v.cross(Vector3.UP) * 1.0, start + Vector3(0, 1.3, 0), 44.0)
	await Cine.fade(w, 0.0, 1.4)
	await Cine.wait(w, 0.8)
	Cine.look(w, "player", VILLAGE_LOOK)
	await Cine.wait(w, 0.9)
	# over his shoulder: Ashford, still there
	var over := start - to_v * 1.4 + Vector3(0, 1.75, 0) + to_v.cross(Vector3.UP) * 0.45
	Cine.shot(w, over, VILLAGE_LOOK, 38.0)
	_bell_slow(w)
	var crying := _nell_crying(w)
	await Cine.wait(w, 4.0)
	# his own: nothing says what to do
	var ground := func(p: Vector3) -> float: return v.height(p.x, p.z)
	var hill_room := {"root": hill, "floor_y": start.y, "ground": ground,
		"walk": Rect2(-3.0, -2.0, 6.0, 12.0), "blocks": []}
	AshfordP1.controls_on(w)
	w.hud._menu_btn.visible = true
	var t0 := [0.0]
	var stepped := [false]
	await AshfordP1.walk_room(w, hill_room, over, func(p: Vector3) -> bool:
		t0[0] += w.get_process_delta_time()
		var down := (p - start).dot(to_v)
		if down > LOOK_STEP:
			stepped[0] = true
			return true
		return t0[0] > LOOK_WAIT)
	w.hud.set_controls_visible(false)
	# a step down the hill on his own. Then another.
	var p := w.player.global_position
	var step1 := p + to_v * 0.7
	step1.y = v.height(step1.x, step1.z)
	await Cine.path(w, "player", [step1], 0.9)
	await Cine.wait(w, 0.5)
	var step2 := step1 + to_v * 0.7
	step2.y = v.height(step2.x, step2.z)
	Cine.path(w, "player", [step2], 0.8)
	# Bram's hand comes down on his shoulder. He doesn't pull; he says nothing.
	var bp := step2 - to_v * 0.55 + to_v.cross(Vector3.UP) * 0.55
	bp.y = v.height(bp.x, bp.z)
	await Cine.path(w, "bram", [bp], 1.6)
	var bf = Cine.fig(w, "bram")
	var sh: Node3D = A.call("_shoulder_point", w, "player")
	if bf is Figure3D:
		(bf as Figure3D).reach(sh, null, 0.6)
	Cine.look(w, "bram", VILLAGE_LOOK)
	Cine.shot(w, step2 + to_v * 1.6 + to_v.cross(Vector3.UP) * 1.4 + Vector3(0, 1.55, 0), (step2 + bp) * 0.5 + Vector3(0, 1.4, 0), 34.0)
	await Cine.wait(w, 3.2)
	# footsteps in the thorns, uneven: Corin, limping on a broken cart spoke,
	# his knee bound in rags, the torn new coat over his arm
	if cb != null:
		var cfig = Cine.fig(w, "corin")
		cfig.visible = true
		var c0 := mouth - to_v * 3.0 + to_v.cross(Vector3.UP) * -2.4
		c0.y = v.height(c0.x, c0.z)
		AshfordP1.put(w, "corin", c0, step2)
		var spoke := Node3D.new()
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.4, 0.28, 0.16)
		v.cyl(spoke, 0.025, 0.03, 1.0, Vector3(0, -0.45, 0), sm, 8)
		spoke.set_meta("p1_prop", true)
		# planted at his right side like a crutch (held in the hand it stuck
		# out sideways like a pole)
		Cine.body(w, "corin").add_child(spoke)
		spoke.position = Vector3(-0.3, 0.97, 0.12)
		spoke.rotation = Vector3(0.0, 0.0, -0.06)
		Cine.look(w, "player", c0)
		if bf is Figure3D:
			(bf as Figure3D).let_go(0.6)
		Cine.look(w, "bram", c0)
		var cto := step2 - to_v.cross(Vector3.UP) * 1.4 - to_v * 0.4
		cto.y = v.height(cto.x, cto.z)
		Cine.shot(w, (c0 + cto) * 0.5 + to_v.cross(Vector3.UP) * 3.5 + Vector3(0, 1.6, 0), (c0 + cto) * 0.5 + Vector3(0, 1.1, 0), 40.0)
		await A.call("_limp", w, "corin", cto, 3.6)
		Cine.look(w, "corin", w.player.global_position)
		Cine.look(w, "player", Cine.body(w, "corin").global_position)
		var mid := (cto + w.player.global_position) * 0.5
		var sd := (w.player.global_position - cto).normalized().cross(Vector3.UP)
		# from the side away from Bram (from his side, he filled the picture)
		var bram_at := Cine.body(w, "bram").global_position
		if (mid + sd * 2.9).distance_to(bram_at) < (mid - sd * 2.9).distance_to(bram_at):
			sd = -sd
		Cine.shot(w, mid + sd * 2.9 + Vector3(0, 1.5, 0), mid + Vector3(0, 1.3, 0), 36.0)
		await Cine.say(w, "corin", "Found your rabbit-hole when we were ten. Never told him I knew.")
		Cine.look(w, "corin", Cine.body(w, "bram").global_position)
		await Cine.wait(w, 0.6)
		Cine.look(w, "corin", w.player.global_position)
		await Cine.say(w, "corin", "I'm staying, Sprout. My mam's still down there. Nell and Tilly need someone too. We all swore to keep you hidden, and I'm not walking away now.")
		await Cine.say(w, "corin", "And I'd only slow you down. That cart crushed my knee. Mam's used some of her old healing magic on it, but I won't get far on it till it's fully healed.")
		await Cine.say(w, "corin", "That clerkship Ironvault offered me... maybe I can use it to find out how to make the House answer for this. You get clear. I'll see you in the city.")
		if Game.flag("corin_button"):
			# he sees it in the player's hand
			await Cine.wait(w, 0.8)
			await Cine.say(w, "corin", "...Keep that. Sell it, I said. Don't you dare sell it.")
		# he goes back down through the thorns, toward the lights, and doesn't look round
		var down_at := cto + to_v * 9.0
		down_at.y = v.height(down_at.x, down_at.z)
		Cine.shot(w, over + Vector3(0, 0.3, 0), VILLAGE_LOOK, 38.0)
		A.call("_limp", w, "corin", down_at, 8.0)
		await Cine.wait(w, 4.5)
	if is_instance_valid(crying):
		crying.queue_free()
	A.call("_free_tracker", sh)
	await Cine.fade(w, 1.0, 1.6)
	if is_instance_valid(hill):
		hill.queue_free()
	_release_village(w)


## The tunnel's mouth under the thorn roots, and a few thorn trees about it.
static func _hillside(v: AshfordVillage, mouth: Vector3, to_v: Vector3) -> Node3D:
	var hill := Node3D.new()
	hill.name = "TunnelMouth"
	v.add_child(hill)
	hill.global_position = mouth
	hill.global_basis = Basis.looking_at(-to_v, Vector3.UP)
	# (+z runs down the hill towards the village: the mouth is behind him)
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color(0.16, 0.12, 0.08)
	v.box(hill, Vector3(2.4, 1.6, 1.4), Vector3(0, 0.6, -1.0), earth)
	v.box(hill, Vector3(1.0, 1.1, 0.1), Vector3(0, 0.55, -0.28), v.mats.dark)
	var thorn := StandardMaterial3D.new()
	thorn.albedo_color = Color(0.08, 0.1, 0.06)
	thorn.roughness = 1.0
	for i in 6:
		var a := -1.2 + i * 0.5
		var at := Vector3(sin(a) * 3.4, 0, -cos(a) * 1.6 - 0.6)
		var bush := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.9 + 0.2 * (i % 3)
		sm.height = 1.4
		bush.mesh = sm
		bush.material_override = thorn
		bush.position = at + Vector3(0, 0.6, 0)
		hill.add_child(bush)
	return hill


## The village held by Ironvault, for the look back: grey coats walking the
## green in pairs, villagers kneeling by the well with their hands bound in
## light, a light moving in the inn's windows.
static func _held_village(w: World) -> void:
	var v := village(w)
	for g in GREYS:
		var id := String(g[0])
		if Cine.body(w, id) == null:
			Cine.spawn(w, id, "hunter", g[1], "Bailiff")
		Cine.place(w, id, g[1], g[2])
		_pace(w, id, g[1], g[2])
	for i in KNEELING.size():
		var id := "kneel%d" % i
		if Cine.body(w, id) == null:
			Cine.spawn(w, id, ["farmer", "merchant", "trader", "refugee"][i % 4], KNEELING[i])
		Cine.place(w, id, KNEELING[i], Vector3(-6.0, 0, 4.0))
		w.area.call("_kneel", w, id, 0.01)
		var at: Vector3 = KNEELING[i]
		v.glow_sprite(v, Vector3(at.x, v.height(at.x, at.z) + 0.75, at.z), Color(0.6, 0.85, 1.0), 0.35, 1.4).set_meta("held_glow", true)
	var inn_i := v.inn_index()
	if inn_i >= 0:
		var inn: Node3D = v.houses[inn_i].root
		var l := OmniLight3D.new()
		l.name = "SearchLight"
		l.light_color = Color(1.0, 0.7, 0.4)
		l.light_energy = 2.0
		l.omni_range = 4.0
		inn.add_child(l)
		l.position = Vector3(-2.0, 1.6, 0.0)
		var tw := l.create_tween().set_loops()
		tw.tween_property(l, "position", Vector3(2.0, 1.6, 0.4), 3.0).set_trans(Tween.TRANS_SINE)
		tw.tween_property(l, "position", Vector3(-2.0, 4.0, 0.0), 3.0).set_trans(Tween.TRANS_SINE)
		w.set_meta("search_light", l)


static func _release_village(w: World) -> void:
	# (the greys are mid-walk: stopped and hidden rather than freed, so their
	# walks' tweens don't call into a body that's gone; the Thornwood clears them)
	w.set_meta("greys_stop", true)
	for g in GREYS:
		var gb := Cine.body(w, String(g[0]))
		if gb != null:
			Cine.place(w, String(g[0]), gb.global_position)
			gb.visible = false
	for i in KNEELING.size():
		Cine.despawn(w, "kneel%d" % i)
	var v := village(w)
	for c in v.get_children():
		if c.has_meta("held_glow"):
			c.queue_free()
	if w.has_meta("search_light"):
		var l = w.get_meta("search_light")
		if is_instance_valid(l):
			(l as Node).queue_free()
		w.remove_meta("search_light")


## Two greys walking a beat back and forth, together.
static func _pace(w: World, id: String, a: Vector3, b: Vector3) -> void:
	w.remove_meta("greys_stop")
	while is_instance_valid(w) and Cine.body(w, id) != null and not w.has_meta("greys_stop"):
		await Cine.path(w, id, [b], 1.1)
		if Cine.body(w, id) == null or w.has_meta("greys_stop"):
			return
		await Cine.path(w, id, [a], 1.1)


## The chapel bell, slow and far off: someone below ringing it for the dead.
static func _bell_slow(w: World) -> void:
	for k in 9:
		if not is_instance_valid(w):
			return
		_sfx(w, "bell_toll", 0.85)
		await Cine.wait(w, 3.2)


## Under the bell, carried up the hill on the cold, a woman crying: Nell.
## (Gary's recording, assets/audio/sfx/nell_crying.ogg, once it exists.)
static func _nell_crying(w: World) -> Node:
	const PATH := "res://assets/audio/sfx/nell_crying.ogg"
	if not ResourceLoader.exists(PATH):
		return null
	var p := AudioStreamPlayer.new()
	var st = load(PATH)
	# (the look back lasts as long as the player stands there: she goes on
	# crying under the bell until they turn away. Gary's recording, made to
	# sound far off and down the hill when it's mastered, docs/handover/2026-11-02-pm.md)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	p.stream = st
	p.volume_db = -14.0
	w.add_child(p)
	p.play()
	return p
