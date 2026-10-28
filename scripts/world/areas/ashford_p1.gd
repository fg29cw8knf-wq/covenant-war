class_name AshfordP1
extends RefCounted
## Prologue P1 on foot, as Master Script v3 has it (docs/script/v3_prologue_p1.md):
## the opening (the attic and its cracked mirror, Bram in the taproom, the
## lantern crate carried to the green, the last lantern hung on the Great
## Lantern's top hook) and the staging for the scenes on the green that
## ashford.gd's talk trees call for: Tam's barrel and his letter, Nell's
## bench, Tilly's moth, Corin's mam and the drum. The words are in ashford.gd;
## this file moves people and things.
##
## Bram teaches the controls in his own words while the Objective line names
## the button for the device in hand (WorldCoach). Every step is gated: it
## waits until it's done, and nothing else can be done meanwhile (no talking
## to anyone else, no pause square until he's mentioned it).
##
## Progress through the opening is saved in the flag p1_stage ("attic",
## "taproom", "street", "green"), so a game closed part-way picks up at the
## start of the part it was in; "ash_started" means it's done.

const STAGES := ["attic", "taproom", "street", "green"]

## The lantern crate: Gary's model (AshfordVillage.make_crate(), 1.11 m
## across as made) at a size one person carries in both arms, its lid left
## off so the lanterns show; a drawn crate if the model isn't there.
const CRATE_SCALE := 0.55
## How far in front of the player's feet the crate goes down at the Lantern
## (m): a stride, so it stands on the grass with their feet clear of it.
const CRATE_DOWN := 0.85
const CRATE_CUT := 0.76            # the model's height (m, as made) above which the lid is left off
## Where the crate rides in the player's arms (their own frame), and where
## their hands go on it.
const CRATE_HOLD := Vector3(0.0, 0.92, 0.36)

## The Great Lantern's hoist: the top hook at the east end of its crossbeam,
## a pulley there, and the line down to a hook at hand height (from the
## Lantern's foot). The player stands south of the low hook to use it.
const TOP_HOOK := Vector3(1.32, 6.05, 0.0)
const LOW_HOOK := Vector3(2.3, 1.45, 0.42)
const HOOK_STAND := Vector3(2.5, 0.0, 1.12)
## The stake the hoist's hauling end is made fast to, clear of the Lantern's stone foot.
const STAKE := Vector3(2.7, 0.0, 0.42)
## How close (m) the player has to be to use something they walk up to.
const REACH := 1.5

## Set dressing on the green: Bram's stool by the Lantern, Nell's bench by the
## well (facing the dancing), the festival drum by Corin, and where Corin's
## mam watches from (the bakery: the cottage north-west of the green).
const STOOL := Vector3(3.5, 0, 2.95)
const BENCH := Vector3(-3.7, 0, 1.75)
const BENCH_YAW := 2.62            # its seat faces north-north-east, towards the dancers
const DANCE := Vector3(-1.4, 0, -3.7)
const DRUM := Vector3(-9.8, 0, -1.35)
const KIDS := [["p1_kid_a", "child_b", Vector3(-7.5, 0, -3.3)], ["p1_kid_b", "girl", Vector3(-9.4, 0, -3.5)],
	["p1_kid_c", "child", Vector3(-7.4, 0, -1.4)]]
## (27 October: the fourth was a courtier cut-out, a Solhaven look and the
## last flat figure at the dance; the trader's model dances instead, and the
## refugee look is Gary's travel-worn woman now)
const DANCERS := [["p1_dance_a", "farmer"], ["p1_dance_b", "refugee"], ["p1_dance_c", "merchant"], ["p1_dance_d", "trader"]]


static func village(w: World) -> AshfordVillage:
	return w.get_meta("village") as AshfordVillage


## A meta value, or null if it isn't set (get_meta(key, null) complains).
static func meta(o: Object, key: String) -> Variant:
	return o.get_meta(key) if o != null and o.has_meta(key) else null


static func coach(w: World) -> WorldCoach:
	return WorldCoach.of(w.hud)


# ================================================================== props ===

## A paper lantern (the village's own, as on the bunting), glowing; its
## origin is the ring at its top, where it hangs from.
static func paper_lantern(v: AshfordVillage, energy := 1.0) -> Node3D:
	var n := Node3D.new()
	n.name = "PaperLantern"
	var mat: ShaderMaterial = (v.mats.lantern as ShaderMaterial).duplicate()
	mat.set_shader_parameter("energy", 2.2 * energy)
	var body := v.multimesh(n, v.lantern_mesh(), mat, [Transform3D(Basis().scaled(Vector3.ONE * 0.62), Vector3(0, -0.2, 0))],
		[Color(1.0, 0.5 + 0.15 * v.rng.randf(), 0.16, v.rng.randf())], false)
	body.name = "Paper"
	v.cyl(n, 0.05, 0.1, 0.03, Vector3(0, -0.04, 0), v.mats.dark, 10)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.012
	tm.outer_radius = 0.026
	ring.mesh = tm
	ring.rotation.x = PI * 0.5
	ring.material_override = v.mats.metal
	n.add_child(ring)
	return n


## The lantern crate, open at the top, with "L" and "R" holds on its sides
## for the hands of whoever carries it. Its origin is the middle of its base.
static func crate(v: AshfordVillage) -> Node3D:
	var n := Node3D.new()
	n.name = "LanternCrate"
	var w := 0.61
	var d := 0.51
	var h := 0.47
	if ResourceLoader.exists(AshfordVillage.CRATE_MODEL):
		var made := v.make_crate()
		made.scale = Vector3.ONE * CRATE_SCALE
		n.add_child(made)
		for mi: MeshInstance3D in made.find_children("*", "MeshInstance3D", true, false):
			for s in mi.mesh.get_surface_count():
				var m := mi.get_active_material(s)
				if m is StandardMaterial3D:
					mi.set_surface_override_material(s, _lidless(m as StandardMaterial3D))
		w = AshfordVillage.CRATE_SIZE.x * CRATE_SCALE
		d = AshfordVillage.CRATE_SIZE.z * CRATE_SCALE
		h = CRATE_CUT * CRATE_SCALE
	else:
		# planks round an open box, a darker inside
		v.box(n, Vector3(w - 0.04, 0.03, d - 0.04), Vector3(0, 0.03, 0), v.mats.wood_h)
		for s in [-1.0, 1.0]:
			v.box(n, Vector3(w, h, 0.03), Vector3(0, h * 0.5, s * (d * 0.5 - 0.015)), v.mats.wood_h)
			v.box(n, Vector3(0.03, h, d), Vector3(s * (w * 0.5 - 0.015), h * 0.5, 0), v.mats.wood)
			for t in [-1.0, 1.0]:
				v.box(n, Vector3(0.05, h + 0.02, 0.05), Vector3(s * (w * 0.5 - 0.02), h * 0.5 + 0.01, t * (d * 0.5 - 0.02)), v.mats.beam_v)
	# the paper lanterns packed in it, their tops showing
	for p in [Vector3(-0.15, 0, -0.11), Vector3(0.14, 0, -0.1), Vector3(-0.12, 0, 0.12), Vector3(0.15, 0, 0.12), Vector3(0.0, 0, 0.0)]:
		var l := paper_lantern(v, 0.55)
		l.position = Vector3(p.x, h + 0.06, p.z)
		l.rotation = Vector3(v.rng.randf_range(-0.15, 0.15), v.rng.randf() * TAU, v.rng.randf_range(-0.15, 0.15))
		l.name = "Packed"
		n.add_child(l)
	for s in [["L", 1.0], ["R", -1.0]]:
		var g := Node3D.new()
		g.name = String(s[0])
		g.position = Vector3(float(s[1]) * (w * 0.5 + 0.02), h * 0.55, 0.0)
		n.add_child(g)
	n.set_meta("size", Vector3(w, h, d))
	return n


## Gary's crate's wood, with everything above CRATE_CUT left out: the lid off.
static func _lidless(src: StandardMaterial3D) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float cut = 0.76;
uniform float rough = 0.91;
varying float ly;
void vertex() { ly = VERTEX.y; }
void fragment() {
	if (ly > cut) { discard; }
	vec3 c = texture(tex, UV).rgb * tint.rgb;
	ALBEDO = FRONT_FACING ? c : c * 0.55;
	ROUGHNESS = rough;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tex", src.albedo_texture)
	m.set_shader_parameter("tint", src.albedo_color)
	m.set_shader_parameter("cut", CRATE_CUT)
	m.set_shader_parameter("rough", src.roughness)
	return m


## A folded letter sealed in red wax ("a coin crossed with a key"), with
## "L" and "R" holds at its edges.
static func letter(v: AshfordVillage) -> Node3D:
	var n := Node3D.new()
	n.name = "Letter"
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.88, 0.82, 0.68)
	paper.roughness = 0.9
	paper.emission_enabled = true
	paper.emission = Color(0.16, 0.14, 0.1)
	v.box(n, Vector3(0.14, 0.095, 0.006), Vector3.ZERO, paper)
	var wax := StandardMaterial3D.new()
	wax.albedo_color = Color(0.55, 0.06, 0.05)
	wax.roughness = 0.4
	v.cyl(n, 0.016, 0.016, 0.006, Vector3(0, -0.005, 0.005), wax, 12, Vector3(PI * 0.5, 0, 0))
	for s in [["L", 1.0], ["R", -1.0]]:
		var g := Node3D.new()
		g.name = String(s[0])
		g.position = Vector3(0.065 * float(s[1]), -0.01, -0.01)
		n.add_child(g)
	return n


## Two worn card boxes, strapped together: Corin's decks.
static func card_boxes(v: AshfordVillage) -> Node3D:
	var n := Node3D.new()
	n.name = "CardBoxes"
	var cols := [Color(0.42, 0.16, 0.08), Color(0.3, 0.2, 0.12)]
	for i in 2:
		var m := StandardMaterial3D.new()
		m.albedo_color = cols[i]
		m.roughness = 0.8
		v.box(n, Vector3(0.075, 0.1, 0.04), Vector3(0, 0, (i - 0.5) * 0.042), m)
	v.box(n, Vector3(0.08, 0.012, 0.09), Vector3(0, 0.02, 0), v.mats.dark)
	return n


## The festival drum: a wide hoop of wood, two skins, a strap.
static func drum(v: AshfordVillage) -> Node3D:
	var n := Node3D.new()
	n.name = "FestivalDrum"
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.86, 0.8, 0.66)
	skin.roughness = 0.8
	v.cyl(n, 0.3, 0.3, 0.26, Vector3.ZERO, v.mats.door_red, 20, Vector3(PI * 0.5, 0, 0))
	for s in [-1.0, 1.0]:
		v.cyl(n, 0.31, 0.31, 0.012, Vector3(0, 0, s * 0.135), skin, 20, Vector3(PI * 0.5, 0, 0))
		v.cyl(n, 0.322, 0.322, 0.03, Vector3(0, 0, s * 0.12), v.mats.wood, 20, Vector3(PI * 0.5, 0, 0))
	for s in [["L", 1.0], ["R", -1.0]]:
		var g := Node3D.new()
		g.name = String(s[0])
		g.position = Vector3(float(s[1]) * 0.3, 0.02, 0.0)
		n.add_child(g)
	return n


## Puts `node` on one of a 3D figure's bones (a letter in Tam's shirt pocket,
## Corin's card boxes at his hip), `at` and `rot` in the bone's own space.
## Returns the attachment, so it can be taken off again.
static func attach(f, bone: String, node: Node3D, at := Vector3.ZERO, rot := Vector3.ZERO) -> Node3D:
	if not (f is Figure3D):
		return null
	var sk := (f as Figure3D).model.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk == null or sk.find_bone(bone) < 0:
		return null
	var ba := BoneAttachment3D.new()
	ba.name = "P1_" + bone
	ba.bone_name = bone
	sk.add_child(ba)
	ba.add_child(node)
	node.position = at
	node.rotation = rot
	ba.set_meta("p1_prop", true)
	return ba


## A soft glow and a slowly breathing ring round something that can be used
## now ("When something will let you use it, it lights up a touch").
## Returns the glow; free it (or call unlight) when the step is done.
static func light_up(v: AshfordVillage, parent: Node3D, at: Vector3, size := 0.5) -> Node3D:
	var n := Node3D.new()
	n.name = "UseGlow"
	parent.add_child(n)
	n.position = at
	var g := v.glow_sprite(n, Vector3.ZERO, Color(1.0, 0.8, 0.4), size, 0.75)
	g.name = "Glow"
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = size * 0.42
	tm.outer_radius = size * 0.5
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(1.0, 0.82, 0.42, 0.85)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	rm.no_depth_test = true
	ring.material_override = rm
	ring.rotation.x = PI * 0.5
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.name = "Ring"
	n.add_child(ring)
	var tw := n.create_tween().set_loops()
	tw.tween_property(n, "scale", Vector3.ONE * 1.18, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	return n


## A wrong tap: the glow flares, so the eye finds it.
static func flare(glow: Node3D) -> void:
	if glow == null or not is_instance_valid(glow):
		return
	var g := glow.get_node_or_null("Glow") as Node3D
	if g == null:
		return
	if not g.has_meta("s0"):
		g.set_meta("s0", g.scale)
	var s0: Vector3 = g.get_meta("s0")
	var tw := g.create_tween()
	tw.tween_property(g, "scale", s0 * 2.2, 0.12)
	tw.tween_property(g, "scale", s0, 0.4).set_trans(Tween.TRANS_SINE)


# ============================================================ the green ===

## The festival on the green before the player gets there: Bram's stool,
## Nell's bench, the drum by Corin, the hoist on the Great Lantern with
## lanterns already on the lower hooks and the top hook empty, the dancers
## round by the fiddler, children with paper lanterns round Corin, and
## Corin's mam at the bakery door. (Gone again at midnight: undress.)
static func dress(w: World) -> void:
	var v := village(w)
	if v == null or v.has_meta("p1_dressed"):
		return
	v.set_meta("p1_dressed", true)
	var g := Node3D.new()
	g.name = "P1Dressing"
	v.add_child(g)
	v.set_meta("p1_root", g)
	# Bram's stool by the Lantern
	var st := STOOL
	st.y = v.height(st.x, st.z)
	v.cyl(g, 0.21, 0.18, 0.46, st + Vector3(0, 0.23, 0), v.mats.wood, 14)
	v.solid_round(st, 0.25)
	# Nell's bench by the well, facing the dancing
	var bn := Node3D.new()
	bn.name = "NellsBench"
	g.add_child(bn)
	bn.position = Vector3(BENCH.x, v.height(BENCH.x, BENCH.z), BENCH.z)
	bn.rotation.y = BENCH_YAW
	v.box(bn, Vector3(1.7, 0.07, 0.42), Vector3(0, 0.44, 0), v.mats.wood_h)
	v.box(bn, Vector3(1.7, 0.32, 0.06), Vector3(0, 0.66, -0.2), v.mats.wood_h, Vector3(-0.15, 0, 0))
	for s in [-1.0, 1.0]:
		v.box(bn, Vector3(0.08, 0.44, 0.38), Vector3(s * 0.7, 0.22, 0), v.mats.beam_v)
	# (the bench and the lantern post at its east end)
	v.solid_box(bn.position + Basis(Vector3.UP, BENCH_YAW) * Vector3(0.12, 1.0, 0), Vector3(2.05, 2.0, 0.6), BENCH_YAW)
	v.set_meta("p1_bench", bn)
	# a lantern on a post at its end, so Nell isn't sat in the dark
	v.box(bn, Vector3(0.08, 1.7, 0.08), Vector3(1.05, 0.85, -0.12), v.mats.beam_v)
	v.box(bn, Vector3(0.36, 0.05, 0.05), Vector3(0.9, 1.68, -0.12), v.mats.beam_v)
	var bl := paper_lantern(v)
	bn.add_child(bl)
	bl.position = Vector3(0.76, 1.64, -0.12)
	var bll := OmniLight3D.new()
	bll.light_color = Color(1.0, 0.64, 0.32)
	bll.light_energy = 1.6
	bll.omni_range = 5.5
	bll.position = Vector3(0.6, 1.3, 0.4)
	bn.add_child(bll)
	# the drum on the grass by Corin
	var dr := drum(v)
	g.add_child(dr)
	dr.position = Vector3(DRUM.x, v.height(DRUM.x, DRUM.z) + 0.31, DRUM.z)
	dr.rotation.y = 0.5
	v.set_meta("p1_drum", dr)
	_dress_hoist(v, g)


## The Great Lantern's hooks: lanterns already on its lower hooks and the
## west end of the crossbeam; on the east end the empty top hook with a
## pulley, its line running down past the Lantern's stone foot to a hook at
## hand height, and the hauling end down to a stake beside it.
static func _dress_hoist(v: AshfordVillage, g: Node3D) -> void:
	var base := Vector3(0, v.height(0, 0), 0)
	var hoist := Node3D.new()
	hoist.name = "Hoist"
	g.add_child(hoist)
	hoist.position = base
	v.set_meta("p1_hoist", hoist)
	# the lanterns already up
	for p in [Vector3(-TOP_HOOK.x, TOP_HOOK.y, 0.0), Vector3(0.0, 4.1, 0.42), Vector3(0.0, 4.1, -0.42), Vector3(-0.42, 3.3, 0.0)]:
		v.box(hoist, Vector3(0.03, 0.12, 0.03), p + Vector3(0, 0.06, 0), v.mats.metal)
		var l := paper_lantern(v)
		hoist.add_child(l)
		l.position = p
	# the top hook and its pulley
	v.box(hoist, Vector3(0.03, 0.14, 0.03), TOP_HOOK + Vector3(0, 0.07, 0), v.mats.metal)
	var pulley := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.07
	pm.bottom_radius = 0.07
	pm.height = 0.04
	pulley.mesh = pm
	pulley.material_override = v.mats.metal
	pulley.rotation.x = PI * 0.5
	pulley.position = PULLEY
	hoist.add_child(pulley)
	# the stake the hauling end is made fast to
	v.box(hoist, Vector3(0.09, 1.2, 0.09), STAKE + Vector3(0, 0.6, 0), v.mats.beam_v)
	v.box(hoist, Vector3(0.05, 0.05, 0.22), STAKE + Vector3(0, 1.05, 0), v.mats.metal)
	# the line and the hauling end, and the hook on the line (moved by _hang)
	var rope := StandardMaterial3D.new()
	rope.albedo_color = Color(0.62, 0.53, 0.38)
	rope.roughness = 1.0
	var line := v.box(hoist, Vector3(0.018, 1.0, 0.018), Vector3.ZERO, rope)
	line.name = "Line"
	var fall := v.box(hoist, Vector3(0.018, 1.0, 0.018), Vector3.ZERO, rope)
	fall.name = "Fall"
	_rope(fall, PULLEY + Vector3(0.05, -0.05, 0), STAKE + Vector3(0, 1.1, 0))
	var hook := Node3D.new()
	hook.name = "Hook"
	hoist.add_child(hook)
	var hm := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.03
	tm.outer_radius = 0.045
	hm.mesh = tm
	hm.rotation.z = PI * 0.5
	hm.material_override = v.mats.metal
	hook.add_child(hm)
	_set_hook(v, LOW_HOOK)

## The pulley on the crossbeam's east end, over the top hook.
const PULLEY := Vector3(1.44, 6.25, 0.0)


## A length of rope (a unit-tall box) stretched from `a` to `b`.
static func _rope(r: Node3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var l := maxf(0.02, d.length())
	r.basis = Basis(Quaternion(Vector3.UP, d / l)).scaled(Vector3(1, l, 1))
	r.position = (a + b) * 0.5


## Puts the hoist's hook at `at` (from the Lantern's foot), on its line from
## the pulley.
static func _set_hook(v: AshfordVillage, at: Vector3) -> void:
	var hoist: Node3D = meta(v, "p1_hoist")
	if hoist == null:
		return
	(hoist.get_node("Hook") as Node3D).position = at
	_rope(hoist.get_node("Line") as Node3D, PULLEY + Vector3(-0.05, -0.05, 0), at + Vector3(0, 0.04, 0))


## A point on the hauling end, `k` of the way down from the pulley.
static func fall_at(k: float) -> Vector3:
	return (PULLEY + Vector3(0.05, -0.05, 0)).lerp(STAKE + Vector3(0, 1.1, 0), k)


## The dancers by the fiddler, the children round Corin with their paper
## lanterns, and Corin's mam at the bakery door. Extras (Cine.spawn): looked
## up by id, and gone at midnight.
static func crowd(w: World) -> void:
	var v := village(w)
	if v == null or w.has_meta("p1_crowd"):
		return
	w.set_meta("p1_crowd", true)
	var corin := Cine.body(w, "corin")
	var cp: Vector3 = corin.global_position if corin != null else Vector3(-8.6, 0, -2.4)
	for k in KIDS:
		var at: Vector3 = k[2]
		at.y = v.height(at.x, at.z)
		var d := Cine.spawn(w, String(k[0]), String(k[1]), at)
		d.look_toward(cp, w.cam)
		var l := paper_lantern(v)
		(Cine.body(w, String(k[0]))).add_child(l)
		l.position = Vector3(0.28, 1.0, 0.12)
	var mam := mam_spot(v)
	var md := Cine.spawn(w, "corin_mam", "refugee", mam.at)
	md.look_toward(mam.at + mam.out, w.cam)
	for i in DANCERS.size():
		var a := TAU * i / DANCERS.size()
		Cine.spawn(w, String(DANCERS[i][0]), String(DANCERS[i][1]), DANCE + Vector3(cos(a), 0, sin(a)) * 1.5)
	_dance(w)


## Round and round to the reel, two steps in and out.
static func _dance(w: World) -> void:
	var t := 0.0
	while is_instance_valid(w) and w.is_inside_tree() and w.has_meta("p1_crowd"):
		var dt := w.get_process_delta_time()
		t += dt
		for i in DANCERS.size():
			var id := String(DANCERS[i][0])
			var b := Cine.body(w, id)
			var f = Cine.fig(w, id)
			if b == null or f == null:
				continue
			var a := TAU * i / DANCERS.size() + t * 0.55
			var r := 1.45 + sin(t * 2.2 + i * PI) * 0.35
			var p := DANCE + Vector3(cos(a), 0, sin(a)) * r
			var was := b.global_position
			b.global_position = p
			f.walking = true
			f.face(p - was, w.cam)
		await w.get_tree().process_frame


## Where Corin's mam stands: the bakery's door (the cottage nearest Corin,
## north-west of the green), and the way it faces.
static func mam_spot(v: AshfordVillage) -> Dictionary:
	var best: Dictionary = {}
	var bd := INF
	for h in v.houses:
		if h.get("inn", false):
			continue
		var r: Node3D = h.root
		var d := r.global_position.distance_to(Vector3(-12.0, 0, -12.0))
		if d < bd:
			bd = d
			best = h
	if best.is_empty():
		return {"at": Vector3(-12.6, 0, -13.4), "out": Vector3(0.6, 0, 0.8).normalized()}
	var root: Node3D = best.root
	var out := root.global_transform.basis.z
	out.y = 0.0
	out = out.normalized()
	var at: Vector3 = root.global_position + out * (float(best.D) * 0.5 + 0.9)
	at.y = v.height(at.x, at.z)
	return {"at": at, "out": out}


## Midnight: the extras go and everyone's hands are emptied, so the film
## starts clean. (The stool, bench, drum and the lanterns on the hooks stay.)
static func undress(w: World) -> void:
	if w.has_meta("p1_crowd"):
		w.remove_meta("p1_crowd")
	for k in KIDS:
		Cine.despawn(w, String(k[0]))
	for d in DANCERS:
		Cine.despawn(w, String(d[0]))
	Cine.despawn(w, "corin_mam")
	for who in ["player", "bram", "corin", "tam", "tilly", "nell"]:
		var f = Cine.fig(w, who)
		if f is Figure3D:
			for ba in (f as Figure3D).find_children("P1_*", "BoneAttachment3D", true, false):
				ba.queue_free()
			for c in (f as Figure3D).get_node("Pivot").get_children():
				if c == meta(village(w), "p1_drum"):
					# the drum goes down where they stand (it's carried home later)
					var at: Vector3 = (c as Node3D).global_position
					c.reparent(village(w).get_meta("p1_root"))
					(c as Node3D).global_position = Vector3(at.x, village(w).height(at.x, at.z) + 0.31, at.z)
				elif c.has_meta("p1_prop"):
					c.queue_free()
			(f as Figure3D).let_go(0.0)
			(f as Figure3D).stand(0.0)
			(f as Figure3D).release(0.0)
			(f as Figure3D).hand_light(null)
		var b := Cine.body(w, who)
		if b != null and Cine._on_terrain(w, b):
			b.global_position.y = Cine.ground(w, b.global_position)
	_solid(w, true)
	w.set_meta("bram_seated", false)


# ============================================================== villagers ===

## Everyone where the script has them before the player gets there: Bram on
## his stool by the Lantern, Nell on her bench, Tam's letter in his shirt
## pocket, Corin's card boxes and his letter. Called on every arrival in
## Ashford before midnight (again is harmless).
static func pose(w: World) -> void:
	var v := village(w)
	if v == null or Game.flag("ash_lantern_duel"):
		return
	dress(w)
	crowd(w)
	if not w.has_meta("p1_posed"):
		w.set_meta("p1_posed", true)
		var tam = Cine.fig(w, "tam")
		if tam is Figure3D:
			var tl := letter(v)
			tl.scale = Vector3.ONE * (0.45 if Game.flag("tam_told") else 1.0)
			attach(tam, "Spine2", tl, POCKET, POCKET_ROT)
			w.set_meta("tam_letter", tl)
		var corin = Cine.fig(w, "corin")
		if corin is Figure3D:
			# his card boxes on their strap at his hip, and the clerkship
			# letter tucked into his coat ("What's that letter tucked into
			# your coat?"): until 25 October both sat on his hand bones and
			# stuck out of his arms (Gary)
			attach(corin, "Hips", card_boxes(v), HIP_BOXES, HIP_BOXES_ROT)
			var cl := letter(v)
			attach(corin, "Spine2", cl, COAT_LETTER, COAT_LETTER_ROT)
			w.set_meta("corin_letter", cl)
	nell_sit(w)
	if Game.flag("ash_started") and not w.get_meta("bram_seated", false) and not w.has_meta("bram_stop") and not w.has_meta("bram_to_stool"):
		bram_sit(w)

## Where a letter sits in a shirt pocket, in the chest bone's own space.
const POCKET := Vector3(0.09, 0.07, 0.13)
const POCKET_ROT := Vector3(-0.2, 0.0, 1.45)
## Where Corin's strapped card boxes hang at his hip, in the Hips bone's own
## space (x to his left, y up, z ahead): on his left side, under the belt,
## turned to lie flat against the hip.
const HIP_BOXES := Vector3(0.22, -0.06, 0.03)
const HIP_BOXES_ROT := Vector3(0.0, PI * 0.5, 0.0)
## Where his clerkship letter is tucked into his vest, in the chest bone's
## space: inside the vest's right panel, standing, leaning back into him, so
## only its top corner shows above the vest's edge (tests/corin_props_shot.tscn).
const COAT_LETTER := Vector3(-0.075, 0.02, 0.095)
const COAT_LETTER_ROT := Vector3(0.35, 0.0, -1.45)


## Bram on his stool by the Lantern, facing the green's south side.
const BRAM_FACES := Vector3(-0.33, 0.0, 0.944)


static func bram_sit(w: World) -> void:
	if Cine.body(w, "bram") == null:
		return
	var at := STOOL
	at.y = village(w).height(at.x, at.z)
	sit_down(w, "bram", at, BRAM_FACES, STOOL_H, 0.0)
	w.set_meta("bram_seated", true)


## Bram up off his stool (before he walks anywhere).
static func bram_stand(w: World) -> void:
	if not w.get_meta("bram_seated", false):
		return
	w.set_meta("bram_seated", false)
	await stand_up(w, "bram", 0.35)


## Where Nell sits on her bench (its west half), or the player beside her
## (the east half): the ground under the middle of that half of the seat.
static func bench_seat(w: World, east := false) -> Vector3:
	var bn: Node3D = meta(village(w), "p1_bench")
	if bn == null:
		return BENCH
	return bn.to_global(Vector3(0.4 if east else -0.4, 0.0, 0.0))


static func bench_facing(w: World) -> Vector3:
	var bn: Node3D = meta(village(w), "p1_bench")
	if bn == null:
		return Vector3.FORWARD
	var f := bn.global_transform.basis.z
	f.y = 0.0
	return f.normalized()


static func nell_sit(w: World) -> void:
	var f = Cine.fig(w, "nell")
	if f is Figure3D:
		sit_down(w, "nell", bench_seat(w), bench_facing(w), BENCH_H, 0.0)
	else:
		# a cut-out can't sit: she stands at the bench's end
		var bn: Node3D = meta(village(w), "p1_bench")
		if bn != null:
			Cine.place(w, "nell", bn.to_global(Vector3(-1.3, 0, 0.15)), bn.to_global(Vector3(-0.6, 0, 2.5)))


## The tops of Bram's stool and Nell's bench (m).
const STOOL_H := 0.46
const BENCH_H := 0.475


## Sits someone on a seat `height` m up (Figure3D.sit()), their hips over
## `at` (the ground under the middle of the seat), facing `fwd`. While the
## player sits they don't collide (the bench is solid, and Nell is beside
## them). A cut-out can't sit: it stands beside the seat.
static func sit_down(w: World, who: String, at: Vector3, fwd: Vector3, height: float, blend := 0.45) -> void:
	var b := Cine.body(w, who)
	var f = Cine.fig(w, who)
	if b == null:
		return
	if not (f is Figure3D):
		var by := at + fwd * 0.45 + fwd.cross(Vector3.UP) * 0.35
		by.y = Cine.ground(w, by)
		Cine.place(w, who, by, by + fwd)
		return
	if who == "player":
		_solid(w, false)
	var fig := f as Figure3D
	if blend > 0.0:
		# from just in front of the seat: they sit as they settle back onto
		# it, the two together (sit() takes the spot they're on as the
		# seat, and lets a settle of under 0.3 m pass; until 22 October they
		# glided the whole way standing, then sat: "Bram glides 0.5 m onto
		# his stool")
		Cine.look(w, who, b.global_position + fwd)
		var shift := b.global_position.distance_to(at)
		var tw := w.create_tween()
		tw.tween_property(b, "global_position", at, blend).set_trans(Tween.TRANS_SINE)
		if shift < 0.28:
			fig.sit(height, blend)
			await tw.finished
		else:
			await tw.finished
			fig.sit(height, blend)
		return
	Cine.place(w, who, at, at + fwd)
	b.global_position = at
	fig.snap_face(fwd)
	fig.sit(height, 0.0)


## Up off a seat. (The player stays unbumpable until they've stepped
## clear of it: see nell_stand.)
static func stand_up(w: World, who: String, blend := 0.4) -> void:
	var f = Cine.fig(w, who)
	if f is Figure3D:
		(f as Figure3D).stand(blend)
	await Cine.wait(w, blend)


## The player's body solid (bumping into things) or not.
static func _solid(w: World, on: bool) -> void:
	for c in w.player.get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).set_deferred("disabled", not on)


## The controls back on screen; the zoom buttons only where the game's own
## camera is following the player (not in the attic or the taproom, nor in
## a scene, where the shot is set).
static func controls_on(w: World) -> void:
	w.hud.set_controls_visible(true)
	if w.cine:
		for b in [w.hud._zoom_in, w.hud._zoom_out]:
			if b != null:
				(b as Control).visible = false


## Holds the NPCs back while a lesson step waits ("Find Tam"): none of them
## shows the Talk button or answers a tap except those in `allowed`. []
## lets them all go.
static func mute_all_but(w: World, allowed: Array, everyone := false) -> void:
	for n in w.npcs:
		n.def["muted"] = everyone or (not allowed.is_empty() and not allowed.has(String(n.def.id)))
	w._near = null
	w.hud.set_talk_target("", false)
	w._refresh_markers()


# ================================================================ gating ===

## Waits until the player uses something: a tap on it where it shows on the
## screen, or E / Space / Enter / a pad's A. With `reach` > 0 they have to
## walk up to it first (standing within `reach` of `stand`; a tap on it from
## further off walks them there and uses it when they arrive); with 0 it's
## right in front of them in a conversation and only it can be tapped. A
## wrong tap flares its glow. Shows the objective `key` while it waits.
static func use(w: World, target: Node3D, key: String, reach := 0.0, stand := Vector3.INF, glow_size := 0.45) -> void:
	var v := village(w)
	var glow := light_up(v, target, Vector3.ZERO, glow_size)
	var u := Use.new()
	u.w = w
	u.target = target
	u.reach = reach
	u.stand = stand
	u.glow = glow
	w.add_child(u)
	var was_cine := w.cine
	if reach <= 0.0:
		w.busy = true
	else:
		w.busy = false
		w.cine = false
	w.hud.dialogue.close()
	controls_on(w)
	coach(w).objective(key)
	await u.used
	u.queue_free()
	if is_instance_valid(glow):
		glow.queue_free()
	coach(w).objective("")
	w.busy = true
	w.cine = was_cine if reach <= 0.0 else true
	w._move_target = null
	w.hud.set_controls_visible(false)


## Watches for the player using one thing (see use()).
class Use:
	extends Node
	signal used
	var w: World
	var target: Node3D
	var reach := 0.0
	var stand := Vector3.INF
	var glow: Node3D
	var _pending := false
	var _done := false
	var _armed := 0

	func _ready() -> void:
		_armed = Time.get_ticks_msec()
		w.hud.tapped.connect(_on_tap)

	func _exit_tree() -> void:
		if w.hud.tapped.is_connected(_on_tap):
			w.hud.tapped.disconnect(_on_tap)

	func _where() -> Vector3:
		return stand if stand != Vector3.INF else target.global_position

	func near() -> bool:
		if reach <= 0.0:
			return true
		var d := w.player.global_position - _where()
		d.y = 0.0
		return d.length() <= reach

	## A tap: on the thing (within a thumb's width of where it shows), or not.
	func hits(pos: Vector2) -> bool:
		var p := target.global_position
		if w.cam.is_position_behind(p):
			return false
		var sp := w.cam.unproject_position(p)
		return sp.distance_to(pos) <= maxf(80.0, get_viewport().get_visible_rect().size.y * 0.1)

	func _on_tap(pos: Vector2) -> void:
		if _done or Time.get_ticks_msec() - _armed < 300 or w.hud.menu_open() or not is_instance_valid(target):
			return
		if hits(pos):
			if near():
				_use()
			else:
				# walk them up to it, and use it when they get there
				_pending = true
				w._move_target = _where()
				w._talk_target = null
		elif reach <= 0.0:
			AshfordP1.flare(glow)
		else:
			_pending = false

	func _unhandled_input(e: InputEvent) -> void:
		if _done or w.hud.menu_open():
			return
		if e.is_action_pressed("interact") and near():
			get_viewport().set_input_as_handled()
			_use()

	func _process(_d: float) -> void:
		if _pending and not _done and near():
			_use()

	func _use() -> void:
		if _done:
			return
		_done = true
		used.emit()


## Lets the player walk a room built below the village (the taproom) the way
## they walk outside: drag, the keys, a stick, or a tap on the floor, the
## camera watching from `cam_at`, until `done.call(position)` says stop.
## `follower` (an NPC's id) walks after them. The room gives "walk" (the
## floor's free rectangle, in its own x/z) and "blocks" ([centre, radius]).
static func walk_room(w: World, room: Dictionary, cam_at: Vector3, done: Callable, follower := "", stray := Callable()) -> void:
	var root: Node3D = room.root
	var floor_y := float(room.floor_y)
	var target = [null]
	# "stairs_zone": a patch of floor (the foot of the stairs) where `stray` is
	# called when the player walks into it, once, and again if they come back;
	# they're stopped and turned back a step while whoever it is says so
	var zone: Rect2 = room.get("stairs_zone", Rect2())
	var in_zone := false
	var strayed_at := -100.0
	var held_until := 0.0   # (no walking while they're being turned back)
	# the walk's own clock, in game time (frames' deltas), not the wall clock:
	# the same to a player, but a test run at --fixed-fps in keys mode gets
	# through 3 s of game in well under 1.6 s of real time, and its tap on
	# the door after Bram's "Wrong way" fell inside the hold and was dropped
	# (23 October: "timed out waiting for the door" on a quiet machine)
	var clock := 0.0
	# (the follower is theirs to move only until a staged walk takes them)
	var fb0 := Cine.body(w, follower) if follower != "" else null
	var follow_token := int(fb0.get_meta("cine_path", 0)) if fb0 != null else 0
	var on_tap := func(pos: Vector2) -> void:
		if w.hud.menu_open():
			return
		var from := w.cam.project_ray_origin(pos)
		var dir := w.cam.project_ray_normal(pos)
		if absf(dir.y) < 0.001:
			return
		var t := (floor_y - from.y) / dir.y
		if t > 0.0:
			target[0] = from + dir * t
			w._spawn_tap_ring(target[0])
	w.hud.tapped.connect(on_tap)
	w.busy = true
	w.cine = true
	var pf = w.player_doll
	var look := w.player.global_position + Vector3(0, 1.0, 0)
	while is_instance_valid(w) and w.is_inside_tree():
		var dt := w.get_process_delta_time()
		clock += dt
		var p := w.player.global_position
		if done.call(p):
			break
		var move := Vector3.ZERO
		if clock < held_until:
			target[0] = null
		elif not w.hud.menu_open() and not (w.hud.dialogue.visible and not w.hud.dialogue.barking()):
			var iv: Vector2 = w.hud.pad.vector
			var k := Input.get_vector("move_left", "move_right", "move_up", "move_down")
			if k.length() > iv.length():
				iv = k
			if iv.length() > 0.15:
				target[0] = null
				# up the screen is away from the camera
				var fwd := -w.cam.global_transform.basis.z
				fwd.y = 0.0
				fwd = fwd.normalized()
				var right := fwd.cross(Vector3.UP)
				move = right * iv.x - fwd * iv.y
				if move.length() > 1.0:
					move = move.normalized()
			elif target[0] != null:
				var to: Vector3 = target[0] - p
				to.y = 0.0
				if to.length() < 0.12:
					target[0] = null
				else:
					move = to.normalized()
		var np := p + move * 2.3 * dt
		# stay on the floor, out of the furniture
		np = room_clamp(room, np)
		var moved := (np - p).length() / maxf(dt, 0.0001)
		w.player.global_position = np
		pf.walking = moved > 0.3
		if pf is Figure3D:
			(pf as Figure3D).gait = "walk"
			(pf as Figure3D).pace = moved if moved > 0.3 else 0.0
		if move.length() > 0.1:
			pf.face(move, w.cam)
		if follower != "":
			_follow_step(w, follower, 1.6, dt, 2.0, room, follow_token)
		if zone.size != Vector2.ZERO and stray.is_valid():
			var lp := root.to_local(np)
			var here := zone.has_point(Vector2(lp.x, lp.z))
			if here and not in_zone and clock - strayed_at > 6.0:
				strayed_at = clock
				target[0] = null   # (they stop: the way's wrong)
				held_until = clock + 1.6
				stray.call()
				# a step back out of it, facing the room again
				var back := Vector3(zone.get_center().x, 0.0, zone.position.y - 0.45)
				var out_at := root.to_global(back)
				out_at.y = floor_y
				var tb := w.create_tween()
				tb.tween_property(w.player, "global_position", out_at, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				pf.face(out_at - np, w.cam)
			in_zone = here
		# the camera stays up in its corner and turns to keep them in view
		# (or, with "cam_follow", comes along behind them: the tunnel)
		look = look.lerp(np + Vector3(0, 1.0, 0), minf(1.0, dt * 4.0))
		var cam_want: Vector3 = (room.cam_follow as Callable).call(np) if room.has("cam_follow") else cam_at
		w.cam.global_position = w.cam.global_position.lerp(cam_want, minf(1.0, dt * 3.0))
		w.cam.look_at(look, Vector3.UP)
		await w.get_tree().process_frame
	if not is_instance_valid(w):
		return
	if w.hud.tapped.is_connected(on_tap):
		w.hud.tapped.disconnect(on_tap)
	pf.walking = false
	if pf is Figure3D:
		(pf as Figure3D).pace = 0.0
	if follower != "":
		var ff = Cine.fig(w, follower)
		var fb := Cine.body(w, follower)
		if ff != null and fb != null and int(fb.get_meta("cine_path", 0)) == follow_token:
			ff.walking = false


## A spot in a room (walk_room's) kept on its floor and out of its
## furniture: inside "walk", out of the round "blocks" and the square
## "keep_out" patches (the stairs), in the room's own x/z.
static func room_clamp(room: Dictionary, np: Vector3) -> Vector3:
	var root: Node3D = room.root
	var rect: Rect2 = room.walk
	var lp := root.to_local(np)
	lp.x = clampf(lp.x, rect.position.x, rect.end.x)
	lp.z = clampf(lp.z, rect.position.y, rect.end.y)
	for b in room.blocks:
		var c: Vector2 = b[0]
		var off := Vector2(lp.x, lp.z) - c
		var r: float = b[1]
		if off.length() < r:
			off = off.normalized() * r if off.length() > 0.001 else Vector2(0, r)
			lp.x = c.x + off.x
			lp.z = c.y + off.y
	for k: Rect2 in room.get("keep_out", []):
		if k.has_point(Vector2(lp.x, lp.z)):
			# out by the nearest side
			var dl := lp.x - k.position.x
			var dr := k.end.x - lp.x
			var dt := lp.z - k.position.y
			var db := k.end.y - lp.z
			var m := minf(minf(dl, dr), minf(dt, db))
			if m == dl:
				lp.x = k.position.x
			elif m == dr:
				lp.x = k.end.x
			elif m == dt:
				lp.z = k.position.y
			else:
				lp.z = k.end.y
	np = root.to_global(lp)
	# a room's floor is flat; a hillside ("ground") follows the land
	np.y = (room.ground as Callable).call(np) if room.has("ground") else float(room.floor_y)
	return np


## One frame of someone walking after the player, staying `keep` metres
## behind (at up to `speed` m/s), looking at them when they stop. In a
## room (walk_room's), they keep out of its furniture too.
## How close the player can come to someone following them before that
## someone steps back (their personal space, m).
const FOLLOW_SPACE := 0.6


static func _follow_step(w: World, who: String, keep: float, dt: float, speed: float, room := {}, token := -1) -> void:
	var b := Cine.body(w, who)
	var f = Cine.fig(w, who)
	if b == null or f == null:
		return
	if token >= 0 and int(b.get_meta("cine_path", 0)) != token:
		return   # a staged walk (Cine.path) has taken them over: theirs now
	var p := w.player.global_position
	var d := p - b.global_position
	d.y = 0.0
	var dist := d.length()
	if dist < FOLLOW_SPACE and dist > 0.001:
		# the player has walked into them: a step back out of their way,
		# rather than standing to be walked through
		var np := b.global_position - d.normalized() * minf(speed * dt, FOLLOW_SPACE - dist)
		if Cine._on_terrain(w, b):
			np = _round_props(w, np)
			np.y = Cine.ground(w, np)
		elif not room.is_empty():
			np = room_clamp(room, np)
		b.global_position = np
		f.walking = true
		if f is Figure3D:
			(f as Figure3D).gait = "walk"
			(f as Figure3D).pace = 0.6
		f.look_toward(p, w.cam)
	elif dist > keep + 0.25:
		var step := minf(speed * dt, dist - keep)
		var np := b.global_position + d.normalized() * step
		if Cine._on_terrain(w, b):
			np = _round_props(w, np)
			np.y = Cine.ground(w, np)
		elif not room.is_empty():
			np = room_clamp(room, np)
		b.global_position = np
		f.walking = true
		if f is Figure3D:
			(f as Figure3D).gait = "walk" if speed < 3.0 else "run"
			(f as Figure3D).pace = step / maxf(dt, 0.0001)
		f.face(d, w.cam)
	else:
		f.walking = false
		if f is Figure3D:
			(f as Figure3D).pace = 0.0
		f.look_toward(p, w.cam)


## A step that would take someone into a pile of Gary's sacks or a stack of
## his crates, or into anything solid and small (Nell's bench, the well, a
## stool: Cine.blockers), slides round it instead.
static func _round_props(w: World, at: Vector3) -> Vector3:
	var v := village(w)
	if v == null:
		return at
	for pr in v.props_placed + Cine.blockers(w):
		var c: Vector2 = pr[0]
		var r := float(pr[1]) + 0.35
		var off := Vector2(at.x, at.z) - c
		if off.length() < r:
			off = off.normalized() * r if off.length() > 0.001 else Vector2(r, 0)
			at.x = c.x + off.x
			at.z = c.y + off.y
	return at


## Someone (Bram, out of the inn) walks after the player until `on[0]` is
## false, or until a staged walk (Cine.path) takes them over. It runs a frame
## behind whoever turns it off, so its clean-up never touches a walk that
## isn't its own: until 22 October it switched Bram's walking off a frame
## after the green scene had started him towards the Lantern, and he glided
## there in his idle ("Bram floats").
static func follow(w: World, who: String, keep: float, on: Array) -> void:
	var body := Cine.body(w, who)
	var token := int(body.get_meta("cine_path", 0)) if body != null else 0
	while on[0] and is_instance_valid(w) and w.is_inside_tree():
		var dt := w.get_process_delta_time()
		var sp := 2.0
		var b := Cine.body(w, who)
		if b == null or int(b.get_meta("cine_path", 0)) != token:
			return   # staged off somewhere: not ours to stop
		if b.global_position.distance_to(w.player.global_position) > keep + 3.0:
			sp = 3.8   # fallen behind: he hurries
		_follow_step(w, who, keep, dt, sp, {}, token)
		await w.get_tree().process_frame
	if not is_instance_valid(w):
		return
	var b2 := Cine.body(w, who)
	if b2 == null or int(b2.get_meta("cine_path", 0)) != token:
		return
	var f = Cine.fig(w, who)
	if f != null:
		f.walking = false
		if f is Figure3D:
			(f as Figure3D).pace = 0.0
			(f as Figure3D).gait = "walk"


# ============================================================ the opening ===
# Master Script v3, P1 · The attic and the taproom. The lines, word for word.

## Morrowen's line, spoken over the dream of the white sky (28 October, Gary:
## "the speech at the beginning of the game happen while we see the sky and
## it turning white"; until then it was spoken once he'd got out of bed).
## His recording, morrowen_attic (v7's one new line for her).
const ATTIC := [
	{"who": "morrowen", "say": "Every soul in my book starts with a debt. Most spend a lifetime paying interest on a life they never asked for, trying to balance an account that was written before they were born.", "vo": "morrowen_attic"},
]
## At the glass, once the name's written in the frost (v7, Q0; Gary, 24
## October: written, not remembered, so it doesn't sound like amnesia).
const NAMED := [
	{"who": "player", "say": "[i]{name}. Same as every winter. Bram still calls me Sprout.[/i]"},
]
## The reflection hub (v7): both questions can be asked; stepping away moves on.
const REFLECTION := [
	{"ask": ["Why do I hide this mark under my collar?", "How long have I lived under Bram's roof?"], "leave": "Step away from the glass.", "then": [
		[
			{"who": "player", "say": "[i]Because you are unbound. The gods hold no mortgage on your soul, and Ironvault has no receipt for your birth.[/i]"},
			{"who": "player", "say": "[i]In a world where every king and kingdom is pledged to a patron, a person who owes nothing is a rarity... and a threat to Aurex Morne's bank.[/i]"},
		],
		[
			{"who": "player", "say": "[i]Twenty years. Ever since an old man walked out of a crater in the Shardlands carrying a baby tucked inside his heavy coat.[/i]"},
			{"who": "player", "say": "[i]He bought this inn with unexplained gold, gave you a bed, and taught you to keep your head down.[/i]"},
		],
	]},
]
const BRAM_CALLS := [
	{"who": "bram", "say": "You coming down, Sprout? The draft blew out the pilot lamp, the porridge is getting cold, and Ironvault's bailiffs don't wait for the sun to clear the pass."},
]
## The taproom (v7): Bram behind the counter with a rag; his hub; the crate
## from the corner. Corin's duel comes first (Gary, 24 October), so Tam is
## for afterwards.
const TAPROOM := [
	{"who": "bram", "say": "Left the shutter unlatched again. Cold air costs firewood, wood costs coin, and coin is the one thing nobody in Ashford has enough of today."},
	{"who": "bram", "say": "Eat something first. I'm not having you walking down to the green on an empty stomach."},
	{"ask": ["Ironvault's bailiffs are on the road early today.", "Is Tam Hayes going to lose the mill tonight?", "Why is this inn the only roof Ironvault doesn't own?"],
		"leave": "I'm ready for the festival prep.", "then": [
		[
			{"who": "bram", "say": "They're always early when a note falls due. Caldus Morne doesn't let his clerks sleep when there's interest compounding in the valley."},
			{"who": "bram", "say": "They've cleared every roof in Ashford except this one."},
		],
		[
			{"who": "bram", "say": "Tam's down there right now counting flour sacks he hasn't even ground yet."},
			{"who": "bram", "say": "Poor bastard can't read the legal script on the letter in his own pocket, and he's too proud to ask Nell to look at it."},
			{"who": "bram", "say": "Look in on him once Corin's had his duel. He won't ask, so you'll have to."},
		],
		[
			{"who": "bram", "say": "Because I paid Aurex Morne in full the week I came down off the Shards. Four thousand gold crowns, signed and sealed on a single page before his son Caldus took the desk."},
			{"who": "bram", "say": "Gold I bled for. Some debts you pay off in coin, Sprout. Some you carry around in your ribs until your knees give out."},
		],
	], "follow": {0: ["Is Morne really as dangerous as people say?", [
		{"who": "bram", "say": "Morne doesn't raise a sword. He takes off his reading glasses, looks at your ledger page, and gives you a price that sounds completely fair..."},
		{"who": "bram", "say": "...until you realize it costs you everything you own three years down the line."},
	]]}},
	{"who": "bram", "say": "Eat every crumb. Then grab the lantern crate from the corner and take it down to the green."},
]
## As the player reaches the door; the pause square glows once while it's up.
## (Gary, 20 October: his first line and this one reworded; the master doc
## still has "Thought you'd sleep through the end of the world." and "And if
## you need to stop, stop. The world'll wait.") {menu} is the bracketed way
## to open the menu on the device in hand (WorldCoach.MENU_HOW), so the line
## says how without Bram saying it.
const AT_DOOR := [{"say": "{menu} [i](It stops the game, and saves it.)[/i]"}]
## If the player dawdles on the way (said in passing; they keep walking).
const DAWDLE := "The green. Big pole, middle of it. You've walked there every day of your life."
## If they head back up the stairs with the crate (Gary, 19 October).
const WRONG_WAY := "Wrong way, Sprout. The green's out the door, not up the stairs."
const AT_GREEN := [{"who": "bram", "say": "Top hook's yours. It always has been."}]
const HUNG := [
	{"who": "bram", "say": "Good. Now go and be useful."},
	{"who": "bram", "say": "Tam first. He's been carrying a letter round all day like it's hot."},
	{"who": "bram", "say": "Nell's on the bench by the well, if you've time. Then Corin, and get the Lantern Duel over with."},
	{"say": "[center][i]He glances up at the stars the way he'd watch a stranger's hands.[/i][/center]", "during": "bram_stars"},
	{"who": "bram", "say": "Go on."},
]

## How long the dream of the white sky plays before the player wakes (s),
## with nothing spoken over it: about 2 s of the night sky through the attic
## window, an even fade to white over about 2.5 s, and a beat of white
## (CineOverlay.dream_sky); 0 goes straight from the caption to the attic.
## Since 28 October Morrowen speaks over it (_dream), and it lasts as long
## as her line: the sky a moment on its own (DREAM_LEAD), her words over
## the stars, the white coming over it through her last few words
## (DREAM_WHITE) so it's full as she finishes, then the beat of white
## (DREAM_HOLD) and black on the drum.
const DREAM_SECS := 5.2
const DREAM_LEAD := 1.2
const DREAM_WHITE := 2.6
const DREAM_HOLD := 0.8
## How near the Great Lantern counts as "at the green" (m).
const GREEN_R := 6.5
## Where the player puts the crate down: the Lantern's south side, clear of
## the well, the bench and the stalls, a couple of steps from the hoist.
const GREEN_SPOT := Vector3(0.9, 0.0, 2.5)
## Seconds without getting nearer the green before Bram says where it is.
const DAWDLE_SECS := 14.0


## The opening, from wherever a game closed part-way left it (p1_stage) to
## "Find Tam at the hay cart". New Game runs it from the attic (World calls
## the area's intro()); a game closed during it runs it again from the start
## of the part it was in (resume()).
static func opening(w: World) -> void:
	var v := village(w)
	# a frosty morning (v7): the village by day, before the attic's window
	# view of it is taken
	v.set_daylight(1.0)
	pose(w)
	w.busy = true
	w.hud.set_controls_visible(false)
	mute_all_but(w, [], true)
	# Bram teaches walking and talking himself, with the Objective line
	# naming the buttons: the world's old standing hints never show
	Game.settings["first_steps"] = 2
	Game.save_settings()
	w.hud.show_hint("")
	var stage := String(Game.flag("p1_stage", "attic"))
	var i := maxi(0, STAGES.find(stage))
	if i <= 1:
		# the views out of the attic window and the taproom door are taken
		# before the rooms' own lighting goes in
		Cine.overlay(w).black(true)
		InnRooms.attic(v)
		InnRooms.eve(v)
		for k in 3:
			await w.get_tree().process_frame
	for k in range(i, STAGES.size()):
		Game.set_flag("p1_stage", STAGES[k])
		Game.save_game()
		match STAGES[k]:
			"attic":
				await _attic(w)
			"taproom":
				await _taproom(w)
			"street":
				await _street(w)
			"green":
				await _green(w)
		if not is_instance_valid(w) or not w.is_inside_tree():
			return
	Game.set_flag("p1_stage", "done")
	Game.set_flag("ash_started")
	Game.save_game()
	mute_all_but(w, ["corin"])
	w.end_cine()
	controls_on(w)
	w.busy = false


## P1 · the attic: black, the drum, the caption; the player asleep on the
## straw bed wakes, gets up and goes to the cracked mirror; the narration;
## "Choose your look."
static func _attic(w: World) -> void:
	var v := village(w)
	var a := InnRooms.attic(v)
	go_inside(v)
	var ov := Cine.overlay(w)
	ov.black(true)
	w.cine = true
	var pf = w.player_doll
	asleep(w)
	var root: Node3D = a.root
	Cine.shot(w, root.to_global(Vector3(2.45, 1.6, 1.3)), a.bed + Vector3(0.2, 0.15, 0.0), 46.0)
	await Cine.caption(w, "Ashford", "The last night of the Age.", 2.4)
	# the dream they're about to tell Bram about: the night sky from the
	# bed, Morrowen's words over it, and the white light that takes it; cut
	# to black on the drum
	if DREAM_SECS > 0.0:
		await _dream(w, ov)
	# (25 October, Gary: getting out of bed "a little bit faster": the whole
	# rise, from the fade-up to standing, is about seven seconds now where
	# it was twelve; each movement is the same, just brisker)
	await Cine.wait(w, 0.2)
	Cine.fade(w, 0.0, 1.0)
	Cine.drift(w, root.to_global(Vector3(2.45, 1.6, 1.3)), root.to_global(Vector3(2.15, 1.5, 1.1)),
		a.bed + Vector3(0.2, 0.15, 0.0), a.bed + Vector3(0.3, 0.2, 0.2), 2.4, 46.0)
	await Cine.wait(w, 1.4)
	# wakes to the drum: sits up, throws the blanket back, swings his legs
	# over the side of the bed, sits there a breath, then stands up off it
	var side: Vector3 = a.bed_side
	if pf is Figure3D:
		var fig := pf as Figure3D
		var rise_clip := fig.anim != null and fig._ensure("get_out_of_bed")   # (borrowed from Player A by the other looks)
		# his right hand finds the blanket's hem beside him and throws it
		# back across him to the wall, the cloth following the hand
		# (BlanketThrow); then the hand goes down on the mattress and he
		# pushes himself up on it
		var hand := Node3D.new()
		hand.name = "BedHand"
		w.add_child(hand)
		var bl: Node3D = a.blanket
		var on_mattress := (a.lie_at as Vector3) + Vector3(-0.28, a.bed_top + 0.02, 0.34)
		if bl is MeshInstance3D and bl.has_meta("rows"):
			var corner := BlanketThrow.corner_of(bl)
			hand.global_position = corner
			fig.reach(null, hand, 0.35)
			await Cine.wait(w, 0.3)
			var bt := BlanketThrow.start(bl, a.blanket_off, hand, 0.8)
			var to := BlanketThrow.corner_in_heap(bl, a.blanket_off)
			var sweep := w.create_tween()
			sweep.tween_method(func(u: float) -> void:
				hand.global_position = corner.lerp(to, u) + Vector3(0, sin(u * PI) * 0.22, 0), 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await sweep.finished
			bt.let_go()
			if not rise_clip:
				var down := w.create_tween()
				down.tween_property(hand, "global_position", on_mattress, 0.3).set_trans(Tween.TRANS_SINE)
				await down.finished
		elif not rise_clip:
			hand.global_position = on_mattress
			fig.reach(null, hand, 0.35)
			await Cine.wait(w, 0.25)
		if rise_clip:
			await _rise_from_bed(w, fig, a)
			if is_instance_valid(hand):
				hand.queue_free()
			# a step on from the bed, to where he turns to the window
			var step := w.player.global_position.lerp(side, 0.5)
			step.y = (a.bed_side as Vector3).y
			await Cine.path(w, "player", [step], 0.6)
		if not rise_clip:
			await _rise_by_poses(w, fig, a, side)
		if is_instance_valid(hand):
			hand.queue_free()
	else:
		var tw := w.create_tween()
		tw.tween_property(w.player, "global_position", Vector3(side.x, side.y, side.z), 0.7).set_trans(Tween.TRANS_SINE)
		await tw.finished
	Cine.look(w, "player", a.window)
	await Cine.wait(w, 0.4)
	# the first lesson: walking, to the washbasin, on their own feet
	controls_on(w)
	w.hud._menu_btn.visible = false   # (the pause square is taught at the door)
	coach(w).objective("basin")
	var stand: Vector3 = a.mirror_stand
	await walk_room(w, a, root.to_global(Vector3(-2.35, 2.0, 1.55)), func(p: Vector3) -> bool:
		return Vector2(p.x - stand.x, p.z - stand.z).length() < 0.8)
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	coach(w).objective("")
	w.hud.set_controls_visible(false)
	Cine.shot(w, root.to_global(Vector3(0.9, 1.7, 1.45)), a.mirror + Vector3(0, -0.1, 0), 42.0)
	await Cine.path(w, "player", [stand], 1.0)
	Cine.look(w, "player", a.mirror)
	await Cine.wait(w, 0.3)
	# the second: using a thing (E / X / a tap on the mirror)
	await use(w, a.mirror_node, "mirror", 0.0, Vector3.INF, 0.42)
	await _at_the_glass(w, a)




## Up out of the attic bed the way it was done before 27 October, built
## from poses (sat up, slid to the edge, sat on it, stood): for a model
## without the get_out_of_bed clip.
## The dream with Morrowen speaking over it: the night sky through the attic
## window comes up, she speaks (her recording, her words as a subtitle over
## the stars), and the white starts coming over the sky DREAM_WHITE seconds
## before she finishes, so it's full white as her last words end; a beat of
## white, then black. A tap skips her line as any voiced line, and the white
## comes at once. Without her recording (on the web, before the voices pack
## is in) the line waits for a tap like any other, the sky holding under it.
static func _dream(w: World, ov: CineOverlay) -> void:
	ov.dream_begin()
	await Cine.wait(w, DREAM_LEAD)
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	var line: Dictionary = ATTIC[0]
	var secs := VoiceLines.play(w, String(line.who), String(line.say), String(line.get("vo", "")))
	if secs > 0.0:
		var start := maxf(secs - VoiceLines.TAIL - DREAM_WHITE, 0.5)
		w.get_tree().create_timer(start, false).timeout.connect(func() -> void:
			if is_instance_valid(ov):
				ov.dream_whiten(DREAM_WHITE, DREAM_HOLD))
	await ov.say(w._speaker(String(line.who)), w._fmt(String(line.say)), secs, secs > 0.0)
	if secs > 0.0:
		VoiceLines.stop(w)
	await ov.dream_whiten(DREAM_WHITE if secs <= 0.0 else 1.4, DREAM_HOLD)


static func _rise_by_poses(w: World, fig: Figure3D, a: Dictionary, side: Vector3) -> void:
	fig.sit_long(a.lie_top, 1.0)
	await Cine.wait(w, 1.05)
	# sat up: a breath, then he slides to the edge and turns to face it,
	# his legs still out along the mattress (they swing down only once
	# they're over the edge: nothing goes through the bed), the hand
	# coming off the mattress as he does
	await Cine.wait(w, 0.2)
	await fig.shift_seat(a.edge_at, Vector3.BACK, 0.8, 0.05)
	fig.sit(a.edge_top, 0.6)
	fig.let_go(0.6)
	await Cine.wait(w, 0.5)
	# a moment on the edge, then up and away from it
	await Cine.wait(w, 0.15)
	fig.stand(0.7)
	var tw := w.create_tween()
	tw.tween_property(w.player, "global_position", Vector3(side.x, side.y, side.z), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


## Up out of the attic bed with the model's own get_out_of_bed (Hob's, the
## Tripo3D library's: lying on his back, he sits up, swings his legs over
## the side, sits a breath on the edge and stands up off it), mirrored so
## it's the open side of the bed, not the wall's (27 October, Gary: getting
## out of bed looked weird when it was built from poses). The clip was made
## on a lower bed with the sleeper nearer its edge, so he's lifted onto this
## mattress while he lies and sits up, slid to its edge as his legs come
## round, and set down on the floor as he stands.
static func _rise_from_bed(w: World, fig: Figure3D, a: Dictionary) -> void:
	var clip: Animation = fig.anim.get_animation("get_out_of_bed")
	var hips_track := -1
	for t in clip.get_track_count():
		if clip.track_get_type(t) == Animation.TYPE_POSITION_3D and String(clip.track_get_path(t).get_concatenated_subnames()) == "Hips":
			hips_track = t
	var pad := Figure3D.SEAT_PAD * fig.stature()
	var lie_off := 0.0
	var edge_off := 0.0
	if hips_track >= 0:
		lie_off = (float(a.lie_top) + pad) - clip.position_track_interpolate(hips_track, 0.0).y
		edge_off = (float(a.edge_top) + pad) - clip.position_track_interpolate(hips_track, 2.8).y
	fig.let_go(0.3)   # (the hand that threw the blanket back)
	var from: Vector3 = w.player.global_position
	var to_edge: Vector3 = (a.edge_at as Vector3) - from
	to_edge.y = 0.0
	var extra := func(t: float) -> Vector3:
		var slide := smoothstep(1.3, 2.5, t)
		var y := lerpf(lie_off, edge_off, slide)
		y = lerpf(y, 0.0, smoothstep(3.1, 4.0, t))
		return to_edge * slide + Vector3(0, y, 0)
	await fig.play_rooted("get_out_of_bed", true, 1.15, extra, 0.35)
	fig.release(0.4)
## Master Script v7 (with Gary's 24 October change to Q0): at the washbasin
## he wipes the frost off the oval glass with his palm and sees the ash-grey
## mark on his collarbone; the frost creeps back and he writes his name in it
## (the name screen: "Write your name in the frost"); then the reflection hub
## (the mark, twenty years under Bram's roof, step away), and Bram calling up
## through the floorboards.
static func _at_the_glass(w: World, a: Dictionary) -> void:
	var root: Node3D = a.root
	var pf = w.player_doll
	var fog_mat: StandardMaterial3D = a.fog_mat
	var writing: Label3D = a.writing
	var glass_at: Vector3 = a.mirror
	# the glass holds the room the other way round from here on (until 27
	# October it was a grey disc: wiped, it showed nothing of him)
	var reflection: MirrorGlass = null
	if a.get("mirror_node") is Node3D:
		reflection = MirrorGlass.start(w, a.mirror_node, Vector3(-0.036, 0, 0), 0.27, 0.27 * 1.32)
	# over his shoulder, the fogged oval in front of him: far enough back that
	# the camera's near edge doesn't cut into his head (Gary, 27 October: "an
	# outline of the body" when he wiped the glass: the camera was half in his
	# hair), and off to the side so the glass isn't behind him
	var away_from := w.player.global_position - glass_at
	away_from.y = 0.0
	away_from = away_from.normalized()
	var aside := Vector3.UP.cross(away_from).normalized()
	var over := w.player.global_position + away_from * 0.7 + aside * 0.55 + Vector3(0, 1.8, 0)
	Cine.move(w, over, glass_at + Vector3(0, -0.02, 0), 0.7, 40.0)
	await Cine.wait(w, 0.6)
	# a bare palm across the glass, side to side, and the grey clears behind it
	var hand := Node3D.new()
	hand.name = "WipeHand"
	w.add_child(hand)
	var toward := (w.player.global_position - glass_at)
	toward.y = 0.0
	toward = toward.normalized() * 0.07
	hand.global_position = glass_at + toward + Vector3(0, 0.12, -0.12)
	if pf is Figure3D:
		(pf as Figure3D).reach(null, hand, 0.4)
	await Cine.wait(w, 0.4)
	var wipe := w.create_tween()
	wipe.tween_method(func(u: float) -> void:
		hand.global_position = glass_at + toward + Vector3(0, 0.12 - u * 0.24, sin(u * PI * 3.0) * 0.14)
		fog_mat.albedo_color.a = lerpf(0.78, 0.12, u), 0.0, 1.0, 1.4).set_trans(Tween.TRANS_SINE)
	await wipe.finished
	if pf is Figure3D:
		(pf as Figure3D).let_go(0.4)
	# the camera in the glass, looking back at him through the mirror's
	# oval: the face, and under the collar the mark like a broken seal. A cut
	# (until 25 October the camera glided there through his head and came
	# out as a wide shot up his chin: Gary, "the camera angle goes weird");
	# the picture is masked to the oval, so it reads as his reflection.
	var face := Cine.head(w, "player") - Vector3(0, 0.08, 0)
	mirror_mask(w, true)
	_glass_shot(w, glass_at, face)
	SealMark.show_on(w, true)
	await Cine.wait(w, 1.6)
	# the frost already creeping back; without thinking he writes his name in it
	var back := w.create_tween()
	back.tween_method(func(k: float) -> void: fog_mat.albedo_color.a = k, 0.12, 0.6, 1.6)
	mirror_mask(w, false)
	_glass_shot_done(w)
	Cine.shot(w, over, glass_at + Vector3(0, -0.02, 0), 40.0)
	await Cine.wait(w, 0.9)
	hand.global_position = glass_at + toward + Vector3(0, 0.05, 0.1)
	if pf is Figure3D:
		(pf as Figure3D).reach(null, hand, 0.35)
	var nm := await Cine.overlay(w).ask_name("Write your name in the frost.", "Ash")
	Game.player_name = nm
	writing.text = nm
	var trace := w.create_tween()
	trace.tween_method(func(u: float) -> void:
		hand.global_position = glass_at + toward + Vector3(0, 0.05 - u * 0.02, 0.1 - u * 0.2)
		writing.modulate.a = u * 0.9, 0.0, 1.0, 1.3).set_trans(Tween.TRANS_SINE)
	await trace.finished
	if pf is Figure3D:
		(pf as Figure3D).let_go(0.4)
	hand.queue_free()
	Game.set_flag("named")
	Game.save_game()
	await w.run_steps(NAMED, null)
	# the questions he asks the glass (his reflection, in the oval again);
	# stepping away moves on
	var head := Cine.head(w, "player") - Vector3(0, 0.08, 0)
	mirror_mask(w, true)
	_glass_shot(w, glass_at, head)
	await w.run_steps(REFLECTION, null)
	w.hud.dialogue.close()
	SealMark.show_on(w, false)
	mirror_mask(w, false)
	_glass_shot_done(w)
	# a step back from the glass, and Bram's voice up through the floorboards
	var away := w.player.global_position + (w.player.global_position - glass_at).normalized() * 0.5
	away.y = w.player.global_position.y
	Cine.shot(w, root.to_global(Vector3(-1.6, 1.75, 1.4)), w.player.global_position + Vector3(0, 1.3, 0), 44.0)
	Cine.path(w, "player", [away], 0.8)
	await Cine.wait(w, 0.6)
	Cine.look(w, "player", a.hatch)
	await w.run_steps(BRAM_CALLS, null)
	if reflection != null and is_instance_valid(reflection):
		reflection.stop()
	w.hud.dialogue.close()
	await Cine.wait(w, 0.3)
	await Cine.fade(w, 1.0, 0.7)


## His face as the glass shows it, framed by the oval mask: the camera on
## the far side of the glass, about a metre from him with a long lens, its
## near edge just past the glass and the wall behind it (27 October, Gary:
## the face looked deformed; the camera was a hand's width from his face
## with a wide lens, his nose cut off by its near edge, and lit from below).
static func _glass_shot(w: World, glass_at: Vector3, face: Vector3) -> void:
	var to_glass := glass_at - face
	to_glass.y = 0.0
	var dist := to_glass.length()
	var dir := to_glass.normalized()
	var at := face + dir * 1.15 + Vector3(0, 0.03, 0)
	Cine.shot(w, at, face, 27.0)
	w.cam.near = maxf(0.05, 1.15 - dist + 0.06)


## The camera's near edge back where the world keeps it.
static func _glass_shot_done(w: World) -> void:
	w.cam.near = 0.3


## The mirror's oval over the picture: dark wood outside a soft-edged oval
## the shape of the glass (taller than wide, as the oval is), its rim a
## thin ring, so a shot taken from the glass reads as the reflection in it.
## Drawn under the dialogue box (layer 9), so the questions sit over it.
static func mirror_mask(w: World, on: bool) -> void:
	var layer: CanvasLayer = w.get_meta("mirror_mask") if w.has_meta("mirror_mask") else null
	if not on:
		if layer != null and is_instance_valid(layer):
			# the picture the right way round again at once (the cut back to
			# the room comes with this), the frame fading off it
			var flip: Node = layer.get_node_or_null("Flip")
			if flip != null:
				flip.queue_free()
			var r: ColorRect = layer.get_node("Frame")
			var tw := w.create_tween()
			tw.tween_property(r, "modulate:a", 0.0, 0.3)
			tw.tween_callback(layer.queue_free)
		w.remove_meta("mirror_mask")
		return
	if layer != null and is_instance_valid(layer):
		return
	layer = CanvasLayer.new()
	layer.name = "MirrorMask"
	layer.layer = 9
	w.add_child(layer)
	var aspect := maxf(0.5, float(w.get_viewport().get_visible_rect().size.x) / maxf(1.0, w.get_viewport().get_visible_rect().size.y))
	# the picture turned left for right, as a reflection is (27 October: the
	# glass itself shows the room mirrored now, so its close-up must too)
	var flip := ColorRect.new()
	flip.name = "Flip"
	flip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := Shader.new()
	fs.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
void fragment() {
	COLOR = vec4(texture(screen_tex, vec2(1.0 - SCREEN_UV.x, SCREEN_UV.y)).rgb, 1.0);
}
"""
	var fm := ShaderMaterial.new()
	fm.shader = fs
	flip.material = fm
	layer.add_child(flip)
	var r := ColorRect.new()
	r.name = "Frame"
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float aspect = 1.78;
void fragment() {
	// the oval: centred, 1.32 times taller than wide, nearly the screen's height
	vec2 p = (UV - 0.5) * vec2(aspect, 1.0);
	float d = length(p * vec2(1.32, 1.0)) / 0.47;
	float wood = smoothstep(0.97, 1.03, d);
	float rim = smoothstep(0.985, 1.0, d) * (1.0 - smoothstep(1.03, 1.07, d));
	vec3 col = mix(vec3(0.07, 0.045, 0.03), vec3(0.2, 0.13, 0.07), rim);
	// the glass itself a touch cold and dim towards its edge, like old silvering
	float edge = smoothstep(0.55, 0.97, d) * 0.35;
	COLOR = vec4(mix(vec3(0.05, 0.07, 0.1), col, wood), max(wood, edge));
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("aspect", aspect)
	r.material = m
	layer.add_child(r)
	r.modulate.a = 0.0
	var tw := w.create_tween()
	tw.tween_property(r, "modulate:a", 1.0, 0.25)
	w.set_meta("mirror_mask", layer)


## Under the title screen (World.prepare): the attic and the taproom built,
## their window views taken, and the attic's first shot put to the camera
## with the player asleep in it, so what the opening draws first has been
## drawn already.
static func warm(w: World) -> void:
	var v := village(w)
	pose(w)
	var a := InnRooms.attic(v)
	InnRooms.eve(v)
	for k in 3:
		await w.get_tree().process_frame   # (the views out of the window and the door)
	if not w.held or not w.is_inside_tree():
		return
	go_inside(v)
	w.cine = true
	asleep(w)
	Cine.shot(w, (a.root as Node3D).to_global(Vector3(2.45, 1.6, 1.3)), a.bed + Vector3(0.2, 0.15, 0.0), 46.0)


## The player asleep in the attic bed: on his back on the mattress, head
## to the west on the bolster, the blanket over him from the chest down.
## (The attic's first shot, and World.prepare's warm-up of it.)
static func asleep(w: World) -> void:
	var a := InnRooms.attic(village(w))
	var pf = w.player_doll
	var at: Vector3 = a.lie_at
	Cine.place(w, "player", at, at + Vector3.RIGHT)
	if pf is Figure3D:
		var fig := pf as Figure3D
		fig.snap_face(Vector3.RIGHT)
		fig.lie_on(a.lie_top, 0.0)
	var bl: Node3D = a.blanket
	if bl != null and is_instance_valid(bl) and not bl.has_meta("on"):
		bl.set_meta("on", bl.transform)
	elif bl != null and is_instance_valid(bl):
		bl.transform = bl.get_meta("on")
	if bl is MeshInstance3D and bl.has_meta("rows"):
		BlanketThrow.reset(bl)


## P1 · the taproom (Master Script v7): morning; Bram behind the counter
## rubbing a rag over oak that doesn't need cleaning, a bowl of porridge
## waiting on the bar, the lantern crate packed in the corner by the door.
## His hub; then the player takes the crate from the corner themselves and
## carries it to the door (walking, and using a thing, again), where the
## game says, in brackets, how to open the menu as the pause square glows.
static func _taproom(w: World) -> void:
	var v := village(w)
	var e := InnRooms.eve(v)
	go_inside(v)
	Cine.overlay(w).black(true)
	w.cine = true
	var root: Node3D = e.root
	# the crate packed and waiting in the corner by the door
	var cr: Node3D = e.get("crate", null)
	if cr == null or not is_instance_valid(cr):
		cr = crate(v)
		root.add_child(cr)
		e["crate"] = cr
	var corner := root.to_global(Vector3(3.55, 0, -2.85))
	cr.global_position = corner
	cr.rotation = Vector3(0, 0.25, 0)
	# breakfast on the bar
	if not e.has("porridge"):
		var bowl := Node3D.new()
		bowl.name = "Porridge"
		root.add_child(bowl)
		bowl.position = Vector3(InnRooms.BAR_X, 1.13, 0.55)
		v.cyl(bowl, 0.09, 0.06, 0.06, Vector3(0, 0.03, 0), v.mats.wood_h, 14)
		var oats := StandardMaterial3D.new()
		oats.albedo_color = Color(0.86, 0.8, 0.66)
		oats.roughness = 0.9
		v.cyl(bowl, 0.08, 0.08, 0.005, Vector3(0, 0.058, 0), oats, 14)
		v.box(bowl, Vector3(0.015, 0.008, 0.16), Vector3(0.05, 0.065, 0.02), v.mats.wood, Vector3(0, 0.4, 0.15))
		e["porridge"] = bowl
	# Bram in the walkway behind the counter, the player a step off its front
	# (25 October: he stood inside the counter, his back in the shelves)
	var bram_at: Vector3 = e.bar_behind
	var me_at := root.to_global(Vector3(InnRooms.BAR_X + 0.85, 0, 0.35))
	Cine.place(w, "bram", bram_at, me_at)
	Cine.place(w, "player", e.stairs_foot, me_at)
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).release(0.0)
	var wiping := [true]
	_wipe(w, root, wiping)
	var cam := root.to_global(Vector3(-0.4, 1.7, 2.1))
	Cine.shot(w, cam, (bram_at + me_at) * 0.5 + Vector3(0, 1.2, 0), 42.0)
	await Cine.fade(w, 0.0, 0.8)
	# down the last stair and up to the bar
	await Cine.path(w, "player", [me_at], 1.3)
	Cine.look(w, "player", bram_at)
	await Cine.wait(w, 0.3)
	Cine.shot(w, root.to_global(Vector3(-1.55, 1.6, 1.7)), (bram_at + me_at) * 0.5 + Vector3(0, 1.3, 0), 36.0)
	await w.run_steps(TAPROOM, null)
	w.hud.dialogue.close()
	wiping[0] = false
	if bf is Figure3D:
		(bf as Figure3D).look_toward(w.player.global_position, w.cam)
	# the crate from the corner: walk to it and take it
	controls_on(w)
	w.hud._menu_btn.visible = false
	coach(w).objective("take_crate")
	var stray := func() -> void:
		Cine.look(w, "bram", w.player.global_position)
		w.hud.dialogue.bark(w._speaker("bram"), w._portrait("bram"), WRONG_WAY)
	await walk_room(w, e, root.to_global(Vector3(0.2, 2.6, 2.6)), func(p: Vector3) -> bool:
		return Vector2(p.x - corner.x, p.z - corner.z).length() < 1.15, "", stray)
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	await use(w, cr, "take_crate", 0.0, Vector3.INF, 0.55)
	await _take_crate(w, cr)
	# to the door with it
	controls_on(w)
	w.hud._menu_btn.visible = false
	coach(w).objective("green_crate")
	var door_in: Vector3 = e.door_in
	await walk_room(w, e, root.to_global(Vector3(-0.6, 2.7, 2.6)), func(p: Vector3) -> bool:
		return Vector2(p.x - door_in.x, p.z - door_in.z).length() < 0.85, "", stray)
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	# at the door: the menu, in brackets, as the pause square glows
	w.hud.set_controls_visible(false)
	w.hud._menu_btn.visible = true
	Cine.look(w, "player", door_in + Vector3(0, 0, -1.0))
	Cine.move(w, root.to_global(Vector3(0.6, 1.7, -1.2)), w.player.global_position + Vector3(0, 1.3, 0), 0.8, 42.0)
	coach(w).light("menu", 3.2)
	await w.run_steps(AT_DOOR, null)
	w.hud.dialogue.close()
	coach(w).light("")
	# out into the morning
	var door: Node3D = e.door
	var sw := w.create_tween()
	sw.tween_property(door, "rotation:y", deg_to_rad(100.0), 0.7).set_trans(Tween.TRANS_SINE)
	await Cine.wait(w, 0.4)
	Cine.path(w, "player", [e.door_out], 1.4)
	await Cine.wait(w, 0.6)
	await Cine.fade(w, 1.0, 0.7)
	door.rotation.y = 0.0


## Bram's rag going over the counter in slow circles until `state[0]` goes
## false (v7: "rubbing a rag over an oak surface that doesn't need cleaning").
## His right hand, in front of his right shoulder on the near part of the
## counter top (WIPE_AT, in his own frame: x to his left, y up, z ahead), the
## circles small: until 28 October it worked half a metre ahead of him and
## well to his left, out of the right arm's reach, so the arm ran across his
## chest, twisted, and the hand fell short through the counter's edge (Gary:
## "Bram's arm twists in a weird way and still passes through his body and
## his hand passed through the bar"). WIPE_AT's height is the palm's, a
## little over the oak (its top is at 1.13) so the fingers lie on it rather
## than in it.
const WIPE_AT := Vector3(-0.21, 1.18, 0.4)


static func _wipe(w: World, _root: Node3D, state: Array) -> void:
	var f = Cine.fig(w, "bram")
	if not (f is Figure3D):
		return
	var fig := f as Figure3D
	var hand := Node3D.new()
	hand.name = "RagHand"
	w.add_child(hand)
	hand.global_position = fig.to_world(WIPE_AT)
	fig.reach(null, hand, 0.5)
	fig.palm("right", Vector3.DOWN, 0.5)   # (flat on the oak, as a hand with a rag is)
	var t := 0.0
	while state[0] and is_instance_valid(w) and is_instance_valid(hand) and is_instance_valid(fig):
		t += w.get_process_delta_time()
		hand.global_position = fig.to_world(WIPE_AT + Vector3(0.07 * cos(t * 2.1) + 0.02 * sin(t * 0.5), 0.0, 0.035 * sin(t * 2.1)))
		await w.get_tree().process_frame
	if is_instance_valid(fig):
		fig.let_go(0.4)
		fig.palm("right", Vector3.ZERO, 0.4)
	if is_instance_valid(hand):
		hand.queue_free()


## The player lifts the crate from the corner into both arms.
static func _take_crate(w: World, cr: Node3D) -> void:
	w.busy = true
	w.cine = true
	var pf = w.player_doll
	Cine.look(w, "player", cr.global_position)
	if pf is Figure3D:
		var me := pf as Figure3D
		me.pose("lift", 0.42, 0.35)
		me.reach(cr.get_node("L"), cr.get_node("R"), 0.4)
		await Cine.wait(w, 0.5)
		var held_at := me.to_world(CRATE_HOLD)
		var lift := w.create_tween()
		lift.tween_property(cr, "global_position", held_at, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await lift.finished
		me.release(0.3)
		me.carry(cr, CRATE_HOLD)
		cr.rotation = Vector3.ZERO
		me.reach(cr.get_node("L"), cr.get_node("R"), 0.2)
	else:
		cr.reparent(w.player)
		cr.position = CRATE_HOLD
	cr.set_meta("p1_prop", true)
	w.set_meta("p1_crate", cr)
	await Cine.wait(w, 0.3)


## Bram packing the last lanterns from the pile into the crate, one at a
## time: his hand to a lantern, over the crate and down into it. Stops when
## state[0] goes false; waits while state[1] is true.
static func _stack(w: World, cr: Node3D, pile: Array, state: Array) -> void:
	var f = Cine.fig(w, "bram")
	if not (f is Figure3D):
		state[2] = true
		return
	var fig := f as Figure3D
	var hand := Node3D.new()
	hand.name = "StackHand"
	w.add_child(hand)
	await Cine.wait(w, 0.4)
	while state[0] and not pile.is_empty() and is_instance_valid(cr):
		while state[1] and state[0]:
			await w.get_tree().process_frame
		if not state[0]:
			break
		var l: Node3D = pile.pop_back()
		hand.global_position = l.global_position + Vector3(0, 0.05, 0)
		fig.reach(null, hand, 0.4)
		await Cine.wait(w, 0.45)
		l.reparent(hand)
		var over: Vector3 = cr.global_position + Vector3(0.0, 0.85, 0.0)
		var into: Vector3 = cr.global_position + Vector3(v_rand(w) * 0.12, 0.42, 0.0)
		var tw := w.create_tween()
		tw.tween_property(hand, "global_position", over, 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(hand, "global_position", into, 0.45).set_trans(Tween.TRANS_SINE)
		await tw.finished
		l.reparent(cr)
		fig.let_go(0.35)
		await Cine.wait(w, 1.6)
	if is_instance_valid(hand):
		hand.queue_free()
	fig.let_go(0.3)
	state[2] = true


static func v_rand(w: World) -> float:
	return village(w).rng.randf_range(-1.0, 1.0)


## Bram lifts the crate off the table and hands it over; the player carries
## it in both arms from here to the green.
static func _crate_to_player(w: World, cr: Node3D) -> void:
	var bf = Cine.fig(w, "bram")
	var pf = w.player_doll
	if not (bf is Figure3D and pf is Figure3D):
		cr.reparent(w.player)
		cr.position = CRATE_HOLD
		return
	var bram := bf as Figure3D
	var me := pf as Figure3D
	bram.look_toward(cr.global_position, w.cam)
	bram.reach(cr.get_node("L"), cr.get_node("R"), 0.4)
	await Cine.wait(w, 0.5)
	# up off the table, into his arms, and he turns to hand it over
	var hold := Node3D.new()
	hold.name = "CrateHold"
	var held_at := bram.to_world(CRATE_HOLD + Vector3(0, 0.08, 0.1))
	var lift := w.create_tween()
	lift.tween_property(cr, "global_position", held_at, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await lift.finished
	bram.carry(cr, CRATE_HOLD + Vector3(0, 0.08, 0.1))
	cr.rotation = Vector3.ZERO
	bram.look_toward(w.player.global_position, w.cam)
	await Cine.wait(w, 0.5)
	# into the player's arms
	me.look_toward(Cine.body(w, "bram").global_position, w.cam)
	var mid := (bram.global_position + me.global_position) * 0.5
	var give := w.create_tween()
	give.tween_property(cr, "global_position", Vector3(mid.x, cr.global_position.y, mid.z), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# (facing him, their left hand takes the side on his right)
	me.reach(cr.get_node("R"), cr.get_node("L"), 0.45)
	await give.finished
	bram.let_go(0.3)
	me.carry(cr, CRATE_HOLD)
	cr.rotation = Vector3.ZERO
	cr.set_meta("p1_prop", true)
	me.reach(cr.get_node("L"), cr.get_node("R"), 0.2)
	w.set_meta("p1_crate", cr)
	await Cine.wait(w, 0.35)


## The crate in the player's arms (made again if the game was closed with it
## on the way).
static func _crate_in_arms(w: World) -> Node3D:
	var cr = meta(w, "p1_crate")
	if cr != null and is_instance_valid(cr):
		return cr
	var c := crate(village(w))
	var pf = w.player_doll
	if pf is Figure3D:
		(pf as Figure3D).carry(c, CRATE_HOLD)
		(pf as Figure3D).reach(c.get_node("L"), c.get_node("R"), 0.0)
	else:
		w.player.add_child(c)
		c.position = Vector3(0.0, 0.85, 0.35)
	c.set_meta("p1_prop", true)
	w.set_meta("p1_crate", c)
	return c


## P1 · out of the inn: Bram follows the player out into the festival street,
## the green beyond. The player walks there themselves (Bram says where it
## is if they dawdle); the pause square works from here on.
static func _street(w: World) -> void:
	var v := village(w)
	InnRooms.outside(v)
	Cine.overlay(w).black(true)
	w.cine = true
	_crate_in_arms(w)
	var front := InnRooms.inn_front(v)
	var door: Vector3 = front.door
	var out: Vector3 = front.out
	var side := out.cross(Vector3.UP).normalized()
	put(w, "player", door + out * 0.5, door + out * 3.0)
	put(w, "bram", door - out * 0.2, door + out * 3.0)
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).release(0.0)
	# the street opens up: thatched cottages and bunting, and the green beyond
	Cine.shot(w, door + out * 3.6 + side * 2.2 + Vector3(0, 1.5, 0), door + Vector3(0, 1.4, 0), 40.0)
	Cine.fade(w, 0.0, 0.8)
	Cine.path(w, "player", [door + out * 2.4], 1.4)
	await Cine.wait(w, 0.5)
	Cine.path(w, "bram", [door + out * 1.0], 1.4)
	await Cine.wait(w, 0.4)
	await Cine.move(w, door + out * 1.2 - side * 0.8 + Vector3(0, 4.2, 0), Vector3(0.0, 3.0, 0.0), 3.2, 46.0)
	await Cine.wait(w, 0.6)
	# a few steps on down the street, Bram behind, to where the game's camera
	# can follow them (it keeps to the village, and the inn's at its edge)
	var from := door + out * 2.4
	var lim := float(w.area.CAMERA_X_LIMIT) - 0.5
	if absf(from.x) > lim:
		var on := from.lerp(Vector3(0.0, from.y, 0.0), 1.0 - lim / absf(from.x))
		on.y = v.height(on.x, on.z)
		var behind := [true]
		follow(w, "bram", 1.8, behind)
		await Cine.path(w, "player", [on], 1.5)
		behind[0] = false
	await home(w, 1.2)
	# their own feet now, Bram behind
	mute_all_but(w, [], true)
	coach(w).objective("green_crate")
	controls_on(w)
	w.busy = false
	var following := [true]
	follow(w, "bram", 1.8, following)
	var best := Vector2(w.player.global_position.x, w.player.global_position.z).length()
	var since := 0.0
	var told := false
	while is_instance_valid(w) and w.is_inside_tree():
		await w.get_tree().process_frame
		if not is_instance_valid(w):
			return   # (quit to the title on the way)
		var d := Vector2(w.player.global_position.x, w.player.global_position.z).length()
		if d < GREEN_R:
			break
		if w.hud.menu_open():
			continue
		since += w.get_process_delta_time()
		if d < best - 1.0:
			best = d
			since = 0.0
		if since > DAWDLE_SECS and not told:
			told = true
			w.hud.dialogue.bark(w._speaker("bram"), w._portrait("bram"), DAWDLE)
	following[0] = false
	if not is_instance_valid(w):
		return
	w.busy = true
	w._move_target = null
	w.hud.set_controls_visible(false)


## P1 · at the green (Master Script v7): the player carries the crate round
## to the Great Lantern's south side, Bram coming up beside them, and sets it
## down on the grass; Bram goes back to his stool. Then Corin calls them over
## (AshfordDay.watch, the moment the opening's done).
static func _green(w: World) -> void:
	var v := village(w)
	var base := Vector3(0, v.height(0, 0), 0)
	w.busy = true
	w.cine = true
	w.hud.set_controls_visible(false)
	var cr := _crate_in_arms(w)
	var pf = w.player_doll
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		(bf as Figure3D).release(0.0)
	var p := w.player.global_position
	if Vector2(p.x, p.z).length() > GREEN_R + 1.0:
		# (picked up here after a closed game: on the green's edge)
		p = Vector3(-4.6, 0, 4.4)
		put(w, "player", p, base)
		put(w, "bram", p + Vector3(-1.6, 0, 0.6), base)
		p = w.player.global_position
	# on round to the Lantern's south side, clear of the well and the stalls,
	# Bram coming up beside them
	var spot := GREEN_SPOT
	spot.y = v.height(spot.x, spot.z)
	var to_c := (base - spot)
	to_c.y = 0.0
	to_c = to_c.normalized()
	var side := to_c.cross(Vector3.UP).normalized()
	var bram_to := spot + side * 1.3 - to_c * 0.3
	bram_to.y = v.height(bram_to.x, bram_to.z)
	var wide := spot - to_c * 6.5 + side * 1.5 + Vector3(0, 3.2, 0)
	Cine.shot(w, clear_cam(w, [wide, spot - to_c * 6.5 - side * 1.5 + Vector3(0, 3.6, 0), spot - to_c * 4.0 + Vector3(0, 5.0, 0)],
		spot + Vector3(0, 1.2, 0)), spot + to_c * 1.5 + Vector3(0, 1.6, 0), 44.0)
	# Bram sets off a beat after them and swings wide on his own side on
	# the way, so his line never crosses theirs (Gary, 23 October)
	Cine.path(w, "player", round_lantern(w, p, spot), 1.4)
	await Cine.wait(w, 0.45)
	var bp := Cine.body(w, "bram").global_position
	var wide_way := (bp + bram_to) * 0.5 + side * 1.5
	wide_way.y = v.height(wide_way.x, wide_way.z)
	await Cine.path(w, "bram", round_lantern(w, bp, wide_way) + round_lantern(w, wide_way, bram_to), 1.6)
	var t := 0.0
	while t < 8.0 and Vector2(w.player.global_position.x - spot.x, w.player.global_position.z - spot.z).length() > 0.15:
		await w.get_tree().process_frame
		t += w.get_process_delta_time()
	p = w.player.global_position
	Cine.look(w, "bram", p)
	# the crate down on the grass a stride in front of them, from low to the
	# side so the crate and their feet clear of it are both seen (Gary, 22
	# October: from behind them their legs hid it)
	var crate_at := p + to_c * CRATE_DOWN
	crate_at.y = v.height(crate_at.x, crate_at.z)
	var between := (p + crate_at) * 0.5 + Vector3(0, 0.42, 0)
	Cine.move(w, clear_cam(w, [between + side * 2.7 - to_c * 0.2 + Vector3(0, 1.1, 0), between - side * 2.7 - to_c * 0.2 + Vector3(0, 1.1, 0),
		crate_at - to_c * 3.2 + side * 1.9 + Vector3(0, 1.4, 0), crate_at - to_c * 3.2 - side * 1.9 + Vector3(0, 1.4, 0)], between), between, 0.9, 40.0)
	Cine.look(w, "player", crate_at)
	if pf is Figure3D:
		(pf as Figure3D).pose("lift", 0.42, 0.35)
	await Cine.wait(w, 0.3)
	var down := w.create_tween()
	down.tween_property(cr, "global_position", crate_at, 0.45).set_trans(Tween.TRANS_SINE)
	await down.finished
	cr.reparent(village(w).get_meta("p1_root"))
	cr.global_rotation = Vector3(0, 0.3, 0)
	w.remove_meta("p1_crate")
	if pf is Figure3D:
		(pf as Figure3D).let_go(0.25)
		(pf as Figure3D).release(0.35)
	await Cine.wait(w, 0.5)
	Game.set_flag("p1_crate_down")
	# Bram back to his stool by the Lantern, and the camera behind the player
	await bram_to_stool(w)
	await home(w, 0.8)


## The player hangs the lantern on the hook and hauls it up to the top hook.
static func _hang(w: World, l: Node3D) -> void:
	var v := village(w)
	var base := Vector3(0, v.height(0, 0), 0)
	var hoist: Node3D = v.get_meta("p1_hoist")
	var hook: Node3D = hoist.get_node("Hook")
	var pf = w.player_doll
	var stand := base + HOOK_STAND
	w.busy = true
	w.cine = true
	Cine.shot(w, stand + Vector3(2.6, 1.5, 2.6), base + LOW_HOOK + Vector3(0, 0.1, 0), 40.0)
	await Cine.path(w, "player", [stand], 1.3)
	Cine.look(w, "player", base + LOW_HOOK)
	await Cine.wait(w, 0.35)
	# on the hook
	if pf is Figure3D:
		var to := Node3D.new()
		hook.add_child(to)
		to.position = Vector3(0, -0.04, 0.06)
		(pf as Figure3D).reach(null, to, 0.4)
		await Cine.wait(w, 0.45)
		l.reparent(hook)
		l.position = Vector3(0, -0.03, 0)
		l.rotation = Vector3.ZERO
		(pf as Figure3D).hand_light(null)   # (the empty holder on the hand goes)
		(pf as Figure3D).let_go(0.3)
		to.queue_free()
	else:
		l.reparent(hook)
		l.position = Vector3(0, -0.03, 0)
	await Cine.wait(w, 0.3)
	# haul it up, hand over hand
	var grip_a := Node3D.new()
	var grip_b := Node3D.new()
	hoist.add_child(grip_a)
	hoist.add_child(grip_b)
	if pf is Figure3D:
		(pf as Figure3D).reach(grip_a, grip_b, 0.3)
	Cine.drift(w, stand + Vector3(2.4, 1.4, 3.0), stand + Vector3(2.0, 1.6, 4.2), base + LOW_HOOK, base + TOP_HOOK, 3.4, 42.0)
	var haul := w.create_tween()
	haul.tween_method(func(u: float) -> void:
		var at := LOW_HOOK.lerp(TOP_HOOK + Vector3(0, -0.08, 0), u)
		_set_hook(v, at)
		# hand over hand on the hauling end, between head and chest height
		var k := fmod(u * 6.0, 1.0)
		var top_k := 1.0 - (1.85 - 1.1) / (PULLEY.y - 1.1)
		var low_k := 1.0 - (1.25 - 1.1) / (PULLEY.y - 1.1)
		grip_a.position = fall_at(lerpf(top_k, low_k, k))
		grip_b.position = fall_at(lerpf(low_k, top_k, k)), 0.0, 1.0, 3.4).set_trans(Tween.TRANS_SINE)
	await haul.finished
	if pf is Figure3D:
		(pf as Figure3D).let_go(0.3)
	grip_a.queue_free()
	grip_b.queue_free()
	# up on the top hook, lit
	var mm := l.get_node_or_null("Paper") as MultiMeshInstance3D
	if mm != null:
		var m := mm.material_override as ShaderMaterial
		if m != null:
			var t2 := w.create_tween()
			t2.tween_method(func(e: float) -> void: m.set_shader_parameter("energy", e), 2.2, 3.4, 0.6)
	v.glow_sprite(l, Vector3(0, -0.2, 0), Color(1.0, 0.62, 0.25), 0.9, 0.6)
	await Cine.wait(w, 1.0)
	Game.set_flag("p1_hung")
	w.remove_meta("p1_lantern")


## Bram goes back to his stool by the Lantern and sits.
static func bram_to_stool(w: World) -> void:
	var v := village(w)
	var seat := STOOL
	seat.y = v.height(seat.x, seat.z)
	var at := seat + BRAM_FACES * 0.22   # just in front of it (he settles back the rest as he sits)
	at.y = v.height(at.x, at.z)
	var b := Cine.body(w, "bram")
	if b == null:
		return
	w.set_meta("bram_to_stool", true)
	await Cine.path(w, "bram", round_lantern(w, b.global_position, at), 1.5)
	await sit_down(w, "bram", seat, BRAM_FACES, STOOL_H, 0.5)
	w.remove_meta("bram_to_stool")
	w.set_meta("bram_seated", true)


## Into the inn's rooms: the moon and sky shut out (once: going from the
## attic to the taproom doesn't count twice, or outside() would restore the
## inside).
static func go_inside(v: AshfordVillage) -> void:
	if not v.has_meta("outside_env"):
		InnRooms.inside(v)


## The way across the green round the Great Lantern (ashford.gd's).
static func round_lantern(w: World, from: Vector3, to: Vector3) -> Array:
	return w.area.call("_round_lantern", w, from, to)


## The first of `cands` (camera spots) with nothing solid between it and
## `look`, and not inside anything (the people in the shot don't count), or
## the first if none is clear.
static func clear_cam(w: World, cands: Array, look: Vector3, people := ["player", "bram"]) -> Vector3:
	var space := w.get_world_3d().direct_space_state
	var skip: Array[RID] = []
	for who in people:
		var b := Cine.body(w, who)
		if b is CollisionObject3D:
			skip.append((b as CollisionObject3D).get_rid())
	# anyone else standing within a shoulder's width of the line of sight is
	# in the way (the extras have no bodies for the ray to hit, and a
	# villager just under the line still fills the bottom of the shot)
	var extras: Array = []
	var ex: Dictionary = w.get_meta("extras", {})
	for id in ex:
		var eb = ex[id].get("body", null)
		if eb != null and is_instance_valid(eb) and (eb as Node3D).is_visible_in_tree():
			extras.append((eb as Node3D).global_position)
	for n in w.npcs:
		if not (String(n.def.id) in people) and (n.body as Node3D).is_visible_in_tree():
			extras.append((n.body as Node3D).global_position)
	for c: Vector3 in cands:
		if c.y < Cine.ground(w, c) + 0.6:
			continue
		var q := PhysicsRayQueryParameters3D.create(c, look)
		q.exclude = skip
		q.hit_from_inside = true
		if not space.intersect_ray(q).is_empty():
			continue
		var a2 := Vector2(c.x, c.z)
		var b2 := Vector2(look.x, look.z)
		var blocked := false
		for e: Vector3 in extras:
			var e2 := Vector2(e.x, e.z)
			if e2.distance_to(Geometry2D.get_closest_point_to_segment(e2, a2, b2)) < 0.45 and e2.distance_to(b2) > 0.8:
				blocked = true
				break
		if not blocked:
			return c
	return cands[0]


## Cine.two_shot from whichever side of the pair has nothing solid in the way.
static func two_shot(w: World, a_who: String, b_who: String, dist: float, height: float, fov: float) -> void:
	var a := Cine.body(w, a_who).global_position
	var b := Cine.body(w, b_who).global_position
	var mid := (a + b) * 0.5
	var d := b - a
	d.y = 0.0
	var perp := d.normalized().cross(Vector3.UP).normalized()
	var at := clear_cam(w, [mid + perp * dist + Vector3(0, height, 0), mid - perp * dist + Vector3(0, height, 0),
		mid + perp * dist * 0.8 + Vector3(0, height + 0.8, 0), mid - perp * dist * 0.8 + Vector3(0, height + 0.8, 0)],
		mid + Vector3(0, 1.3, 0), [a_who, b_who])
	Cine.shot(w, at, mid + Vector3(0, 1.3, 0), fov)


## Puts someone on a spot, on the ground there (out of a room below the
## village, too), facing `face_to`.
static func put(w: World, who: String, at: Vector3, face_to = null) -> void:
	var b := Cine.body(w, who)
	if b == null:
		return
	if at.y > -20.0:
		at.y = village(w).height(at.x, at.z)
	b.global_position = at
	Cine.place(w, who, at, face_to)


## The camera back behind the player, its lens back to the game's.
static func home(w: World, secs := 0.9) -> void:
	var tw := w.create_tween()
	tw.tween_property(w.cam, "fov", World.CAM_FOV, secs)
	await w.cine_home(secs)


# ============================================================== on the green ===

## The scenes ashford.gd's talk trees call for ({"scene": name}). True if
## the name was one of these.
static func scene(name: String, w: World) -> bool:
	match name:
		"p1_unmute":
			mute_all_but(w, [])
			coach(w).light("")
			Game.set_flag("objective_key", "")
		"bram_stops":
			var st: Array = w.get_meta("p1_stacking", [false, false])
			st[1] = true
			Cine.look(w, "bram", w.player.global_position)
			await Cine.wait(w, 0.7)
		"bram_next_lantern":
			# the player says nothing; he picks up the next lantern
			await Cine.wait(w, 1.6)
			var st2: Array = w.get_meta("p1_stacking", [false, false])
			st2[1] = false
			await Cine.wait(w, 0.9)
		"bram_stars":
			var bf = Cine.fig(w, "bram")
			if bf is Figure3D:
				(bf as Figure3D).hold("look_up", 0.8, 0.4)
				await Cine.wait(w, 3.2)
				(bf as Figure3D).release(0.5)
		"tam_lift":
			await tam_lift(w)
		"tam_carry":
			await use(w, _stall_mark(w), "barrel", 0.0, Vector3.INF, 0.7)
			await tam_carry(w)
		"tam_letter_out":
			await tam_letter_out(w)
		"tam_letter_read":
			await tam_letter_read(w)
		"letter_back":
			await letter_back(w)
		"tam_folds":
			await tam_pockets(w, true)
		"tam_pockets":
			await tam_pockets(w, false)
		"nell_face":
			nell_sit(w)
		"nell_pats":
			await nell_pats(w)
		"nell_sit":
			await sit_with_nell(w)
		"nell_watches":
			await nell_watches(w)
		"nell_stand":
			await nell_stand(w)
		"tilly_up":
			await tilly_up(w)
		"moth_wake":
			await moth_wake(w)
		"tilly_leans":
			await tilly_leans(w)
		"corin_calls":
			await corin_calls(w)
		"corin_glances":
			await corin_glances(w)
		"beat":
			await beat(w, "corin")
		"corin_grin":
			await corin_grin(w)
		"drum_to_player":
			await drum_to(w, true)
		"drum_to_corin":
			await drum_to(w, false)
		_:
			return false
	return true


## A marker over the stall where the barrel goes (what lights up to tap).
static func _stall_mark(w: World) -> Node3D:
	var v := village(w)
	var m: Node3D = meta(v, "p1_stall_mark")
	if m == null:
		m = Node3D.new()
		m.name = "StallMark"
		v.get_meta("p1_root").add_child(m)
		v.set_meta("p1_stall_mark", m)
	m.global_position = v.barrel_spot + Vector3(0, 0.9, 0)
	return m


# ------------------------------------------------------------- Tam's barrel ---

## Tam and the player take an end of the last cider barrel each and lift it
## between them (they carry it once the player taps the stall: tam_carry).
static func tam_lift(w: World) -> void:
	var v := village(w)
	var tam = w._npc_by_id("tam")
	var b: Node3D = v.tam_barrel
	if b == null or tam == null:
		return
	var start := b.global_position - Vector3(0, AshfordVillage.BARREL_HALF, 0)
	var spot := v.barrel_spot
	var dir := spot - start
	dir.y = 0.0
	dir = dir.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	if side.dot(w.cam.global_transform.basis.x) < 0.0:
		side = -side   # the player takes the end nearer the camera's right
	var end := spot - dir * 0.75
	var held := 0.7
	w.cine = true
	# from the side, the barrel and the stall both in the shot (the stall is
	# what the player taps), with nothing solid in the way
	var half := start.lerp(spot, 0.42)
	var back := maxf(5.5, start.distance_to(spot) * 1.1)
	var cam_at := clear_cam(w, [half + side * back + Vector3(0, 2.0, 0), half - side * back + Vector3(0, 2.0, 0),
		half + side * back * 0.8 - dir * 1.5 + Vector3(0, 3.2, 0), half - side * back * 0.8 - dir * 1.5 + Vector3(0, 3.2, 0)],
		half + Vector3(0, 0.9, 0), ["player", "tam"])
	Cine.move(w, cam_at, half + Vector3(0, 0.9, 0), 1.0, 50.0)
	var mine := start + side * held
	var his := start - side * held
	Cine.path(w, "player", [mine], maxf(0.6, w.player.global_position.distance_to(mine) / 0.8))
	await Cine.path(w, "tam", [his], maxf(0.6, tam.body.global_position.distance_to(his) / 0.8))
	w.player_doll.look_toward(start, w.cam)
	tam.doll.look_toward(start, w.cam)
	await Cine.wait(w, 0.25)
	var b0 := b.basis
	var lifted := Basis(dir, PI * 0.5)
	var holds := []
	for who in [[w.player_doll, 1.0], [tam.doll, -1.0]]:
		var f = who[0]
		if f is Figure3D:
			var e: Vector3 = side * float(who[1])
			var grips := []
			for fwd in [1.0, -1.0]:
				var g := Node3D.new()
				g.name = "BarrelGrip"
				b.add_child(g)
				g.position = lifted.inverse() * (e * (AshfordVillage.BARREL_HALF - 0.05) + dir * 0.17 * fwd - Vector3(0, 0.07, 0))
				grips.append(g)
			var left_fwd: bool = (-e).cross(Vector3.UP).dot(dir) < 0.0
			(f as Figure3D).pose("lift", 0.45, 0.35)
			(f as Figure3D).reach(grips[0] if left_fwd else grips[1], grips[1] if left_fwd else grips[0], 0.45)
			holds.append_array(grips)
	if not holds.is_empty():
		await Cine.wait(w, 0.3)
	var tw := w.create_tween().set_parallel(true)
	tw.tween_property(b, "global_position", start + Vector3(0, 0.95, 0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(u: float) -> void: b.basis = Basis(b0.get_rotation_quaternion().slerp(lifted.get_rotation_quaternion(), u)), 0.0, 1.0, 0.5)
	await tw.finished
	for f in [w.player_doll, tam.doll]:
		if f is Figure3D:
			(f as Figure3D).release(0.25)
	w.set_meta("p1_barrel", {"start": start, "end": end, "dir": dir, "side": side, "held": held, "lifted": lifted,
		"holds": holds, "cam_at": cam_at})


## They carry it over to the stall, side by side, and set it down. Tam
## doesn't let go of it straight away.
static func tam_carry(w: World) -> void:
	var v := village(w)
	var tam = w._npc_by_id("tam")
	var b: Node3D = v.tam_barrel
	var s: Dictionary = w.get_meta("p1_barrel", {})
	if b == null or tam == null or s.is_empty():
		return
	w.busy = true
	w.cine = true
	var start: Vector3 = s.start
	var end: Vector3 = s.end
	var dir: Vector3 = s.dir
	var side: Vector3 = s.side
	var held: float = s.held
	var lifted: Basis = s.lifted
	var cam_at: Vector3 = s.cam_at
	var spot := v.barrel_spot
	var secs := maxf(2.2, start.distance_to(end) / 1.7)
	var pace := start.distance_to(end) / secs
	for f in [w.player_doll, tam.doll]:
		if f is Figure3D:
			(f as Figure3D).pace = pace
	w.player_doll.walking = true
	tam.doll.walking = true
	w.player_doll.face(dir, w.cam)
	tam.doll.face(dir, w.cam)
	var pb: Node3D = w.player
	var tb: Node3D = tam.body
	var carry := w.create_tween()
	carry.tween_method(func(u: float) -> void:
		var c := start.lerp(end, u)
		var bob := absf(sin(u * secs * 5.2)) * 0.035
		b.global_position = c + Vector3(0, 0.95 + bob, 0)
		pb.global_position = c + side * held
		tb.global_position = c - side * held, 0.0, 1.0, secs)
	var half := start.lerp(spot, 0.42)
	Cine.drift(w, cam_at, cam_at + dir * 0.6, half + Vector3(0, 0.9, 0), end + Vector3(0, 0.85, 0), secs)
	await carry.finished
	w.player_doll.walking = false
	tam.doll.walking = false
	for f in [w.player_doll, tam.doll]:
		if f is Figure3D:
			(f as Figure3D).pace = 0.0
	# down on its end beside the others; the player lets go as it lands, Tam not yet
	if w.player_doll is Figure3D:
		(w.player_doll as Figure3D).let_go(0.3)
	var up_basis := Basis(Vector3.UP, 0.4)
	var down := w.create_tween().set_parallel(true)
	down.tween_property(b, "global_position", spot + Vector3(0, AshfordVillage.BARREL_HALF + 0.25, 0), 0.35).set_trans(Tween.TRANS_SINE)
	down.tween_method(func(u: float) -> void: b.basis = Basis(lifted.get_rotation_quaternion().slerp(up_basis.get_rotation_quaternion(), u)), 0.0, 1.0, 0.35)
	await down.finished
	var thud := w.create_tween()
	thud.tween_property(b, "global_position", spot + Vector3(0, AshfordVillage.BARREL_HALF, 0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await thud.finished
	v.dust_puff(spot)
	w.shake(0.12)
	w.player_doll.look_toward(tb.global_position, w.cam)
	# Tam's hands stay on the barrel a moment, the camera on him
	var tam_at := tb.global_position + Vector3(0, 1.1, 0)
	Cine.move(w, clear_cam(w, [spot + side * 2.6 + dir * 1.8 + Vector3(0, 1.6, 0), spot + side * 2.6 - dir * 1.8 + Vector3(0, 1.6, 0),
		spot - side * 2.6 - dir * 1.8 + Vector3(0, 1.6, 0), spot - side * 2.6 + dir * 1.8 + Vector3(0, 1.6, 0)], tam_at, ["player", "tam"]),
		tam_at, 0.9, 36.0)
	await Cine.wait(w, 1.6)
	if tam.doll is Figure3D:
		(tam.doll as Figure3D).let_go(0.4)
	for g in s.holds:
		(g as Node).queue_free()
	w.remove_meta("p1_barrel")
	tam.doll.look_toward(pb.global_position, w.cam)
	await Cine.wait(w, 0.4)
	two_shot(w, "player", "tam", 3.4, 1.5, 36.0)


# -------------------------------------------------------------- Tam's letter ---

## He takes the letter out of his shirt pocket and holds it out.
static func tam_letter_out(w: World) -> void:
	var v := village(w)
	var tf = Cine.fig(w, "tam")
	var l = meta(w, "tam_letter")
	if l == null or not is_instance_valid(l):
		l = letter(v)
		w.set_meta("tam_letter", l)
	if tf is Figure3D:
		var f := tf as Figure3D
		var ba = (l as Node3D).get_parent()
		(l as Node3D).get_parent().remove_child(l)
		if ba is BoneAttachment3D:
			(ba as Node).queue_free()
		f.hand_light(l)
		(l as Node3D).position = Vector3(0.0, 0.07, 0.05)
		(l as Node3D).rotation = Vector3(0.0, 0.0, 0.0)
		(l as Node3D).scale = Vector3.ONE
		f.look_toward(w.player.global_position, w.cam)
		f.pose("play_card", 0.45, 0.4)
	else:
		var tb := Cine.body(w, "tam")
		if (l as Node3D).get_parent() != null:
			(l as Node3D).get_parent().remove_child(l)
		tb.add_child(l)
		(l as Node3D).position = Vector3(0.3, 1.1, 0.35)
	await Cine.wait(w, 0.6)


## "Read Tam's letter. (Tap it.)": the player takes it and it's held up to
## the screen; a tap puts it down (still in their hands).
static func tam_letter_read(w: World) -> void:
	var l: Node3D = meta(w, "tam_letter")
	if l == null:
		return
	var tp := Cine.body(w, "tam").global_position
	# from the side, so the letter he holds out is in plain sight
	two_shot(w, "player", "tam", 2.6, 1.35, 34.0)
	await use(w, l, "letter", 0.0, Vector3.INF, 0.28)
	var pf = w.player_doll
	var tf = Cine.fig(w, "tam")
	if pf is Figure3D:
		var me := pf as Figure3D
		var to := Node3D.new()
		w.add_child(to)
		to.global_position = l.global_position
		me.reach(null, to, 0.35)
		await Cine.wait(w, 0.4)
		l.get_parent().remove_child(l)
		if tf is Figure3D:
			(tf as Figure3D).hand_light(null)
			(tf as Figure3D).release(0.35)
		me.carry(l, Vector3(0.0, 1.22, 0.3))
		l.rotation = Vector3(-0.5, 0.0, 0.0)
		me.reach(l.get_node("L"), l.get_node("R"), 0.3)
		to.queue_free()
	Cine.look(w, "player", tp)
	await Cine.wait(w, 0.3)
	await LetterView.read(w.hud._root, LetterView.TAM)


## The player hands the letter back to Tam.
static func letter_back(w: World) -> void:
	var l: Node3D = meta(w, "tam_letter")
	var tf = Cine.fig(w, "tam")
	var pf = w.player_doll
	if l == null or not (tf is Figure3D):
		return
	if pf is Figure3D:
		(pf as Figure3D).let_go(0.3)
	l.get_parent().remove_child(l)
	(tf as Figure3D).hand_light(l)
	l.position = Vector3(0.0, 0.07, 0.05)
	l.rotation = Vector3.ZERO
	(tf as Figure3D).pose("play_card", 0.3, 0.3)
	await Cine.wait(w, 0.4)


## He puts it back in his shirt pocket: folded very small first, if the
## player told him what it says.
static func tam_pockets(w: World, folded: bool) -> void:
	var l: Node3D = meta(w, "tam_letter")
	var tf = Cine.fig(w, "tam")
	if l == null or not (tf is Figure3D):
		return
	var f := tf as Figure3D
	if l.get_parent() == null or not (l.get_parent() is BoneAttachment3D):
		await letter_back(w)
	if folded:
		f.pose("play_card", 0.22, 0.3)
		var tw := w.create_tween()
		tw.tween_property(l, "scale", Vector3(0.7, 0.5, 1.0), 0.5)
		tw.tween_property(l, "scale", Vector3.ONE * 0.45, 0.5)
		await tw.finished
		await Cine.wait(w, 0.3)
	l.get_parent().remove_child(l)
	f.hand_light(null)
	attach(f, "Spine2", l, POCKET, POCKET_ROT)
	f.release(0.4)
	await Cine.wait(w, 0.4)


# -------------------------------------------------------------- Nell's bench ---

## She pats the bench beside her (a 3D Nell's hand on the seat, twice): her
## left hand, across her lap to the near half of the free seat, since her
## right holds her stick (rigid in her hand since 23 October: a right-hand
## pat would push it through the bench and the ground).
static func nell_pats(w: World) -> void:
	var nf = Cine.fig(w, "nell")
	if not (nf is Figure3D):
		return
	var f := nf as Figure3D
	var pat := Node3D.new()
	w.add_child(pat)
	var seat := bench_seat(w, true).lerp(bench_seat(w), 0.3)
	for k in 2:
		pat.global_position = seat + Vector3(0, 0.5, 0) + bench_facing(w) * 0.05
		f.reach(pat, null, 0.3)
		await Cine.wait(w, 0.35)
		var tw := w.create_tween()
		tw.tween_property(pat, "global_position:y", pat.global_position.y - 0.04, 0.12)
		await tw.finished
	f.let_go(0.4)
	pat.queue_free()


## "Sit with Nell. (Tap the bench.)": the seat beside her lights up; the
## player sits down on it.
static func sit_with_nell(w: World) -> void:
	var seat := bench_seat(w, true)
	var fwd := bench_facing(w)
	var mark := Node3D.new()
	village(w).get_meta("p1_root").add_child(mark)
	mark.global_position = seat + Vector3(0, 0.55, 0)
	var side := fwd.cross(Vector3.UP).normalized()
	Cine.shot(w, seat + fwd * 3.4 + side * 1.3 + Vector3(0, 1.3, 0), seat + Vector3(0, 0.7, 0) - side * 0.4, 38.0)
	await use(w, mark, "bench", 0.0, Vector3.INF, 0.6)
	mark.queue_free()
	await Cine.path(w, "player", [seat + fwd * 0.6], 1.3)
	await sit_down(w, "player", seat, fwd, BENCH_H, 0.5)
	await Cine.wait(w, 0.5)
	# side by side, from in front of the bench
	Cine.shot(w, (seat + bench_seat(w)) * 0.5 + fwd * 2.9 + Vector3(0, 1.05, 0), (seat + bench_seat(w)) * 0.5 + Vector3(0, 0.85, 0), 36.0)


## (She watches the dancers for a while.)
static func nell_watches(w: World) -> void:
	var nb := Cine.body(w, "nell")
	if nb == null:
		return
	Cine.shot(w, nb.global_position + bench_facing(w) * 1.9 + bench_facing(w).cross(Vector3.UP) * -0.6 + Vector3(0, 1.05, 0),
		Cine.head(w, "nell") - Vector3(0, 0.06, 0), 32.0)
	await Cine.wait(w, 2.6)
	var seat := bench_seat(w, true)
	var mid := (seat + bench_seat(w)) * 0.5
	Cine.shot(w, mid + bench_facing(w) * 2.9 + Vector3(0, 1.05, 0), mid + Vector3(0, 0.85, 0), 36.0)


## The player gets up off the bench.
static func nell_stand(w: World) -> void:
	var fwd := bench_facing(w)
	await stand_up(w, "player", 0.4)
	var tw := w.create_tween()
	tw.tween_property(w.player, "global_position", bench_seat(w, true) + fwd * 0.75, 0.5).set_trans(Tween.TRANS_SINE)
	await tw.finished
	_solid(w, true)
	await home(w, 0.8)


# ------------------------------------------------------------ Tilly's moth ---

## Tilly, seven, runs up holding her card in both hands.
static func tilly_up(w: World) -> void:
	var v := village(w)
	var tb := Cine.body(w, "tilly")
	var tf = Cine.fig(w, "tilly")
	if tb == null:
		return
	var card: Node3D = meta(w, "tilly_card_node")
	if card == null or not is_instance_valid(card):
		card = w.area.call("_moth_card", v)
		card.set_meta("p1_prop", true)
		w.set_meta("tilly_card_node", card)
		if tf is Figure3D:
			(tf as Figure3D).carry(card, TILLY_HOLD)
			(tf as Figure3D).reach(card.get_node("L"), card.get_node("R"), 0.2)
		else:
			tb.add_child(card)
			card.position = Vector3(0.0, 0.85, 0.25)
		v.glow_sprite(card, Vector3.ZERO, Color(1.0, 0.72, 0.32), 0.3, 0.55).name = "CardGlow"
	var p := w.player.global_position
	var d := tb.global_position - p
	d.y = 0.0
	if d.length() > 1.7:
		w.cine = true
		var dn := d.normalized()
		var sd := dn.cross(Vector3.UP)
		var look := (p + tb.global_position) * 0.5 + Vector3(0, 1.0, 0)
		Cine.move(w, clear_cam(w, [p - dn * 2.6 + sd * 2.4 + Vector3(0, 1.7, 0), p - dn * 2.6 - sd * 2.4 + Vector3(0, 1.7, 0),
			p - dn * 3.2 + Vector3(0, 2.8, 0), p + sd * 3.6 + Vector3(0, 2.0, 0), p - sd * 3.6 + Vector3(0, 2.0, 0)], look, ["player", "tilly"]),
			look, 0.8, 38.0)
		await Cine.path(w, "tilly", [p + d.normalized() * 1.1], 3.2, "run")
	Cine.look(w, "tilly", p)
	Cine.look(w, "player", tb.global_position)
	two_shot(w, "player", "tilly", 3.0, 1.2, 38.0)
## Where a 3D Tilly holds her card, in her own frame (y up, z ahead).
const TILLY_HOLD := Vector3(0.0, 0.74, 0.25)


## "Wake the Lantern Moth. (Tap the card.)" A moth made of lamplight unfolds
## out of the card. It does not go to Tilly: it circles the player, twice,
## and settles on the back of their hand, and only goes back into the card
## when they hand it back to her.
static func moth_wake(w: World) -> void:
	var v := village(w)
	var card: Node3D = meta(w, "tilly_card_node")
	if card == null:
		await tilly_up(w)
		card = w.get_meta("tilly_card_node")
	await use(w, card, "moth", 0.0, Vector3.INF, 0.32)
	w.busy = true
	w.cine = true
	var pf = w.player_doll
	var tb := Cine.body(w, "tilly")
	var p := w.player.global_position
	var to_t := tb.global_position - p
	to_t.y = 0.0
	to_t = to_t.normalized()
	var perp := to_t.cross(Vector3.UP).normalized()
	if perp.dot(w.cam.global_position - p) < 0.0:
		perp = -perp
	var moth_look := p + to_t * 0.5 + Vector3(0, 1.25, 0)
	Cine.move(w, clear_cam(w, [p + to_t * 0.6 + perp * 4.0 + Vector3(0, 1.6, 0), p + to_t * 0.6 - perp * 4.0 + Vector3(0, 1.6, 0),
		p + to_t * 0.6 + perp * 3.2 + Vector3(0, 2.6, 0), p + to_t * 0.6 - perp * 3.2 + Vector3(0, 2.6, 0)], moth_look, ["player", "tilly"]),
		moth_look, 0.8, 40.0)
	# the card glows; the moth unfolds out of it
	var cg := card.get_node_or_null("CardGlow") as Node3D
	if cg != null:
		var gt := w.create_tween()
		gt.tween_property(cg, "scale", cg.scale * 2.0, 0.5).set_trans(Tween.TRANS_SINE)
		await gt.finished
	var cls = w.area.get_script_constant_map().get("LanternMothFlight")
	var moth: Node3D = cls.new()
	w.add_child(moth)
	var from := card.global_position
	moth.global_position = from
	moth.scale = Vector3.ONE * 0.05
	var grow := w.create_tween()
	grow.tween_property(moth, "scale", Vector3.ONE * 1.8, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# twice round the player's head, not hers
	var head := Cine.head(w, "player") + Vector3(0, 0.05, 0)
	var r := 0.75
	var a0 := atan2(to_t.z, to_t.x)
	# their hand comes up, back of it uppermost, for it to land on
	var perch := Node3D.new()
	perch.name = "Perch"
	var me: Figure3D = pf if pf is Figure3D else null
	if me != null:
		me.carry(perch, Vector3(-0.12, 1.12, 0.36))
	else:
		w.player.add_child(perch)
		perch.position = Vector3(0.2, 1.1, 0.35)
	var flight := w.create_tween()
	flight.tween_method(func(u: float) -> void:
		var pos: Vector3
		var ring := head + Vector3(cos(a0) * r, 0.0, sin(a0) * r)
		if u < 0.14:
			var k := u / 0.14
			pos = from.lerp(ring, k * k * (3.0 - 2.0 * k)) + Vector3(0, sin(k * PI) * 0.3, 0)
		elif u < 0.84:
			var k2 := (u - 0.14) / 0.7
			var a := a0 + k2 * TAU * 2.0
			pos = head + Vector3(cos(a) * r, sin(k2 * TAU * 3.0) * 0.12, sin(a) * r)
		else:
			var k3 := (u - 0.84) / 0.16
			var ring2 := head + Vector3(cos(a0) * r, 0.0, sin(a0) * r)
			pos = ring2.lerp(perch.global_position + Vector3(0, 0.06, 0), k3 * k3 * (3.0 - 2.0 * k3))
		moth.fly_to(pos), 0.0, 1.0, 6.5)
	await Cine.wait(w, 4.6)
	if me != null:
		me.reach(null, perch, 0.5)
	await flight.finished
	# it settles; it sits on the back of their hand
	moth.reparent(perch)
	var settle := w.create_tween()
	settle.tween_property(moth, "position", Vector3(0, 0.05, 0), 0.3)
	settle.parallel().tween_property(moth, "scale", Vector3.ONE * 1.4, 0.3)
	Cine.move(w, perch.global_position + perp * 1.3 + to_t * -0.4 + Vector3(0, 0.25, 0), perch.global_position, 0.8, 34.0)
	await Cine.wait(w, 1.8)
	# handed back: their hand over her card, and it goes back in
	var pair := (p + tb.global_position) * 0.5 + Vector3(0, 1.0, 0)
	Cine.move(w, clear_cam(w, [p + to_t * 0.55 + perp * 3.2 + Vector3(0, 1.3, 0), p + to_t * 0.55 - perp * 3.2 + Vector3(0, 1.3, 0),
		p + to_t * 0.55 + perp * 2.6 + Vector3(0, 2.3, 0)], pair, ["player", "tilly"]), pair, 0.8, 38.0)
	var hand_to := card.global_position + Vector3(0, 0.12, 0) - to_t * 0.05
	var over := w.create_tween()
	over.tween_property(perch, "global_position", hand_to, 0.8).set_trans(Tween.TRANS_SINE)
	await over.finished
	moth.reparent(w)
	var back := w.create_tween().set_parallel(true)
	back.tween_property(moth, "global_position", card.global_position, 0.4)
	back.tween_property(moth, "scale", Vector3.ONE * 0.05, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await back.finished
	moth.queue_free()
	if me != null:
		me.let_go(0.4)
	perch.queue_free()
	if cg != null:
		var gt2 := w.create_tween()
		gt2.tween_property(cg, "scale", cg.scale * 0.7, 0.6)
	two_shot(w, "player", "tilly", 3.0, 1.2, 38.0)
	await Cine.wait(w, 0.5)


## The card brightens as the player leans in.
static func tilly_leans(w: World) -> void:
	var card: Node3D = meta(w, "tilly_card_node")
	var tb := Cine.body(w, "tilly")
	if card == null or tb == null:
		return
	var p := w.player.global_position
	var d := tb.global_position - p
	d.y = 0.0
	var lean := w.create_tween()
	lean.tween_property(w.player, "global_position", p + d.normalized() * 0.3, 0.6).set_trans(Tween.TRANS_SINE)
	var cg := card.get_node_or_null("CardGlow") as Node3D
	if cg != null:
		var gt := w.create_tween()
		gt.tween_property(cg, "scale", cg.scale * 1.9, 1.2).set_trans(Tween.TRANS_SINE)
	Cine.move(w, card.global_position + d.normalized().cross(Vector3.UP) * 1.4 + Vector3(0, 0.35, 0), card.global_position, 1.0, 34.0)
	await Cine.wait(w, 1.4)


## Her card goes back in her pocket (before she comes running with it after
## the Lantern Duel: ashford.gd's _tilly_gift makes its own).
static func tilly_card_away(w: World) -> void:
	var card = meta(w, "tilly_card_node")
	if card != null and is_instance_valid(card):
		(card as Node).queue_free()
	w.remove_meta("tilly_card_node")
	var tf = Cine.fig(w, "tilly")
	if tf is Figure3D:
		(tf as Figure3D).let_go(0.0)


# ----------------------------------------------------------------- Corin ---

## Corin calls out and comes over to the player at the Lantern (the
## children round him gather to watch): the two of them face to face, from
## the side.
static func corin_calls(w: World) -> void:
	var cb := Cine.body(w, "corin")
	if cb == null:
		return
	w.cine = true
	var c := cb.global_position
	var d := w.player.global_position - c
	d.y = 0.0
	var dn := d.normalized() if d.length() > 0.01 else Vector3.BACK
	var to := c + dn * 1.6
	to.y = village(w).height(to.x, to.z)
	# the children gather behind him to watch, out of everyone's way
	var aside := dn.cross(Vector3.UP)
	for i in KIDS.size():
		var id := String(KIDS[i][0])
		var kb := Cine.body(w, id)
		if kb == null:
			continue
		var at := c - dn * 1.9 + aside * (float(i) - 1.0) * 1.15 - dn * absf(float(i) - 1.0) * 0.3
		at.y = village(w).height(at.x, at.z)
		_walk_then_look(w, id, at, to)
	if d.length() > 1.9:
		# v7: he comes over to them at the Lantern, twirling his card, and
		# they turn to watch him come
		var p := w.player.global_position
		var meet := p - dn * 1.7
		meet.y = village(w).height(meet.x, meet.z)
		Cine.look(w, "player", c)
		var mid := (p + c) * 0.5
		var sd := dn.cross(Vector3.UP)
		var look := mid + Vector3(0, 1.2, 0)
		Cine.shot(w, clear_cam(w, [p + sd * 3.4 - dn * 0.6 + Vector3(0, 1.8, 0), p - sd * 3.4 - dn * 0.6 + Vector3(0, 1.8, 0),
			p + dn * 3.0 + Vector3(0, 2.4, 0)], look, ["player", "corin"]), (p + meet) * 0.5 + Vector3(0, 1.2, 0), 40.0)
		await Cine.path(w, "corin", round_lantern(w, c, meet), 2.1)
	Cine.look(w, "corin", w.player.global_position)
	Cine.look(w, "player", Cine.body(w, "corin").global_position)
	two_shot(w, "player", "corin", 3.6, 1.5, 36.0)


## Someone walks to `at` and then turns to look at `look` (not waited for).
static func _walk_then_look(w: World, who: String, at: Vector3, look: Vector3) -> void:
	await Cine.path(w, who, [at], 1.6)
	Cine.look(w, who, look)


## He glances at the bakery door, where his mam is watching, and lowers his voice.
static func corin_glances(w: World) -> void:
	var mam := Cine.body(w, "corin_mam")
	if mam != null:
		Cine.look(w, "corin", mam.global_position)
	await Cine.wait(w, 1.0)
	Cine.look(w, "corin", w.player.global_position)
	await Cine.wait(w, 0.3)


## A beat: they look away, and back.
static func beat(w: World, who: String) -> void:
	var b := Cine.body(w, who)
	if b == null:
		await Cine.wait(w, 0.7)
		return
	var p := w.player.global_position
	var away := b.global_position + (b.global_position - p).normalized().rotated(Vector3.UP, 1.1) * 2.0
	Cine.look(w, who, away)
	await Cine.wait(w, 0.8)
	Cine.look(w, who, p)
	await Cine.wait(w, 0.2)


## (He looks at the crowd, then at you, and the grin comes back a beat late.)
static func corin_grin(w: World) -> void:
	var kid := Cine.body(w, "p1_kid_a")
	if kid != null:
		Cine.look(w, "corin", kid.global_position)
	await Cine.wait(w, 1.0)
	Cine.look(w, "corin", w.player.global_position)
	await Cine.wait(w, 0.9)


## The festival drum after the rematch: Corin picks it up and hands it to the
## player ("Evens!"), or picks it up himself ("Two.").
static func drum_to(w: World, player: bool) -> void:
	var v := village(w)
	var dr: Node3D = meta(v, "p1_drum")
	var cf = Cine.fig(w, "corin")
	var cb := Cine.body(w, "corin")
	if dr == null or cb == null:
		return
	w.cine = true
	var back := cb.global_position
	var to_drum := dr.global_position - back
	to_drum.y = 0.0
	Cine.move(w, (back + dr.global_position) * 0.5 + to_drum.normalized().cross(Vector3.UP) * 3.6 + Vector3(0, 1.6, 0),
		(back + dr.global_position) * 0.5 + Vector3(0, 0.9, 0), 0.8, 40.0)
	await Cine.path(w, "corin", [dr.global_position - to_drum.normalized() * 0.55], 1.6)
	if cf is Figure3D:
		(cf as Figure3D).pose("lift", 0.42, 0.3)
		await Cine.wait(w, 0.35)
		(cf as Figure3D).carry(dr, Vector3(0.0, 0.95, 0.38))
		dr.rotation = Vector3(0, PI * 0.5, 0)
		(cf as Figure3D).reach(dr.get_node("L"), dr.get_node("R"), 0.3)
		(cf as Figure3D).release(0.3)
	else:
		dr.reparent(cb)
		dr.position = Vector3(0, 0.95, 0.35)
	dr.set_meta("p1_prop", true)
	await Cine.wait(w, 0.4)
	var p := w.player.global_position
	if not player:
		await Cine.path(w, "corin", [back], 1.5)
		Cine.look(w, "corin", p)
		two_shot(w, "player", "corin", 3.8, 1.5, 36.0)
		return
	# grinning, he brings it over and hands it to them
	var d := p - cb.global_position
	d.y = 0.0
	await Cine.path(w, "corin", [p - d.normalized() * 1.0], 1.5)
	Cine.look(w, "corin", p)
	Cine.look(w, "player", cb.global_position)
	two_shot(w, "player", "corin", 3.4, 1.4, 36.0)
	var pf = w.player_doll
	if pf is Figure3D and cf is Figure3D:
		(pf as Figure3D).reach(dr.get_node("R"), dr.get_node("L"), 0.4)
		await Cine.wait(w, 0.45)
		(cf as Figure3D).let_go(0.3)
		(pf as Figure3D).carry(dr, Vector3(0.0, 0.95, 0.38))
		dr.rotation = Vector3(0, PI * 0.5, 0)
		(pf as Figure3D).reach(dr.get_node("L"), dr.get_node("R"), 0.2)
	await Cine.wait(w, 0.6)
	w.set_meta("p1_drum_held", true)


## The drum goes down by the player's feet (before Tilly comes running).
static func drum_down(w: World) -> void:
	if not w.get_meta("p1_drum_held", false):
		return
	w.set_meta("p1_drum_held", false)
	var v := village(w)
	var dr: Node3D = meta(v, "p1_drum")
	var pf = w.player_doll
	if dr == null:
		return
	var ahead: Vector3 = (pf as Figure3D).facing() if pf is Figure3D else Vector3.BACK
	var at: Vector3 = w.player.global_position + ahead.rotated(Vector3.UP, 1.2) * 0.7
	at.y = v.height(at.x, at.z) + 0.31
	if pf is Figure3D:
		(pf as Figure3D).pose("lift", 0.42, 0.3)
	var tw := w.create_tween()
	tw.tween_property(dr, "global_position", at, 0.4).set_trans(Tween.TRANS_SINE)
	await tw.finished
	dr.reparent(v.get_meta("p1_root"))
	if pf is Figure3D:
		(pf as Figure3D).let_go(0.2)
		(pf as Figure3D).release(0.3)


# ================================================================ watching ===

## While the player is free in Ashford before midnight (Master Script v7:
## AshfordDay.watch, which has Corin call them over, the lane to the mill,
## the sunset and Tilly's run).
static func watch(w: World) -> void:
	AshfordDay.watch(w)
