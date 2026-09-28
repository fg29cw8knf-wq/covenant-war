class_name DollArt
extends RefCounted
## Character pictures for the walkable world ("paper dolls").
##
## Real art is loaded from res://assets/art/characters/<id>_front.png and
## <id>_back.png. Until an image exists, a placeholder figure is drawn from the
## look described in LOOKS below, so every character already reads as a
## distinct person on screen.

const DIR := "res://assets/art/characters/"
## Height in metres of a whole character image (head to feet plus margins).
const WORLD_HEIGHT := 2.0

## Placeholder looks: skin, hair colour and style, outfit, trim, legs,
## cloak (optional) and extras (hood, helm, beard, eyepatch, armor, robe).
const LOOKS := {
	"player": {"skin": "f1c7a3", "hair": "4a3426", "style": "short", "outfit": "3f5f8a", "trim": "d9b25f", "legs": "3a2f2a", "cloak": "6b7c93"},
	"bram": {"skin": "e8b894", "hair": "c9c3b8", "style": "bald", "outfit": "7a4a2a", "trim": "c69a52", "legs": "3b2a20", "extras": ["beard", "eyepatch"]},
	"wren": {"skin": "f3cfae", "hair": "b5552e", "style": "short", "outfit": "3f6b3f", "trim": "a58a4a", "legs": "2d3a2a", "cloak": "2f5a34", "extras": ["hood"]},
	"aldric": {"skin": "efc19c", "hair": "e3c26a", "style": "short", "outfit": "e8dcc0", "trim": "e0b040", "legs": "b9a36a", "cloak": "f2f0e6", "extras": ["armor"]},
	"guard": {"skin": "e2b18c", "hair": "5a4030", "style": "short", "outfit": "d8d2c0", "trim": "d1a43c", "legs": "8a8a92", "extras": ["helm", "armor"]},
	"acolyte": {"skin": "f2d0b0", "hair": "2c2420", "style": "long", "outfit": "f4efe2", "trim": "e2b64a", "legs": "c8bfa8", "extras": ["robe", "hood"]},
	"merchant": {"skin": "c98e66", "hair": "2a1c14", "style": "short", "outfit": "a8452f", "trim": "e6c060", "legs": "4a3226", "extras": ["beard"]},
	"child": {"skin": "f6d5b8", "hair": "e0a040", "style": "long", "outfit": "5d8fd0", "trim": "f2f2f2", "legs": "5a4a3a"},
	"elder": {"skin": "e7bf9e", "hair": "e8e4dc", "style": "long", "outfit": "6c5a8a", "trim": "cdb680", "legs": "4a4058", "extras": ["robe"]},
	"hunter": {"skin": "d9a883", "hair": "1e1a18", "style": "short", "outfit": "3a3a44", "trim": "b08a3a", "legs": "26262c", "cloak": "22222a", "extras": ["hood"]},
}

static var _cache := {}


static func has_art(id: String) -> bool:
	return ResourceLoader.exists(DIR + id + "_front.png")


## The character's picture seen from the front ("front") or behind ("back").
static func texture(id: String, view: String = "front") -> Texture2D:
	var key := id + ":" + view
	if _cache.has(key):
		return _cache[key]
	var t: Texture2D = null
	var path := DIR + "%s_%s.png" % [id, view]
	if ResourceLoader.exists(path):
		t = load(path)
	elif view == "back" and has_art(id):
		t = load(DIR + id + "_front.png")  # no back view drawn yet: reuse the front
	else:
		t = _placeholder(id, view)
	_cache[key] = t
	return t


## A head-and-shoulders crop for dialogue boxes.
static func portrait(id: String) -> Texture2D:
	var key := id + ":portrait"
	if _cache.has(key):
		return _cache[key]
	var t: Texture2D = null
	var path := DIR + id + "_portrait.png"
	if ResourceLoader.exists(path):
		t = load(path)
	else:
		var full := texture(id, "front")
		var img := full.get_image()
		if img != null:
			var w := img.get_width()
			var crop := img.get_region(Rect2i(int(w * 0.18), int(img.get_height() * 0.07), int(w * 0.64), int(w * 0.64)))
			t = ImageTexture.create_from_image(crop)
		else:
			t = full
	_cache[key] = t
	return t


# ---------------------------------------------------------- placeholder ---

static func _placeholder(id: String, view: String) -> Texture2D:
	var look: Dictionary = LOOKS.get(id, LOOKS.player)
	var svg := _svg(look, view == "back")
	var img := Image.new()
	if img.load_svg_from_string(svg, 2.0) != OK:
		img = Image.create(400, 600, false, Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _svg(k: Dictionary, back: bool) -> String:
	var ex: Array = k.get("extras", [])
	var skin: String = "#" + k.skin
	var hair: String = "#" + k.hair
	var outfit: String = "#" + k.outfit
	var trim: String = "#" + k.trim
	var legs: String = "#" + k.legs
	var cloak: String = ("#" + k.cloak) if k.has("cloak") else ""
	var metal := "#cfd3dc"
	var shapes: Array = []  # [path/shape markup without fill, fill colour]
	var robe := ex.has("robe")
	# legs and boots
	if not robe:
		shapes.append(["<rect x='78' y='222' width='19' height='60' rx='7'/>", legs])
		shapes.append(["<rect x='103' y='222' width='19' height='60' rx='7'/>", legs])
		shapes.append(["<rect x='74' y='262' width='25' height='22' rx='8'/>", "#2a2220"])
		shapes.append(["<rect x='101' y='262' width='25' height='22' rx='8'/>", "#2a2220"])
	# cloak behind the body
	if cloak != "":
		shapes.append(["<path d='M56 146 Q100 126 144 146 L162 272 Q100 286 38 272 Z'/>", cloak])
	# body
	if robe:
		shapes.append(["<path d='M60 150 Q100 134 140 150 L158 282 Q100 294 42 282 Z'/>", outfit])
		shapes.append(["<path d='M96 150 H104 L106 284 H94 Z'/>", trim])
	else:
		shapes.append(["<path d='M62 150 Q100 134 138 150 L148 240 Q100 252 52 240 Z'/>", outfit])
	shapes.append(["<rect x='56' y='204' width='88' height='10' rx='4'/>", trim])
	# arms and hands
	shapes.append(["<path d='M62 154 Q44 160 41 200 L43 224 Q52 230 58 222 L63 190 Z'/>", outfit])
	shapes.append(["<path d='M138 154 Q156 160 159 200 L157 224 Q148 230 142 222 L137 190 Z'/>", outfit])
	shapes.append(["<circle cx='49' cy='228' r='9'/>", skin])
	shapes.append(["<circle cx='151' cy='228' r='9'/>", skin])
	if ex.has("armor"):
		shapes.append(["<ellipse cx='60' cy='156' rx='18' ry='13'/>", metal])
		shapes.append(["<ellipse cx='140' cy='156' rx='18' ry='13'/>", metal])
		if not back:
			shapes.append(["<path d='M74 152 Q100 144 126 152 L122 198 Q100 206 78 198 Z'/>", metal])
			shapes.append(["<circle cx='100' cy='174' r='9'/>", trim])
	# neck and head
	shapes.append(["<rect x='90' y='126' width='20' height='18' rx='4'/>", skin])
	shapes.append(["<circle cx='100' cy='92' r='46'/>", skin])
	# hair / hood / helm
	var style: String = k.get("style", "short")
	if ex.has("hood"):
		var hood: String = cloak if cloak != "" else outfit
		if back:
			shapes.append(["<path d='M48 100 Q46 34 100 32 Q154 34 152 100 Q150 136 100 142 Q50 136 48 100 Z'/>", hood])
		else:
			shapes.append(["<path d='M48 100 Q46 34 100 32 Q154 34 152 100 Q150 128 138 140 L128 112 Q132 74 100 70 Q68 74 72 112 L62 140 Q50 128 48 100 Z'/>", hood])
	elif ex.has("helm"):
		if back:
			shapes.append(["<path d='M52 100 Q52 38 100 38 Q148 38 148 100 Q146 126 100 130 Q54 126 52 100 Z'/>", metal])
		else:
			shapes.append(["<path d='M52 98 Q52 38 100 38 Q148 38 148 98 L140 98 Q138 68 100 66 Q62 68 60 98 Z'/>", metal])
		shapes.append(["<path d='M94 20 Q100 12 106 20 L104 44 H96 Z'/>", trim])
	elif style != "bald":
		if back:
			shapes.append(["<path d='M52 96 Q50 40 100 40 Q150 40 148 96 Q148 130 100 136 Q52 130 52 96 Z'/>", hair])
			if style == "long":
				shapes.append(["<path d='M56 110 Q50 160 70 172 Q100 180 130 172 Q150 160 144 110 Z'/>", hair])
		else:
			if style == "long":
				shapes.append(["<path d='M54 86 Q46 150 64 160 L74 100 Z'/>", hair])
				shapes.append(["<path d='M146 86 Q154 150 136 160 L126 100 Z'/>", hair])
			shapes.append(["<path d='M53 94 Q50 42 100 40 Q150 42 147 94 Q140 70 124 62 Q108 76 80 70 Q62 74 53 94 Z'/>", hair])
	if ex.has("beard") and not back:
		shapes.append(["<path d='M64 104 Q100 160 136 104 Q134 142 100 150 Q66 142 64 104 Z'/>", hair])

	var under := ""
	var over := ""
	for sh in shapes:
		under += _with(sh[0], "#ffffff", "#ffffff", 14)
		over += _with(sh[0], sh[1], "#1c1a26", 3.5)
	# face details
	var face := ""
	if not back:
		face += "<ellipse cx='84' cy='98' rx='6' ry='8' fill='#1c1a26'/><circle cx='86' cy='95' r='2.2' fill='#fff'/>"
		if ex.has("eyepatch"):
			face += "<path d='M60 80 L140 104' stroke='#1c1a26' stroke-width='3'/><ellipse cx='116' cy='98' rx='10' ry='9' fill='#1c1a26'/>"
		else:
			face += "<ellipse cx='116' cy='98' rx='6' ry='8' fill='#1c1a26'/><circle cx='118' cy='95' r='2.2' fill='#fff'/>"
		face += "<ellipse cx='76' cy='114' rx='7' ry='4' fill='#e06a6a' fill-opacity='0.25'/><ellipse cx='124' cy='114' rx='7' ry='4' fill='#e06a6a' fill-opacity='0.25'/>"
		if not ex.has("beard"):
			face += "<path d='M92 118 Q100 124 108 118' fill='none' stroke='#1c1a26' stroke-width='3' stroke-linecap='round'/>"
		else:
			face += "<path d='M92 122 Q100 126 108 122' fill='none' stroke='#1c1a26' stroke-width='3' stroke-linecap='round'/>"
	return "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 300'>%s%s%s</svg>" % [under, over, face]


static func _with(shape: String, fill: String, stroke: String, width: float) -> String:
	var attrs := " fill='%s' stroke='%s' stroke-width='%s' stroke-linejoin='round'" % [fill, stroke, width]
	# insert attributes after the element name
	var i := shape.find(" ")
	return shape.substr(0, i) + attrs + shape.substr(i)
