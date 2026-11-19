## RosterScreen.gd: pick who to challenge. Each heroine starts out hating
## you; six matches win her over, and each win plays her next story beat
## and unlocks a memory. No levels, no grind: winning is the only gate.
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
	title.position = Vector2(40, 12)
	add_child(title)
	var sub := UI.label("Difficulty: %s" % String(GameState.diff().get("label", "Normal")), 18, UI.INK_SOFT)
	sub.position = Vector2(42, 62)
	add_child(sub)
	add_child(UI.pin_top_right(UI.status_bar(Vector2.ZERO), 20, 8))
	var hub := HBoxContainer.new()
	hub.add_theme_constant_override("separation", 8)
	add_child(UI.pin_top_right(hub, 20, 62))
	hub.add_child(UI.button("Store", func(): main.show_store(), 18, UI.GOLD, "gem"))
	hub.add_child(UI.button("Wardrobe", func(): main.show_wardrobe(), 18, UI.CYAN, "star"))
	hub.add_child(UI.button("Pro Shop", func(): main.show_shop(), 18, UI.GOLD, "shoppingBasket"))
	var cups := UI.button("Cups" + (" (in progress)" if not GameState.cup_run.is_empty() else ""), main.show_cups, 18, UI.CYAN, "trophy")
	hub.add_child(cups)
	if GameState.finale_open():
		var fin := GameState.finale()
		var fl := int(fin.get("level", 1))
		var ftext := String(fin.get("title", "Finale"))
		if GameState.finale_done:
			ftext += " (won)"
		elif GameState.level < fl and not GameState.unlock_all:
			ftext += ", level %d" % fl
		var fb := UI.button(ftext, main.start_finale, 18, UI.PINK, "trophy")
		fb.disabled = GameState.level < fl and not GameState.unlock_all
		hub.add_child(fb)
	var row := HBoxContainer.new()
	row.position = Vector2(40, 112)
	row.add_theme_constant_override("separation", 16)
	add_child(row)
	var first: Button = null
	for id in GameState.order():
		var b := _card(row, id)
		if first == null and b:
			first = b
	_shot_picker()
	var back := UI.button("Back", main.show_menu, 20, UI.LINE, "return")
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
	p.custom_minimum_size = Vector2(288, 610)
	row.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var por := HeroinePortrait.new(id, 0, "stage")
	por.custom_minimum_size = Vector2(258, 200)
	if not unlocked:
		por.modulate = Color(0.35, 0.35, 0.4)
	v.add_child(por)
	var name_row := HBoxContainer.new()
	name_row.add_child(UI.label(String(h.get("name", id)), 22, col))
	name_row.add_child(UI.label("  %d" % int(h.get("age", 21)), 16, UI.INK_SOFT))
	v.add_child(name_row)
	var tl := UI.wrap_label(String(h.get("tagline", "")), 14, UI.INK)
	tl.custom_minimum_size = Vector2(258, 0)
	v.add_child(tl)
	v.add_child(UI.label("%s player, shoots the %s" % [h.get("style", ""), h.get("signature_name", "")], 14, UI.INK_SOFT))
	# What she thinks of you.
	var att := HBoxContainer.new()
	att.add_child(UI.label("Thinks: ", 14, UI.INK_SOFT))
	var att_col := UI.BAD.lerp(col, float(wins) / maxf(1.0, float(total)))
	att.add_child(UI.label(GameState.attitude(id), 16, att_col))
	v.add_child(att)
	var meter := ProgressBar.new()
	meter.max_value = total
	meter.value = wins
	meter.show_percentage = false
	meter.custom_minimum_size = Vector2(258, 12)
	meter.add_theme_stylebox_override("background", UI.box(UI.BG, 6, UI.LINE, 1))
	var fill := UI.box(att_col, 6)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	meter.add_theme_stylebox_override("fill", fill)
	v.add_child(meter)
	var pips := UI.label("Won %d of %d, memories %d of %d" % [wins, total, wins, total], 14, UI.INK_SOFT)
	v.add_child(pips)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	if not unlocked:
		var lk := UI.wrap_label("Locked: " + String(h.get("unlock", "")), 15, UI.GOLD)
		lk.custom_minimum_size = Vector2(258, 0)
		v.add_child(lk)
		return null
	var main_btn: Button
	if wins < total:
		var need := GameState.match_level(id, wins)
		if GameState.can_play_story(id, wins):
			var label := "Story match %d" % (wins + 1) if wins > 0 else "Challenge her"
			main_btn = UI.button(label, func(): main.start_story_match(id, wins), 18, col)
			v.add_child(main_btn)
		else:
			var lk2 := UI.button("Match %d: level %d" % [wins + 1, need], func(): pass, 17, UI.LINE)
			lk2.disabled = true
			v.add_child(lk2)
			v.add_child(UI.label("%d XP to go (pickups, cups)" % _xp_until(need), 13, UI.INK_SOFT))
	else:
		v.add_child(UI.label("Won over! %s learned." % String(h.get("signature_name", "")), 15, UI.GOOD))
	if wins > 0:
		var rr := HBoxContainer.new()
		rr.add_theme_constant_override("separation", 4)
		rr.add_child(UI.label("Replay", 13, UI.INK_SOFT))
		for i in wins:
			var mi := i
			rr.add_child(UI.button("%d" % (i + 1), func(): main.start_story_match(id, mi), 13, UI.LINE))
		v.add_child(rr)
	var pk := UI.button("Pickup game", func(): main.start_pickup(id), 16, UI.CYAN)
	v.add_child(pk)
	if main_btn == null:
		main_btn = pk
	return main_btn


func _xp_until(lv: int) -> int:
	var n := GameState.xp_to_next() - GameState.xp
	for l in range(GameState.level + 1, lv):
		n += GameState.xp_to_next(l)
	return maxi(0, n)


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
		var text: String = sh["name"] if ok else "%s (%s)" % [sh["name"], UI.first_name(sh["from"])]
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
