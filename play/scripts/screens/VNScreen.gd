## VNScreen.gd: short dialogue before and after each match.
## Click / Enter / Space advances; Skip jumps to the end.
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
var _finished := false


func _init(m, id: String, ls: Array, on_done: Callable) -> void:
	main = m
	heroine_id = id
	lines = ls
	done = on_done


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(UI.background())
	portrait = HeroinePortrait.new(heroine_id, 0, "vn")
	portrait.position = Vector2(390, 30)
	portrait.size = Vector2(500, 560)
	add_child(portrait)
	var box := UI.panel(Color(UI.PANEL, 0.95), 18, UI.hcolor(heroine_id) if heroine_id != "" else UI.PINK)
	box.position = Vector2(80, 560)
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
	var skip := UI.button("Skip", _finish, 18, UI.LINE)
	skip.position = Vector2(1150, 20)
	add_child(skip)
	var hint := UI.label("Click or press Space to continue", 15, UI.INK_SOFT)
	hint.position = Vector2(960, 770)
	add_child(hint)
	_next()


func _next() -> void:
	idx += 1
	if idx >= lines.size():
		_finish()
		return
	var L: Dictionary = lines[idx]
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
		if portrait.heroine_id != who:
			portrait.heroine_id = who
		portrait.set_expression(String(L.get("e", "neutral")))
	text_lbl.text = String(L.get("text", ""))


func _finish() -> void:
	if _finished:
		return
	_finished = true
	done.call()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_accept") or (e is InputEventKey and e.pressed and e.keycode == KEY_SPACE):
		_next()
		get_viewport().set_input_as_handled()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_next()
