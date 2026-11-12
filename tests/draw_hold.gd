extends RefCounted
## Who wants frames drawn while a test runs in "keys" mode (only the frames
## kept are drawn: much faster). The play-throughs' stills and the body
## check's glitch stills (tests/body_check.gd) share it, so neither stops the
## drawing while the other is still waiting for its frame.
##
##   const DrawHold = preload("res://tests/draw_hold.gd")
##   DrawHold.keys = true            # at the start, in keys mode
##   DrawHold.hold() ... await RenderingServer.frame_post_draw ... DrawHold.release()

static var holds := 0
static var keys := false


static func start_keys() -> void:
	keys = true
	if holds == 0:
		RenderingServer.render_loop_enabled = false


static func hold() -> void:
	holds += 1
	RenderingServer.render_loop_enabled = true


static func release() -> void:
	holds = maxi(0, holds - 1)
	if holds == 0 and keys:
		RenderingServer.render_loop_enabled = false
