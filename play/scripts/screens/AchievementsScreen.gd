## AchievementsScreen.gd: every achievement in data/extras.json, earned or
## not, with progress toward the ones still open. Shared by both games.
class_name AchievementsScreen
extends Control

var main
var back: Callable


func _init(m, on_back: Callable) -> void:
	main = m
	back = on_back


func _ready() -> void:
	add_child(UI.background())
	var list := Extras.achievements()
	var t := UI.label("Achievements  %d / %d" % [Extras.unlocked.size(), list.size()], 38, UI.GOLD)
	t.position = Vector2(40, 18)
	add_child(t)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 84)
	scroll.size = Vector2(1200, 640)
	add_child(scroll)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 12)
	scroll.add_child(g)
	for a in list:
		var got := Extras.unlocked.has(String(a.get("id", "")))
		var hidden := bool(a.get("hidden", false)) and not got
		var p := UI.panel(UI.PANEL_2 if got else UI.PANEL, 12, UI.GOLD if got else UI.LINE)
		p.custom_minimum_size = Vector2(585, 84)
		g.add_child(p)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		p.add_child(h)
		h.add_child(UI.label("★" if got else "☆", 34, UI.GOLD if got else UI.LINE))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		v.add_child(UI.label("Hidden achievement" if hidden else String(a.get("name", "")), 20, UI.INK if got else UI.INK_SOFT))
		var d := UI.wrap_label("Keep playing." if hidden else String(a.get("desc", "")), 15, UI.INK_SOFT)
		d.custom_minimum_size = Vector2(470, 0)
		v.add_child(d)
		var n := int(a.get("n", 1))
		if not got and not hidden and n > 1:
			v.add_child(UI.label("%d / %d" % [mini(Extras.progress_of(a), n), n], 14, UI.CYAN))
	var b := UI.button("Back", back, 20, UI.LINE, "return")
	b.position = Vector2(40, 735)
	add_child(b)
	b.call_deferred("grab_focus")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.call()
