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
	if get_tree().current_scene == self and not "--no-notice" in args:
		# who made the game, and a word about the adverts (tests that load
		# main.tscn inside their own scene skip it)
		var notice := NoticeScreen.new()
		add_child(notice)
		await notice.finished
	show_title()


## The opening movie; returns when it ends or is skipped (on the web, its
## download can be skipped too).
func play_opening() -> void:
	if not await Packs.need("movie", true):
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
	_swap(holder)
	_world = null
	_starting = false
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
	add_child(w)
	await w.prepare()


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
	if await Packs.need("movie", true):
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


# ---------------------------------------------------------------- world ---

func go_world(area: String, spawn: String) -> void:
	if area == "solhaven":
		await Packs.need("solhaven")
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
	if hidden_world != null:
		hidden_world.visible = false
		if hidden_world.hud != null:
			hidden_world.hud.visible = false
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
		hidden_world.visible = true
		if hidden_world.hud != null:
			hidden_world.hud.visible = true
		hidden_world.resume_music()   # the area's music carries on from where it left off
	return won
