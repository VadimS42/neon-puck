## CreditsScreen.gd: shows data/credits.txt. The music (CC BY 4.0) and the
## Ravenmore icons need their credit shown, so keep this screen reachable.
class_name CreditsScreen
extends Control

var main


func _init(m) -> void:
	main = m


func _ready() -> void:
	add_child(UI.background())
	var t := UI.label("Credits", 38, UI.PINK)
	t.position = Vector2(40, 22)
	add_child(t)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 84)
	scroll.size = Vector2(1200, 630)
	add_child(scroll)
	var text := ""
	var f := FileAccess.open("res://data/credits.txt", FileAccess.READ)
	if f:
		text = f.get_as_text()
	var l := UI.wrap_label(text, 18, UI.INK)
	l.custom_minimum_size = Vector2(1180, 0)
	scroll.add_child(l)
	var back := UI.button("Back", main.show_menu, 20, UI.LINE)
	back.position = Vector2(40, 735)
	add_child(back)
	back.call_deferred("grab_focus")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		main.show_menu()
