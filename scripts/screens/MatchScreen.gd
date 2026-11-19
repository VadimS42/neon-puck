## MatchScreen.gd: one air hockey match.
##
## Layout (1280x800): score bar on top, the table on the left, her card on
## the right (portrait at her current strip stage, outfit layers and what
## each one does, Composure pips, her signature meter), your Heat meter and
## the SMASH button along the bottom.
class_name MatchScreen
extends Control

const TABLE_POS := Vector2(24, 92)
const TABLE_SCALE := 0.9

var main
var heroine_id := ""
var match_index := 0
var rules := MatchRules.new()
var debug_stage := 0
## Debug: a bot plays your side (screenshots, soak tests).
var autoplay := false
var _bot: AIBrain

var table: _TableView
var portrait: HeroinePortrait
var score_lbl: Label
var target_lbl: Label
var composure_box: HBoxContainer
var layer_rows: Array = []
var her_bar: ProgressBar
var her_sig_lbl: Label
var my_bar: ProgressBar
var smash_btn: Button
var hint_lbl: Label
var banners: VBoxContainer
var pause_layer: Control
var bubble: PanelContainer
var bubble_lbl: Label
var bubble_t := 0.0
var _bark_i := 0

var countdown := 3.2
var paused := false
var ending := -1.0
var use_keys := false
var _h: Dictionary


var ctx: Dictionary = {}


func _init(m, id: String, mi: int, context: Dictionary = {}) -> void:
	main = m
	ctx = context
	heroine_id = id
	match_index = mi


func _ready() -> void:
	_h = GameState.heroine(heroine_id)
	rules.setup(heroine_id, match_index, ctx)
	add_child(UI.background())
	_build_top()
	table = _TableView.new()
	table.screen = self
	table.position = TABLE_POS
	table.size = Vector2(PuckSim.W, PuckSim.H) * TABLE_SCALE
	add_child(table)
	banners = VBoxContainer.new()
	banners.position = TABLE_POS + Vector2(0, 30)
	banners.size = Vector2(PuckSim.W * TABLE_SCALE, 200)
	banners.alignment = BoxContainer.ALIGNMENT_BEGIN
	banners.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banners)
	_build_side()
	_build_bubble()
	_build_bottom()
	_build_pause()
	if debug_stage > 0:
		call_deferred("_apply_debug_stage")
	_refresh_side()


func _apply_debug_stage() -> void:
	rules.layers_lost = debug_stage
	rules.apply_her(debug_stage)
	portrait.set_stage(debug_stage)
	rules.sim.paddle(0).heat = 100.0
	countdown = 0.0
	_refresh_side()


func _build_top() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(24, 14)
	bar.size = Vector2(864, 60)
	bar.add_theme_constant_override("separation", 20)
	add_child(bar)
	score_lbl = UI.label("", 40, UI.INK)
	bar.add_child(score_lbl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(sp)
	target_lbl = UI.label(_mode_text(), 20, UI.INK_SOFT)
	target_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(target_lbl)
	var pause_btn := UI.button("Pause", _toggle_pause, 18, UI.LINE)
	pause_btn.focus_mode = Control.FOCUS_NONE
	bar.add_child(pause_btn)


func _build_side() -> void:
	var col := UI.hcolor(heroine_id)
	var p := UI.panel(UI.PANEL, 16, col)
	p.position = Vector2(906, 14)
	p.size = Vector2(354, 772)
	add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(UI.label(String(_h.get("name", "")), 26, col))
	portrait = HeroinePortrait.new(heroine_id, 0, "stage")
	portrait.custom_minimum_size = Vector2(322, 330)
	v.add_child(portrait)
	var crow := HBoxContainer.new()
	crow.add_child(UI.label("Composure ", 17, UI.INK_SOFT))
	composure_box = HBoxContainer.new()
	composure_box.add_theme_constant_override("separation", 4)
	crow.add_child(composure_box)
	v.add_child(crow)
	v.add_child(UI.label("Outfit (each layer off weakens her)", 15, UI.INK_SOFT))
	for L in _h.get("layers", []):
		var row := HBoxContainer.new()
		var n := UI.label(String(L.get("name", "")), 18, UI.INK)
		n.custom_minimum_size = Vector2(140, 0)
		row.add_child(n)
		var e := UI.label(String(L.get("effect", "")), 15, UI.INK_SOFT)
		row.add_child(e)
		v.add_child(row)
		layer_rows.append([n, e])
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	v.add_child(sp)
	her_sig_lbl = UI.label("Signature: %s" % String(_h.get("signature_name", "")), 18, col)
	v.add_child(her_sig_lbl)
	her_bar = _bar(col)
	v.add_child(her_bar)
	var tip := UI.wrap_label(String(_h.get("signature_tip", "")), 14, UI.INK_SOFT)
	tip.custom_minimum_size = Vector2(320, 0)
	v.add_child(tip)


## Her speech bubble over the portrait: taunts, reactions, strip lines.
func _build_bubble() -> void:
	bubble = UI.panel(Color(UI.BG, 0.92), 12, UI.hcolor(heroine_id))
	bubble.position = Vector2(922, 64)
	bubble.custom_minimum_size = Vector2(322, 0)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.visible = false
	add_child(bubble)
	bubble_lbl = UI.wrap_label("", 17, UI.INK)
	bubble_lbl.custom_minimum_size = Vector2(294, 0)
	bubble.add_child(bubble_lbl)


func _bark(key: String) -> void:
	var tier := "hostile" if match_index < 2 else "warm"
	var set_: Dictionary = _h.get("barks", {}).get(tier, {})
	var line = set_.get(key, "")
	if line is Array:
		if line.is_empty():
			return
		line = line[_bark_i % line.size()]
		_bark_i += 1
	if String(line) == "":
		return
	bubble_lbl.text = "\"%s\"" % String(line)
	bubble.visible = true
	bubble.size = Vector2(322, 0)
	bubble_t = 2.8


func _build_bottom() -> void:
	var p := UI.panel(UI.PANEL, 16, UI.CYAN)
	p.position = Vector2(24, 600)
	p.size = Vector2(864, 186)
	add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(UI.label("Your Heat", 20, UI.CYAN))
	my_bar = _bar(UI.CYAN)
	my_bar.custom_minimum_size = Vector2(560, 26)
	left.add_child(my_bar)
	smash_btn = UI.button("SMASH", _try_arm, 30, UI.GOLD)
	smash_btn.custom_minimum_size = Vector2(220, 70)
	smash_btn.focus_mode = Control.FOCUS_NONE
	row.add_child(smash_btn)
	hint_lbl = UI.wrap_label("", 16, UI.INK_SOFT)
	v.add_child(hint_lbl)


func _bar(col: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.max_value = PuckSim.HEAT_MAX
	b.show_percentage = false
	b.custom_minimum_size = Vector2(320, 18)
	b.add_theme_stylebox_override("background", UI.box(UI.BG, 8, UI.LINE, 1))
	var f := UI.box(col, 8)
	f.content_margin_top = 0
	f.content_margin_bottom = 0
	b.add_theme_stylebox_override("fill", f)
	return b


func _mode_text() -> String:
	var t := "First to %d" % rules.target
	match String(ctx.get("mode", "story")):
		"pickup":
			t += " · pickup game"
			if GameState.pickup_streak > 0:
				t += " · streak %d" % GameState.pickup_streak
		"cup":
			var c := GameState.cup(String(ctx.get("cup", "")))
			t += " · %s round %d of %d" % [String(c.get("name", "Cup")), int(ctx.get("round", 0)) + 1, int(c.get("rounds", 3))]
		"replay":
			t += " · replay of match %d" % (match_index + 1)
		"finale":
			t += " · CHAMPIONSHIP round %d of %d" % [int(ctx.get("round", 0)) + 1, GameState.finale().get("rounds", []).size()]
		_:
			t += " · match %d of %d" % [match_index + 1, GameState.match_count(heroine_id)]
	var pu: Array = ctx.get("powerups", [])
	if not pu.is_empty():
		var names := []
		for pid in pu:
			names.append(String(GameState.powerup(pid).get("name", pid)))
		t += "\n" + ", ".join(names)
	return t


func _restart() -> void:
	# A restart keeps the match type but not the power-ups (they were spent).
	var c := ctx.duplicate()
	c["powerups"] = []
	main.play_match(heroine_id, match_index, c)


func _build_pause() -> void:
	pause_layer = ColorRect.new()
	(pause_layer as ColorRect).color = Color(0, 0, 0, 0.6)
	UI.fill(pause_layer)
	pause_layer.visible = false
	add_child(pause_layer)
	var c := CenterContainer.new()
	UI.fill(c)
	pause_layer.add_child(c)
	var p := UI.panel(UI.PANEL, 18, UI.PINK)
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(340, 0)
	p.add_child(v)
	v.add_child(UI.label("Paused", 34, UI.PINK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.button("Resume", _toggle_pause))
	v.add_child(UI.button("Restart match", _restart, 22, UI.CYAN))
	v.add_child(UI.button("Forfeit to roster", func(): main.forfeit(ctx), 22, UI.LINE))


func _toggle_pause() -> void:
	if ending >= 0.0:
		return
	paused = not paused
	pause_layer.visible = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if paused:
		(pause_layer.get_child(0).get_child(0).get_child(0).get_child(1) as Button).grab_focus()


func _try_arm() -> void:
	if paused or countdown > 0.0 or ending >= 0.0:
		return
	rules.sim.arm(0)


# ---------------------------------------------------------------- input

func to_table(screen_pos: Vector2) -> Vector2:
	return (screen_pos - TABLE_POS) / TABLE_SCALE


func _input(e: InputEvent) -> void:
	if paused:
		if e.is_action_pressed("ui_cancel"):
			_toggle_pause()
			get_viewport().set_input_as_handled()
		return
	if e is InputEventMouseMotion:
		use_keys = false
		rules.sim.paddle(0).target = to_table(e.position)
	elif e is InputEventScreenDrag or e is InputEventScreenTouch:
		use_keys = false
		if e.position.x < TABLE_POS.x + PuckSim.W * TABLE_SCALE:
			rules.sim.paddle(0).target = to_table(e.position)
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var tr := Rect2(TABLE_POS, Vector2(PuckSim.W, PuckSim.H) * TABLE_SCALE)
		if tr.has_point(e.position):
			_try_arm()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
		_try_arm()
	elif e.is_action_pressed("ui_cancel") or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_START):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif (e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_SPACE) or (e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A):
		_try_arm()
		get_viewport().set_input_as_handled()


func _key_vector() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1
	var joy := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if joy.length() > 0.2:
		v += joy
	return v.limit_length(1.0)


# ---------------------------------------------------------------- loop

func _physics_process(delta: float) -> void:
	if paused:
		return
	if countdown > 0.0:
		countdown -= delta
		if countdown <= 0.0:
			_banner("GO!", UI.GOLD)
		return
	var kv := _key_vector()
	if kv != Vector2.ZERO:
		use_keys = true
	if use_keys:
		var me: PuckSim.Paddle = rules.sim.paddle(0)
		me.target = me.pos + kv * 220.0
	if autoplay:
		if _bot == null:
			_bot = AIBrain.new()
			_bot.side = 0
			_bot.setup(5)
		_bot.think(rules.sim, delta)
	rules.step(delta)
	for e in rules.events:
		_on_event(e)
	rules.events.clear()
	if ending >= 0.0:
		ending -= delta
		if ending < 0.0:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			main.match_finished(heroine_id, match_index, rules.player_won, rules, ctx)


func _process(_d: float) -> void:
	if bubble_t > 0.0:
		bubble_t -= _d
		if bubble_t <= 0.0:
			bubble.visible = false
	var a: int = rules.sim.paddle(0).score
	var b: int = rules.sim.paddle(1).score
	score_lbl.text = "YOU  %d : %d  %s" % [a, b, UI.first_name(heroine_id).to_upper()]
	var me: PuckSim.Paddle = rules.sim.paddle(0)
	var her: PuckSim.Paddle = rules.sim.paddle(1)
	my_bar.value = me.heat
	her_bar.value = her.heat
	smash_btn.disabled = me.heat < PuckSim.HEAT_MAX and not me.armed
	smash_btn.text = "ARMED!" if me.armed else _shot_name().to_upper()
	if countdown > 0.0:
		hint_lbl.text = "Get ready... %d" % int(ceil(countdown - 0.2))
	elif me.armed:
		hint_lbl.text = ("Smash armed: your next hit flies at top speed." if rules.sim.paddle(0).power_kind == "smash" else "%s armed: your next touch fires it at her goal." % _shot_name()) + " Score with it to take a whole layer."
	elif me.heat >= PuckSim.HEAT_MAX:
		hint_lbl.text = "Heat full! Click the table, press Space / A, or tap SMASH to arm a power smash."
	elif her.armed:
		hint_lbl.text = "%s armed her %s. %s" % [UI.first_name(heroine_id), String(_h.get("signature_name", "")), String(_h.get("signature_tip", ""))]
	else:
		hint_lbl.text = "Hits, saves and goals build Heat. Bank shots off the wall build it fastest."
	# Hide the system cursor over the table: your paddle is the cursor.
	var over := Rect2(TABLE_POS, Vector2(PuckSim.W, PuckSim.H) * TABLE_SCALE).has_point(get_local_mouse_position())
	var want := Input.MOUSE_MODE_HIDDEN if over and not paused and ending < 0.0 else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != want and DisplayServer.get_name() != "headless":
		Input.mouse_mode = want


func _on_event(e: Dictionary) -> void:
	var her_name := UI.first_name(heroine_id)
	var sig := String(_h.get("signature_name", ""))
	match String(e.kind):
		"hit":
			SFX.play("hit", clampf(0.7 + float(e.speed) / 2000.0, 0.7, 1.6))
		"wall":
			SFX.play("wall")
		"armed":
			if e.side == 1:
				_banner("%s readies %s!" % [her_name, sig.to_upper()], UI.hcolor(heroine_id))
				SFX.play("warn")
				_bark("signature")
			else:
				_banner("%s ARMED" % _shot_name().to_upper(), UI.GOLD)
		"power_shot":
			SFX.play("smash")
		"power_saved":
			if e.side == 0:
				_banner("Blocked her %s! +Heat" % sig, UI.CYAN)
		"save":
			pass
		"second_wind":
			_banner("SECOND WIND! Heat full.", UI.GOLD)
		"flustered":
			_banner("Her %s went in. Your Heat drained." % sig, UI.BAD)
		"goal":
			if e.scorer == 0:
				SFX.play("goal")
				_bark("your_goal")
				if e.power:
					_banner("SMASH GOAL!", UI.GOLD)
				elif e.bank:
					_banner("BANK SHOT GOAL!", UI.CYAN)
				elif e.own_goal:
					_banner("Own goal! Thanks, %s." % her_name, UI.CYAN)
				else:
					_banner("GOAL!", UI.CYAN)
			else:
				SFX.play("goal_against")
				_bark("her_goal")
				_banner("%s scores" % her_name, UI.hcolor(heroine_id))
			_refresh_side()
		"strip":
			var stage := int(e.stage)
			var L: Dictionary = _h.get("layers", [])[stage - 1]
			_banner("%s off! %s" % [String(L.get("name", "")), String(L.get("effect", ""))], UI.PINK, 2.6)
			portrait.set_stage(stage)
			_bark("strip%d" % stage)
			portrait.flash = 0.6
			rules.sim.paused = maxf(rules.sim.paused, 2.2)
			SFX.play("strip")
			_refresh_side()
		"match_over":
			ending = 2.0
			if e.won:
				_banner("YOU WIN!", UI.GOLD, 2.5)
				SFX.play("win")
			else:
				_banner("%s wins this one" % her_name, UI.BAD, 2.5)
				SFX.play("lose")


func _shot_name() -> String:
	var k: String = rules.sim.paddle(0).power_kind
	for sh in GameState.shots():
		if sh["kind"] == k:
			return String(sh["name"])
	return "Smash"


func _refresh_side() -> void:
	for c in composure_box.get_children():
		c.queue_free()
	var col := UI.hcolor(heroine_id)
	if rules.layers_lost >= rules.layer_count:
		composure_box.add_child(UI.label("none left", 16, UI.INK_SOFT))
	else:
		for i in rules.composure_per_layer:
			var full := i < rules.composure
			if ArtAssets.icon("HeartFull"):
				composure_box.add_child(UI.icon_rect("HeartFull" if full else "HeartEmpty", 34))
			else:
				composure_box.add_child(UI.label("♥" if full else "♡", 20, col if full else UI.LINE))
	for i in layer_rows.size():
		var off := i < rules.layers_lost
		var n: Label = layer_rows[i][0]
		var ef: Label = layer_rows[i][1]
		n.add_theme_color_override("font_color", UI.LINE if off else UI.INK)
		ef.add_theme_color_override("font_color", UI.GOOD if off else UI.INK_SOFT)
		var base := String(_h["layers"][i].get("name", ""))
		n.text = ("✗ " + base) if off else base


func _banner(text: String, color: Color, life: float = 1.6) -> void:
	var l := UI.label(text, 34, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 8)
	banners.add_child(l)
	while banners.get_child_count() > 3:
		banners.get_child(0).free()
	var tw := l.create_tween()
	tw.tween_interval(life)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


## Draws the table, puck, paddles and trails. Uses art from res://art/table
## when present, flat neon shapes otherwise.
class _TableView extends Control:
	var screen: MatchScreen
	var trail: Array = []
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(d: float) -> void:
		t += d
		var sim := screen.rules.sim
		trail.append([sim.puck_pos, sim.powered])
		if trail.size() > 12:
			trail.pop_front()
		queue_redraw()

	func _draw() -> void:
		var s := MatchScreen.TABLE_SCALE
		var sim := screen.rules.sim
		var W := PuckSim.W * s
		var H := PuckSim.H * s
		var her_col := UI.hcolor(screen.heroine_id)
		var tex := ArtAssets.table("table")
		if tex:
			draw_texture_rect(tex, Rect2(0, 0, W, H), false)
		else:
			draw_rect(Rect2(0, 0, W, H), Color("#120C24"))
			for i in range(1, 12):
				var x := W * i / 12.0
				draw_line(Vector2(x, 0), Vector2(x, H), Color(1, 1, 1, 0.03), 1)
			draw_line(Vector2(W / 2, 0), Vector2(W / 2, H), Color(UI.PINK, 0.5), 3)
			draw_arc(Vector2(W / 2, H / 2), 70 * s, 0, TAU, 48, Color(UI.PINK, 0.5), 3)
			draw_arc(Vector2(0, H / 2), 120 * s, -PI / 2, PI / 2, 32, Color(UI.CYAN, 0.35), 2)
			draw_arc(Vector2(W, H / 2), 120 * s, PI / 2, PI * 1.5, 32, Color(her_col, 0.35), 2)
			draw_rect(Rect2(0, 0, W, H), UI.CYAN.lerp(her_col, 0.5), false, 4)
		var gw := PuckSim.GOAL_W * s
		draw_rect(Rect2(-8, H / 2 - gw / 2, 10, gw), UI.CYAN)
		draw_rect(Rect2(W - 2, H / 2 - gw / 2, 10, gw), her_col)
		# Puck trail.
		for i in trail.size():
			var tp: Vector2 = trail[i][0] * s
			var a := float(i) / trail.size()
			var c := Color(1, 1, 1, 0.12 * a)
			if trail[i][1] == 0:
				c = Color(UI.GOLD, 0.45 * a)
			elif trail[i][1] == 1:
				c = Color(her_col, 0.5 * a)
			draw_circle(tp, PuckSim.PUCK_R * s * (0.5 + 0.5 * a), c)
		# Paddles.
		for side in 2:
			var p: PuckSim.Paddle = sim.paddle(side)
			var col := UI.CYAN if side == 0 else her_col
			var pos := p.pos * s
			var r := p.radius * s
			if p.armed:
				var pulse := 0.5 + 0.5 * sin(t * 14.0)
				draw_circle(pos, r * (1.35 + 0.15 * pulse), Color(UI.GOLD if side == 0 else her_col, 0.35))
			var ptex := ArtAssets.table("paddle_player" if side == 0 else "paddle_" + screen.heroine_id)
			if ptex:
				draw_texture_rect(ptex, Rect2(pos - Vector2(r, r), Vector2(r, r) * 2), false)
			else:
				draw_circle(pos, r, col.darkened(0.3))
				draw_circle(pos, r * 0.78, col)
				draw_circle(pos, r * 0.35, col.lightened(0.5))
		# Puck.
		var pk := sim.puck_pos * s
		var pr := PuckSim.PUCK_R * s
		var puck_tex := ArtAssets.table("puck")
		var pcol := UI.GOLD if sim.powered == 0 else (her_col if sim.powered == 1 else Color("#F4F4F8"))
		if puck_tex:
			draw_texture_rect(puck_tex, Rect2(pk - Vector2(pr, pr), Vector2(pr, pr) * 2), false, pcol if sim.powered >= 0 else Color.WHITE)
		else:
			draw_circle(pk, pr, pcol)
			draw_circle(pk, pr * 0.6, pcol.darkened(0.25))
		if screen.countdown > 0.0:
			var n := int(ceil(screen.countdown - 0.2))
			var font := ThemeDB.fallback_font
			var txt := str(n) if n > 0 else "GO"
			draw_string(font, Vector2(0, H / 2 + 40), txt, HORIZONTAL_ALIGNMENT_CENTER, W, 120, Color(UI.GOLD, 0.9))
