## RosterScreen.gd: pick who to challenge. Each heroine starts out hating
## you; four matches win her over, and each win plays her next story beat
## and unlocks a scene. No levels, no grind: winning is the only gate.
## Finishing a heroine's story teaches you her signature shot, which you
## can pick as your power shot along the bottom.
class_name RosterScreen
extends Control

var main
var shot_btns := {}


func _init(m) -> void:
	main = m


func _ready() -> void:
	add_child(UI.background())
	var title := UI.label("Last Call League", 38, UI.PINK)
	title.position = Vector2(40, 18)
	add_child(title)
	var sub := UI.label("Win them over one match at a time. Difficulty: %s" % String(GameState.diff().get("label", "Normal")), 18, UI.INK_SOFT)
	sub.position = Vector2(42, 66)
	add_child(sub)
	var row := HBoxContainer.new()
	row.position = Vector2(40, 100)
	row.add_theme_constant_override("separation", 24)
	add_child(row)
	var first: Button = null
	for id in GameState.order():
		var b := _card(row, id)
		if first == null and b:
			first = b
	_shot_picker()
	var back := UI.button("Back", main.show_menu, 20, UI.LINE)
	back.position = Vector2(1170, 735)
	add_child(back)
	if first:
		first.call_deferred("grab_focus")


func _card(row: HBoxContainer, id: String) -> Button:
	var h := GameState.heroine(id)
	var col := UI.hcolor(id)
	var unlocked := GameState.is_unlocked(id)
	var wins := GameState.wins(id)
	var total := GameState.match_count(id)
	var p := UI.panel(UI.PANEL, 18, col)
	p.custom_minimum_size = Vector2(382, 612)
	row.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var por := HeroinePortrait.new(id, 0, "stage")
	por.custom_minimum_size = Vector2(350, 250)
	if not unlocked:
		por.modulate = Color(0.35, 0.35, 0.4)
	v.add_child(por)
	var name_row := HBoxContainer.new()
	name_row.add_child(UI.label(String(h.get("name", id)), 26, col))
	name_row.add_child(UI.label("  %d" % int(h.get("age", 21)), 18, UI.INK_SOFT))
	v.add_child(name_row)
	var tl := UI.wrap_label(String(h.get("tagline", "")), 16, UI.INK)
	tl.custom_minimum_size = Vector2(350, 0)
	v.add_child(tl)
	v.add_child(UI.label("Style: %s   ·   Signature: %s" % [h.get("style", ""), h.get("signature_name", "")], 15, UI.INK_SOFT))
	# What she thinks of you.
	var att := HBoxContainer.new()
	att.add_child(UI.label("Thinks of you: ", 16, UI.INK_SOFT))
	var att_col := UI.BAD.lerp(col, float(wins) / maxf(1.0, float(total)))
	att.add_child(UI.label(GameState.attitude(id), 18, att_col))
	v.add_child(att)
	var meter := ProgressBar.new()
	meter.max_value = total
	meter.value = wins
	meter.show_percentage = false
	meter.custom_minimum_size = Vector2(350, 12)
	meter.add_theme_stylebox_override("background", UI.box(UI.BG, 6, UI.LINE, 1))
	var fill := UI.box(att_col, 6)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	meter.add_theme_stylebox_override("fill", fill)
	v.add_child(meter)
	var pips := UI.label("%d / %d matches won · %d / %d scenes" % [wins, total, wins, total], 15, UI.INK_SOFT)
	v.add_child(pips)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	if not unlocked:
		var lk := UI.wrap_label("Locked: " + String(h.get("unlock", "")), 16, UI.GOLD)
		lk.custom_minimum_size = Vector2(350, 0)
		v.add_child(lk)
		return null
	var main_btn: Button
	if wins < total:
		var label := "Face her · match %d" % (wins + 1) if wins > 0 else "Challenge her · match 1"
		main_btn = UI.button(label, func(): main.start_story_match(id, wins), 21, col)
		v.add_child(main_btn)
	else:
		v.add_child(UI.label("Won over! You learned her %s." % String(h.get("signature_name", "")), 16, UI.GOOD))
	if wins > 0:
		var rr := HBoxContainer.new()
		rr.add_theme_constant_override("separation", 6)
		rr.add_child(UI.label("Replay:", 15, UI.INK_SOFT))
		for i in wins:
			var mi := i
			rr.add_child(UI.button("%d" % (i + 1), func(): main.play_match(id, mi), 15, UI.LINE))
		v.add_child(rr)
		if main_btn == null:
			main_btn = rr.get_child(1)
	return main_btn


func _shot_picker() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(40, 735)
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	row.add_child(UI.label("Your power shot:", 18, UI.INK_SOFT))
	var learned := {}
	for sh in GameState.shots():
		learned[sh["kind"]] = true
	var all := [{"kind": "smash", "name": "Smash", "from": ""}]
	for id in GameState.order():
		var h := GameState.heroine(id)
		all.append({"kind": String(h.get("signature", "")), "name": String(h.get("signature_name", "")), "from": id})
	for sh in all:
		var kind: String = sh["kind"]
		var ok := learned.has(kind)
		var text: String = sh["name"] if ok else "%s (win over %s)" % [sh["name"], UI.first_name(sh["from"])]
		var b := UI.button(text, func(): _pick(kind), 16, UI.GOLD if ok else UI.LINE)
		b.toggle_mode = true
		b.disabled = not ok
		b.button_pressed = ok and GameState.player_shot == kind
		if not ok:
			b.tooltip_text = String(GameState.heroine(sh["from"]).get("perk_text", ""))
		row.add_child(b)
		shot_btns[kind] = b
	if not learned.has(GameState.player_shot):
		(shot_btns["smash"] as Button).button_pressed = true


func _pick(kind: String) -> void:
	GameState.player_shot = kind
	GameState.save()
	for k in shot_btns:
		(shot_btns[k] as Button).button_pressed = k == kind


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		main.show_menu()
