class_name BakedLight
extends RefCounted
## Baked bounced light for a room whose light holds while it's seen (18
## November, Gary's yes: "bake the inn's rooms: the taproom in the evening,
## the attic at night and in the morning"). The light that bounces off the
## walls, the floor and the furniture (a lamp's warmth on the far wall, the
## window's cold light off the floorboards, the dark under the bed) is worked
## out once, in Godot's editor (tools/bake/README.md), and kept as a picture
## on every fixed thing in the room. The lights themselves stay live (their
## bake mode Dynamic: a candle still flickers, a shadow still moves); only
## their bounce is baked. It costs next to nothing to draw, so the iPhone on
## Smooth has it as well as the Mac.
##
## A room is built by code (InnRooms), so what was baked is matched to it by
## the nodes' paths: names() gives every node the code left unnamed a name
## from its place in the room (the same every time the room is built: the
## code builds it the same way on every device), prepare() swaps each baked
## thing's shape for the copy with a second set of UVs the bake laid its
## light out on (assets/bake/<room>/), and adds the LightmapGI with the
## state's light. use() changes the state (the attic's frosty morning and
## its grey pre-dawn). Anything the room hands its scene (the blanket, the
## door, the window's view, the mirror) is left out of the bake: it may move.

## Off: no baked light anywhere (a test's before).
static var enabled := true
## Set by the bake tool while it builds a room to bake: names only, nothing
## loaded (what's on disk is what's being remade).
static var baking := false

const DIR := "res://assets/bake/"
## What each room's states are called, the first its own when it's built.
const STATES := {
	"attic": ["morning", "awakening"],
	"eve": ["evening"],
	"shards": ["walk", "torn"],   # (WhiteSky's set, not switched on: WhiteSky.BAKED_LIGHT)
}


## Every node under `root` that the code left unnamed (Godot's "@...@"
## names, which change from run to run) named from its place: "n<i>" in the
## order the room was built. Named nodes keep their names (code finds some by
## name: a model's "Lid", a hinge).
static func names(root: Node) -> void:
	var i := 0
	for n in _walk(root):
		if String(n.name).begins_with("@"):
			n.name = "n%d" % i
		i += 1


static func _walk(root: Node) -> Array:
	var out: Array = []
	for c in root.get_children(true):
		out.append(c)
		out.append_array(_walk(c))
	return out


## The room's baked shapes swapped in and its light for `state` (its first
## when ""), if it's been baked. Called once the room is built.
static func prepare(root: Node3D, room: String, state := "") -> void:
	names(root)
	if baking or not enabled or RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return   # (the Compatibility renderer draws no baked light)
	var mf := DIR + room + "/shapes.json"
	if not FileAccess.file_exists(mf):
		return
	var shapes = JSON.parse_string(FileAccess.get_file_as_string(mf))
	if not (shapes is Dictionary):
		return
	var cache := {}
	var swaps: Array = []
	for path in shapes:
		var mi := root.get_node_or_null(NodePath(String(path))) as MeshInstance3D
		var file := DIR + room + "/" + String(shapes[path])
		if not cache.has(file):
			cache[file] = load(file)
		var baked: Mesh = cache[file]
		# (the room changed since it was baked: a thing added or taken away
		# before this one moves every unnamed thing's name along, and a baked
		# shape would go on the wrong thing. Then none of it, till it's baked
		# again: tools/bake/bake_rooms.sh)
		if mi == null or mi.mesh == null or baked == null or not _same(mi.mesh, baked):
			push_warning("BakedLight: %s's %s isn't what was baked (the room changed since): no baked light there till it's baked again" % [room, path])
			return
		swaps.append([mi, baked])
	for sw in swaps:
		(sw[0] as MeshInstance3D).mesh = sw[1]
		(sw[0] as MeshInstance3D).gi_mode = GeometryInstance3D.GI_MODE_STATIC
	var lm := LightmapGI.new()
	lm.name = "BakedLight"
	root.add_child(lm)
	use(root, room, state if state != "" else String(STATES.get(room, [""])[0]))


## The same shape, near enough: its parts, and its box within a centimetre
## or 5% (a sphere's box is its size; the same sphere baked, its corners
## cut by its facets, a hair smaller).
static func _same(a: Mesh, b: Mesh) -> bool:
	if a.get_surface_count() != b.get_surface_count():
		return false
	var x := a.get_aabb()
	var y := b.get_aabb()
	var tol := Vector3.ONE * 0.01 + x.size.abs() * 0.05
	var dp := (x.position - y.position).abs()
	var ds := (x.size - y.size).abs()
	return dp.x <= tol.x and dp.y <= tol.y and dp.z <= tol.z and ds.x <= tol.x and ds.y <= tol.y and ds.z <= tol.z


## The room's baked light for `state` (nothing if that state wasn't baked).
static func use(root: Node3D, room: String, state: String) -> void:
	var lm := root.get_node_or_null("BakedLight") as LightmapGI
	if lm == null:
		return
	var f := DIR + "%s/%s.lmbake" % [room, state]
	lm.light_data = load(f) if ResourceLoader.exists(f) else null


## No baked light on `root`'s room from now (the Shardlands at dawn).
static func off(root: Node3D) -> void:
	var lm := root.get_node_or_null("BakedLight") as LightmapGI
	if lm != null:
		lm.light_data = null


## True when `root`'s room wears baked light now.
static func on(root: Node3D) -> bool:
	var lm := root.get_node_or_null("BakedLight") as LightmapGI
	return lm != null and lm.light_data != null


## The fixed things to bake in a room (the bake tool): every visible
## MeshInstance3D under `root` that isn't one of the nodes the room hands its
## scene (`out`'s, and anything under them), isn't see-through, glowing on
## its own or a view of somewhere else, and isn't skinned.
static func bakeable(root: Node3D, out: Dictionary) -> Array:
	var skip := {}
	_handed(out, skip)
	var res: Array = []
	for n in _walk(root):
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or mi.skeleton != NodePath("") and mi.get_node_or_null(mi.skeleton) is Skeleton3D:
			continue
		var under := false
		var p: Node = mi
		while p != null and p != root:
			if skip.has(p):
				under = true
				break
			p = p.get_parent()
		if under or not _solid(mi):
			continue
		res.append(mi)
	return res


static func _handed(v, skip: Dictionary) -> void:
	if v is Node3D and not (v as Node3D).name.begins_with("Taproom") and not (v as Node3D).name.begins_with("Attic"):
		skip[v] = true
	elif v is Dictionary:
		for k in v:
			if String(k) != "root":
				_handed(v[k], skip)
	elif v is Array:
		for x in v:
			_handed(x, skip)


## Lit by the room like a solid thing: every material opaque, shaded and
## mixed normally, nothing showing a viewport.
static func _solid(mi: MeshInstance3D) -> bool:
	for i in mi.mesh.get_surface_count():
		var m := mi.get_active_material(i)
		if m == null:
			continue
		if m is BaseMaterial3D:
			var b := m as BaseMaterial3D
			if b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED \
					or b.blend_mode != BaseMaterial3D.BLEND_MODE_MIX or b.albedo_texture is ViewportTexture:
				return false
		elif m is ShaderMaterial:
			var s := (m as ShaderMaterial).shader
			if s == null or s.code.contains("unshaded") or s.code.contains("blend_add"):
				return false
	return true
