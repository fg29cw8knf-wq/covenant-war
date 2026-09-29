extends Node
## The game's root: switches between the title screen, story scenes, the
## walkable world and duels.

var _current: Node = null
var _world: World = null


func _ready() -> void:
	get_tree().root.theme = UITheme.make()
	var args := OS.get_cmdline_user_args()
	if "--lab" in args or "--lab-watch" in args:
		show_lab()
		return
	if not Game.settings.get("seen_opening", false):
		await play_opening()
	show_title()


## The opening movie; returns when it ends or is skipped.
func play_opening() -> void:
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
	var backdrop := World.new().setup("solhaven", "gate")
	backdrop.attract = true
	holder.add_child(backdrop)
	var title := TitleScreen.new()
	holder.add_child(title)
	title.new_game.connect(_on_new_game)
	title.continue_game.connect(_on_continue)
	title.watch_opening.connect(func() -> void:
		await play_opening())
	title.open_lab.connect(show_lab)
	_swap(holder)
	_world = null


func _on_continue() -> void:
	if Game.load_game():
		go_world(Game.area, Game.spawn)
	else:
		_on_new_game()


func _on_new_game() -> void:
	var story := StoryScreen.new()
	_swap(story)
	await Prologue.play(story, self)
	story.queue_free()
	_current = null
	go_world("solhaven", "gate")


# -------------------------------------------------------------- duel lab ---

func show_lab() -> void:
	var lab := DuelLab.new()
	lab.closed.connect(show_title)
	_swap(lab)


# ---------------------------------------------------------------- world ---

func go_world(area: String, spawn: String) -> void:
	var w := World.new().setup(area, spawn)
	w.duel_handler = run_duel
	w.exit_to_title.connect(show_title)
	_swap(w)
	Game.save_game()


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
	var screen := BattleScreen.new().configure(spec)
	layer.add_child(screen)
	var won: bool = await screen.finished
	layer.queue_free()
	if hidden_world != null and is_instance_valid(hidden_world):
		hidden_world.visible = true
		if hidden_world.hud != null:
			hidden_world.hud.visible = true
	return won
