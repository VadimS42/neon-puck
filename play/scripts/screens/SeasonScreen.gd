## SeasonScreen.gd: the season pass. Matches (win or lose) and missions earn
## season XP; every tier has a free reward, and the paid track adds outfits
## and gems. Cosmetics and currency only: nothing that changes how a match
## plays is locked behind the paid track.
class_name SeasonScreen
extends Control

var main
var back: Callable


func _init(m, on_back: Callable) -> void:
	main = m
	back = on_back


func _ready() -> void:
	Store.purchase_finished.connect(_on_purchase)
	add_child(UI.background())
	var cfg := Extras.season_cfg()
	var tiers: Array = cfg.get("tiers", [])
	var t := UI.label(String(cfg.get("name", "Season pass")), 38, UI.GOLD)
	t.position = Vector2(40, 18)
	add_child(t)
	var per := int(cfg.get("xp_per_tier", 100))
	var xp := int(Extras.season_now().get("xp", 0))
	var tier := Extras.season_tier()
	var sub := UI.label("Tier %d of %d    %s    Ends %s" % [tier, tiers.size(), ("next tier in %d XP" % (per - xp % per)) if tier < tiers.size() else "complete", String(cfg.get("ends", ""))], 18, UI.INK_SOFT)
	sub.position = Vector2(42, 66)
	add_child(sub)
	add_child(UI.pin_top_right(UI.status_bar(Vector2.ZERO), 20, 14))
	var pid := String(cfg.get("product", ""))
	var buy_row := HBoxContainer.new()
	buy_row.position = Vector2(40, 100)
	buy_row.add_theme_constant_override("separation", 14)
	add_child(buy_row)
	if Extras.season_premium():
		buy_row.add_child(UI.label("Premium track unlocked", 20, UI.GOLD))
	else:
		buy_row.add_child(UI.button("Unlock the premium track: %s" % Store.price(pid), func(): Store.buy(pid), 20, UI.GOLD, "gem"))
		buy_row.add_child(UI.label(String(GameState.product(pid).get("desc", "")), 15, UI.INK_SOFT))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 160)
	scroll.size = Vector2(1200, 560)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	scroll.add_child(row)
	var first: Button
	for i in tiers.size():
		var ti := i
		var reached := i < tier
		var p := UI.panel(UI.PANEL_2 if reached else UI.PANEL, 12, UI.GOLD if reached else UI.LINE)
		p.custom_minimum_size = Vector2(190, 520)
		row.add_child(p)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		p.add_child(v)
		v.add_child(UI.label("Tier %d" % (i + 1), 22, UI.GOLD if reached else UI.INK_SOFT))
		for track in ["free", "premium"]:
			var tr: String = track
			var r: Dictionary = tiers[i].get(track, {})
			var box := UI.panel(UI.BG, 10, UI.CYAN if track == "free" else UI.PINK)
			box.custom_minimum_size = Vector2(166, 210)
			v.add_child(box)
			var bv := VBoxContainer.new()
			box.add_child(bv)
			bv.add_child(UI.label("FREE" if track == "free" else "PREMIUM", 13, UI.CYAN if track == "free" else UI.PINK))
			if r.is_empty():
				bv.add_child(UI.label("-", 18, UI.LINE))
				continue
			var txt := _reward_text(r)
			var l := UI.wrap_label(txt, 16)
			l.custom_minimum_size = Vector2(150, 90)
			bv.add_child(l)
			var got: bool = Extras.season_now().get(track, {}).has(str(i))
			var can: bool = reached and not got and (track == "free" or Extras.season_premium())
			var b := UI.button("Claimed" if got else ("Claim" if can else ("Locked" if not reached else "Premium")), func():
				if Extras.claim_season(ti, tr):
					SFX.play("win")
					main.show_season(back), 16, UI.GOLD if can else UI.LINE)
			b.disabled = not can
			bv.add_child(b)
			if first == null and can:
				first = b
	var bk := UI.button("Back", back, 20, UI.LINE, "return")
	bk.position = Vector2(40, 735)
	add_child(bk)
	(first if first else bk).call_deferred("grab_focus")
	if tier > 3:
		await get_tree().process_frame
		scroll.scroll_horizontal = (tier - 3) * 200


func _reward_text(r: Dictionary) -> String:
	var parts := []
	var d := GameState.describe(r)
	if d != "":
		parts.append(d)
	var o := String(r.get("outfit", ""))
	if o.contains(":"):
		var bits := o.split(":")
		parts.append("%s outfit: %s" % [UI.first_name(bits[0]), String(GameState.outfit_def(bits[0], bits[1]).get("name", bits[1]))])
	return "\n".join(parts)


func _on_purchase(pid: String, ok: bool, msg: String) -> void:
	if not is_inside_tree():
		return
	if ok and pid == String(Extras.season_cfg().get("product", "")):
		main.show_season(back)
	elif not ok and msg != "":
		UI.popup(self, "Purchase", msg, [["OK", func(): pass]])


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		back.call()
