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
		m.add_theme_constant_override("margin_" + k, 16 if k in ["top", "bottom"] else 50)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	m.add_child(v)
	v.add_child(UI.label("How to play", 34, UI.PINK))
	var rows := [
		["Story", "The regulars hate you: you're the chain's new manager. Beat each one six times to win her over. Every win changes what she thinks of you and unlocks a memory for your album; win her over completely and she teaches you her signature shot and her Date outfit. Win over all four for the championship."],
		["Level up", "Every match pays XP and tips, win or lose. Later story matches need a level: pickup games and cups get you there. Spend tips in the Pro Shop on gear (for good) and power-ups (one match each)."],
		["Play", "Your paddle follows your finger (or the mouse; keys and a gamepad work too) and can't cross the centre line. First to the target wins. Pure physics: where and how hard you hit is where the puck goes."],
		["Heat", "Hits, saves and goals fill your Heat meter. When it's full, click, press Space / A, or tap SMASH to arm a power smash: your next hit flies at top speed."],
		["Her cool", "She has Cool pips. Each goal you score knocks one off; a smash that scores cracks her cool at once. Each crack lowers one of her stats (shown on her card), so the more rattled she gets, the weaker she plays."],
		["Lives", "A match costs a life when it starts and gives it back if you win, so only losses cost you. Lives refill on their own (one every 20 minutes). Replays of matches you've won are free. Out of lives? Wait, watch an ad, or use gems."],
		["Her shot", "When her meter fills she arms her signature shot and the game tells you. Each heroine always uses the same one, so you can learn to stop it. Block it and you gain Heat; let it in and your Heat drains."],
		["Gems", "Gems come from first wins, finishing a story, cups and the daily reward, or from the Store. Spend them on lives, tips and outfits in the Wardrobe. Outfits are just for looks."],
		["Difficulty", "Story, Normal or Hard in Settings, any time."],
	]
	for r in rows:
		var p := UI.panel(UI.PANEL, 12)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 18)
		p.add_child(h)
		var t := UI.label(r[0], 20, UI.CYAN)
		t.custom_minimum_size = Vector2(130, 0)
		h.add_child(t)
		var d := UI.wrap_label(r[1], 15)
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
