## EventScreen.gd: this week's event cup. A fixed set of special rules,
## a few rounds in a row; win it once this week for its outfit and gems.
## Losing a round sends you back to round 1 (the first round costs a life,
## like a cup). A new event starts every Monday.
class_name EventScreen
extends Control

var main
var back: Callable


func _init(m, on_back: Callable) -> void:
	main = m
	back = on_back


func _ready() -> void:
	add_child(UI.background())
	var ev := Extras.current_event()
	var st := Extras.event_now()
	var t := UI.label("Weekly event: " + String(ev.get("name", "")), 38, UI.PINK)
	t.position = Vector2(40, 18)
	add_child(t)
	var left := Extras.seconds_left_in_event()
	var sub := UI.label("Ends in %dd %dh. %s" % [left / 86400, (left % 86400) / 3600, String(ev.get("blurb", ""))], 18, UI.INK_SOFT)
	sub.position = Vector2(42, 66)
	add_child(sub)
	add_child(UI.pin_top_right(UI.status_bar(Vector2.ZERO), 20, 14))
	var v := VBoxContainer.new()
	v.position = Vector2(40, 120)
	v.custom_minimum_size = Vector2(760, 0)
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	var mods: Array = ev.get("mods", [])
	var rp := UI.panel(UI.PANEL, 14, UI.PINK)
	v.add_child(rp)
	var rl := UI.wrap_label("Rules this week:\n" + MatchMods.describe(mods), 18)
	rl.custom_minimum_size = Vector2(720, 0)
	rp.add_child(rl)
	var opp := Extras.event_opponents()
	var rounds := int(ev.get("rounds", 3))
	var r := int(st.get("round", 0))
	var names := []
	for i in rounds:
		var id := String(opp[mini(i, opp.size() - 1)])
		names.append(("▶ " if i == r else ("✓ " if i < r else "  ")) + "Round %d: %s" % [i + 1, UI.first_name(id)])
	v.add_child(UI.label("\n".join(names), 20, UI.INK))
	var reward: Dictionary = ev.get("reward", {})
	var rtext := GameState.describe(reward)
	var o := String(ev.get("outfit", ""))
	if o.contains(":"):
		var bits := o.split(":")
		rtext += (", " if rtext != "" else "") + "%s's %s outfit" % [UI.first_name(bits[0]), String(GameState.outfit_def(bits[0], bits[1]).get("name", bits[1]))]
	var won := bool(st.get("won", false))
	v.add_child(UI.label(("Won this week! Play again for tips and XP." if won else "Win it this week: " + rtext), 20, UI.GOLD))
	var go := UI.button(("Play round %d" % (r + 1)) if r > 0 else "Enter the event", main.start_event_round, 26, UI.PINK, "trophy")
	v.add_child(go)
	var bk := UI.button("Back", back, 20, UI.LINE, "return")
	bk.position = Vector2(40, 735)
	add_child(bk)
	go.call_deferred("grab_focus")


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.call()
