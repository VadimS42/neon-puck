## CupScreen.gd: the league cups. Pay the entry, beat every round in a row
## (each round she plays a little sharper), take the prize and a cup scene.
## Lose a round and the run ends, but round rewards are kept.
class_name CupScreen
extends Control

var main


func _init(m) -> void:
	main = m


func _ready() -> void:
	add_child(UI.background())
	var t := UI.label("Cups", 38, UI.GOLD)
	t.position = Vector2(40, 18)
	add_child(t)
	var sub := UI.label("Bracket nights at the Afterglow. Win every round for the prize and a cup scene.", 18, UI.INK_SOFT)
	sub.position = Vector2(42, 66)
	add_child(sub)
	add_child(UI.status_bar(Vector2(760, 18)))
	var first: Button
	var y := 110.0
	var run := GameState.cup_run
	if not run.is_empty():
		var c := GameState.cup(String(run["id"]))
		var r := int(run["round"])
		var opp := String(run["opponents"][r])
		var p := UI.panel(UI.PANEL_2, 14, UI.GOLD)
		p.position = Vector2(40, y)
		p.custom_minimum_size = Vector2(1200, 0)
		add_child(p)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		p.add_child(h)
		var l := UI.label("%s in progress: round %d of %d vs %s" % [String(c["name"]), r + 1, int(c["rounds"]), String(GameState.heroine(opp).get("name", opp))], 22, UI.GOLD)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		first = UI.button("Play round %d" % (r + 1), main.start_cup_round, 20)
		h.add_child(first)
		h.add_child(UI.button("Withdraw", _withdraw, 16, UI.LINE))
		y += 90.0
	var row := HBoxContainer.new()
	row.position = Vector2(40, y)
	row.add_theme_constant_override("separation", 20)
	add_child(row)
	for c in GameState.prog.get("tournaments", []):
		var b := _cup_card(row, c, not run.is_empty())
		if first == null and b and not b.disabled:
			first = b
	var back := UI.button("Back", main.show_roster, 20, UI.LINE)
	back.position = Vector2(1150, 735)
	add_child(back)
	(first if first else back).call_deferred("grab_focus")


func _cup_card(row: HBoxContainer, c: Dictionary, busy: bool) -> Button:
	var cid := String(c["id"])
	var won := GameState.trophies.has(cid)
	var col: Color = {"bronze": Color("#D8925A"), "silver": Color("#CFD8E8"), "gold": UI.GOLD}.get(cid, UI.GOLD)
	var p := UI.panel(UI.PANEL, 16, col)
	p.custom_minimum_size = Vector2(386, 420)
	row.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(UI.label(String(c["name"]) + ("  ★ won" if won else ""), 30, col))
	v.add_child(UI.label("%d rounds · first to %d" % [int(c["rounds"]), int(c["target"])], 18, UI.INK))
	v.add_child(UI.label("Opponents get sharper each round", 15, UI.INK_SOFT))
	v.add_child(UI.label("Needs level %d and %d story wins" % [int(c["level"]), int(c["requires_wins"])], 16, UI.INK_SOFT))
	v.add_child(UI.label("Entry: %d tips" % int(c["entry"]), 18, UI.GOLD))
	var rr: Dictionary = c.get("round_reward", {})
	var pz: Dictionary = c.get("prize", {})
	v.add_child(UI.label("Each round won: +%d XP, +%d tips" % [int(rr.get("xp", 0)), int(rr.get("tips", 0))], 16, UI.INK_SOFT))
	v.add_child(UI.label("Prize: +%d XP, +%d tips" % [int(pz.get("xp", 0)), int(pz.get("tips", 0))], 18, UI.CYAN))
	var sc: Dictionary = c.get("scene", {})
	v.add_child(UI.label("Scene: " + (String(sc.get("title", "")) if won or GameState.unlock_all else "???"), 18, UI.PINK))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var block := GameState.cup_block(cid)
	var b := UI.button(("Enter again" if won else "Enter") + " · %d tips" % int(c["entry"]) if block == "" else block, _enter.bind(cid), 20, col)
	b.disabled = busy or block != ""
	v.add_child(b)
	return b


func _enter(cid: String) -> void:
	if GameState.start_cup(cid):
		main.start_cup_round()


func _withdraw() -> void:
	GameState.cup_run = {}
	GameState.save()
	main.show_cups()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		main.show_roster()
