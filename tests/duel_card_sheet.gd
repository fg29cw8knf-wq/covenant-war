extends SceneTree
## Renders a sheet of card faces to a PNG for visual review.
## Needs a real renderer (not --headless):
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 \
##       --script res://tests/card_sheet.gd -- out.png [card ids...] [--size 250] [--compact]

var _ids: Array = []
var _size := 250.0
var _compact := false
var _out := "user://duel_card_sheet.png"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		var a: String = args[i]
		if a == "--size":
			_size = float(args[i + 1])
			i += 1
		elif a == "--compact":
			_compact = true
		elif a.ends_with(".png"):
			_out = a
		else:
			_ids.append(a)
		i += 1
	if _ids.is_empty():
		for id in DuelCards.CARDS:
			_ids.append(id)
	var cols := mini(8, _ids.size())
	var rows := int(ceil(_ids.size() / float(cols)))
	var cw := _size
	var ch := _size * (350.0 / 250.0)
	var pad := 16.0
	var win := Vector2i(int(cols * (cw + pad) + pad), int(rows * (ch + pad) + pad + 40))
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = win
	DisplayServer.window_set_size(win)
	var bg := ColorRect.new()
	bg.color = Color("20232e")
	bg.size = Vector2(win)
	root.add_child(bg)
	var sheet := Sheet.new()
	sheet.ids = _ids
	sheet.cw = cw
	sheet.ch = ch
	sheet.pad = pad
	sheet.cols = cols
	sheet.compact = _compact
	sheet.size = Vector2(win)
	root.add_child(sheet)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(_out)
	print("saved ", _out, " ", img.get_size())
	quit()


class Sheet:
	extends Control
	var ids: Array
	var cw: float
	var ch: float
	var pad: float
	var cols: int
	var compact: bool

	func _draw() -> void:
		CardFace.text(self, CardFace.font("display_bold"), Vector2(pad, 30), "The Covenant War — duel cards v1", 20, CardFace.GOLD)
		for i in ids.size():
			var x := pad + (i % cols) * (cw + pad)
			var y := 40 + pad + (i / cols) * (ch + pad)
			var r := Rect2(x, y, cw, ch)
			if ids[i] == "_back":
				DuelCardFace.draw_back(self, r)
			else:
				var opts := {"compact": compact}
				if i % 2 == 0:
					opts["attrs"] = {"might": 7, "resolve": 7, "swiftness": 7, "cunning": 7, "insight": 7, "intellect": 7, "presence": 7}
				DuelCardFace.draw_card(self, r, ids[i], opts)
