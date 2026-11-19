## Main.gd
##
## Root of the game. Each screen is a Control built in code; switching
## screens frees the old one and adds the new. Story flow lives here too:
##   roster -> dialogue before -> match -> (win) dialogue after -> scene -> roster
##                                       -> (loss) result screen: retry / tips
extends Control

var host: Control
var current: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	host = Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	if GameState.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var args := OS.get_cmdline_user_args()
	# Screenshot / debug entry points: -- screen=match id=mila
	var opts := {}
	for a in args:
		var kv := a.split("=")
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	if opts.has("speed"):
		var k := float(opts["speed"])
		Engine.physics_ticks_per_second = int(120 * k)
		Engine.max_physics_steps_per_frame = int(8 * k)
		Engine.time_scale = k
	if opts.has("shot"):
		_take_shot(String(opts["shot"]), float(opts.get("delay", "1.5")))
	if opts.has("screen"):
		_debug_open(opts)
		return
	if GameState.age_ok:
		show_menu()
	else:
		_show(AgeGateScreen.new(self))


func _show(screen: Control) -> void:
	if current and is_instance_valid(current):
		current.queue_free()
	current = screen
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(screen)


func show_menu() -> void:
	_show(MenuScreen.new(self))


func show_roster() -> void:
	if not GameState.prologue_seen:
		_show(VNScreen.new(self, "mila", GameState.data.get("prologue", []), func():
			GameState.prologue_seen = true
			GameState.save()
			show_roster()))
		return
	_show(RosterScreen.new(self))


func show_gallery() -> void:
	_show(GalleryScreen.new(self))


func show_settings(back: Callable = Callable()) -> void:
	_show(SettingsScreen.new(self, back if back.is_valid() else show_menu))


func show_how_to_play() -> void:
	_show(HowToPlayScreen.new(self))


## Starts match `mi` of a heroine's story, with its dialogue first.
func start_story_match(id: String, mi: int) -> void:
	var m: Dictionary = GameState.heroine(id)["matches"][mi]
	_show(VNScreen.new(self, id, m.get("before", []), func(): play_match(id, mi)))


func play_match(id: String, mi: int) -> void:
	_show(MatchScreen.new(self, id, mi))


func match_finished(id: String, mi: int, won: bool, rules: MatchRules) -> void:
	if not won:
		_show(ResultScreen.new(self, id, mi, rules))
		return
	GameState.record_win(id, mi)
	var m: Dictionary = GameState.heroine(id)["matches"][mi]
	var scene: Dictionary = m.get("scene", {})
	_show(ResultScreen.new(self, id, mi, rules, func():
		_show(VNScreen.new(self, id, m.get("after", []), func():
			GameState.see_scene(String(scene.get("id", "")))
			_show(SceneViewer.new(self, id, scene, show_roster))))))


func open_scene(id: String, scene: Dictionary) -> void:
	_show(SceneViewer.new(self, id, scene, show_gallery))


func open_stage(id: String, stage: int) -> void:
	_show(SceneViewer.new(self, id, {"stage": stage, "title": "%s · stage %d" % [UI.first_name(id), stage]}, show_gallery))


func _debug_open(o: Dictionary) -> void:
	var id := String(o.get("id", "mila"))
	match String(o["screen"]):
		"menu": show_menu()
		"age": _show(AgeGateScreen.new(self))
		"roster": _show(RosterScreen.new(self))
		"gallery": show_gallery()
		"settings": show_settings()
		"howto": show_how_to_play()
		"vn": start_story_match(id, int(o.get("m", "0")))
		"prologue": _show(VNScreen.new(self, "mila", GameState.data.get("prologue", []), show_menu))
		"match":
			var ms := MatchScreen.new(self, id, int(o.get("m", "0")))
			ms.debug_stage = int(o.get("stage", "0"))
			ms.autoplay = o.get("autoplay", "0") == "1"
			_show(ms)
		"scene": _show(SceneViewer.new(self, id, GameState.heroine(id)["matches"][0]["scene"], show_roster))
		"result":
			var r := MatchRules.new()
			r.setup(id, 0)
			r.sim.paddle(0).score = 5
			r.sim.paddle(1).score = 3
			r.layers_lost = 2
			_show(ResultScreen.new(self, id, 0, r, show_roster) if o.get("won", "1") == "1" else ResultScreen.new(self, id, 0, r))
		_: show_menu()


## Debug: saves a screenshot after `delay` seconds and quits.
func _take_shot(path: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
