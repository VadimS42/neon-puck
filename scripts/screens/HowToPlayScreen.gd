## HowToPlayScreen.gd: the rules on one page.
class_name HowToPlayScreen
extends Control

var main


func _init(m) -> void:
	main = m


func _ready() -> void:
	add_child(UI.background())
	var m := MarginContainer.new()
	UI.fill(m)
	for k in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, 60)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	m.add_child(v)
	v.add_child(UI.label("How to play", 40, UI.PINK))
	var rows := [
		["Story", "The regulars hate you: you're the chain's new manager. Beat each one four times to win her over. Every win changes what she thinks of you and unlocks a scene; win her over completely and she teaches you her signature shot."],
		["Move", "Your paddle follows the mouse (or your finger). Keys / left stick work too. You can't cross the centre line."],
		["Score", "First to the match target wins. Shots are pure physics: where and how hard you hit is where the puck goes. Nothing is rolled."],
		["Heat", "Hits, saves and goals fill your Heat meter. When it's full, click, press Space / A, or tap SMASH to arm a power smash: your next hit flies at top speed."],
		["Strip", "She has Composure pips. Each goal you score knocks one off; a smash that scores knocks off a whole layer. Each layer she loses lowers one of her stats (shown on her card), so she gets weaker as she strips."],
		["Her shot", "When her meter fills she arms her signature shot and the game tells you. Each heroine always uses the same one, so you can learn to stop it. Block it and you gain Heat; let it in and your Heat drains."],
		["Difficulty", "Story, Normal or Hard in Settings, any time. Story slows her down and fills your Heat faster. The gallery can be unlocked outright in Settings."],
	]
	for r in rows:
		var p := UI.panel(UI.PANEL, 12)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 18)
		p.add_child(h)
		var t := UI.label(r[0], 24, UI.CYAN)
		t.custom_minimum_size = Vector2(150, 0)
		h.add_child(t)
		var d := UI.wrap_label(r[1], 19)
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(d)
		v.add_child(p)
	var b := UI.button("Back", main.show_menu)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(b)
	b.call_deferred("grab_focus")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		main.show_menu()
