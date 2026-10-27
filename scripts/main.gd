extends Node
## The game's root: switches between the title screen, story scenes, the
## walkable world and duels.

var _current: Node = null
var _world: World = null
## New Game's Ashford, built under the title screen a piece a frame
## (World.prepare), so the attic comes up the moment the opening movie ends or
## is skipped instead of after a long wait; the game state from before it was
## built goes back if the player picks anything but New Game.
var _prepared: World = null
var _kept := {}
var _starting := false   # New Game pressed before the world could be prepared


func _ready() -> void:
	get_tree().root.theme = UITheme.make()
	var args := OS.get_cmdline_user_args()
	if "--lab" in args or "--lab-watch" in args:
		show_lab()
		return
	LaunchLog.start()
	if get_tree().current_scene == self and not "--no-notice" in args:
		# who made the game, and a word about the adverts (tests that load
		# main.tscn inside their own scene skip it). Nothing is built under
		# it: it's up and taking taps at once.
		var notice := NoticeScreen.new()
		add_child(notice)
		LaunchLog.mark("notice")
		await notice.finished
	show_title()


## The opening movie; returns when it ends or is skipped (on the web, its
## download can be skipped too).
func play_opening() -> void:
	# (the phone link streams the film, and fetches the Theora pack only if
	# the stream can't play: OpeningMovie._play)
	if not OpeningMovie.streams() and not await Packs.need("movie", true):
		return
	var movie := OpeningMovie.new()
	add_child(movie)
	await movie.finished
	Game.settings["seen_opening"] = true
	Game.save_settings()


func _swap(n: Node) -> void:
	if _current != null:
		_current.queue_free()
	_current = n
	_world = n as World
	if n != null:
		add_child(n)


# ---------------------------------------------------------------- title ---

func show_title() -> void:
	var holder := Node.new()
	holder.name = "Title"
	if not TitleScreen.has_art() and Packs.has("solhaven"):
		# until the painted title exists, the old slow flight over Solhaven
		var backdrop := World.new().setup("solhaven", "gate")
		backdrop.attract = true
		holder.add_child(backdrop)
	var title := TitleScreen.new()
	holder.add_child(title)
	title.new_game.connect(_on_new_game)
	title.continue_game.connect(_on_continue)
	title.watch_opening.connect(func() -> void:
		await play_opening())
	title.open_lab.connect(func() -> void:
		_drop_prepared()
		show_lab())
	title.open_puzzles.connect(func() -> void:
		_drop_prepared()
		show_puzzles())
	_swap(holder)
	_world = null
	_starting = false
	LaunchLog.mark("title")
	_prepare_new_game()


## Builds New Game's Ashford under the title screen, a piece a frame, once
## the title has had a moment to paint. Nothing of it shows, and once built
## it neither draws nor runs until _on_new_game lets it go.
func _prepare_new_game() -> void:
	if _prepared != null or not TitleScreen.has_art():
		return
	await get_tree().create_timer(0.5).timeout
	if _current == null or _current.name != "Title" or _prepared != null or _starting:
		return
	_kept = Game.save_data()
	Game.new_game("Sprout", "")
	var w := World.new()
	w.ahead = true
	w.setup("ashford", "green")
	w.duel_handler = run_duel
	w.exit_to_title.connect(show_title)
	w.story_next.connect(_on_story_next)
	_prepared = w
	# The first launch of a build compiles every shader the opening draws
	# the first time it's drawn, and on an iPhone (Metal) that can hold the
	# screen for a long moment with nothing to say why: on the first launch
	# it's done behind a loading bar, so the title never looks hung, and
	# every launch after finds the shaders in the cache. (Ashford itself is
	# built a piece a frame, and never holds the notice or the title.)
	var first := first_launch()
	var holding: CanvasLayer = Packs.hold("Getting the game ready: the first time takes a moment") if first else null
	LaunchLog.mark("ashford building" + (", first launch" if first else ""))
	var watch := LaunchLog.FrameWatch.new()
	add_child(watch)
	add_child(w)
	await w.prepare()
	LaunchLog.mark("ready, slowest frame %d ms" % watch.report())
	if holding != null:
		holding.queue_free()
		Game.settings["warmed"] = Packs.build_id()
		Game.save_settings()


## True until this build's shaders have been warmed once on this device (the
## apps; the phone link and the editor compile theirs every time anyway).
## `-- --first-launch` makes any run behave as one.
static func first_launch() -> bool:
	if "--first-launch" in OS.get_cmdline_user_args():
		return true
	if OS.has_feature("web") or OS.has_feature("editor"):
		return false
	return String(Game.settings.get("warmed", "")) != Packs.build_id()


## The world built for a New Game isn't wanted (Continue, the Duel Lab): it
## goes, and the game as it was comes back.
func _drop_prepared() -> void:
	if _prepared == null:
		return
	_prepared.queue_free()
	_prepared = null
	if not _kept.is_empty():
		Game.load_data(_kept)
	_kept = {}


func _on_continue() -> void:
	_drop_prepared()
	if Game.load_game():
		go_world(Game.area, Game.spawn)
	else:
		_on_new_game()


func _on_new_game() -> void:
	# The story starts with the opening movie (skippable), then Ashford: the
	# festival and the Sigilfall are played in the village. The player's real
	# name is asked later, when the herald reads it out. No cards yet: Bram
	# hands over the first deck in Ashford, before the Lantern Duel.
	if _prepared == null:
		_starting = true
		await play_opening()
		Game.new_game("Sprout", "")
		go_world("ashford", "green")
		return
	# Ashford was built under the title screen (or is still being built,
	# under the movie now): the attic starts the moment the movie's done.
	# On the web the movie's download can be skipped like the movie itself.
	var done := [false]
	if OpeningMovie.streams() or await Packs.need("movie", true):
		var movie := OpeningMovie.new()
		add_child(movie)
		movie.finished.connect(func() -> void: done[0] = true)
	else:
		done[0] = true
	_swap(null)   # the title screen's gone (under the movie anyway)
	# if the movie's over before Ashford is ready (New Game pressed the
	# moment the title came up, then Skip), say so rather than sit on black
	var holding: CanvasLayer = null
	while not done[0] or _prepared == null or not _prepared.prepared:
		if done[0] and holding == null:
			holding = Packs.hold("Lighting the lanterns in Ashford")
		await get_tree().process_frame
	if holding != null:
		holding.queue_free()
	Game.settings["seen_opening"] = true
	Game.save_settings()
	Packs.want("looks")   # (Ironvault's hunters in Ashford: Player D)
	var w := _prepared
	_prepared = null
	_kept = {}
	_current = w
	_world = w
	w.release()
	Game.save_game()


# -------------------------------------------------------------- duel lab ---

func show_lab() -> void:
	var lab := DuelLab.new()
	lab.closed.connect(show_title)
	_swap(lab)


# --------------------------------------------------------- Bram's Riddles ---

## The one-turn duel puzzles (DuelPuzzles): pick one, play it (as many tries
## as it takes, or leave), and back to the list with it ticked if solved.
func show_puzzles() -> void:
	var menu := PuzzleMenu.new()
	menu.closed.connect(show_title)
	menu.play.connect(func(i: int) -> void:
		var won := await run_duel(DuelPuzzles.spec(i, Game.player_name))
		if won:
			DuelPuzzles.mark_solved(String(DuelPuzzles.get_puzzle(i).id))
		show_puzzles())
	_swap(menu)


# ---------------------------------------------------------------- world ---

func go_world(area: String, spawn: String) -> void:
	if area == "solhaven":
		await Packs.need("solhaven")
	# (the phone link: Gary's Player B, C and D models, who play Dask, Wren and
	# Ironvault's hunters since v7: fetched before the places they're in,
	# and quietly in the background everywhere else)
	if area in ["thornwood", "solhaven"]:
		await Packs.need("looks")
	else:
		Packs.want("looks")
	var w := World.new().setup(area, spawn)
	w.duel_handler = run_duel
	w.exit_to_title.connect(show_title)
	w.story_next.connect(_on_story_next)
	_swap(w)
	Game.save_game()


## The story moving on from one place to the next.
func _on_story_next(what: String) -> void:
	match what:
		"thornwood":
			go_world("thornwood", "river")
		"solhaven":
			go_world("solhaven", "gate")


# ---------------------------------------------------------------- duels ---

## Plays a duel on top of whatever is showing; returns true if the player won.
func run_duel(spec: Dictionary) -> bool:
	var hidden_world := _world
	var world_mode := Node.PROCESS_MODE_INHERIT
	if hidden_world != null:
		hidden_world.visible = false
		if hidden_world.hud != null:
			hidden_world.hud.visible = false
		# the place stops still under the duel, not only out of sight: until
		# 27 October Ashford's whole festival (every villager's animation, the
		# lanterns, the grass, the scripts) carried on behind the first duel,
		# and on the phone it ran slow and kept freezing (Gary)
		world_mode = hidden_world.process_mode
		hidden_world.process_mode = Node.PROCESS_MODE_DISABLED
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var won := false
	await Packs.need("duel")
	if spec.has("decks"):
		# a duel on the v1 rules; an advert may come first (Ads has the rules)
		await Ads.before_duel(spec)
		var ds := DuelScreen.new().configure(spec)
		layer.add_child(ds)
		var r: String = await ds.finished
		while r == "again":
			ds.queue_free()
			await Ads.before_duel(spec, true)
			ds = DuelScreen.new().configure(spec)
			layer.add_child(ds)
			r = await ds.finished
		won = r == "won"
	else:
		var screen := BattleScreen.new().configure(spec)
		layer.add_child(screen)
		won = await screen.finished
	layer.queue_free()
	if hidden_world != null and is_instance_valid(hidden_world):
		hidden_world.process_mode = world_mode
		hidden_world.visible = true
		if hidden_world.hud != null:
			hidden_world.hud.visible = true
		hidden_world.resume_music()   # the area's music carries on from where it left off
	return won
