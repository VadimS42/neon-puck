## ResultScreen.gd: after a match. A win continues to her story beat and
## scene; a loss offers a retry, her counter-tip, and an easier difficulty.
class_name ResultScreen
extends Control

var main
var heroine_id := ""
var match_index := 0
var rules: MatchRules
var on_continue: Callable


func _init(m, id: String, mi: int, r: MatchRules, cont: Callable = Callable()) -> void:
	main = m
	heroine_id = id
	match_index = mi
	rules = r
	on_continue = cont


func _ready() -> void:
	var won := on_continue.is_valid()
	var h := GameState.heroine(heroine_id)
	add_child(UI.background())
	var por := HeroinePortrait.new(heroine_id, rules.layers_lost, "stage")
	por.position = Vector2(760, 60)
	por.size = Vector2(440, 680)
	add_child(por)
	var v := VBoxContainer.new()
	v.position = Vector2(80, 90)
	v.custom_minimum_size = Vector2(600, 0)
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	v.add_child(UI.label("You win!" if won else "%s wins" % UI.first_name(heroine_id), 54, UI.GOLD if won else UI.BAD))
	v.add_child(UI.label("%d : %d" % [rules.sim.paddle(0).score, rules.sim.paddle(1).score], 40, UI.INK))
	var stats := "Layers taken: %d / %d\nSmash goals: %d    Bank goals: %d    Saves: %d\nHer %s goals: %d" % [rules.layers_lost, rules.layer_count, rules.smash_goals, rules.bank_goals, rules.saves, String(h.get("signature_name", "")), rules.her_signature_goals]
	v.add_child(UI.wrap_label(stats, 20, UI.INK_SOFT))
	var first: Button
	if won:
		var scene: Dictionary = h["matches"][match_index].get("scene", {})
		v.add_child(UI.label("Scene unlocked: " + String(scene.get("title", "")), 24, UI.PINK))
		v.add_child(UI.label("%s now: %s" % [UI.first_name(heroine_id), GameState.attitude(heroine_id)], 22, UI.hcolor(heroine_id)))
		if GameState.story_done(heroine_id) and match_index == GameState.match_count(heroine_id) - 1:
			v.add_child(UI.label("You learned her %s! Pick it on the roster." % String(h.get("signature_name", "")), 20, UI.GOLD))
		first = UI.button("Continue", on_continue, 26)
		v.add_child(first)
	else:
		v.add_child(UI.wrap_label("Tip: " + String(h.get("signature_tip", "")), 19, UI.CYAN))
		v.add_child(UI.wrap_label("Every layer you take makes her slower or smaller, so landing smashes early makes the rest of the match easier.", 17, UI.INK_SOFT))
		first = UI.button("Rematch", func(): main.play_match(heroine_id, match_index), 26)
		v.add_child(first)
		if GameState.difficulty != "story":
			v.add_child(UI.button("Rematch on Story difficulty", func():
				GameState.difficulty = "story"
				GameState.save()
				main.play_match(heroine_id, match_index), 20, UI.CYAN))
		v.add_child(UI.button("Back to roster", main.show_roster, 20, UI.LINE))
	first.call_deferred("grab_focus")
