extends Node
## How long the pack's Deck tab takes to come up with a full 30-card deck
## (the campfire's "short stall", Still to Make item 29): a new game past the
## Prologue with Bram's deck, then the pack opened on Deck cold (nothing
## loaded), closed, and opened again after CardFace.warm_art had a second
## (as the campfire does), and again warm. Prints the build time of the page
## (show_tab, synchronous), the first frame after it and the longest of the
## next ten, in milliseconds. Run with a real renderer, and read the numbers
## as a proxy: a phone is slower at the same things.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --resolution 1600x900 res://tests/deck_open_probe.tscn

var world: World


func _ready() -> void:
	get_viewport().scaling_3d_scale = 0.5
	Game.new_game("Ash", "emberstorm")
	Game.flags["arrived_solhaven"] = true
	for f in ["ash_marked", "ash_won_lantern", "bram_deck", "beat_hunter", "met_bram"]:
		Game.flags[f] = true
	world = World.new().setup("solhaven", "gate")
	add_child(world)
	for i in 40:
		await get_tree().process_frame
	var ids: Array = DuelCards.card_list("emberstorm")
	print("deck of %d cards, %d distinct paintings" % [ids.size(), _distinct(ids).size()])
	await _open("cold", "deck")
	await _open("again, art cached", "deck")
	# the codex as a comparison (every card known)
	await _open("codex", "codex")
	# a fresh run of the art cache: as the campfire warms it
	CardFace._art.clear()
	CardFace.warm_art(_distinct(ids))
	await get_tree().create_timer(1.0).timeout
	await _open("after warm_art", "deck")
	# the phone link's way (no threads): the paintings loaded one a frame
	CardFace._art.clear()
	CardFace.force_spread = true
	CardFace.warm_art(_distinct(ids))
	var t0 := Time.get_ticks_usec()
	var frames := 0
	var longest := 0.0
	while CardFace._spreading or not CardFace._queued.is_empty():
		var f0 := Time.get_ticks_usec()
		await get_tree().process_frame
		longest = maxf(longest, (Time.get_ticks_usec() - f0) / 1000.0)
		frames += 1
	print("spread loads (web): %d paintings over %d frames, %.0f ms in all, the longest frame %.1f ms" % [CardFace._art.size(), frames, (Time.get_ticks_usec() - t0) / 1000.0, longest])
	await _open("after the spread", "deck")
	CardFace.force_spread = false
	print("DECK OPEN PROBE: done")
	get_tree().quit()


func _distinct(ids: Array) -> Array:
	var out := []
	for id in ids:
		if not out.has(id):
			out.append(id)
	return out


func _open(label: String, tab: String) -> void:
	var menu: PauseMenu = world.hud._menu
	var t0 := Time.get_ticks_usec()
	world.hud.open_menu(tab)
	var build := (Time.get_ticks_usec() - t0) / 1000.0
	t0 = Time.get_ticks_usec()
	await RenderingServer.frame_post_draw
	var first := (Time.get_ticks_usec() - t0) / 1000.0
	var longest := 0.0
	for i in 10:
		t0 = Time.get_ticks_usec()
		await RenderingServer.frame_post_draw
		longest = maxf(longest, (Time.get_ticks_usec() - t0) / 1000.0)
	print("%-18s %-6s build %6.1f ms, first frame %6.1f ms, longest of the next ten %6.1f ms" % [label, tab, build, first, longest])
	world.hud.close_menu()
	for i in 20:
		await get_tree().process_frame
