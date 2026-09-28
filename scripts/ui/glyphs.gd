class_name Glyphs
extends RefCounted
## White vector icons for the 16 elements, the 7 attributes and a few UI marks.
## They are SVG drawn on a 100 x 100 grid and rasterised at whatever size is
## asked for, so they stay crisp on a phone and on a 5K display.
## Draw them tinted: draw_texture_rect(Glyphs.tex("fire", 64), rect, false, colour)

const _S := "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>%s</svg>"
const _STROKE := "fill='none' stroke='#fff' stroke-linecap='round' stroke-linejoin='round'"

const SHAPES := {
	# ----------------------------------------------------------- elements
	"fire": "<path fill='#fff' d='M52 4 C60 22 80 34 80 60 C80 80 66 95 50 95 C33 95 20 81 20 63 C20 49 27 40 35 30 C37 42 42 49 48 52 C44 36 44 20 52 4 Z'/><path fill='#000' fill-opacity='0.25' d='M50 88 C60 88 66 80 66 70 C66 60 58 54 54 46 C52 56 46 60 42 64 C38 68 36 72 36 76 C36 83 42 88 50 88 Z'/>",
	"frost": "<g %s stroke-width='7'><path d='M50 6 V94 M50 18 L40 8 M50 18 L60 8 M50 82 L40 92 M50 82 L60 92'/><path d='M50 6 V94 M50 18 L40 8 M50 18 L60 8 M50 82 L40 92 M50 82 L60 92' transform='rotate(60 50 50)'/><path d='M50 6 V94 M50 18 L40 8 M50 18 L60 8 M50 82 L40 92 M50 82 L60 92' transform='rotate(120 50 50)'/></g>" % _STROKE,
	"tide": "<path fill='#fff' d='M50 5 C50 5 18 44 18 64 C18 82 32 95 50 95 C68 95 82 82 82 64 C82 44 50 5 50 5 Z'/><path %s stroke='#000' stroke-opacity='0.28' stroke-width='6' d='M30 66 C38 58 44 74 52 66 C60 58 66 74 72 66'/>" % _STROKE,
	"storm": "<path fill='#fff' d='M60 3 L20 55 L45 55 L36 97 L80 38 L55 38 L66 3 Z'/>",
	"earth": "<path fill='#fff' d='M4 88 L36 32 L49 52 L65 20 L96 88 Z'/><path fill='#000' fill-opacity='0.28' d='M65 20 L74 38 L66 34 L60 42 L57 35 Z M36 32 L42 43 L36 40 L31 45 Z'/>",
	"wind": "<g %s stroke-width='8'><path d='M8 36 H60 C72 36 80 29 80 20 C80 12 74 7 67 7 C59 7 55 13 55 19'/><path d='M8 56 H76 C87 56 94 63 94 72 C94 81 87 88 79 88 C71 88 66 82 66 76'/><path d='M8 76 H44'/></g>" % _STROKE,
	"verdant": "<path fill='#fff' d='M14 90 C12 42 42 12 90 10 C90 60 60 88 14 90 Z'/><path %s stroke='#000' stroke-opacity='0.3' stroke-width='5' d='M20 84 L72 30 M40 64 L40 46 M54 50 L68 50'/>" % _STROKE,
	"metal": "<path fill='#fff' fill-rule='evenodd' d='M50 5 L89 27 L89 73 L50 95 L11 73 L11 27 Z M50 32 C60 32 68 40 68 50 C68 60 60 68 50 68 C40 68 32 60 32 50 C32 40 40 32 50 32 Z'/>",
	"venom": "<path fill='none' stroke='#fff' stroke-width='13' stroke-linecap='round' d='M22 90 C4 74 18 56 40 58 C62 60 80 52 76 32'/><path fill='#fff' d='M60 30 C60 16 72 8 84 12 C96 16 96 32 86 38 C78 42 64 42 60 30 Z'/><circle cx='80' cy='22' r='3.5' fill='#000' fill-opacity='0.45'/><path fill='none' stroke='#fff' stroke-width='4' stroke-linecap='round' d='M92 34 L98 42 M92 34 L100 34'/><circle cx='18' cy='20' r='7' fill='#fff' fill-opacity='0.8'/><circle cx='34' cy='32' r='4.5' fill='#fff' fill-opacity='0.6'/>",
	"psychic": "<path fill='#fff' fill-rule='evenodd' d='M3 50 C22 18 78 18 97 50 C78 82 22 82 3 50 Z M68 50 C68 40 60 32 50 32 C40 32 32 40 32 50 C32 60 40 68 50 68 C60 68 68 60 68 50 Z'/><circle fill='#fff' cx='50' cy='50' r='10'/>",
	"mystic": "<g %s stroke-width='6'><circle cx='50' cy='50' r='42'/><path d='M50 12 L83 69 H17 Z'/><path d='M50 88 L17 31 H83 Z' stroke-opacity='0.5'/></g><circle fill='#fff' cx='50' cy='50' r='7'/>" % _STROKE,
	"spirit": "<path fill='#fff' fill-rule='evenodd' d='M18 92 V46 C18 26 32 10 50 10 C68 10 82 26 82 46 V92 L71 81 L61 92 L50 81 L39 92 L29 81 Z M36 38 C31 38 30 44 30 48 C30 52 32 56 36 56 C40 56 42 52 42 48 C42 44 41 38 36 38 Z M64 38 C59 38 58 44 58 48 C58 52 60 56 64 56 C68 56 70 52 70 48 C70 44 69 38 64 38 Z'/>",
	"radiant": "<circle fill='#fff' cx='50' cy='50' r='21'/><g fill='#fff'><path d='M50 2 L57 22 H43 Z'/><path d='M50 2 L57 22 H43 Z' transform='rotate(45 50 50)'/><path d='M50 2 L57 22 H43 Z' transform='rotate(90 50 50)'/><path d='M50 2 L57 22 H43 Z' transform='rotate(135 50 50)'/><path d='M50 2 L57 22 H43 Z' transform='rotate(180 50 50)'/><path d='M50 2 L57 22 H43 Z' transform='rotate(225 50 50)'/><path d='M50 2 L57 22 H43 Z' transform='rotate(270 50 50)'/><path d='M50 2 L57 22 H43 Z' transform='rotate(315 50 50)'/></g>",
	"umbral": "<path fill='#fff' d='M47.9 10 A40 40 0 1 0 87.1 64.9 A34 34 0 1 1 47.9 10 Z'/><path fill='#fff' d='M74 14 L77 22 L85 25 L77 28 L74 36 L71 28 L63 25 L71 22 Z'/>",
	"astral": "<path fill='#fff' d='M44 6 C48 36 56 44 86 48 C56 52 48 60 44 90 C40 60 32 52 2 48 C32 44 40 36 44 6 Z'/><path fill='#fff' d='M80 62 C81 72 84 75 94 76 C84 77 81 80 80 90 C79 80 76 77 66 76 C76 75 79 72 80 62 Z'/><circle fill='#fff' cx='82' cy='18' r='5'/>",
	"void": "<path fill='#fff' fill-rule='evenodd' d='M6 50 A44 44 0 1 0 94 50 A44 44 0 1 0 6 50 Z M28 50 A22 22 0 1 1 72 50 A22 22 0 1 1 28 50 Z'/><path %s stroke-width='6' d='M50 38 C58 38 62 44 62 50'/>" % _STROKE,
	"any": "<path fill='#fff' d='M50 4 L59 37 L92 26 L67 50 L92 74 L59 63 L50 96 L41 63 L8 74 L33 50 L8 26 L41 37 Z'/>",
	# --------------------------------------------------------- attributes
	"might": "<path fill='#fff' d='M47 4 H53 L57 62 H43 Z M28 62 H72 V70 H28 Z M45 70 H55 V88 H45 Z'/><circle fill='#fff' cx='50' cy='92' r='6'/>",
	"resolve": "<path fill='#fff' fill-rule='evenodd' d='M50 4 L88 16 V46 C88 72 72 88 50 96 C28 88 12 72 12 46 V16 Z M50 18 L26 26 V46 C26 64 36 76 50 82 Z'/>",
	"swiftness": "<path fill='#fff' d='M8 88 C30 80 46 66 58 48 C70 30 80 16 94 8 C88 28 80 44 68 58 C56 72 36 84 8 88 Z'/><path %s stroke-width='6' d='M6 60 H30 M14 44 H40 M24 28 H48'/>" % _STROKE,
	"cunning": "<path fill='#fff' fill-rule='evenodd' d='M4 38 C20 28 36 30 50 40 C64 30 80 28 96 38 C94 60 78 70 64 66 C58 64 54 58 50 54 C46 58 42 64 36 66 C22 70 6 60 4 38 Z M22 44 C26 52 34 54 40 48 C34 42 26 40 22 44 Z M78 44 C74 52 66 54 60 48 C66 42 74 40 78 44 Z'/>",
	"insight": "<circle fill='#fff' cx='50' cy='40' r='30'/><path fill='#000' fill-opacity='0.3' d='M36 26 C40 20 48 18 54 20 C46 22 40 26 36 34 Z'/><path fill='#fff' d='M30 74 H70 L76 92 H24 Z'/>",
	"intellect": "<path fill='#fff' d='M50 22 C40 14 22 12 6 16 V84 C22 80 40 82 50 90 Z M50 22 C60 14 78 12 94 16 V84 C78 80 60 82 50 90 Z'/><path %s stroke='#000' stroke-opacity='0.3' stroke-width='4' d='M50 24 V88'/>" % _STROKE,
	"presence": "<path fill='#fff' d='M8 30 L28 52 L50 16 L72 52 L92 30 L84 80 H16 Z M16 86 H84 V94 H16 Z'/><circle fill='#fff' cx='8' cy='28' r='6'/><circle fill='#fff' cx='50' cy='13' r='6'/><circle fill='#fff' cx='92' cy='28' r='6'/>",
	# ---------------------------------------------------------------- UI
	"heart": "<path fill='#fff' d='M50 90 C20 68 6 52 6 34 C6 20 17 10 30 10 C39 10 46 15 50 22 C54 15 61 10 70 10 C83 10 94 20 94 34 C94 52 80 68 50 90 Z'/>",
	"retreat": "<path fill='#fff' d='M40 14 L8 50 L40 86 V64 H92 V36 H40 Z'/>",
	"crown_sigil": "<path fill='#fff' fill-rule='evenodd' d='M50 2 L98 50 L50 98 L2 50 Z M50 18 L82 50 L50 82 L18 50 Z'/><path fill='#fff' d='M30 58 L36 40 L44 50 L50 34 L56 50 L64 40 L70 58 Z'/>",
	"prize": "<path fill='#fff' d='M50 4 L63 36 L97 38 L70 60 L80 94 L50 74 L20 94 L30 60 L3 38 L37 36 Z'/>",
	"deck": "<path fill='#fff' d='M24 10 H76 C80 10 82 12 82 16 V84 C82 88 80 90 76 90 H24 C20 90 18 88 18 84 V16 C18 12 20 10 24 10 Z'/><path fill='#000' fill-opacity='0.3' fill-rule='evenodd' d='M50 28 L66 50 L50 72 L34 50 Z M50 38 L58 50 L50 62 L42 50 Z'/>",
	"talk": "<path fill='#fff' d='M14 14 H86 C92 14 96 18 96 24 V62 C96 68 92 72 86 72 H46 L24 90 L28 72 H14 C8 72 4 68 4 62 V24 C4 18 8 14 14 14 Z'/><circle fill='#000' fill-opacity='0.35' cx='30' cy='43' r='7'/><circle fill='#000' fill-opacity='0.35' cx='50' cy='43' r='7'/><circle fill='#000' fill-opacity='0.35' cx='70' cy='43' r='7'/>",
	"duel": "<g fill='#fff'><path d='M20 18 H56 C59 18 61 20 61 23 V77 C61 80 59 82 56 82 H20 C17 82 15 80 15 77 V23 C15 20 17 18 20 18 Z' transform='rotate(-16 38 50)'/><path d='M44 18 H80 C83 18 85 20 85 23 V77 C85 80 83 82 80 82 H44 C41 82 39 80 39 77 V23 C39 20 41 18 44 18 Z' transform='rotate(16 62 50)'/></g><path fill='#000' fill-opacity='0.3' d='M62 34 L70 50 L62 66 L54 50 Z' transform='rotate(16 62 50)'/>",
	"menu": "<g fill='#fff'><rect x='12' y='18' width='76' height='12' rx='6'/><rect x='12' y='44' width='76' height='12' rx='6'/><rect x='12' y='70' width='76' height='12' rx='6'/></g>",
	"coin": "<circle fill='#fff' cx='50' cy='50' r='44'/><circle fill='#000' fill-opacity='0.25' cx='50' cy='50' r='34'/><path fill='#fff' d='M50 22 L58 42 L78 44 L62 58 L68 78 L50 66 L32 78 L38 58 L22 44 L42 42 Z'/>",
}

static var _cache := {}


## A white icon texture about `px` pixels across (cached by size bucket).
static func tex(name: String, px: float = 64.0) -> Texture2D:
	var size := _bucket(px)
	var key := "%s@%d" % [name, size]
	if _cache.has(key):
		return _cache[key]
	var svg: String = _S % SHAPES.get(name, SHAPES.any)
	var img := Image.new()
	var err := img.load_svg_from_string(svg, size / 100.0)
	if err != OK:
		push_warning("Glyph %s failed to rasterise" % name)
		img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


static func _bucket(px: float) -> int:
	# Rasterise at the next size up from a fixed ladder so the cache stays small
	# and downscaling (with mipmaps) keeps edges smooth.
	for s in [32, 48, 64, 96, 128, 192, 256, 384, 512]:
		if px * 1.5 <= s:
			return s
	return 512


## Draw an icon centred at `c`, `r` pixels from centre to edge, tinted `col`.
static func draw(ci: CanvasItem, name: String, c: Vector2, r: float, col: Color = Color.WHITE) -> void:
	var t := tex(name, r * 2.0)
	ci.draw_texture_rect(t, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, col)
