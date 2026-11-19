## SettingsScreen.gd: difficulty, gallery unlock, display, sound, reset.
class_name SettingsScreen
extends Control

var main
var back: Callable
var diff_btns := {}
var unlock_btn: Button


func _init(m, b: Callable) -> void:
	main = m
	back = b


func _ready() -> void:
	add_child(UI.background())
	var c := CenterContainer.new()
	UI.fill(c)
	add_child(c)
	var p := UI.panel(UI.PANEL, 20, UI.CYAN)
	p.custom_minimum_size = Vector2(700, 0)
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(UI.label("Settings", 36, UI.CYAN))
	v.add_child(UI.label("Difficulty", 22))
	var dr := HBoxContainer.new()
	dr.add_theme_constant_override("separation", 10)
	v.add_child(dr)
	for key in ["story", "normal", "hard"]:
		var k: String = key
		var b := UI.button(String(GameState.data["difficulty"][k].get("label", k)), func(): _set_diff(k), 20, UI.PINK)
		b.toggle_mode = true
		dr.add_child(b)
		diff_btns[k] = b
	v.add_child(UI.wrap_label("Story: she's slower and your Heat fills faster. Hard: she's quicker and reads the puck sooner.", 16, UI.INK_SOFT))
	unlock_btn = UI.button("", _toggle_unlock, 20, UI.CYAN)
	v.add_child(unlock_btn)
	var sfw_btn := UI.button("All-ages mode: on" if GameState.sfw else "All-ages mode: off", func(): pass, 20, UI.CYAN)
	sfw_btn.pressed.connect(func():
		GameState.sfw = not GameState.sfw
		GameState.save()
		sfw_btn.text = "All-ages mode: on" if GameState.sfw else "All-ages mode: off")
	v.add_child(sfw_btn)
	var fs := UI.button("Toggle fullscreen", func():
		GameState.fullscreen = not GameState.fullscreen
		GameState.save()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if GameState.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED), 20, UI.CYAN)
	v.add_child(fs)
	var snd := UI.button("Sound: on" if SFX.enabled else "Sound: off", func(): pass, 20, UI.CYAN)
	snd.pressed.connect(func():
		SFX.enabled = not SFX.enabled
		snd.text = "Sound: on" if SFX.enabled else "Sound: off")
	v.add_child(snd)
	v.add_child(UI.button("Reset story progress", func():
		GameState.reset_progress()
		main.show_settings(back), 18, UI.BAD))
	var bk := UI.button("Back", back, 22, UI.LINE)
	v.add_child(bk)
	_refresh()
	diff_btns[GameState.difficulty].call_deferred("grab_focus")


func _set_diff(k: String) -> void:
	GameState.difficulty = k
	GameState.save()
	_refresh()


func _toggle_unlock() -> void:
	GameState.unlock_all = not GameState.unlock_all
	GameState.save()
	_refresh()


func _refresh() -> void:
	for k in diff_btns:
		(diff_btns[k] as Button).button_pressed = k == GameState.difficulty
	unlock_btn.text = "Gallery: everything unlocked" if GameState.unlock_all else "Gallery: unlock as you play (click to unlock all)"


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.call()
