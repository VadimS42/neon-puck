## VNScreen.gd: dialogue before and after each match, crossovers, dates.
## Click / Enter / Space advances; Skip jumps to the end.
##
## Memories mode: Log shows every line so far, Auto advances on its own
## (remembered in Extras.auto_advance).
##
## Lines can carry:
##   "if": a condition (Extras.cond), the line only shows when it holds.
##   "choice": [{"text", "tag", "reply": [lines], "mods": [...]}, ...] with
##     "key": the flag it sets (Extras.set_flag). The reply lines play
##     right after. "mods" become the next match's special rules.
## In `replay` (gallery) a choice shows the reply you picked back then.
class_name VNScreen
extends Control

var main
var heroine_id := ""
var lines: Array = []
var done: Callable
var idx := -1
var portrait: HeroinePortrait
var name_lbl: Label
var text_lbl: Label
var parchment := false
var choice_box: VBoxContainer
var auto_btn: Button
var log_layer: Control
var history: Array = []
var replay := false
var _finished := false
var _auto_t := 0.0
var _choosing := false


func _init(m, id: String, ls: Array, on_done: Callable, is_replay: bool = false) -> void:
	main = m
	heroine_id = id
	lines = Extras.filter_lines(ls)
	done = on_done
	replay = is_replay


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.background())
	portrait = HeroinePortrait.new(heroine_id, 0, "vn")
	portrait.position = Vector2(390, 30)
	portrait.size = Vector2(500, 560)
	add_child(portrait)
	var box := UI.panel(Color(UI.PANEL, 0.95), 18, UI.hcolor(heroine_id) if heroine_id != "" else UI.PINK)
	var frame := ArtAssets.ui("dialogue_box")
	if frame:
		var st := StyleBoxTexture.new()
		st.texture = frame
		st.texture_margin_top = 70
		st.texture_margin_left = 24
		st.texture_margin_right = 24
		st.texture_margin_bottom = 24
		st.content_margin_left = 40
		st.content_margin_right = 40
		st.content_margin_top = 60
		st.content_margin_bottom = 20
		box.add_theme_stylebox_override("panel", st)
		parchment = true
	box.position = Vector2(80, 540)
	box.size = Vector2(1120, 200)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	box.add_child(v)
	name_lbl = UI.label("", 26, UI.hcolor(heroine_id))
	v.add_child(name_lbl)
	text_lbl = UI.wrap_label("", 24)
	text_lbl.custom_minimum_size = Vector2(1080, 0)
	v.add_child(text_lbl)
	choice_box = VBoxContainer.new()
	choice_box.position = Vector2(340, 250)
	choice_box.custom_minimum_size = Vector2(600, 0)
	choice_box.add_theme_constant_override("separation", 12)
	choice_box.visible = false
	add_child(choice_box)
	var top := HBoxContainer.new()
	top.position = Vector2(930, 20)
	top.add_theme_constant_override("separation", 8)
	add_child(top)
	top.add_child(UI.button("Log", _show_log, 18, UI.LINE))
	auto_btn = UI.button("Auto", _toggle_auto, 18, UI.LINE)
	auto_btn.toggle_mode = true
	auto_btn.button_pressed = Extras.auto_advance
	top.add_child(auto_btn)
	top.add_child(UI.button("Skip", _skip, 18, UI.LINE))
	for b in top.get_children():
		(b as Button).focus_mode = Control.FOCUS_NONE
	var hint := UI.label("Click or press Space to continue", 15, UI.INK_SOFT)
	hint.position = Vector2(960, 770)
	add_child(hint)
	_next()


func _process(d: float) -> void:
	if not Extras.auto_advance or _choosing or _finished or log_layer != null:
		return
	_auto_t -= d
	if _auto_t <= 0.0:
		_next()


func _toggle_auto() -> void:
	Extras.auto_advance = auto_btn.button_pressed
	Extras.save()
	_auto_t = 1.2


func _next() -> void:
	if _choosing:
		return
	idx += 1
	if idx >= lines.size():
		_finish()
		return
	var L: Dictionary = lines[idx]
	if L.has("choice"):
		_choice(L)
		return
	var who := String(L.get("who", heroine_id))
	text_lbl.add_theme_color_override("font_color", UI.INK)
	if who == "narrator":
		name_lbl.text = ""
		portrait.visible = false
		text_lbl.add_theme_color_override("font_color", UI.INK_SOFT)
	elif who == "you":
		name_lbl.text = "You"
		name_lbl.add_theme_color_override("font_color", UI.CYAN)
		portrait.modulate = Color(0.6, 0.6, 0.65)
	else:
		name_lbl.text = UI.first_name(who)
		name_lbl.add_theme_color_override("font_color", UI.hcolor(who))
		portrait.visible = true
		portrait.modulate = Color.WHITE
	if parchment:
		text_lbl.add_theme_color_override("font_color", Color("3b2410") if who != "narrator" else Color("6b4a26"))
		name_lbl.add_theme_constant_override("outline_size", 6)
		name_lbl.add_theme_color_override("font_outline_color", Color("3b2410"))
		if portrait.heroine_id != who:
			portrait.heroine_id = who
		portrait.set_expression(String(L.get("e", "neutral")))
	var text := String(L.get("text", ""))
	text_lbl.text = text
	history.append([name_lbl.text, text, who])
	_auto_t = 2.0 + text.length() * 0.035


## A choice: buttons in the middle of the screen. In a replay, the reply you
## picked back then plays without asking again.
func _choice(L: Dictionary) -> void:
	var opts: Array = L.get("choice", [])
	var key := String(L.get("key", ""))
	if opts.is_empty():
		_next()
		return
	if replay:
		var tag := Extras.flag(key)
		var pick: Dictionary = opts[0]
		for o in opts:
			if String(o.get("tag", "")) == tag:
				pick = o
		_take(pick, key, false)
		return
	_choosing = true
	for c in choice_box.get_children():
		c.queue_free()
	var first: Button
	for o in opts:
		var opt: Dictionary = o
		var b := UI.button(String(opt.get("text", "")), func(): _take(opt, key, true), 22, UI.hcolor(heroine_id))
		choice_box.add_child(b)
		if first == null:
			first = b
	choice_box.visible = true
	if first:
		first.call_deferred("grab_focus")


func _take(opt: Dictionary, key: String, record: bool) -> void:
	choice_box.visible = false
	_choosing = false
	if record:
		if key != "":
			Extras.set_flag(key, String(opt.get("tag", "")))
		Extras.pending_mods = opt.get("mods", [])
	history.append(["You", "> " + String(opt.get("text", "")), "you"])
	var reply: Array = Extras.filter_lines(opt.get("reply", []))
	for i in reply.size():
		lines.insert(idx + 1 + i, reply[i])
	_next()


## Skip: jumps to the next choice if there is one, otherwise ends.
func _skip() -> void:
	if _choosing:
		return
	for i in range(idx + 1, lines.size()):
		if (lines[i] as Dictionary).has("choice") and not replay:
			idx = i - 1
			_next()
			return
	_finish()


func _show_log() -> void:
	if log_layer:
		return
	log_layer = ColorRect.new()
	(log_layer as ColorRect).color = Color(0, 0, 0, 0.85)
	UI.fill(log_layer)
	log_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(log_layer)
	var lt := UI.label("Log", 34, UI.PINK)
	lt.position = Vector2(80, 30)
	log_layer.add_child(lt)
	var sc := ScrollContainer.new()
	sc.position = Vector2(80, 90)
	sc.size = Vector2(1120, 600)
	log_layer.add_child(sc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	sc.add_child(v)
	for h in history:
		var row := VBoxContainer.new()
		var who := String(h[2])
		if String(h[0]) != "":
			row.add_child(UI.label(String(h[0]), 18, UI.CYAN if who == "you" else UI.hcolor(who)))
		var t := UI.wrap_label(String(h[1]), 19, UI.INK_SOFT if who == "narrator" else UI.INK)
		t.custom_minimum_size = Vector2(1080, 0)
		row.add_child(t)
		v.add_child(row)
	var close := UI.button("Close", func():
		log_layer.queue_free()
		log_layer = null, 20, UI.LINE)
	close.position = Vector2(80, 715)
	log_layer.add_child(close)
	close.call_deferred("grab_focus")
	await get_tree().process_frame
	sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	done.call()


func _unhandled_input(e: InputEvent) -> void:
	if log_layer or _choosing:
		if log_layer and e.is_action_pressed("ui_cancel"):
			log_layer.queue_free()
			log_layer = null
			get_viewport().set_input_as_handled()
		return
	if e.is_action_pressed("ui_accept") or (e is InputEventKey and e.pressed and e.keycode == KEY_SPACE):
		_next()
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_next()
