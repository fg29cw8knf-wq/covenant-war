class_name DuelArt
extends RefCounted
## Finds the painted art for the duel. Every picture is optional: when a
## file is missing the game falls back to its drawn placeholder.
##
##   assets/art/cards/<card id>.jpg        card paintings (CardFace.art)
##   assets/art/creatures/<card id>.webp   battlefield cut-outs (transparent)
##   assets/art/summons/<card id>.webp     Summon cut-outs (transparent)
##   assets/art/summons/<card id>_scene.jpg  the sky behind a Summon
##   assets/art/arenas/arena_<name>.jpg    duel backgrounds
##   assets/art/gods/<god id>.jpg          patron portraits
##   assets/art/card_back.jpg

static var _cache := {}

## Creatures that float rather than stand.
const FLYERS := ["emberwisp", "bloomsprite"]

## Which arena each starter deck calls home.
const DECK_ARENA := {
	"emberstorm": "emberforge", "tidegrove": "tidegrove", "ironstone": "ironstone", "veilwild": "veilwild",
}


static func _load(base: String, exts: Array = ["webp", "png", "jpg"]) -> Texture2D:
	if _cache.has(base):
		return _cache[base]
	var tex: Texture2D = null
	for ext in exts:
		var p := "%s.%s" % [base, ext]
		if ResourceLoader.exists(p):
			tex = load(p)
			break
	_cache[base] = tex
	return tex


static func creature(id: String) -> Texture2D:
	return _load("res://assets/art/creatures/" + id)


static func summon(id: String) -> Texture2D:
	return _load("res://assets/art/summons/" + id)


static func summon_scene(id: String) -> Texture2D:
	return _load("res://assets/art/summons/%s_scene" % id, ["jpg", "webp", "png"])


static func arena(name: String) -> Texture2D:
	return _load("res://assets/art/arenas/arena_" + name, ["jpg", "webp", "png"])


static func god(id: String) -> Texture2D:
	if id == "":
		return null
	return _load("res://assets/art/gods/" + id, ["jpg", "webp", "png"])


## The arena seen from above, for the 3D field's floor.
static func mat(name: String) -> Texture2D:
	return _load("res://assets/art/mats/mat_" + name, ["jpg", "webp", "png"])


## The scenery behind the far edge of the 3D field.
static func backdrop(name: String) -> Texture2D:
	return _load("res://assets/art/mats/back_" + name, ["jpg", "webp", "png"])


static func card_back() -> Texture2D:
	return _load("res://assets/art/card_back", ["jpg", "webp", "png"])


static func arena_for_deck(deck) -> String:
	if deck is String:
		return DECK_ARENA.get(deck, "solhaven")
	return "solhaven"


## Draws `tex` to fill `r` completely, cropping the edges (focus 0-1 picks which part stays).
static func cover(ci: CanvasItem, r: Rect2, tex: Texture2D, focus := Vector2(0.5, 0.5), mod := Color.WHITE) -> void:
	var ts := Vector2(tex.get_width(), tex.get_height())
	var k := maxf(r.size.x / ts.x, r.size.y / ts.y)
	var src_size := r.size / k
	var src := Rect2((ts - src_size) * focus, src_size)
	ci.draw_texture_rect_region(tex, r, src, mod)


## A face-crop of a god's portrait inside a circle.
static func god_medallion(ci: CanvasItem, c: Vector2, rad: float, id: String, rim: Color) -> bool:
	var tex := god(id)
	if tex == null:
		return false
	var ts := Vector2(tex.get_width(), tex.get_height())
	var side := ts.x * 0.44
	var src := Rect2(Vector2((ts.x - side) * 0.5, ts.y * 0.06), Vector2(side, side))
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		var d := Vector2(cos(a), sin(a))
		pts.append(c + d * rad)
		uvs.append((src.position + (d * 0.5 + Vector2(0.5, 0.5)) * src.size) / ts)
	ci.draw_polygon(pts, PackedColorArray([Color.WHITE]), uvs, tex)
	ci.draw_arc(c, rad, 0, TAU, 48, rim, maxf(2.0, rad * 0.08), true)
	return true


## Draws `tex` stretched over `r` with rounded corners.
static func rounded(ci: CanvasItem, r: Rect2, radius: float, tex: Texture2D, mod := Color.WHITE) -> void:
	var pts := CardFace.round_rect_points(r, radius)
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append((p - r.position) / r.size)
	ci.draw_polygon(pts, PackedColorArray([mod]), uvs, tex)
