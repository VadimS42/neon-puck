## SettingsScreen.gd: difficulty, display, sound, purchases, privacy and
## ad choices, credits, reset.
class_name SettingsScreen
extends Control

var main
var back: Callable
var diff_btns := {}
## Replace with your hosted privacy policy before release (Play requires one
## because the game shows ads and sells in-app products).
const PRIVACY_URL := "https://example.com/neon-puck-rivals/privacy"


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
	var snd := UI.button("Sound: on" if SFX.enabled else "Sound: off", func(): pass, 20, UI.CYAN)
	snd.pressed.connect(func():
		SFX.enabled = not SFX.enabled
		snd.text = "Sound: on" if SFX.enabled else "Sound: off")
	v.add_child(snd)
	var mus := UI.button("Music: on" if Music.enabled else "Music: off", func(): pass, 20, UI.CYAN)
	mus.pressed.connect(func():
		Music.set_enabled(not Music.enabled)
		mus.text = "Music: on" if Music.enabled else "Music: off")
	v.add_child(mus)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	v.add_child(row2)
	row2.add_child(UI.button("Restore purchases", func(): Store.restore(), 18, UI.GOLD))
	row2.add_child(UI.button("Privacy policy", func(): OS.shell_open(PRIVACY_URL), 18, UI.CYAN))
	row2.add_child(UI.button("Ad choices", func():
		GameState.ad_consent = "unknown"
		Ads.request_consent(), 18, UI.CYAN))
	row2.add_child(UI.button("Credits", main.show_credits, 18, UI.CYAN))
	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 10)
	v.add_child(row3)
	row3.add_child(UI.button("Save to cloud", func():
		CloudSave.upload()
		UI.popup(self, "Cloud save", "Saved%s." % (" (test backend: stored on this device)" if CloudSave.is_test() else " to your Google account"), [["OK", func(): pass]]), 18, UI.CYAN))
	row3.add_child(UI.button("Load from cloud", func():
		UI.popup(self, "Load from cloud?", "This replaces the progress on this device with your cloud save.", [
			["Load it", func(): CloudSave.download(), UI.GOLD],
			["Cancel", func(): pass, UI.LINE]]), 18, UI.CYAN))
	var nb := UI.button("Reminders: on" if Extras.notify_on else "Reminders: off", func(): pass, 18, UI.CYAN)
	nb.pressed.connect(func():
		Extras.notify_on = not Extras.notify_on
		Extras.save()
		nb.text = "Reminders: on" if Extras.notify_on else "Reminders: off")
	row3.add_child(nb)
	if not CloudSave.loaded.is_connected(_on_cloud):
		CloudSave.loaded.connect(_on_cloud)
	v.add_child(UI.button("Reset story progress (purchases and gems are kept)", func():
		GameState.reset_progress()
		Extras.reset_story()
		main.show_settings(back), 18, UI.BAD))
	var bk := UI.button("Back", back, 22, UI.LINE)
	v.add_child(bk)
	_refresh()
	diff_btns[GameState.difficulty].call_deferred("grab_focus")


func _on_cloud(ok: bool, msg: String) -> void:
	if is_inside_tree():
		UI.popup(self, "Cloud save", msg, [["OK", func(): main.show_settings(back)]])


func _set_diff(k: String) -> void:
	GameState.difficulty = k
	GameState.save()
	_refresh()


func _refresh() -> void:
	for k in diff_btns:
		(diff_btns[k] as Button).button_pressed = k == GameState.difficulty


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.call()
