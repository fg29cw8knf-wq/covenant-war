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
## (m): with their feet clear of it, and near enough to set it down from a
## crouch.
const CRATE_DOWN := 0.66
## How far into the "sit" clip a crouch is (knees bent, back over, hands
## low): putting something down on the ground.
const CROUCH := 0.17
const CRATE_CUT := 0.76            # the model's height (m, as made) above which the lid is left off
## Where the crate rides in the player's arms (their own frame), and where
## their hands go on it.
const CRATE_HOLD := Vector3(0.0, 0.86, 0.34)

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

## How big the lanterns packed in the crate are (the bunting's lantern mesh
## scaled; the ones hung about the green are 0.62).
const PACKED_SCALE := 0.5


## The widest a packed lantern is (m): the mesh's top radius at PACKED_SCALE.
static func paper_lantern_size() -> float:
	return 0.2 * PACKED_SCALE


## A paper lantern (the village's own, as on the bunting), glowing; its
## origin is the ring at its top, where it hangs from. `size` scales the
## body (the bunting's 0.62 by default).
static func paper_lantern(v: AshfordVillage, energy := 1.0, size := 0.62) -> Node3D:
	var n := Node3D.new()
	n.name = "PaperLantern"
	var mat: ShaderMaterial = (v.mats.lantern as ShaderMaterial).duplicate()
	# (unlit by day, lit as the light goes: AshfordVillage.lit_by_night)
	mat.set_shader_parameter("energy", 2.2 * energy * v.night_lamps())
	v.lit_by_night.append([mat, 2.2 * energy])
	var body := v.multimesh(n, v.lantern_mesh(), mat, [Transform3D(Basis().scaled(Vector3.ONE * size), Vector3(0, -0.04 - 0.26 * size, 0))],
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
	# the paper lanterns packed in it, their tops showing (2 November, Gary:
	# "lanterns in the crate show through the crate": Gary's crate's walls
	# are thick, its inside only 0.5 by 0.38 m at this size, and the
	# lanterns, a fifth wider than the ones on the bunting and tipped over up
	# to nine degrees, stood through its sides; they're the bunting's size
	# now, packed inside its walls, and only a touch askew)
	var packed := paper_lantern_size()
	var p_in := Vector2(0.5 * 0.5 - packed * 1.05, 0.38 * 0.5 - packed * 1.05)
	for p in [Vector3(-p_in.x, 0, -p_in.y), Vector3(p_in.x, 0, -p_in.y), Vector3(-p_in.x, 0, p_in.y), Vector3(p_in.x, 0, p_in.y), Vector3(0.0, 0.03, 0.0)]:
		var l := paper_lantern(v, 0.55, PACKED_SCALE)
		l.position = Vector3(p.x, h + 0.06 + p.y, p.z)
		l.rotation = Vector3(v.rng.randf_range(-0.06, 0.06), v.rng.randf() * TAU, v.rng.randf_range(-0.06, 0.06))
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
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
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
	v.house_lights.append(bll)   # (out by day: set_daylight)
	bll.visible = v.night_lamps() > 0.1
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
		AshfordLife.solid(w, String(k[0]), AshfordLife.KID_BODY_R, 1.15)
	var mam := mam_spot(v)
	var md := Cine.spawn(w, "corin_mam", "refugee", mam.at)
	md.look_toward(mam.at + mam.out, w.cam)
	AshfordLife.solid(w, "corin_mam")
	for i in DANCERS.size():
		var a := TAU * i / DANCERS.size()
		Cine.spawn(w, String(DANCERS[i][0]), String(DANCERS[i][1]), DANCE + Vector3(cos(a), 0, sin(a)) * 1.5)
		AshfordLife.solid(w, String(DANCERS[i][0]))
	_dance(w)


## The reel, danced in couples (1 November, Gary: "in Ashford there are 4
## people just walking around in a circle, it makes no sense": they walked
## round and round the spot). Two couples, each pair facing each other and
## dancing (their own dance clip, each at its own moment), turning about
## each other as they go, and the two couples slowly changing places round
## the dancing ground.
## (8 November, Gary: "You can run through the villagers next to Ned": each
## dancer has a body now, AshfordLife.solid, and the reel makes way for the
## player: when a step would bring a dancer into them, the couples' turning
## eases to a stop and they dance on the spot until the player moves, so
## nobody dances through them and nobody shoves them.)
## How far ahead the reel looks for the player (s), and how quickly it eases
## to a stop and back to its pace (1/s).
static var dance_gives_way := true
const DANCE_LOOK := 0.35
const DANCE_EASE := 8.0

static func _dance_at(i: int, t: float) -> Vector3:
	var pair := i / 2
	var side := 1.0 if i % 2 == 0 else -1.0
	var ca := PI * pair + t * 0.16
	var c := DANCE + Vector3(cos(ca), 0, sin(ca)) * 1.35
	var sa := t * 0.7 + pair * 1.3
	return c + Vector3(cos(sa), 0, sin(sa)) * 0.43 * side


static func _dance_mid(i: int, t: float) -> Vector3:
	var ca := PI * (i / 2) + t * 0.16
	return DANCE + Vector3(cos(ca), 0, sin(ca)) * 1.35


## Would the reel, `ahead` s on at its full pace, bring a dancer into the
## player (on the green, not in a room built under it)?
static func _dance_blocked(w: World, t: float, ahead: float) -> bool:
	if w.player == null or not w.player.is_inside_tree():
		return false
	var pp := w.player.global_position
	var clear := 0.35 + AshfordLife.BODY_R + 0.04   # (the player's capsule, a dancer's body, a little)
	for i in DANCERS.size():
		var b := Cine.body(w, String(DANCERS[i][0]))
		if b == null or absf(b.global_position.y - pp.y) > 1.5:
			continue
		for k in 3:
			var q := _dance_at(i, t + ahead * (k + 1) / 3.0)
			if Vector2(q.x - pp.x, q.z - pp.z).length() < clear:
				return true
	return false


static func _dance(w: World) -> void:
	var t := 0.0
	var pace := 1.0
	var started := false
	var v := village(w)
	while is_instance_valid(w) and w.is_inside_tree() and w.has_meta("p1_crowd"):
		var dt := w.get_process_delta_time()
		var want := 0.0 if dance_gives_way and _dance_blocked(w, t, DANCE_LOOK) else 1.0
		pace = lerpf(pace, want, 1.0 - exp(-dt * DANCE_EASE))
		if want == 0.0 and pace < 0.02:
			pace = 0.0
		var step := dt * pace
		# (never a step into them, whatever the easing has left)
		if dance_gives_way and step > 0.0 and _dance_blocked(w, t, step):
			step = 0.0
			pace = 0.0
		t += step
		w.set_meta("dance_pace", pace)
		for i in DANCERS.size():
			var id := String(DANCERS[i][0])
			var b := Cine.body(w, id)
			var f = Cine.fig(w, id)
			if b == null or f == null:
				continue
			var c := _dance_mid(i, t)
			var p := _dance_at(i, t)
			if v != null:
				p.y = v.height(p.x, p.z)
			b.global_position = p
			f.walking = false
			f.face(c - p, w.cam)
			if not started and f is Figure3D:
				var fg := f as Figure3D
				fg.hold("dance", 1.0, 0.3)
				if fg.anim != null and fg.anim.current_animation_length > 0.1:
					fg.anim.seek(fmod(i * 1.37, fg.anim.current_animation_length), true)
		started = true
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
	w.remove_meta("life_through_cine")
	w.remove_meta("corin_coming")
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
			# letter in his vest pocket ("What's that letter tucked into
			# your coat?"): until 25 October both sat on his hand bones and
			# stuck out of his arms (Gary)
			attach(corin, "Hips", card_boxes(v), HIP_BOXES, HIP_BOXES_ROT)
			var cl := letter(v)
			cl.scale = Vector3.ONE * COAT_LETTER_SCALE
			attach(corin, COAT_LETTER_BONE, cl, COAT_LETTER, COAT_LETTER_ROT)
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
## Where his clerkship letter is, folded small, in the upper patch pocket on
## the right of his vest, in the Spine1 bone's own space (x to his left, y
## up, z ahead): stood on end, its top edge two centimetres out of the
## pocket and leant a little out from him, the rest of it down in the
## pocket. (8 November, Gary: "Corin's letter has moved from his pocket to
## his chest": since 25 October it stood inside the vest's neck, a big
## white sheet up by his collar. The pocket's top edge is at y 0.018, where
## the patch stands proud of the vest; tests/corin_letter_probe.tscn finds
## the pocket in his picture and measures the letter through his clips.)
const COAT_LETTER := Vector3(-0.077, 0.006, 0.12)
const COAT_LETTER_ROT := Vector3(0.3, 0.0, -PI * 0.5)
const COAT_LETTER_BONE := "Spine1"
const COAT_LETTER_SCALE := 0.45


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
	return bn.to_global(Vector3(0.4 if east else -0.4, 0.0, BENCH_SIT_FWD))


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
		# her stick stood on the ground by her right knee, clear of the seat
		var fwd := bench_facing(w)
		var foot := bench_seat(w) + fwd * NELL_STICK.y + fwd.cross(Vector3.UP).normalized() * NELL_STICK.x
		foot.y = Cine.ground(w, foot)
		(f as Figure3D).plant_stick(foot, 0.0)
		# her free hand flat on the bench beside her, not hanging down
		# through the seat
		lap_hands(w, "nell", ["left"], 0.0, "at", nell_rest(w))
	else:
		# a cut-out can't sit: she stands at the bench's end
		var bn: Node3D = meta(village(w), "p1_bench")
		if bn != null:
			Cine.place(w, "nell", bn.to_global(Vector3(-1.3, 0, 0.15)), bn.to_global(Vector3(-0.6, 0, 2.5)))


## Where Nell's stick stands while she sits (m from the middle of her half
## of the seat): to her right, and ahead of the seat's front edge.
const NELL_STICK := Vector2(0.22, 0.3)
## How far forward of the seat's middle line people sit on the bench (m):
## a little forward, so Nell's shawl hangs clear of the backrest (it showed
## through its boards from behind).
const BENCH_SIT_FWD := 0.06


## The tops of Bram's stool and Nell's bench (m).
const STOOL_H := 0.46
const BENCH_H := 0.475


## Sits someone on a seat `height` m up (Figure3D.sit()), their hips over
## `at` (the ground under the middle of the seat), facing `fwd`. While the
## player sits they don't collide (the bench is solid, and Nell is beside
## them). A cut-out can't sit: it stands beside the seat.
## `lap`: their hands come to rest on their thighs as they sit (lap_hands:
## a bench, a wall, where hanging arms would go into the seat).
static func sit_down(w: World, who: String, at: Vector3, fwd: Vector3, height: float, blend := 0.45, lap := false) -> void:
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
		# the way anyone sits: standing where the feet will be once they're
		# sat (a shin's length in front of the seat, Figure3D.seat_feet_ahead),
		# the hips go back and down onto the seat as the knees bend, the feet
		# staying put (5 November, Gary: "When you go to sit next to old Nell
		# your legs go through the bench": until then anyone more than a step
		# off glided standing to the seat's middle, straight legs through the
		# boards, and sat there). A longer way to the feet's spot is walked;
		# a short one stepped; then the sit and the shift back are one move
		# (the spot taken for the seat moves with them: `_seat_at`).
		var feet := at + fwd * fig.seat_feet_ahead()
		feet.y = b.global_position.y
		var off := b.global_position.distance_to(feet)
		if off > 0.3:
			await Cine.path(w, who, [feet], 1.1)
		elif off > 0.03:
			var step := w.create_tween()
			step.tween_property(b, "global_position", feet, 0.3).set_trans(Tween.TRANS_SINE)
			await step.finished
		if not is_instance_valid(w) or not is_instance_valid(b):
			return
		Cine.look(w, who, b.global_position + fwd)
		await Cine.wait(w, 0.3)
		var from := b.global_position
		var to := at
		to.y = from.y
		fig.sit(height, blend)
		if lap:
			lap_hands(w, who, ["left", "right"], blend)
		var tw := w.create_tween()
		tw.tween_method(func(k: float) -> void:
			if is_instance_valid(b) and is_instance_valid(fig):
				b.global_position = from.lerp(to, k)
				fig._seat_at = fig.global_position, 0.0, 1.0, blend).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tw.finished
		return
	Cine.place(w, who, at, at + fwd)
	b.global_position = at
	fig.snap_face(fwd)
	fig.sit(height, 0.0)
	if lap:
		lap_hands(w, who, ["left", "right"], 0.0)


## Up off a seat, onto their feet where their feet are: in front of it, the
## body coming forward over them as they rise (29 October, Gary: "after
## duel with Nell your legs go through the bench as you get up": they stood
## up where they sat, hips over the seat, so the legs straightened up
## through it). (The player stays unbumpable until they've stepped clear
## of it: see nell_stand.)
static func stand_up(w: World, who: String, blend := 0.4) -> void:
	var f = Cine.fig(w, who)
	var b := Cine.body(w, who)
	if f is Figure3D:
		var fig := f as Figure3D
		var ahead := fig.seat_feet_ahead() if fig.seat >= 0.0 else 0.0
		var from := b.global_position if b != null else Vector3.ZERO
		var fwd := fig.facing()
		fig.stand(blend)
		if ahead > 0.0 and b != null:
			var to := from + fwd * ahead
			# (on the village's ground; in a room built under it, its floor:
			# Bram got up off his stool in the attic onto the green 40 m
			# overhead, and walked about up there out of every shot)
			to.y = Cine.ground(w, to) if Cine._on_terrain(w, b) else from.y
			var tw := w.create_tween()
			tw.tween_property(b, "global_position", to, blend).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
## `stray` is called with a zone's name when the player walks into one of
## the room's stray zones (see below), if it takes an argument; a `stray`
## that takes none is called for the stairs alone (as before 2 November).
## How soon the same stray zone speaks again once they've left it (s).
const STRAY_AGAIN := 3.0

static func walk_room(w: World, room: Dictionary, cam_at: Vector3, done: Callable, follower := "", stray := Callable()) -> void:
	var root: Node3D = room.root
	var floor_y := float(room.floor_y)
	var target = [null]
	# "stairs_zone": a patch of floor (the foot of the stairs) where `stray` is
	# called when the player walks into it, once, and again if they come back;
	# they're stopped and turned back a step while whoever it is says so.
	# "stray_zones" (2 November: the taproom's two open doorways, Gary: "if
	# player tries to walk through either of the open doors have a message
	# pop up"): more of the same, each {"name", "rect", "back"}, `back` the
	# way (in the room's x/z) they're turned back a step, named to `stray`
	var zones: Array = []
	if room.has("stairs_zone"):
		var sz: Rect2 = room.stairs_zone
		zones.append({"name": "stairs", "rect": sz, "back": Vector2(0, -1)})
	for z in room.get("stray_zones", []):
		zones.append(z)
	var in_zone := ""
	# when each zone last spoke (by name): a zone speaks again once its
	# STRAY_AGAIN has passed, and another zone speaks whenever it's entered
	# (5 November, Gary: "Bram doesn't try and stop you when you approach
	# the second door to the right of the fireplace": one clock served every
	# zone, so going from the kitchen's doorway to the passage's within six
	# seconds, a two-second walk, met silence at the second)
	var strayed_at := {}
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
		# (a thing in the room tapped from further off, a Use with reach: it
		# asks the world to walk the player there, and in here that's ours)
		if w._move_target != null:
			target[0] = w._move_target
			w._move_target = null
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
		if not zones.is_empty() and stray.is_valid():
			var lp := root.to_local(np)
			var here := ""
			var hit: Dictionary = {}
			for z in zones:
				if (z.rect as Rect2).has_point(Vector2(lp.x, lp.z)):
					here = String(z.name)
					hit = z
					break
			if here != "" and here != in_zone and clock - float(strayed_at.get(here, -100.0)) > STRAY_AGAIN:
				strayed_at[here] = clock
				target[0] = null   # (they stop: the way's wrong)
				held_until = clock + 1.6
				if stray.get_argument_count() > 0:
					stray.call(here)
				elif here == "stairs":
					stray.call()
				# a step back out of it, facing the room again
				var rect: Rect2 = hit.rect
				var dir: Vector2 = (hit.back as Vector2).normalized()
				var edge := Vector2(rect.get_center().x if dir.x == 0.0 else (rect.position.x if dir.x < 0.0 else rect.end.x),
					rect.get_center().y if dir.y == 0.0 else (rect.position.y if dir.y < 0.0 else rect.end.y))
				var back2 := edge + dir * 0.45
				var out_at := root.to_global(Vector3(back2.x, 0.0, back2.y))
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
	for pr in v.props_placed + Cine.blockers_at(w, at.y):
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
	# (2 November, Gary: say who left it: it's the player he's telling off)
	{"who": "bram", "say": "You left the shutter unlatched again, Sprout. Cold air costs firewood, wood costs coin, and coin is the one thing nobody in Ashford has enough of today."},
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
## If they head through the kitchen's or the back passage's doorway (2
## November, Gary): with the crate, their own thought; before it, Bram.
const DOORS_LATER := "[i]I need to get these lanterns to the green first.[/i]"
const DOORS_FIRST := "Not through there, Sprout. The crate. Corner by the door."
## If they head off down the lane to Tam's mill with the crate still in their
## arms (1 November, Gary: "the game glitches: make it so Bram stops you and
## reminds you where to go"). Bram calls them back, they turn round, and he
## says where the crate goes.
const LANE_TOO_SOON := [
	{"who": "bram", "say": "Oi! Not that way, Sprout. Tam's mill can wait."},
	{"who": "bram", "say": "Lanterns first. The green: the big pole in the middle of it. Then you can go where you like."},
]
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
## The Night of the White Sky (WhiteSky, 3 November) in place of the dream;
## false puts the five seconds of stars back.
const MEMORY := true
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
	# (the green as the opening left it: Ashford.resume, which World calls
	# straight after intro() on a New Game, mustn't stage it again)
	w.set_meta("p1_opened", true)
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
	if MEMORY and _memory_wanted(w):
		# The Night of the White Sky (3 November, Gary): twenty years ago in
		# the Shardlands, Bram finds the child and duels the faceless hunter
		# for it; Morrowen's line is spoken over its sky. It ends on black.
		var m := WhiteSky.new()
		m.w = w
		w.add_child(m)
		# the village isn't drawn under it (the memory has a 3D view of its
		# own, and a phone shouldn't draw both)
		var vp := w.get_viewport()
		vp.disable_3d = true
		await m.play()
		ov.black(true)
		vp.disable_3d = false
		m.queue_free()
		await Cine.caption(w, "Ashford", "The last night of the Age.", 2.4)
		if not w.music.is_empty():
			Music.play(w.music, 4.0, true)
	else:
		await Cine.caption(w, "Ashford", "The last night of the Age.", 2.4)
	var memory := MEMORY and _memory_wanted(w)
	# the dream they're about to tell Bram about: the night sky from the
	# bed, Morrowen's words over it, and the white light that takes it; cut
	# to black on the drum (until 3 November: the memory takes its place)
	if not memory and DREAM_SECS > 0.0:
		await _dream(w, ov)
		# Morrowen speaks alone over the sky; the village's music comes in
		# softly as he wakes (Ashford.quiet_start held it back till now)
		if not w.music.is_empty():
			Music.play(w.music, 4.0, true)
	# (25 October, Gary: getting out of bed "a little bit faster": the whole
	# rise, from the fade-up to standing, is about seven seconds now where
	# it was twelve; each movement is the same, just brisker. 8 November,
	# Gary: "Bed scene looks much better, can we now make it slightly faster":
	# a quarter off again, RISE_STIR to STRETCH_SECS, every movement the same)
	await Cine.wait(w, 0.2)
	if memory:
		# the mark under his collar still glowing from the dream, fading as
		# he comes round (it was the mark that showed him the night)
		SealMark.blaze(w, 0.45, 0.01)
		w.get_tree().create_timer(0.9, false).timeout.connect(func() -> void:
			if is_instance_valid(w):
				SealMark.blaze(w, 0.0, 2.2))
		w.get_tree().create_timer(3.4, false).timeout.connect(func() -> void:
			if is_instance_valid(w):
				SealMark.show_on(w, false))
	Cine.fade(w, 0.0, 1.0)
	Cine.drift(w, root.to_global(Vector3(2.45, 1.6, 1.3)), root.to_global(Vector3(2.15, 1.5, 1.1)),
		a.bed + Vector3(0.2, 0.15, 0.0), a.bed + Vector3(0.3, 0.2, 0.2), 2.4, 46.0)
	await Cine.wait(w, RISE_STIR)
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
			# (2 November, Gary: the arms "deform in unnatural way": the hand
			# was sent to the hem's corner and then to the corner's place in
			# the heap by the wall, up and over on a high arc, and where that
			# was beyond the arm the arm stood straight up like a pole; the
			# hand now goes only as far as the arm reaches from the shoulder
			# he's lying on, low across his chest, and the cloth follows the
			# hand as far as it goes and settles the rest of the way itself)
			await throw_blanket(w, fig, a, hand, BLANKET_SECS)
			if not rise_clip:
				var down := w.create_tween()
				down.tween_property(hand, "global_position", on_mattress, 0.25).set_trans(Tween.TRANS_SINE)
				await down.finished
		elif not rise_clip:
			hand.global_position = on_mattress
			fig.reach(null, hand, 0.3)
			await Cine.wait(w, 0.2)
		if rise_clip:
			await _rise_from_bed(w, fig, a)
			if is_instance_valid(hand):
				hand.queue_free()
			# a step on from the bed, to where he turns to the window
			var step := w.player.global_position.lerp(side, 0.5)
			step.y = (a.bed_side as Vector3).y
			await Cine.path(w, "player", [step], 0.8)
		if not rise_clip:
			await _rise_by_poses(w, fig, a, side)
		if is_instance_valid(hand):
			hand.queue_free()
	else:
		var tw := w.create_tween()
		tw.tween_property(w.player, "global_position", Vector3(side.x, side.y, side.z), 0.7).set_trans(Tween.TRANS_SINE)
		await tw.finished
	Cine.look(w, "player", a.window)
	# (1 November, Gary: the getting up "looking a lot better ... can we
	# improve it any more so it looks more real and natural"): on his feet,
	# a slow stretch, both arms up over his head and back down, as anyone
	# does first thing (2 November: the arms turned at the shoulders by a
	# clip of their own, Figure3D.stretch, not reached up after targets)
	if pf is Figure3D:
		await (pf as Figure3D).stretch(STRETCH_SECS)
	await Cine.wait(w, 0.2)
	# the first lesson: walking, to the washbasin, on their own feet
	controls_on(w)
	w.hud._menu_btn.visible = false   # (the pause square is taught at the door)
	coach(w).objective("basin")
	var stand: Vector3 = a.mirror_stand
	# the camera comes along behind them, under the collar beams (4 November,
	# Gary: "when you walk towards mirror it cuts player out due to stairs
	# leading up, character should stay in view": from its corner up by the
	# roof, the beams stepping away across the room came between it and
	# him as he crossed to the glass)
	a["cam_follow"] = func(p: Vector3) -> Vector3:
		var lp := root.to_local(p)
		return root.to_global(Vector3(clampf(lp.x - 2.4, -2.55, 0.3), 1.62, clampf(lp.z + 1.0, 0.6, 1.35)))
	await walk_room(w, a, root.to_global(Vector3(-2.35, 1.62, 1.35)), func(p: Vector3) -> bool:
		return Vector2(p.x - stand.x, p.z - stand.z).length() < 0.8)
	a.erase("cam_follow")
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


## The sleeper's right hand takes the blanket's hem by them and throws it
## back across them to the wall, the cloth following the hand (BlanketThrow),
## the hand kept within the arm's reach. `hand` is the hand's target, left
## where the throw ends and still reached for (let_go() to give the arm
## back). Used by the morning's rise and by the wake after the white light
## (6 November, Gary: "When you wake up in bed after the white card you're
## not under the covers, your body is half way through them": there he sat
## up and swung his legs out through a blanket that never moved).
static func throw_blanket(w: World, fig: Figure3D, a: Dictionary, hand: Node3D, secs := 0.8) -> void:
	var bl: Node3D = a.blanket
	if not (bl is MeshInstance3D and bl.has_meta("rows")):
		return
	var corner := _hand_can(fig, "right", BlanketThrow.corner_of(bl))
	hand.global_position = corner
	# (8 November: the hand finds the hem a little quicker, morning and
	# midnight both; the throw's own `secs` is each scene's)
	fig.reach(null, hand, 0.3)
	await Cine.wait(w, 0.2)
	var bt := BlanketThrow.start(bl, a.blanket_off, hand, secs)
	var to := _hand_can(fig, "right", BlanketThrow.corner_in_heap(bl, a.blanket_off))
	var sweep := w.create_tween()
	sweep.tween_method(func(u: float) -> void:
		hand.global_position = _hand_can(fig, "right", corner.lerp(to, u) + Vector3(0, sin(u * PI) * 0.1, 0)), 0.0, 1.0, secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await sweep.finished
	bt.let_go()


## `to` pulled back towards a hand's own shoulder (the upper arm bone, wherever
## the body is: lying, sitting or standing) until the arm can get there with
## the elbow still a little bent, so a hand sent after something never
## straightens the arm out at it. (_in_reach does the same from a standing
## figure's frame; this reads the shoulder itself, so it holds lying down.)
static func _hand_can(f: Figure3D, side: String, to: Vector3) -> Vector3:
	var sh := f.bone_pos(("Left" if side == "left" else "Right") + "Arm")
	var d := to - sh
	var most := f.arm_reach() * 0.9
	if d.length() > most:
		return sh + d.normalized() * most
	return to


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
## The memory plays in the game, and in a test only when the test asks for it
## (test_memory: tests/ashford_test.gd plays it; the attic's own stills and
## checks start from the attic as they always have).
static var test_memory := false


static func _memory_wanted(w: World) -> bool:
	var sc := w.get_tree().current_scene
	if sc != null and String(sc.scene_file_path).begins_with("res://tests/"):
		return test_memory
	return true


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
	fig.sit_long(a.lie_top, 0.8)
	await Cine.wait(w, 0.85)
	# sat up: a breath, then he slides to the edge and turns to face it,
	# his legs still out along the mattress (they swing down only once
	# they're over the edge: nothing goes through the bed), the hand
	# coming off the mattress as he does
	await Cine.wait(w, 0.15)
	await fig.shift_seat(a.edge_at, Vector3.BACK, 0.65, 0.05)
	fig.sit(a.edge_top, 0.5)
	fig.let_go(0.5)
	await Cine.wait(w, 0.4)
	# a moment on the edge, then up and away from it
	await Cine.wait(w, 0.1)
	fig.stand(0.6)
	var tw := w.create_tween()
	tw.tween_property(w.player, "global_position", Vector3(side.x, side.y, side.z), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
	# (2 November, Gary: he "goes through objects more": the feet swung round
	# over the side through the bed's rail and the straw, the clip's legs
	# being made for a lower bed; and the body jumped up a hand's breadth on
	# the first frame, the lift onto the mattress coming all at once) the
	# lift comes in over the clip's blend-in, and the seat rises a little
	# as the legs come round, so the feet clear the rail, and settles again
	# as they come down
	var blend := 0.35
	var extra := func(t: float) -> Vector3:
		var slide := smoothstep(1.3, 2.5, t)
		# (the lift over LIFT_IN seconds of the world's time: `t` is the
		# clip's own seconds, so it's scaled to the clip's pace; a shade
		# under the blend-in, so the hips never dip as the lying pose gives
		# way to the clip's lower one)
		var y := lerpf(lie_off * smoothstep(0.0, LIFT_IN * RISE_SPEED, t), edge_off, slide)
		y += SWING_LIFT * sin(PI * clampf((t - 1.45) / 1.05, 0.0, 1.0))
		y = lerpf(y, 0.0, smoothstep(3.1, 4.0, t))
		return to_edge * slide + Vector3(0, y, 0)
	await fig.play_rooted("get_out_of_bed", true, RISE_SPEED, extra, blend)
	fig.release(0.3)


## How far the seat rises as the legs swing round over the bed's side (m):
## enough for the feet to clear the rail and the straw at the mattress's
## edge, most as they cross it.
const SWING_LIFT := 0.13
## The rise's pace (8 November, Gary: "Bed scene looks much better, can we
## now make it slightly faster"): a quarter off the whole, from the fade-up
## to the controls coming on (tests/bed_probe.gd times it: 9.8 s before,
## 7.3 after), each movement kept and only brisker. From the fade-up to his
## hand going to the blanket's hem (s; was 1.4); the blanket's throw (s; was
## 0.8: the midnight waking's is its own, AshfordNight.awakening); the
## get_out_of_bed clip's speed (was 1.15); the stretch on his feet (s; was
## 2.8).
const RISE_STIR := 0.9
const BLANKET_SECS := 0.6
const RISE_SPEED := 1.6
const STRETCH_SECS := 2.0
## How long the lift onto the mattress takes as the clip comes in (s).
const LIFT_IN := 0.28
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
	# a fingertip to the frost, where the name will start
	_finger_to_frost(w, a, hand, -0.06, 0.35)
	var nm := await Cine.overlay(w).ask_name("Write your name in the frost.", "Ash")
	Game.player_name = nm
	await _write_in_frost(w, a, hand, nm)
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


## Writing in the frost (5 November, Gary: "When you write player's name on
## mirror can we make that look better, at the moment it looks like they
## just wave their hand in front"): the hand had slid once across the glass
## while the whole name faded up at once. Now the hand is turned so its
## fingers point at the glass and the palm faces in and down, the
## fingertips on the frost (the palm a finger's length short of it,
## WRITE_FINGER); each letter comes up in turn under the fingertip as it
## travels along the line, the finger rising and dipping over each the way
## a hand writing does, from the left of the name to its right; a letter is
## the frost cleared dark, the glass showing through it, with a bright rim
## of pushed frost round it (one Label3D a letter, left-aligned where that
## letter falls in the name; the name's own label takes over once it's
## written); and a faint squeak of skin on cold glass with each letter
## (Sfx "frost_write").
## A letter of average width takes this long (s); the fingertip's rise and
## dip over a letter (m); how far the palm's middle stands short of the glass
## (m: the fingers' length, straight).
const WRITE_LETTER_SECS := 0.28
const WRITE_WIGGLE := 0.022
const WRITE_FINGER := 0.095
## The letters: the frost cleared to the dark glass, and the frost's rim.
const WRITE_INK := Color(0.1, 0.12, 0.17)
const WRITE_RIM := Color(0.93, 0.96, 1.0)
const WRITE_RIM_SIZE := 7


## The hand as a writing hand, its fingertip on the frost `along` the name's
## line (m from the glass's middle, + to the viewer's right), eased in over
## `secs`. `hand` is the palm's mark (reached for by the right hand).
static func _finger_to_frost(w: World, a: Dictionary, hand: Node3D, along: float, secs: float) -> void:
	var pf = w.player_doll
	var oval: Node3D = a.mirror_node
	var writing: Label3D = a.writing
	var glass_at: Vector3 = a.mirror
	var to_player := w.player.global_position - glass_at
	to_player.y = 0.0
	to_player = to_player.normalized()
	hand.global_position = _frost_tip(oval, writing, along, 0.0) + to_player * WRITE_FINGER
	if pf is Figure3D:
		var fig := pf as Figure3D
		# the palm in towards the body and down, the fingers at the glass
		var left := Vector3.UP.cross(-to_player).normalized()
		fig.palm("right", (Vector3.DOWN * 0.75 + left * 0.65).normalized(), secs, 1.0, false, -to_player)
		fig.reach(null, hand, secs)


## A point on the frost on the name's line: `along` m from the glass's
## middle (+ to the viewer's right, the way the name reads), `rise` m up.
## (The hand's mark sits WRITE_HAND_UP over the line: Player A's hand is a
## loose fist, its fingers kept as he modelled them, and it's the knuckles
## that touch the glass, a little under the mark.)
const WRITE_HAND_UP := 0.02

static func _frost_tip(oval: Node3D, writing: Label3D, along: float, rise: float) -> Vector3:
	# (the name's label runs along the oval's own z; its y is scaled)
	return oval.to_global(writing.position + Vector3(0.0, 0.0, along)) + Vector3(0, rise + WRITE_HAND_UP, 0)


static func _write_in_frost(w: World, a: Dictionary, hand: Node3D, nm: String) -> void:
	var pf = w.player_doll
	var oval: Node3D = a.mirror_node
	var writing: Label3D = a.writing
	var glass_at: Vector3 = a.mirror
	var to_player := w.player.global_position - glass_at
	to_player.y = 0.0
	to_player = to_player.normalized()
	var font: Font = writing.font if writing.font != null else ThemeDB.fallback_font
	var fs := writing.font_size
	var px := writing.pixel_size
	# where each letter falls along the line, from the name's middle
	var total := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * px
	var edges: Array = []   # [left, width] a letter
	for i in nm.length():
		var l := font.get_string_size(nm.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * px
		var r := font.get_string_size(nm.substr(0, i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * px
		edges.append([l - total * 0.5, maxf(0.002, r - l)])
	var avg := total / maxf(1.0, float(nm.length()))
	var letters: Array = []
	for i in nm.length():
		var lb := Label3D.new()
		lb.text = nm[i]
		lb.font = writing.font
		lb.font_size = fs
		lb.pixel_size = px
		# (a Label3D's line is centred on its origin whatever its alignment:
		# each letter is put at its own middle)
		lb.modulate = Color(WRITE_INK, 0.0)
		lb.outline_modulate = Color(WRITE_RIM, 0.0)
		lb.outline_size = WRITE_RIM_SIZE
		lb.double_sided = false
		lb.shaded = false
		oval.add_child(lb)
		lb.position = writing.position + Vector3(0.0, 0.0, float(edges[i][0]) + float(edges[i][1]) * 0.5)
		lb.rotation = writing.rotation
		lb.scale = writing.scale
		letters.append(lb)
	var sfx := Sfx.new()
	w.add_child(sfx)
	# to the start of the name
	var start := _frost_tip(oval, writing, float(edges[0][0]), 0.0) + to_player * WRITE_FINGER
	var go := w.create_tween()
	go.tween_property(hand, "global_position", start, 0.25).set_trans(Tween.TRANS_SINE)
	await go.finished
	var rng := RandomNumberGenerator.new()
	rng.seed = nm.hash()
	for i in nm.length():
		if not is_instance_valid(w) or not is_instance_valid(hand):
			break
		var left := float(edges[i][0])
		var wd := float(edges[i][1])
		var lb: Label3D = letters[i]
		var is_space := nm[i] == " "
		var secs := WRITE_LETTER_SECS * clampf(0.55 + 0.6 * wd / maxf(avg, 0.001), 0.5, 1.6)
		if is_space:
			secs *= 0.5
		else:
			sfx.play("frost_write", rng.randf_range(0.9, 1.15))
		# the stroke: along the letter, up and down over it (a letter has its
		# own number of ups and downs, two or three)
		var waves := 2.0 + float(rng.randi_range(0, 1))
		var phase := rng.randf_range(0.0, TAU)
		var tw := w.create_tween()
		tw.tween_method(func(u: float) -> void:
			if not is_instance_valid(hand) or not is_instance_valid(oval):
				return
			var rise := 0.0 if is_space else sin(u * PI * waves + phase) * WRITE_WIGGLE
			# (off the glass a little between letters)
			var off := (1.0 - sin(u * PI)) * 0.012
			hand.global_position = _frost_tip(oval, writing, left + wd * u, rise) + to_player * (WRITE_FINGER + off)
			if is_instance_valid(lb):
				var k := clampf(u * 1.5, 0.0, 1.0)
				lb.modulate.a = 0.94 * k
				lb.outline_modulate.a = 0.9 * k, 0.0, 1.0, secs)
		await tw.finished
	# the name's own label takes over from the letters, the hand comes away
	writing.text = nm
	writing.modulate = Color(WRITE_INK, 0.94)
	writing.outline_modulate = Color(WRITE_RIM, 0.9)
	writing.outline_size = WRITE_RIM_SIZE
	for lb in letters:
		if is_instance_valid(lb):
			(lb as Node).queue_free()
	if is_instance_valid(sfx):
		sfx.queue_free()
	if pf is Figure3D and is_instance_valid(hand):
		var fig := pf as Figure3D
		var away := w.create_tween()
		away.tween_property(hand, "global_position", hand.global_position + to_player * 0.12 - Vector3(0, 0.08, 0), 0.35).set_trans(Tween.TRANS_SINE)
		await away.finished
		fig.let_go(0.4)
		fig.palm("right", Vector3.ZERO, 0.4)


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
	# the frosty morning, before the attic's window and the taproom's doorway
	# take their pictures of the village (4 November, Gary: "when door opens
	# in tavern before you walk out with crate it shows it as night outside
	# but then you walk out into day": the village is built as the festival
	# night, opening() turns the day on, and under the title screen the two
	# views were taken here, first, by night)
	v.set_daylight(1.0)
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
	# (on a side table, not the floor: from the floor the hands couldn't get
	# down to its sides without a squat the lift doesn't have, and the arms
	# stretched; Gary, 1 November: "when the player picks up the lantern it
	# looks weird")
	if not e.has("crate_stand"):
		e["crate_stand"] = _crate_stand(v, root, root.to_local(corner), 0.25)
		var lc := root.to_local(corner)
		(e.blocks as Array).append([Vector2(lc.x, lc.z), 0.48])
	cr.global_position = corner + Vector3(0, CRATE_STAND_H, 0)
	cr.rotation = Vector3(0, 0.25, 0)
	# breakfast on the bar
	if not e.has("porridge"):
		var bowl := Node3D.new()
		bowl.name = "Porridge"
		root.add_child(bowl)
		# (near the counter's front edge, where a hand reaches it from the
		# room: 2 November, it's eaten; 9 November, its rim a hand's width
		# in from the edge, BOWL_IN: 22 cm in, it was out of Player A's reach
		# and his arm went out straight to it)
		bowl.position = Vector3(InnRooms.BAR_X + 0.425 - BOWL_IN, 1.13, 0.55)
		v.cyl(bowl, 0.09, 0.06, 0.06, Vector3(0, 0.03, 0), v.mats.wood_h, 14)
		var oats := StandardMaterial3D.new()
		oats.albedo_color = Color(0.86, 0.8, 0.66)
		oats.roughness = 0.9
		v.cyl(bowl, 0.08, 0.08, 0.005, Vector3(0, 0.058, 0), oats, 14).name = "Oats"
		var sp := v.box(bowl, Vector3(0.015, 0.008, SPOON_LEN), Vector3(0.05, 0.065, 0.02), v.mats.wood, Vector3(0, 0.4, 0.15))
		sp.name = "Spoon"
		# its bowl: a flat oval at the +z end, the end that goes to the mouth
		# (8 November: a bare stick read as nothing in the hand)
		var sb := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.017
		sm.height = 0.011
		sm.radial_segments = 12
		sm.rings = 6
		sb.mesh = sm
		sb.material_override = v.mats.wood
		sb.position = Vector3(0, 0.002, SPOON_LEN * 0.5 - 0.014)
		sb.scale = Vector3(1.0, 1.0, 1.35)
		sp.add_child(sb)
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
	# the crate from the corner: walk to it and take it; or the porridge
	# first, from the bar (2 November, Gary: "should have option to eat the
	# porridge on the side and have character eat if they want"): the bowl
	# glows too, and a tap on it (walking up to the bar) eats it
	controls_on(w)
	w.hud._menu_btn.visible = false
	coach(w).objective("take_crate" if Game.flag("p1_ate") else "crate_or_eat")
	# the wrong way: up the stairs, or through the kitchen's or the back
	# passage's doorway (2 November, Gary: "if player tries to walk through
	# either of the open doors have a message pop up (I need to get these
	# lanterns to the green first)"): with the crate in their arms it's their
	# own thought; before that, Bram
	var stray := func(zone: String) -> void:
		if zone == "stairs":
			Cine.look(w, "bram", w.player.global_position)
			w.hud.dialogue.bark(w._speaker("bram"), w._portrait("bram"), WRONG_WAY)
		elif w.has_meta("p1_crate"):
			w.hud.dialogue.bark(w._speaker("player"), w._portrait("player"), DOORS_LATER)
		else:
			Cine.look(w, "bram", w.player.global_position)
			w.hud.dialogue.bark(w._speaker("bram"), w._portrait("bram"), DOORS_FIRST)
	var eat := [false]
	var bowl_use: Use = null
	var bowl_glow: Node3D = null
	if not Game.flag("p1_ate"):
		var bowl: Node3D = e.porridge
		bowl_glow = light_up(v, bowl, Vector3(0, 0.05, 0), 0.3)
		bowl_use = Use.new()
		bowl_use.w = w
		bowl_use.target = bowl
		bowl_use.reach = 1.1
		bowl_use.stand = root.to_global(Vector3(InnRooms.BAR_X + 0.75, 0, 0.55))
		bowl_use.glow = bowl_glow
		w.add_child(bowl_use)
		bowl_use.used.connect(func() -> void: eat[0] = true)
	while true:
		await walk_room(w, e, root.to_global(Vector3(0.2, 2.6, 2.6)), func(p: Vector3) -> bool:
			return eat[0] or Vector2(p.x - corner.x, p.z - corner.z).length() < 1.15, "", stray)
		if not is_instance_valid(w) or not w.is_inside_tree():
			return
		if not eat[0]:
			break
		eat[0] = false
		if is_instance_valid(bowl_use):
			bowl_use.queue_free()
		if is_instance_valid(bowl_glow):
			bowl_glow.queue_free()
		await _eat(w, e)
		controls_on(w)
		w.hud._menu_btn.visible = false
		coach(w).objective("take_crate")
	if is_instance_valid(bowl_use):
		bowl_use.queue_free()
	if is_instance_valid(bowl_glow):
		bowl_glow.queue_free()
	await use(w, cr, "take_crate", 0.0, Vector3.INF, 0.55)
	await _take_crate(w, cr)
	# to the door with it
	controls_on(w)
	w.hud._menu_btn.visible = false
	coach(w).objective("green_crate")
	var door_in: Vector3 = e.door_in
	# (8 November, Gary: "Door passes through player when it opens before
	# leaving inn": the walk ended anywhere within a stride of the door, and
	# the leaf, hung on the east jamb and opening into the room, swung
	# through them and the crate. The walk ends within a stride of the door
	# or at the stand's circle; they're walked the last step to door_stand,
	# back out of the leaf's swing, and only step off once the leaf is past
	# square to the wall)
	var door_stand: Vector3 = e.door_stand
	await walk_room(w, e, root.to_global(Vector3(-0.6, 2.7, 2.6)), func(p: Vector3) -> bool:
		# (within a stride of the door as before, or near the stand: coming
		# up the room they reach the stand's circle first and walk the last
		# half step on to it. Both are small: the crate's corner is a stride
		# east of the door, and a patch across the door's front ended the
		# walk as they set off from it towards the stairs)
		return Vector2(p.x - door_in.x, p.z - door_in.z).length() < 0.85 \
			or Vector2(p.x - door_stand.x, p.z - door_stand.z).length() < 0.45, "", stray)
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	# at the door: the camera comes round to the door's side of the room as
	# they take the last step to the stand; then the menu, in brackets, as
	# the pause square glows
	w.hud.set_controls_visible(false)
	Cine.move(w, root.to_global(DOOR_CAM), door_stand + Vector3(0, 1.25, 0), 0.8, 44.0)
	if Vector2(w.player.global_position.x - door_stand.x, w.player.global_position.z - door_stand.z).length() > 0.08:
		await Cine.path(w, "player", [door_stand], 1.2)
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	w.hud._menu_btn.visible = true
	Cine.look(w, "player", door_in + Vector3(0, 0, -1.0))
	coach(w).light("menu", 3.2)
	await w.run_steps(AT_DOOR, null)
	w.hud.dialogue.close()
	coach(w).light("")
	# out into the morning: the leaf swings open (DOOR_SWING), and they step
	# off once it's past square to the wall (DOOR_STEP_OFF), so they're
	# through the doorway with it open
	var door: Node3D = e.door
	var sw := w.create_tween()
	sw.tween_property(door, "rotation:y", deg_to_rad(100.0), DOOR_SWING).set_trans(Tween.TRANS_SINE)
	await Cine.wait(w, DOOR_STEP_OFF)
	Cine.path(w, "player", [e.door_out], 1.4)
	await Cine.wait(w, 0.9)
	await Cine.fade(w, 1.0, 0.7)
	door.rotation.y = 0.0


## The camera for the menu at the door and the way out (the room's frame):
## on the door's side of the table, the player at the stand and the door
## beyond them, the leaf swinging in towards it.
const DOOR_CAM := Vector3(0.1, 1.72, 0.25)
## The front door's swing (s), and how long after it starts they step off
## for the doorway (the leaf is square to the wall at 0.5 and clear of
## their way; they reach the doorway over a second later).
const DOOR_SWING := 0.7
const DOOR_STEP_OFF := 0.55


## Breakfast at the bar (2 November, Gary: "have character eat if they
## want"): the player walks up to the bar in front of the bowl, takes the
## spoon in their right hand, and eats, the spoon going from the bowl to
## their mouth and back a few times; the bowl's empty after ("Eat every
## crumb"), and Bram says so. The camera watches from along the bar.
static func _eat(w: World, e: Dictionary) -> void:
	var root: Node3D = e.root
	var bowl: Node3D = e.porridge
	var pf = w.player_doll
	w.busy = true
	w.cine = true
	w.hud.set_controls_visible(false)
	coach(w).objective("")
	# (up to the counter's edge, the bowl within the arm's reach: EAT_STAND
	# from it, 9 November; a step further off, 0.24, his arm was straight
	# reaching for it)
	var stand := root.to_global(Vector3(InnRooms.BAR_X + 0.425 + EAT_STAND, 0, 0.55))
	if w.player.global_position.distance_to(stand) > 0.1:
		await Cine.path(w, "player", [stand], 1.0)
	var at_bowl: Vector3 = bowl.global_position
	Cine.look(w, "player", at_bowl)
	# from over the counter's north end, his face and the spoon coming up
	# to it in three-quarter, the bowl below (8 November: from the room's
	# north side the shot had his back and the hand at the back of his head,
	# so the eating couldn't be seen; the raised flap at the counter's south
	# end fills a shot from the south)
	Cine.move(w, root.to_global(Vector3(InnRooms.BAR_X - 0.3, 1.52, -0.75)), root.to_global(Vector3(InnRooms.BAR_X + 0.6, 1.4, 0.55)), 0.8, 36.0)
	await Cine.wait(w, 0.45)
	if pf is Figure3D:
		var me := pf as Figure3D
		# (4 November, Gary: "when the player eats the porridge his arm goes
		# through himself": the palm was sent to the mouth itself, with the
		# spoon hanging off it, and the elbow's usual hint, out and back,
		# folded the arm back past the shoulder so the forearm came forward
		# through the chest: the elbow is kept down in front of the ribs, and
		# the targets are in his own frame, so they go with him.
		# 8 November, Gary: "When eating the porridge the spoon doesn't go
		# all the way to the mouth": the spoon is held by its handle's end in
		# the fist (SpoonHold, in the skeleton's own pass) and points from
		# there at where its bowl end is wanted, the lips read off the model
		# each frame (mouth_of); the fist as drawn is read back and the arm's
		# target corrected by what it fell short.
		# 9 November, Gary: "When eating porridge hand moves in an unnatural
		# way": the spoon came up from under the chin standing almost upright
		# (SPOON_UP 118 degrees: the fist under the chin, the bowl end poked up
		# at the lips like a lolly stick), in 0.42 s; the palm was turned from
		# down to in-and-up whatever the forearm was doing, so the wrist bent
		# back and twisted; and the correction for the fist's shortfall was
		# learnt only at the two ends, 60% a frame, so the hand lurched at the
		# top of each rise as it caught up. Now it goes as a spoonful does:
		# the spoon dips into the oats and drags a little through them
		# (SPOON_SCOOP), lifts straight up off the bowl, and comes up in an
		# arc to the mouth, carried near level and coming in at the lips from
		# in front and to his right (SPOON_DIR_MOUTH: the fist out at the side
		# of the chin, the elbow lifting out, SPOON_ELBOW_*), the lips take it
		# (in a little, the bowl end tipping up, SPOON_TAKE), and it goes
		# back down the way it came; over 2.3 s a mouthful (SPOON_SECS). The
		# fist is always turned square to the forearm round the handle (the
		# hammer grip a hand modelled as a loose fist has: a straight wrist,
		# the spoon out past the thumb), and the shortfall is corrected every
		# frame against what was asked the frame before, a third of it a
		# frame, so the hand never jumps. tests/eat_probe.gd measures the
		# wrist and the elbow and the hand's speed frame to frame.
		var hand := Node3D.new()
		hand.name = "SpoonHand"
		var spoon: Node3D = bowl.get_node_or_null("Spoon")
		var in_bowl := me.to_own(at_bowl + Vector3(0, SPOON_IN_BOWL, 0))
		var over_bowl := in_bowl + Vector3(0, SPOON_OVER_BOWL, 0)
		var dir_bowl := SPOON_DIR_BOWL.normalized()
		var dir_mouth := SPOON_DIR_MOUTH.normalized()
		# where the spoon is wanted (his own frame): its bowl end, which way
		# it points (from the handle to the bowl), how far up the arm is (0 at
		# the bowl, 1 at the mouth: the elbow)
		var st := {"end": over_bowl, "dir": dir_bowl, "k": 0.0}
		# first to the spoon where it lies on the bowl's rim, its handle's end
		# lifted in the fist and its bowl end left where it is
		var rest_end := Vector3.ZERO
		var rest_dir := Vector3.ZERO
		if spoon != null:
			var s_bowl := me.to_own(spoon.to_global(Vector3(0, 0, SPOON_LEN * 0.5)))
			var s_handle := me.to_own(spoon.to_global(Vector3(0, 0, -SPOON_LEN * 0.5)))
			rest_end = s_bowl
			rest_dir = (s_bowl - s_handle).normalized()
			st.end = s_bowl
			st.dir = (s_bowl - s_handle - Vector3(0, SPOON_PICK_LIFT, 0)).normalized()
		me.carry(hand, (st.end as Vector3) - (st.dir as Vector3) * SPOON_LEN)
		me.elbow("right", SPOON_ELBOW_BOWL + Vector3(0, me._shoulder, 0), 0.7)
		me.palm("right", Vector3.DOWN, 0.7, 0.0, false, me.facing())
		me.reach(null, hand, 0.7)
		# (the spoon's hold last in the skeleton's list, after the arm's reach
		# and the hand's turn that reach() and palm() have just put there: before
		# them it read the arm as the clip had it, the hand down by his hip)
		var hold := SpoonHold.new()
		hold.name = "SpoonHold"
		hold.fig = me
		me._skel.add_child(hold)
		me._skel.move_child(hold, -1)
		# his eyes on the bowl: the head dips to it (Figure3D.eyes_on, as far
		# as a head dips), and so meets the spoon as it comes up
		me.eyes_on(at_bowl)
		var corr := [Vector3.ZERO]
		var asked := [Vector3.INF]
		var feeding := [true]
		var apply := func() -> void:
			var dir: Vector3 = (st.dir as Vector3).normalized()
			var end: Vector3 = st.end
			var want: Vector3 = end - dir * SPOON_LEN
			asked[0] = want
			hand.position = want + (corr[0] as Vector3)
			hold.aim = me.to_world(end)
			var pole := me._pivot.get_node_or_null("RightElbow") as Node3D
			if pole != null:
				pole.position = SPOON_ELBOW_BOWL.lerp(SPOON_ELBOW_MOUTH, float(st.k)) + Vector3(0, me._shoulder, 0)
			# the fist round the handle, square to the forearm as drawn: the
			# fingers on along the forearm, the spoon out past the thumb
			if hold.fore != Vector3.ZERO and me._palms.has("right"):
				var sw := (me.to_world(end) - me.to_world(want)).normalized()
				var fo: Vector3 = hold.fore
				var fw := fo - sw * fo.dot(sw)
				if fw.length() > 0.05:
					fw = fw.normalized()
					me._palms["right"][0] = sw.cross(fw).normalized() * SPOON_PALM_SIDE
					me._palms["right"][3] = false
					me._palms["right"][4] = fw
		var drive := func() -> void:
			while feeding[0] and is_instance_valid(hand) and is_instance_valid(me):
				await w.get_tree().process_frame
				if not feeding[0] or not is_instance_valid(hand) or not is_instance_valid(hold):
					break
				# (what was drawn last frame against what was asked for it)
				# (not while the arm's at full stretch: there the shortfall is
				# the arm's, and learning it only sends the target further off)
				var reach_ok := (hand.position - me.to_own(me.bone_pos("RightArm"))).length() < me._arm * 0.95
				if hold.grip != Vector3.INF and asked[0] != Vector3.INF and reach_ok:
					var err: Vector3 = (asked[0] as Vector3) - me.to_own(hold.grip)
					corr[0] = ((corr[0] as Vector3) + err * SPOON_FEEDBACK).limit_length(SPOON_CORR_MOST)
				apply.call()
		apply.call()
		drive.call()
		await Cine.wait(w, 0.8)
		hold.spoon = spoon   # (in the fist, by its handle's end)
		# the bowl end over the bowl, the spoon turned down into it
		var to_bowl := func(from_end: Vector3, from_dir: Vector3, secs: float) -> void:
			var tw := w.create_tween()
			tw.tween_method(func(u: float) -> void:
				var ez := smoothstep(0.0, 1.0, u)
				st.end = from_end.lerp(over_bowl, ez) + Vector3(0, sin(ez * PI) * 0.04, 0)
				st.dir = from_dir.slerp(dir_bowl, ez)
				st.k = 0.0, 0.0, 1.0, secs)
			await tw.finished
		await to_bowl.call(st.end, st.dir, 0.45)
		for mouthful in 3:
			# into the oats and through them towards him, and up off the bowl
			var sc := w.create_tween()
			var dip := in_bowl + Vector3(0, -SPOON_SCOOP.y, SPOON_SCOOP.z * 0.3)
			var drag := in_bowl + Vector3(0, 0.004, -SPOON_SCOOP.z)
			var clear := drag + Vector3(0, SPOON_OVER_BOWL, 0)
			sc.tween_method(func(u: float) -> void:
				st.end = over_bowl.lerp(dip, smoothstep(0.0, 1.0, u)), 0.0, 1.0, SPOON_SECS[0] * 0.35)
			sc.tween_method(func(u: float) -> void:
				st.end = dip.lerp(drag, smoothstep(0.0, 1.0, u)), 0.0, 1.0, SPOON_SECS[0] * 0.35)
			sc.tween_method(func(u: float) -> void:
				st.end = drag.lerp(clear, smoothstep(0.0, 1.0, u)), 0.0, 1.0, SPOON_SECS[0] * 0.3)
			await sc.finished
			# up in an arc to the lips: straight up off the bowl first, coming
			# in to the mouth from in front and to his right, carried level
			var up := w.create_tween()
			up.tween_method(func(u: float) -> void:
				var ez := smoothstep(0.0, 1.0, u)
				var m: Vector3 = mouth_end(me, hold)
				st.end = _bezier(clear, clear + Vector3(0, SPOON_ARC_UP, 0), m + SPOON_ARC_IN, m, ez)
				st.dir = dir_bowl.slerp(dir_mouth, smoothstep(0.0, 0.7, u))
				st.k = ez, 0.0, 1.0, SPOON_SECS[1])
			await up.finished
			# the lips take it: in a little, the bowl end tipping up, and out
			var take := w.create_tween()
			take.tween_method(func(u: float) -> void:
				var m: Vector3 = mouth_end(me, hold)
				var a := sin(u * PI)
				st.end = m + dir_mouth * SPOON_TAKE.x * a - dir_mouth * SPOON_TAKE.y * smoothstep(0.55, 1.0, u)
				st.dir = dir_mouth.rotated(dir_mouth.cross(Vector3.UP).normalized(), deg_to_rad(SPOON_TAKE.z) * smoothstep(0.2, 0.7, u))
				st.k = 1.0, 0.0, 1.0, SPOON_SECS[2])
			await take.finished
			# and back down the way it came, to over the bowl
			var from_end: Vector3 = st.end
			var from_dir: Vector3 = st.dir
			var down := w.create_tween()
			down.tween_method(func(u: float) -> void:
				var ez := smoothstep(0.0, 1.0, u)
				st.end = _bezier(from_end, from_end + SPOON_ARC_IN, over_bowl + Vector3(0, SPOON_ARC_UP, 0), over_bowl, ez)
				st.dir = from_dir.slerp(dir_bowl, smoothstep(0.3, 1.0, u))
				st.k = 1.0 - ez, 0.0, 1.0, SPOON_SECS[3])
			await down.finished
			await Cine.wait(w, SPOON_SECS[4])
		# the spoon back on the bowl's rim where it was, and let go
		if spoon != null:
			var from_end: Vector3 = st.end
			var from_dir: Vector3 = st.dir
			var back := w.create_tween()
			back.tween_method(func(u: float) -> void:
				var ez := smoothstep(0.0, 1.0, u)
				st.end = from_end.lerp(rest_end, ez) + Vector3(0, sin(ez * PI) * 0.03, 0)
				st.dir = from_dir.slerp(rest_dir, ez), 0.0, 1.0, 0.5)
			await back.finished
			await Cine.wait(w, 0.1)
		feeding[0] = false
		hold.aim = Vector3.INF
		hold.queue_free()
		var oats: Node3D = bowl.get_node_or_null("Oats")
		if oats != null:
			oats.visible = false
		if spoon != null:
			spoon.position = Vector3(0.05, 0.065, 0.02)
			spoon.rotation = Vector3(0, 0.4, 0.15)
		me.eyes_on(null)
		me.let_go(0.4)
		me.palm("right", Vector3.ZERO, 0.4)
		me.elbow("right", Vector3.INF, 0.4)
		await Cine.wait(w, 0.4)
		hand.queue_free()
	else:
		await Cine.wait(w, 1.5)
	Game.set_flag("p1_ate")
	Cine.look(w, "bram", w.player.global_position)
	await w.run_steps(ATE, null)
	w.hud.dialogue.close()
	Cine.move(w, root.to_global(Vector3(0.2, 2.6, 2.6)), w.player.global_position + Vector3(0, 1.0, 0), 0.7, 50.0)


## Where the bowl sits, from the counter's front edge to its middle (m), and
## where the player stands to eat, from the edge to their middle.
const BOWL_IN := 0.15
const EAT_STAND := 0.16
## Bram, once the bowl's empty.
const ATE := [{"who": "bram", "say": "That's more like it. Now the crate."}]
## The spoon: a stick of a spoon SPOON_LEN long, held by its handle's end in
## the curl of the fingers (SpoonHold; SPOON_GRIP in the palm's own frame,
## Figure3D.palm_frame: x across to the little finger's side, y up off the
## palm, z along the fingers), across the fingers and out past the thumb.
## (9 November: held 1.2 cm over the palm's middle, it hung under an open
## hand and read as nothing held; Player A's right hand is modelled near
## open, its fingers curling up 2 to 4 cm from 7 cm along, so the handle lies
## along the fingers' roots with their curl closing over it.)
const SPOON_LEN := 0.16
const SPOON_GRIP := Vector3(0.02, 0.006, 0.06)
## The spoon's bowl end in the porridge: this far up from the bowl's base at
## its middle (the oats' top is 0.06 up); over the bowl between mouthfuls,
## this much higher.
const SPOON_IN_BOWL := 0.055
const SPOON_OVER_BOWL := 0.035
## How high the fist lifts the handle's end off the bowl's rim as it takes
## the spoon up (m).
const SPOON_PICK_LIFT := 0.05
## Which way the spoon points (handle to bowl end; his own frame: x to his
## left, y up, z ahead): in the bowl, down into it from the fist over it on
## his right; at the lips, near level, coming in from in front and to his
## right (9 November: it was near upright, the fist under the chin).
const SPOON_DIR_BOWL := Vector3(0.18, -0.85, 0.45)
const SPOON_DIR_MOUTH := Vector3(0.55, 0.12, -0.83)
## The scoop: how deep the bowl end goes into the oats (y) and how far it's
## drawn through them towards him (z), m.
const SPOON_SCOOP := Vector3(0.0, 0.012, 0.035)
## The way up: straight up off the bowl this far before it turns towards the
## mouth, and coming in to the lips from this far in front, to his right and
## below (his own frame); the same arc back down.
const SPOON_ARC_UP := 0.12
const SPOON_ARC_IN := Vector3(-0.05, -0.04, 0.09)
## At the lips: in this far along the spoon (x), back out this far as they
## let it go (y), the bowl end tipping up this many degrees (z).
const SPOON_TAKE := Vector3(0.012, 0.03, 16.0)
## A mouthful's parts (s): the scoop, the way up, at the lips, the way down,
## the pause over the bowl.
const SPOON_SECS := [0.5, 0.8, 0.55, 0.65, 0.18]
## Where the right elbow bends towards (his own frame, from the shoulders'
## height): down at his side over the bowl, lifting out as the spoon comes up.
const SPOON_ELBOW_BOWL := Vector3(-0.32, -0.42, 0.02)
const SPOON_ELBOW_MOUTH := Vector3(-0.44, -0.24, 0.08)
## The palm's way round the handle: 1 if the model's palm is where
## Figure3D.palm_frame says, -1 if it's the back of the hand.
const SPOON_PALM_SIDE := 1.0
## The feedback on the fist's target: how much of the drawn fist's shortfall
## (against the frame before's asking) is added to the target each frame,
## and the most the target is moved by it (m).
const SPOON_FEEDBACK := 0.35
const SPOON_CORR_MOST := 0.1


## Where the spoon's bowl end is wanted at the mouth (his own frame): the lips
## as drawn (read in the hold's pass, after the head's own turn and dip) and
## SPOON_AT_MOUTH off them.
static func mouth_end(me: Figure3D, hold: SpoonHold) -> Vector3:
	return me.to_own(hold.mouth if hold != null and hold.mouth != Vector3.INF else mouth_of(me)) + SPOON_AT_MOUTH
## Where the spoon's bowl end stops at each mouthful, from the lips (his own
## frame: a little to his right, just under and in front of them).
const SPOON_AT_MOUTH := Vector3(-0.01, -0.012, 0.02)


## A cubic Bezier from a to d, by b and c, at t.
static func _bezier(a: Vector3, b: Vector3, c: Vector3, d: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return a * (u * u * u) + b * (3.0 * u * u * t) + c * (3.0 * u * t * t) + d * (t * t * t)


## The spoon in the fist, drawn where the hand is this frame (a modifier at
## the end of the skeleton's list, after the arm's reach, the hand's turn and
## the hands kept off the counter): the handle's end on the palm's skin at
## its middle (Figure3D.palm_frame), the spoon pointing from there at `aim`
## (world; INF leaves it be), its flat the palm's way, its bowl end SPOON_LEN
## along. `grip` and `tip` are where they were drawn, for the feedback and
## the tests.
class SpoonHold:
	extends SkeletonModifier3D
	var fig: Figure3D
	var spoon: Node3D
	var aim := Vector3.INF
	var grip := Vector3.INF
	var tip := Vector3.INF
	var mouth := Vector3.INF   # the lips as drawn (after the head's own turn and dip)
	var fore := Vector3.ZERO   # the right forearm's way as drawn, elbow to wrist (world)

	func _process_modification_with_delta(_delta: float) -> void:
		if not is_instance_valid(fig) or fig._skel == null:
			return
		mouth = AshfordP1.mouth_of(fig)
		var sk := fig._skel
		var fa := sk.find_bone("RightForeArm")
		var hb := sk.find_bone("RightHand")
		if fa >= 0 and hb >= 0:
			fore = (sk.global_transform.basis * (sk.get_bone_global_pose(hb).origin - sk.get_bone_global_pose(fa).origin)).normalized()
		var f := fig.palm_frame("right")
		grip = f.origin + f.basis * AshfordP1.SPOON_GRIP
		if aim == Vector3.INF or not is_instance_valid(spoon) or not spoon.is_inside_tree():
			return
		var d := aim - grip
		if d.length() < 0.01:
			return
		d = d.normalized()
		var up := f.basis.y - d * f.basis.y.dot(d)
		if up.length() < 0.05:
			up = Vector3.UP - d * d.y
		up = up.normalized()
		spoon.global_transform = Transform3D(Basis(up.cross(d), up, d).orthonormalized(), grip + d * AshfordP1.SPOON_LEN * 0.5)
		tip = grip + d * AshfordP1.SPOON_LEN
## Where the lips are on each model, from the Head bone in the bone's own
## frame (m): tests/mouth_find.gd profiles the face off the mesh (Player A's:
## the chin's front 0 to 3 cm over the bone, the lips at 4 to 5, the nose's
## tip at 6 to 7, 19 cm ahead; checked against a still of his face with
## the point marked). The default is Player A's, which every look plays in
## the game (DollArt.player_look).
const MOUTH := {"player_a": Vector3(0.0, 0.045, 0.17)}
const MOUTH_DEFAULT := Vector3(0.0, 0.045, 0.17)


## The mouth, in the world, on the pose as it stands now: the Head bone's
## pose (as drawn, read inside the skeleton's pass; the clip's, read from a
## scene) and the model's MOUTH offset.
static func mouth_of(f: Figure3D) -> Vector3:
	var sk: Skeleton3D = f._skel
	var hb := sk.find_bone("Head") if sk != null else -1
	if hb < 0:
		return f.global_position + Vector3(0, f._top + 0.05, 0)
	var off: Vector3 = MOUTH.get(f._model_name, MOUTH_DEFAULT)
	return sk.global_transform * (sk.get_bone_global_pose(hb) * off)


## Bram's rag going over the counter until `state[0]` goes false (v7:
## "rubbing a rag over an oak surface that doesn't need cleaning"). His
## right hand, in front of his right shoulder on the near part of the
## counter top (WIPE_AT, in his own frame: x to his left, y up, z ahead):
## until 28 October it worked half a metre ahead of him and well to his
## left, out of the right arm's reach, so the arm ran across his chest,
## twisted, and the hand fell short through the counter's edge (Gary:
## "Bram's arm twists in a weird way and still passes through his body and
## his hand passed through the bar"). Since 29 October (Gary: "Bram isn't
## rubbing the counter he is waving his hand above it his hand needs to be
## a bit lower and he needs a cloth in his hand") the hand is down on a rag
## that lies on the counter and goes where the hand goes (_rag: a striped
## linen cloth wadded up under the palm, its ends out flat on the oak), in
## long strokes from side to side rather than little circles; the counter is solid to his hands
## (Figure3D.hands_off, InnRooms.eve's hand_solids), so the other hand,
## talking, stops on it too. WIPE_AT's height is the palm's on the rag's
## wad (the counter's top is at 1.13, the wad RAG_WAD over it), the fingers
## curled round it as a hand gripping a cloth.
const WIPE_AT := Vector3(-0.2, 1.195, 0.3)
## How high the rag's wad stands in the middle, under the palm (m).
const RAG_WAD := 0.04
## How high the middle of his palm is held over the oak (m): down in the
## wad, the cloth gathered up into his hand.
const RAG_PALM := 0.034
## The stroke: how far to each side of WIPE_AT and how far in and out (m),
## and how fast (radians a second).
const WIPE_SWEEP := Vector2(0.1, 0.035)
const WIPE_RATE := 2.0


static func _wipe(w: World, root: Node3D, state: Array) -> void:
	var f = Cine.fig(w, "bram")
	if not (f is Figure3D):
		return
	var fig := f as Figure3D
	var e := InnRooms.eve(village(w))
	fig.hands_off(e.get("hand_solids", []))
	var top: float = (e.bar_top as Vector3).y if e.has("bar_top") else root.global_position.y + 1.13
	var rag: Node3D = e.get("rag", null)
	if rag == null or not is_instance_valid(rag):
		rag = _rag()
		root.add_child(rag)
		e["rag"] = rag
	var hand := Node3D.new()
	hand.name = "RagHand"
	w.add_child(hand)
	var place := func(t: float) -> void:
		var off := Vector3(WIPE_SWEEP.x * sin(t * WIPE_RATE), 0.0, WIPE_SWEEP.y * sin(t * WIPE_RATE * 2.0) + 0.01 * sin(t * 0.6))
		var at := fig.to_world(WIPE_AT + off)
		hand.global_position = at
		# the rag's wad under the palm where it was last drawn (the reach
		# and the press put it near `at`, not on it), turned the way the
		# hand points, from the shoulder
		var pal: Vector3 = fig.palm_seen.get("right", at)
		if pal.distance_to(at) > 0.25:
			pal = at   # (not drawn there yet)
		var sh := fig.to_world(Vector3(-0.18, 0.0, -0.05))
		var way := Vector3(pal.x - sh.x, 0.0, pal.z - sh.z)
		way = way.normalized() if way.length() > 0.01 else fig.facing()
		rag.global_position = Vector3(pal.x, top + 0.001, pal.z) + way * 0.015
		rag.rotation = Vector3(0.0, atan2(way.x, way.z) + 0.12 * sin(t * WIPE_RATE), 0.0)
	place.call(0.0)
	fig.reach(null, hand, 0.5)
	fig.palm("right", Vector3.DOWN, 0.5, 0.55)   # (palm down on the wad, the fingers half curled round it)
	# the palm pressed onto the wad, eased down as the arm comes to it
	var pressing := w.create_tween()
	pressing.tween_method(func(k: float) -> void:
		if is_instance_valid(fig):
			fig.press("right", lerpf(fig.palm_seen.get("right", Vector3(0, top + 0.3, 0)).y, top + RAG_PALM, k)), 0.0, 1.0, 0.5)
	var t := 0.0
	while state[0] and is_instance_valid(w) and is_instance_valid(hand) and is_instance_valid(fig):
		t += w.get_process_delta_time()
		place.call(t)
		await w.get_tree().process_frame
	# the rag stays on the counter where he leaves it
	if is_instance_valid(fig):
		fig.press("right", NAN)
		fig.let_go(0.4)
		fig.palm("right", Vector3.ZERO, 0.4)
	if is_instance_valid(hand):
		hand.queue_free()


## A bar rag: a cloth of worn linen with faded red stripes at its ends, a
## tea towel's look so it reads as cloth at a glance (flat and pale it read as
## a sheet of paper), about 34 by 26 cm: wadded up into a crumpled mound in
## the middle where the hand grips it (4.5 cm), its ends lying out flat on
## the counter in creases that run out from the mound.
static func _rag() -> Node3D:
	var n := Node3D.new()
	n.name = "Rag"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 26
	var nz := 20
	var sx := 0.34
	var sz := 0.26
	var hgt := func(u: float, v: float) -> float:
		var x := (u - 0.5) * sx
		var z := (v - 0.5) * sz
		var r2 := pow(x / 0.085, 2.0) + pow(z / 0.07, 2.0)
		var r := sqrt(r2)
		# gathered up under the hand: a lumpy, rounded wad, not a peak
		var mound := RAG_WAD * (1.0 - smoothstep(0.35, 1.15, r)) * (0.85 + 0.15 * sin(x * 60.0 - z * 35.0))
		# crumpled: the mound lumpy, creases running out from it
		var ang := atan2(z, x)
		var crease := 0.006 * maxf(0.0, sin(ang * 7.0 + 1.3)) * exp(-r2 * 0.25) * clampf(r2, 0.0, 1.0)
		var lumps := 0.008 * sin(x * 90.0 + z * 40.0) * sin(z * 75.0 - x * 20.0) * exp(-r2 * 0.6)
		var edge := minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
		var ripple := 0.0025 * sin(x * 52.0 + z * 17.0) * clampf(edge * 8.0, 0.0, 1.0)
		return 0.0015 + mound + crease + lumps + ripple
	var pt := func(i: int, j: int) -> Vector3:
		var u := float(i) / nx
		var v := float(j) / nz
		# drawn in towards the mound a little (the cloth is gathered into
		# the hand), the ends ragged
		var x := (u - 0.5) * sx
		var z := (v - 0.5) * sz
		var pull := 1.0 - 0.18 * exp(-(pow(x / 0.12, 2.0) + pow(z / 0.1, 2.0)))
		var wob := 0.007 * sin(float(i) * 0.9 + float(j) * 1.3) * (1.0 if (i == 0 or i == nx or j == 0 or j == nz) else 0.0)
		return Vector3(x * pull + wob, float(hgt.call(u, v)), z * pull + wob * 0.6)
	for i in nx:
		for j in nz:
			var a: Vector3 = pt.call(i, j)
			var b: Vector3 = pt.call(i + 1, j)
			var c: Vector3 = pt.call(i + 1, j + 1)
			var d: Vector3 = pt.call(i, j + 1)
			var ua := Vector2(float(i) / nx, float(j) / nz)
			var ub := Vector2(float(i + 1) / nx, float(j) / nz)
			var uc := Vector2(float(i + 1) / nx, float(j + 1) / nz)
			var ud := Vector2(float(i) / nx, float(j + 1) / nz)
			for tri in [[a, ua, c, uc, b, ub], [a, ua, d, ud, c, uc]]:
				st.set_uv(tri[1]); st.add_vertex(tri[0])
				st.set_uv(tri[3]); st.add_vertex(tri[2])
				st.set_uv(tri[5]); st.add_vertex(tri[4])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for yy in 64:
		for xx in 64:
			var u := xx / 63.0
			# two faded red stripes towards each end, a coarse weave
			var stripe := 1.0 if (absf(u - 0.12) < 0.035 or absf(u - 0.2) < 0.015 or absf(u - 0.88) < 0.035 or absf(u - 0.8) < 0.015) else 0.0
			var weave := 0.94 + 0.06 * float((xx + yy) % 2) - 0.04 * float(xx % 3 == 0)
			var base := Color(0.86, 0.82, 0.74) * weave
			img.set_pixel(xx, yy, base.lerp(Color(0.62, 0.2, 0.16), stripe * 0.85))
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mi.material_override = m
	n.add_child(mi)
	return n


## The side table the crate waits on in the taproom's corner: a thick board
## on four stout legs, a table's height.
const CRATE_STAND_H := 0.72
static func _crate_stand(v: AshfordVillage, root: Node3D, at: Vector3, yaw: float) -> Node3D:
	var n := Node3D.new()
	n.name = "CrateStand"
	root.add_child(n)
	n.position = at
	n.rotation.y = yaw
	var top := Vector3(0.72, 0.05, 0.6)
	v.box(n, top, Vector3(0, CRATE_STAND_H - top.y * 0.5, 0), v.mats.wood_h)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			v.box(n, Vector3(0.06, CRATE_STAND_H - top.y, 0.06), Vector3(sx * 0.29, (CRATE_STAND_H - top.y) * 0.5, sz * 0.23), v.mats.wood)
		# a stretcher between each pair of legs
		v.box(n, Vector3(0.04, 0.04, 0.42), Vector3(sx * 0.29, 0.14, 0), v.mats.wood)
	# and an apron under the top, front and back
	for sz in [-1.0, 1.0]:
		v.box(n, Vector3(0.6, 0.08, 0.025), Vector3(0, CRATE_STAND_H - top.y - 0.04, sz * 0.23), v.mats.wood)
	return n


## The player lifts the crate off its stand in the corner into both arms:
## knees bent, hands to its sides, and up with it as they straighten, the
## crate coming in to their middle. (It went up on its own while they
## stayed bent, then they stood under it, arms out straight.)
static func _take_crate(w: World, cr: Node3D) -> void:
	w.busy = true
	w.cine = true
	var pf = w.player_doll
	Cine.look(w, "player", cr.global_position)
	if pf is Figure3D:
		var me := pf as Figure3D
		# up to it, close enough to get both hands to its sides (they could
		# press "use" from a stride and more away)
		var c := cr.global_position
		var from := w.player.global_position
		var dir := Vector3(from.x - c.x, 0.0, from.z - c.z)
		dir = dir.normalized() if dir.length() > 0.01 else Vector3.BACK
		var spot := Vector3(c.x, from.y, c.z) + dir * 0.5
		if from.distance_to(spot) > 0.06:
			await Cine.path(w, "player", [spot], 1.0)
		Cine.look(w, "player", c)
		await Cine.wait(w, 0.3)
		# each hand to the side nearer it (they may come at it from the back)
		var left_dir := Vector3.UP.cross(-dir)
		var on_l := left_dir.dot(cr.global_basis.x) >= 0.0
		var lh: Node3D = cr.get_node("L" if on_l else "R")
		var rh: Node3D = cr.get_node("R" if on_l else "L")
		me.pose("lift", 0.42, 0.45)
		me.reach(lh, rh, 0.45)
		await Cine.wait(w, 0.6)
		# a little up off the stand first, as the weight is taken
		var y0 := cr.global_position.y
		var take := w.create_tween()
		take.tween_property(cr, "global_position:y", y0 + 0.05, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await take.finished
		# then up and in, as they straighten
		me.release(0.6)
		var held_at := me.to_world(CRATE_HOLD)
		var lift := w.create_tween().set_parallel(true)
		lift.tween_property(cr, "global_position", held_at, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var face := me.global_rotation.y + me._yaw + (0.0 if on_l else PI)
		lift.tween_property(cr, "global_rotation:y", _yaw_toward(cr.global_rotation.y, face), 0.6)
		await lift.finished
		me.carry(cr, CRATE_HOLD)
		cr.rotation = Vector3(0, 0.0 if on_l else PI, 0)
		me.reach(lh, rh, 0.0)
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


## `to` turned to the nearest equal angle to `from` (so a turn goes the short way).
static func _yaw_toward(from: float, to: float) -> float:
	return from + wrapf(to - from, -PI, PI)


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
	# the green's people are already at their morning as the door opens, and
	# go on with it through the opening's own shots, which never have them in
	# (AshfordLife; 2 November, Gary: Corin and the kids stood "solid" until
	# the crate was down; 5 November: they "take a while to come to life")
	w.set_meta("life_through_cine", true)
	AshfordLife.start(w)
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
	AshfordLife.start(w)   # (already running from the door; harmless)
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
		if _toward_lane(w.player.global_position):
			await _lane_turned_back(w)
			if not is_instance_valid(w):
				return
			best = Vector2(w.player.global_position.x, w.player.global_position.z).length()
			since = 0.0
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


## Off the green's east side into the lane to Tam's mill (AshfordDay.LANE_MOUTH
## on to the gate), or out past the ring road there.
static func _toward_lane(p: Vector3) -> bool:
	var a := Vector2(AshfordDay.LANE_MOUTH.x, AshfordDay.LANE_MOUTH.z)
	var b := Vector2(AshfordDay.LANE.x, AshfordDay.LANE.z) + Vector2(AshfordDay.LANE_DIR.x, AshfordDay.LANE_DIR.z) * 6.0
	var q := Vector2(p.x, p.z)
	var ab := b - a
	var t := clampf((q - a).dot(ab) / ab.length_squared(), -0.15, 1.0)
	if q.distance_to(a + ab * t) < 2.6:
		return true
	return p.x > 13.6 and p.z < -7.5


## Bram calls them back from the lane: the walk stops, they turn and come back
## a few steps towards the green, he says where the crate goes, and it's their
## feet again.
static func _lane_turned_back(w: World) -> void:
	w.busy = true
	w._move_target = null
	w.hud.set_controls_visible(false)
	var p := w.player.global_position
	var back := p.lerp(Vector3(0.0, p.y, 0.0), 0.0)
	var toward := Vector3(-p.x, 0.0, -p.z).normalized()
	back = p + toward * 2.6
	back.y = village(w).height(back.x, back.z)
	Cine.look(w, "bram", p)
	await Cine.path(w, "player", [back], 1.4)
	if not is_instance_valid(w):
		return
	var bb := Cine.body(w, "bram")
	if bb != null:
		Cine.look(w, "player", bb.global_position)
	await w.run_steps(LANE_TOO_SOON, null)
	if not is_instance_valid(w):
		return
	w.hud.dialogue.close()
	Cine.look(w, "player", Vector3(0.0, back.y, 0.0))
	controls_on(w)
	w.busy = false


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
	# (a game picked up here starts on black, Ashford.starts_black, and the
	# street's fade in, which brings the picture up, isn't played: up it comes)
	if Cine.overlay(w)._black.modulate.a > 0.5:
		Cine.fade(w, 0.0, 0.8)
	# Bram sets off a beat after them and swings wide on his own side on
	# the way, so his line never crosses theirs (Gary, 23 October)
	Cine.path(w, "player", round_lantern(w, p, spot), 1.4)
	await Cine.wait(w, 0.45)
	var bp := Cine.body(w, "bram").global_position
	var wide_way := (bp + bram_to) * 0.5 + side * 1.5
	wide_way.y = v.height(wide_way.x, wide_way.z)
	var bram_there := [false]
	var bram_walk := func() -> void:
		await Cine.path(w, "bram", round_lantern(w, bp, wide_way) + round_lantern(w, wide_way, bram_to), 1.6)
		bram_there[0] = true
	bram_walk.call()
	var t := 0.0
	while t < 8.0 and Vector2(w.player.global_position.x - spot.x, w.player.global_position.z - spot.z).length() > 0.15:
		await w.get_tree().process_frame
		t += w.get_process_delta_time()
	p = w.player.global_position
	# Corin sets off across the green to them the moment they're at the
	# Lantern with the crate, in the wide shot, so he's there as it's set
	# down (5 November, Gary: "Can Corin start walking over as we're putting
	# planters down so we're not waiting so long for him to get to player";
	# 8 November: "Corin is back to taking ages to walk over to you instead
	# of as soon as you put crates down": he set off as the crate started
	# down, after the wait for Bram to come up, and was still four seconds
	# off when it was on the grass)
	corin_sets_off(w)
	# Bram up beside them
	t = 0.0
	while t < 8.0 and not bram_there[0]:
		await w.get_tree().process_frame
		t += w.get_process_delta_time()
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
	# down into a crouch with it, knees bent and back over it, and it set on
	# the grass; the hands come off its sides in the last of the way down,
	# where arms would have to stretch to stay on them (it went down a stride
	# ahead with them standing over it, their arms pulled long after it)
	if pf is Figure3D:
		(pf as Figure3D).pose("sit", CROUCH, 0.55)
	await Cine.wait(w, 0.2)
	cr.reparent(village(w).get_meta("p1_root"))
	var down := w.create_tween()
	down.tween_property(cr, "global_position", crate_at + Vector3(0, 0.14, 0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await down.finished
	if pf is Figure3D:
		(pf as Figure3D).let_go(0.2)
	var settle := w.create_tween()
	settle.tween_property(cr, "global_position", crate_at, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await settle.finished
	village(w).dust_puff(crate_at)
	w.remove_meta("p1_crate")
	await Cine.wait(w, 0.25)
	if pf is Figure3D:
		(pf as Figure3D).release(0.6)
	Game.set_flag("p1_crate_down")
	# Bram back to his stool by the Lantern while the camera comes up behind
	# the player, who straightens and looks up to Corin coming across the
	# green (8 November, Gary: "Corin is back to taking ages to walk over to
	# you instead of as soon as you put crates down": the low shot of the
	# crate was held for the three and a half seconds Bram took to walk off
	# and sit, with Corin behind the player and the Lantern's foot the whole
	# time, so his walk wasn't seen until the camera came home with him
	# nearly there; now his walk is in view from the moment the crate's down,
	# and the talk starts two seconds sooner)
	bram_to_stool(w)
	var cb := Cine.body(w, "corin")
	if cb != null and (w.has_meta("corin_coming") or Vector2(cb.global_position.x - p.x, cb.global_position.z - p.z).length() < CORIN_MEET + 1.0):
		Cine.look(w, "player", cb.global_position)
	await Cine.wait(w, 0.3)
	await home(w, 0.9)


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
	var b := Cine.body(w, "bram")
	if b == null:
		return
	var bf = Cine.fig(w, "bram")
	# to where his feet will be once sat (he settles back onto it as he sits)
	var at := seat + BRAM_FACES * ((bf as Figure3D).seat_feet_ahead() if bf is Figure3D else 0.4)
	at.y = v.height(at.x, at.z)
	w.set_meta("bram_to_stool", true)
	await Cine.path(w, "bram", round_lantern(w, b.global_position, at), 1.5)
	if not is_instance_valid(w) or not is_instance_valid(b):
		return
	w.remove_meta("bram_to_stool")
	# (8 November: not waited for from the green any more, so a scene may
	# have taken his walk over before he got there, Ashford._bram_sets_off:
	# then he isn't sat down onto the stool from wherever he is)
	if Vector2(b.global_position.x - at.x, b.global_position.z - at.z).length() > 0.3:
		return
	await sit_down(w, "bram", seat, BRAM_FACES, STOOL_H, 0.5)
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


## When the talk that took the camera is over (and any game in it), the
## camera goes back behind the player, if nothing else has taken it home.
static func _home_after_talk(w: World) -> void:
	await w.get_tree().process_frame
	while is_instance_valid(w) and w.is_inside_tree() and w.busy:
		await w.get_tree().process_frame
	if is_instance_valid(w) and w.is_inside_tree() and w.cine and not w.busy:
		await home(w, 0.8)


## Cine.two_shot from whichever side of the pair has nothing solid in the way.
static func two_shot(w: World, a_who: String, b_who: String, dist: float, height: float, fov: float) -> void:
	var cam := two_shot_cam(w, Cine.body(w, a_who).global_position, Cine.body(w, b_who).global_position, dist, height, [a_who, b_who])
	Cine.shot(w, cam[0], cam[1], fov)


## The two-shot's camera for two people standing at `a` and `b`: [where it
## stands, what it looks at], from whichever side of the pair has nothing
## solid in the way (a glide can be aimed at it before the second of them
## has got there: corin_calls).
static func two_shot_cam(w: World, a: Vector3, b: Vector3, dist: float, height: float, people: Array) -> Array:
	var mid := (a + b) * 0.5
	var d := b - a
	d.y = 0.0
	var perp := d.normalized().cross(Vector3.UP).normalized()
	var look := mid + Vector3(0, 1.3, 0)
	var at := clear_cam(w, [mid + perp * dist + Vector3(0, height, 0), mid - perp * dist + Vector3(0, height, 0),
		mid + perp * dist * 0.8 + Vector3(0, height + 0.8, 0), mid - perp * dist * 0.8 + Vector3(0, height + 0.8, 0)],
		look, people)
	return [at, look]


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
			# the two of them, framed (the game's own camera stayed up over
			# the green, Nell small behind the bunting)
			two_shot(w, "player", "nell", 2.7, 1.1, 38.0)
			_home_after_talk(w)
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
		f.look_toward(w.player.global_position, w.cam)
		_tam_holds_letter(w, f, l)
	else:
		var tb := Cine.body(w, "tam")
		if (l as Node3D).get_parent() != null:
			(l as Node3D).get_parent().remove_child(l)
		tb.add_child(l)
		(l as Node3D).position = Vector3(0.3, 1.1, 0.35)
	await Cine.wait(w, 0.6)


## Tam holds the letter up in front of his chest in both hands, a hand at
## each side of it (Figure3D.attach "between": it's where his palms are,
## every frame). (1 November, Gary: "Tam his hands are deformed and the
## letter is in his arm rather than his hand": it hung off his right hand
## bone, whose turn in his rig put it along his forearm, and the arm was held
## straight out by the card-playing pose, the fingers splayed.)
static func _tam_holds_letter(w: World, f: Figure3D, l: Node3D) -> void:
	var ba = l.get_parent()
	if ba != null:
		ba.remove_child(l)
		if ba is BoneAttachment3D:
			(ba as Node).queue_free()
	f.hand_light(null)
	w.add_child(l)
	l.scale = Vector3.ONE
	var old = meta(w, "tam_letter_hold")
	if old != null and is_instance_valid(old):
		(old as Node).queue_free()
	var hold := Node3D.new()
	hold.name = "TamLetterHold"
	f.carry(hold, f.hold_point(0.36, 0.42))
	for sd in [["L", 1.0], ["R", -1.0]]:
		var mk := Node3D.new()
		mk.name = String(sd[0])
		mk.position = Vector3(float(sd[1]) * 0.085, -0.02, 0.0)
		hold.add_child(mk)
	w.set_meta("tam_letter_hold", hold)
	f.release(0.35)
	# (2 November, Gary: the letter "goes through the characters' hands as
	# they are talking": the palms faced in but the fingers were left to the
	# clip, curling through the paper as he talked, and pointed on along the
	# forearms, in at it; straight now, and up, the way anyone holds a sheet
	# up to read it)
	f.palm("left", Vector3.RIGHT * -1.0, 0.35, 1.0, true, Vector3.UP)
	f.palm("right", Vector3.RIGHT, 0.35, 1.0, true, Vector3.UP)
	f.reach(hold.get_node("L"), hold.get_node("R"), 0.4)
	f.attach(l, "between", "right", 0.02, 0.0, 0.15)


## The letter out of Tam's hands (someone takes it, or it goes in his pocket).
static func _tam_lets_letter_go(w: World, f: Figure3D, l: Node3D) -> void:
	f.detach(l)
	f.let_go(0.3)
	f.palm("left", Vector3.ZERO, 0.3)
	f.palm("right", Vector3.ZERO, 0.3)
	var hold = meta(w, "tam_letter_hold")
	if hold != null and is_instance_valid(hold):
		(hold as Node).queue_free()
	w.remove_meta("tam_letter_hold")
	if l.get_parent() != null:
		l.get_parent().remove_child(l)


## How far apart Tam and the player stand when the letter changes hands
## (m, between their middles): held out, it's within the other's reach.
const LETTER_GAP := 0.82


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
		# a step in to him first, so it's within reach (2 November: the arm
		# went out straight across the gap to it), and the hand goes only as
		# far as the arm reaches
		var mp := w.player.global_position
		var gap := Vector2(tp.x - mp.x, tp.z - mp.z).length()
		if gap > LETTER_GAP + 0.05:
			var near := mp + Vector3(tp.x - mp.x, 0.0, tp.z - mp.z).normalized() * (gap - LETTER_GAP)
			await Cine.path(w, "player", [near], 0.8)
			Cine.look(w, "player", tp)
		var to := Node3D.new()
		w.add_child(to)
		to.global_position = _hand_can(me, "right", l.global_position)
		me.reach(null, to, 0.35)
		await Cine.wait(w, 0.4)
		if tf is Figure3D:
			_tam_lets_letter_go(w, tf as Figure3D, l)
			(tf as Figure3D).release(0.35)
		elif l.get_parent() != null:
			l.get_parent().remove_child(l)
		me.carry(l, Vector3(0.0, 1.22, 0.3))
		l.rotation = Vector3(-0.5, 0.0, 0.0)
		# (their hands flat to its sides, fingers up: 2 November, the letter
		# went through them while they talked)
		me.palm("left", Vector3.RIGHT * -1.0, 0.3, 1.0, true, Vector3(0.0, 0.85, -0.5))
		me.palm("right", Vector3.RIGHT, 0.3, 1.0, true, Vector3(0.0, 0.85, -0.5))
		me.reach(l.get_node("L"), l.get_node("R"), 0.3)
		to.queue_free()
	Cine.look(w, "player", tp)
	await Cine.wait(w, 0.3)
	await LetterView.read(w.hud._root, LetterView.TAM)


## The player hands the letter back to Tam: a step in if he's more than an
## arm and a bit away, the letter held out, and his hands come up and take
## it from theirs. (It jumped from their hands to his, their arms pulled out
## straight after it across the gap.)
static func letter_back(w: World) -> void:
	var l: Node3D = meta(w, "tam_letter")
	var tf = Cine.fig(w, "tam")
	var pf = w.player_doll
	if l == null or not (tf is Figure3D):
		return
	var tam := tf as Figure3D
	if pf is Figure3D and l.get_parent() != null and l.has_node("L"):
		var me := pf as Figure3D
		var tp := Cine.body(w, "tam").global_position
		var mp := w.player.global_position
		var gap := Vector2(tp.x - mp.x, tp.z - mp.z).length()
		if gap > LETTER_GAP + 0.05:
			var to := mp + Vector3(tp.x - mp.x, 0.0, tp.z - mp.z).normalized() * (gap - LETTER_GAP)
			await Cine.path(w, "player", [to], 0.8)
		Cine.look(w, "player", tp)
		var out := w.create_tween()
		out.tween_property(l, "position", Vector3(0.0, 1.16, 0.4), 0.45).set_trans(Tween.TRANS_SINE)
		# his hands to its sides, his left to the side on their right
		tam.palm("left", Vector3.RIGHT * -1.0, 0.35, 1.0, true, Vector3.UP)
		tam.palm("right", Vector3.RIGHT, 0.35, 1.0, true, Vector3.UP)
		tam.reach(l.get_node("R"), l.get_node("L"), 0.45)
		await out.finished
		await Cine.wait(w, 0.15)
		me.let_go(0.35)
		me.palm("left", Vector3.ZERO, 0.3)
		me.palm("right", Vector3.ZERO, 0.3)
	_tam_holds_letter(w, tam, l)
	await Cine.wait(w, 0.45)


## He puts it back in his shirt pocket: folded very small first, if the
## player told him what it says.
static func tam_pockets(w: World, folded: bool) -> void:
	var l: Node3D = meta(w, "tam_letter")
	var tf = Cine.fig(w, "tam")
	if l == null or not (tf is Figure3D):
		return
	var f := tf as Figure3D
	if not f.holding() == l:
		await letter_back(w)
	if folded:
		var tw := w.create_tween()
		tw.tween_property(l, "scale", Vector3(0.7, 0.5, 1.0), 0.5)
		tw.tween_property(l, "scale", Vector3.ONE * 0.45, 0.5)
		await tw.finished
		await Cine.wait(w, 0.3)
	_tam_lets_letter_go(w, f, l)
	attach(f, "Spine2", l, POCKET, POCKET_ROT)
	f.release(0.4)
	await Cine.wait(w, 0.4)


# -------------------------------------------------------------- Nell's bench ---

## Hands at rest on the thighs, sat on Nell's bench (8 November, Gary: "Hand
## goes through bench when you sit down with Nell"). A sat figure's arms
## are its standing clip's, hanging at its sides, and on the bench that's
## down through the seat beside the hips (and Nell's free hand, after her
## pat, the same). Now the hands come to rest on the tops of the thighs, a
## little over half way to the knee, palm down, fingers on towards the
## knee: each hand's mark rides its own thigh, read off the thigh's bones as
## they're posed each frame (LapMarks, a skeleton modifier before the
## reaches), so as someone sits down their hands go onto their thighs as the
## thighs come forward, and stay there through the talk. When they stand up
## the hands stay on the thighs a moment as the legs straighten, pushing
## off, then go back to the clip (LapMarks lets them go by itself, however
## they're stood up: nell_stand, the dance, midnight). `lap_rest = false`
## turns it off.
static var lap_rest := true
const LAP_ALONG := 0.6       # of the way from the hip joint to the knee
const LAP_UP := 0.095        # over the thigh's bone (a grown-up's m): its top, and the palm's depth
const LAP_OUT := 0.012       # out from the thigh's middle line, to their side
const LAP_LET_GO := Vector2(0.3, 0.35)   # stood up: how long the hands stay, and how long they take to go (s)
const STICK_REST := 0.065    # a hand on the stick hand: over its middle (a grown-up's m)
## Nell's pat on the seat: where the hand's middle rests over the seat's top
## (the palm's skin under it) and how high it lifts between pats (m).
const PAT_REST := 0.03
const PAT_LIFT := 0.04


## `on`: "thigh" (the hand on its own thigh), "stick" (on the back of the
## other hand where it holds a walking stick), or "at" (flat on whatever's
## at `at`, a point in the world: Nell's free hand on the bench beside her,
## where her pat leaves it; her skirt stands well off her thighs, so a hand
## "on the thigh" was inside the cloth and down on the seat, and her stick's
## out by her other knee, past her reach).
static func lap_hands(w: World, who: String, sides: Array, secs := 0.5, on := "thigh", at := Vector3.INF) -> void:
	var f = Cine.fig(w, who)
	if not lap_rest or not (f is Figure3D):
		return
	var fig := f as Figure3D
	if fig._skel == null:
		return
	var lm := fig._skel.get_node_or_null("LapMarks") as LapMarks
	if lm == null:
		lm = LapMarks.new()
		lm.name = "LapMarks"
		lm.fig = fig
		fig._skel.add_child(lm)
		fig._skel.skeleton_updated.connect(lm._drawn)
	lm.up_for = 0.0
	for side in sides:
		lm.on[side] = on
		var mk: Node3D = lm.marks.get(side, null)
		if mk == null or not is_instance_valid(mk):
			mk = Node3D.new()
			mk.name = "Lap_" + String(side)
			fig.add_child(mk)
			lm.marks[side] = mk
		if on == "at":
			lm.fixed[side] = at
			mk.global_position = at
		fig._reach(String(side), mk, secs)
		if on == "at":
			# (flat, the fingers on along the forearm, as her pat lays it)
			fig.palm(String(side), Vector3.DOWN, secs, 0.5)
		else:
			fig.palm(String(side), Vector3.DOWN, secs, 0.0, true, Vector3(0, 0, 1))
	# (before the reaches, which read the marks; after Posture, which the
	# thighs hang from)
	fig._skel.move_child(lm, 0)
	if fig._skel.has_node("Posture"):
		fig._skel.move_child(fig._skel.get_node("Posture"), 0)


class LapMarks:
	extends SkeletonModifier3D
	var fig: Figure3D
	var marks := {}        # side -> Node3D (the reach's target)
	var on := {}           # side -> "thigh", "stick" or "at"
	var fixed := {}        # side -> the world point an "at" hand rests on
	var up_for := 0.0      # how long they've been stood up (s)
	## Where each hand's middle was as last drawn, every modifier done (the
	## stick hand is put on its stick last of all, after these marks are read).
	var seen := {}

	func _drawn() -> void:
		var sk := get_skeleton()
		if sk == null:
			return
		for pre in ["Left", "Right"]:
			var h := sk.find_bone(pre + "Hand")
			var m := sk.find_bone(pre + "HandMiddle1")
			if h < 0:
				continue
			var wr := sk.global_transform * sk.get_bone_global_pose(h).origin
			seen[pre] = (wr + sk.global_transform * sk.get_bone_global_pose(m).origin) * 0.5 if m >= 0 else wr

	func _process_modification_with_delta(delta: float) -> void:
		if not is_instance_valid(fig) or marks.is_empty():
			return
		var sk := get_skeleton()
		if sk == null:
			return
		if fig.seat < 0.0:
			up_for += delta
			if up_for >= AshfordP1.LAP_LET_GO.x:
				_let_go()
				return
		else:
			up_for = 0.0
		var xf := sk.global_transform
		var s := fig.stature()
		var o := fig.to_world(Vector3.ZERO)
		var fwd := (fig.to_world(Vector3(0, 0, 1)) - o).normalized()
		var left := (fig.to_world(Vector3(1, 0, 0)) - o).normalized()
		for side in marks:
			var mk = marks[side]
			if not is_instance_valid(mk):
				continue
			var pre := "Left" if side == "left" else "Right"
			if String(on.get(side, "thigh")) == "at":
				# (where it rests in the world, whichever way they've turned:
				# the mark is in their node)
				(mk as Node3D).global_position = fixed.get(side, (mk as Node3D).global_position)
				continue
			if String(on.get(side, "thigh")) == "stick":
				# on the back of the other hand, which holds the stick
				var other := "Right" if pre == "Left" else "Left"
				if seen.has(other):
					(mk as Node3D).global_position = (seen[other] as Vector3) + Vector3.UP * AshfordP1.STICK_REST * s
				elif sk.find_bone(pre + "Hand") >= 0:
					# (its first frame: where the hand is now)
					(mk as Node3D).global_position = xf * sk.get_bone_global_pose(sk.find_bone(pre + "Hand")).origin
				continue
			var up := sk.find_bone(pre + "UpLeg")
			var kn := sk.find_bone(pre + "Leg")
			if up < 0 or kn < 0:
				continue
			var a := xf * sk.get_bone_global_pose(up).origin
			var b := xf * sk.get_bone_global_pose(kn).origin
			var t := (b - a).normalized()
			# the thigh's top: up from it, or (stood, the thigh upright) its front
			var v := Vector3.UP + fwd * 0.25
			var n := (v - t * v.dot(t)).normalized()
			var out := left if side == "left" else -left
			(mk as Node3D).global_position = a.lerp(b, AshfordP1.LAP_ALONG) + n * AshfordP1.LAP_UP * s + out * AshfordP1.LAP_OUT * s

	## The hands back to the clip (only those still on their marks: a scene
	## may have reached them for something else since).
	func _let_go() -> void:
		var secs: float = AshfordP1.LAP_LET_GO.y
		for side in marks:
			var mk = marks[side]
			var ik = fig._ik.get(side)
			if ik != null and is_instance_valid(ik) and ik.has_meta("target") and ik.get_meta("target") == mk:
				fig.call_deferred("_reach", String(side), null, secs)
				fig.call_deferred("palm", String(side), Vector3.ZERO, secs)
			if is_instance_valid(mk):
				# (kept where it was till the hand has let go of it)
				AshfordP1._free_after.call_deferred(mk, secs + 0.1)
		marks.clear()


static func _free_after(n: Node, secs: float) -> void:
	if not is_instance_valid(n) or not n.is_inside_tree():
		return
	await n.get_tree().create_timer(secs, false).timeout
	if is_instance_valid(n):
		n.queue_free()


## Where Nell's free hand rests flat on the bench beside her (her left, on
## the side of the seat the player sits on): its middle, over the boards.
const NELL_REST := 0.24     # m from the middle of her half of the seat, towards the other half

static func nell_rest(w: World) -> Vector3:
	var p := bench_seat(w).lerp(bench_seat(w, true), NELL_REST / 0.8)
	return p + Vector3(0, BENCH_H + PAT_REST, 0) + bench_facing(w) * 0.02


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
	# (8 November: palm down on the boards, its skin coming to the seat's
	# top and no further: the mark was the hand's middle 2.5 cm over the
	# seat and the pat took it 1.5 cm under, the palm's skin lower still)
	f.palm("left", Vector3.DOWN, 0.3, 0.5)
	for k in 2:
		pat.global_position = seat + Vector3(0, BENCH_H + PAT_REST + PAT_LIFT, 0) + bench_facing(w) * 0.05
		f._reach("left", pat, 0.3)
		await Cine.wait(w, 0.35)
		var tw := w.create_tween()
		tw.tween_property(pat, "global_position:y", pat.global_position.y - PAT_LIFT, 0.12)
		await tw.finished
	# and it stays on the bench, nearer her
	lap_hands(w, "nell", ["left"], 0.4, "at", nell_rest(w))
	await Cine.wait(w, 0.4)
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
	# to where the feet will be once sat, then down onto the seat (sit_down)
	var pf = w.player_doll
	var ahead := (pf as Figure3D).seat_feet_ahead() if pf is Figure3D else 0.6
	await Cine.path(w, "player", [seat + fwd * ahead], 1.3)
	await sit_down(w, "player", seat, fwd, BENCH_H, 0.6, true)
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
	await stand_up(w, "player", 0.6)
	var tw := w.create_tween()
	var off := bench_seat(w, true) + fwd * 0.85
	off.y = Cine.ground(w, off)
	tw.tween_property(w.player, "global_position", off, 0.45).set_trans(Tween.TRANS_SINE)
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
	# handed back: their hand over her card, and it goes back in.
	# (1 November, Gary: "arms deform when you go to touch Tilly's card": her
	# card was held at her waist a metre off, past the end of his arm, and
	# the arm stretched out after it. Now he steps in, she lifts it to him,
	# and the hand goes no further than his arm reaches.)
	var pair := (p + tb.global_position) * 0.5 + Vector3(0, 1.0, 0)
	Cine.move(w, clear_cam(w, [p + to_t * 0.55 + perp * 3.2 + Vector3(0, 1.3, 0), p + to_t * 0.55 - perp * 3.2 + Vector3(0, 1.3, 0),
		p + to_t * 0.55 + perp * 2.6 + Vector3(0, 2.3, 0)], pair, ["player", "tilly"]), pair, 0.8, 38.0)
	var gap := 0.74
	var tp := tb.global_position
	var now := w.player.global_position
	var flat := Vector2(tp.x - now.x, tp.z - now.z).length()
	if flat > gap + 0.05:
		var step := tp - to_t * gap
		step.y = now.y
		Cine.path(w, "player", [step], 0.9)
	if card.get_parent() != null and card.get_parent() != w:
		var lift := w.create_tween()
		lift.tween_property(card, "position", TILLY_HOLD + Vector3(0, 0.14, 0.08), 0.6).set_trans(Tween.TRANS_SINE)
	await Cine.wait(w, 0.65)
	Cine.look(w, "player", tb.global_position)
	var hand_to := card.global_position + Vector3(0, 0.11, 0) - to_t * 0.04
	if me != null:
		hand_to = _in_reach(me, hand_to, "right")
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


## `to` pulled back towards a figure's shoulder until a hand can get there
## with the elbow still a little bent (its arm's length, Figure3D.arm_reach,
## less a few percent), so an arm never stretches out after something
## beyond it.
static func _in_reach(f: Figure3D, to: Vector3, side := "right") -> Vector3:
	var sh := f.to_world(Vector3(0.17 * f.stature() * (1.0 if side == "left" else -1.0), f.hold_point(0.0, 0.0).y, 0.02))
	var d := to - sh
	var most := f.arm_reach() * 0.93
	if d.length() > most:
		return sh + d.normalized() * most
	return to


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

## How far short of the player Corin stops to talk (m), and how fast he
## comes over: a brisk walk (his own walk goes at 1.7; 8 November, Gary:
## "Corin is back to taking ages to walk over to you": ten metres across the
## green at a stroll was six seconds).
const CORIN_MEET := 1.7
const CORIN_WALK := 2.0


## Corin sets off across the green towards the player, not waited for (from
## _green, the moment they're at the Lantern with the crate: 5 November,
## Gary; since 8 November before Bram's come up, not as the crate starts
## down), so that corin_calls finds him there or nearly. AshfordLife leaves
## him be on the way (`corin_coming`, `life_busy`), and his spot to shift
## about round becomes where he stops. The walk is his one walk over (6
## November, Gary: "Corin starts walking up when you put down lanterns but
## then it cuts to him back where he was and walks up again"): corin_calls
## lets it run on from wherever he's got to, and only walks him the rest of
## the way if it's been cut short; where he's coming to is kept
## (`corin_meet`).
static func corin_sets_off(w: World) -> void:
	var cb := Cine.body(w, "corin")
	if cb == null or Game.flag("corin_met") or w.has_meta("corin_coming"):
		return
	var c := cb.global_position
	var dn := w.player.global_position - c
	dn.y = 0.0
	if dn.length() < CORIN_MEET + 0.3:
		return
	dn = dn.normalized()
	var meet := w.player.global_position - dn * CORIN_MEET
	meet.y = village(w).height(meet.x, meet.z)
	w.set_meta("corin_coming", true)
	w.set_meta("corin_meet", meet)
	cb.set_meta("life_busy", true)
	# (whatever he was doing for the children stops: a show-off clip played
	# on under the walk, and he slid across the grass in his fight stance)
	var cf = Cine.fig(w, "corin")
	if cf is Figure3D and (cf as Figure3D)._action != "":
		(cf as Figure3D).release(0.2)
	_corin_comes(w, cb, c, meet)


static func _corin_comes(w: World, cb: Node3D, from: Vector3, meet: Vector3) -> void:
	await Cine.path(w, "corin", round_lantern(w, from, meet), CORIN_WALK)
	if not is_instance_valid(w) or not is_instance_valid(cb):
		return
	w.remove_meta("corin_coming")
	if cb.get_meta("corin_called", false):
		return   # (corin_calls has him from here)
	# (there before them: he stands waiting, eyes on them, until his talk
	# begins and corin_calls lets the green's life have him back; left to
	# it he showed off or shifted a step off his mark while they set the
	# crate down, 8 November)
	cb.set_meta("life_home", cb.global_position)
	if Cine.body(w, "corin") != null:
		Cine.look(w, "corin", w.player.global_position)


## Corin calls out and comes over to the player at the Lantern (the
## children round him gather to watch): the two of them face to face, from
## the side. If he's already on his way (corin_sets_off) that walk carries
## on from wherever he's got to: no second walk, and the camera glides round
## to the two of them rather than cutting, so it's one walk seen through.
static func corin_calls(w: World) -> void:
	var cb := Cine.body(w, "corin")
	if cb == null:
		return
	w.cine = true
	# (the green's people keep still for the scene from here: AshfordLife)
	w.remove_meta("life_through_cine")
	cb.set_meta("corin_called", true)
	var coming := w.has_meta("corin_coming")
	var c := cb.global_position
	var p := w.player.global_position
	# where he'll stand: where he's coming to, or where he is
	var stand := c
	var d := p - c
	d.y = 0.0
	if coming:
		stand = w.get_meta("corin_meet", p - d.normalized() * CORIN_MEET)
	elif d.length() > CORIN_MEET + 0.2:
		stand = p - d.normalized() * CORIN_MEET
		stand.y = village(w).height(stand.x, stand.z)
	var dn := p - stand
	dn.y = 0.0
	dn = dn.normalized() if dn.length() > 0.01 else Vector3.BACK
	var to := stand + dn * 1.6
	to.y = village(w).height(to.x, to.z)
	# the children gather behind him to watch, out of everyone's way
	var aside := dn.cross(Vector3.UP)
	for i in KIDS.size():
		var id := String(KIDS[i][0])
		var kb := Cine.body(w, id)
		if kb == null:
			continue
		var at := stand - dn * 1.9 + aside * (float(i) - 1.0) * 1.15 - dn * absf(float(i) - 1.0) * 0.3
		# (off anything solid there: with Corin met nearer the crate, the
		# third child's place behind him fell on Nell's bench, and a walk
		# that ends on a thing goes straight through it; 8 November,
		# p1_v7_test)
		at = Cine.off_blockers(w, at, 0.4)
		at.y = village(w).height(at.x, at.z)
		_walk_then_look(w, id, at, to)
	var far := Vector2(stand.x - c.x, stand.z - c.z).length() > 0.25
	if far:
		# v7: he comes over to them at the Lantern, twirling his card, and
		# they turn to watch him come; the camera glides from behind them to
		# the side of the two of them as he comes: straight to the talk's own
		# framing (two_shot_cam, for where he'll stop), so when he stops
		# there's no cut (8 November; until then it glided to a shot of its
		# own and cut to the two-shot as he arrived)
		Cine.look(w, "player", c)
		var cam := two_shot_cam(w, p, stand, 3.6, 1.5, ["player", "corin"])
		Cine.move(w, cam[0], cam[1], 1.1, 36.0)
		if coming:
			# (his walk from the crate carries on: wait for it)
			var t := 0.0
			while w.has_meta("corin_coming") and t < 12.0:
				await w.get_tree().process_frame
				t += w.get_process_delta_time()
				Cine.look(w, "player", cb.global_position)
		# the rest of the way, only if he isn't there (cut short, or none yet)
		var left := cb.global_position - stand
		left.y = 0.0
		if left.length() > 0.3:
			await Cine.path(w, "corin", round_lantern(w, cb.global_position, stand), 2.1)
	cb.remove_meta("corin_called")
	cb.remove_meta("life_busy")
	w.remove_meta("corin_meet")
	cb.set_meta("life_home", cb.global_position)
	Cine.look(w, "corin", w.player.global_position)
	Cine.look(w, "player", Cine.body(w, "corin").global_position)
	if not far:
		# (he was there already, waiting for them to look up: the camera
		# glides round from behind them to the talk's shot)
		var cam := two_shot_cam(w, w.player.global_position, cb.global_position, 3.6, 1.5, ["player", "corin"])
		await Cine.move(w, cam[0], cam[1], 0.8, 36.0)


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
