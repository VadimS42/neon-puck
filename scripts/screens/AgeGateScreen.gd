## AgeGateScreen.gd: 18+ confirmation on first launch.
class_name AgeGateScreen
extends Control

var main


func _init(m) -> void:
	main = m


func _ready() -> void:
	add_child(UI.background())
	var c := CenterContainer.new()
	UI.fill(c)
	add_child(c)
	var p := UI.panel(UI.PANEL, 20, UI.PINK)
	p.custom_minimum_size = Vector2(620, 0)
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	p.add_child(v)
	v.add_child(UI.label("Adults only", 40, UI.PINK, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.wrap_label("Neon Puck contains nudity and sexual content between adult characters (all 21+). Please confirm you are 18 or older and that this content is legal where you live.", 20, UI.INK))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	var yes := UI.button("I am 18 or older", func():
		GameState.age_ok = true
		GameState.save()
		main.show_menu())
	row.add_child(yes)
	row.add_child(UI.button("Leave", func(): get_tree().quit(), 22, UI.LINE))
	yes.call_deferred("grab_focus")
