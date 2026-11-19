## Headless checks for the free-to-play rules: lives (spend, refund, clock
## refill, free replays), daily streak, outfits, store grants, ad pacing.
##   godot --headless --path . -s tools/f2p_test.gd
extends SceneTree

var gs
var fails := 0


func ok(cond: bool, what: String) -> void:
	print(("  ok    " if cond else "  FAIL  ") + what)
	if not cond:
		fails += 1


func _init() -> void:
	await process_frame
	gs = root.get_node("GameState")
	gs.no_save = true
	gs.reset_progress()
	gs.owned_products = {}
	gs.outfits_owned = {}
	gs.outfit = {}
	gs.unlimited_until = 0
	gs.today = {}
	gs.daily_last = ""
	gs.refill_lives()
	var story := {"mode": "story"}
	print("Lives")
	ok(gs.lives == 5 and gs.max_lives() == 5, "start with 5 of 5")
	ok(gs.spend_life(story) and gs.lives == 4, "a story match takes a life")
	ok(gs.life_next_at > 0, "refill clock starts")
	ok(not gs.spend_life({"mode": "replay"}) and gs.lives == 4, "replays are free")
	ok(not gs.match_costs_life({"mode": "cup", "round": 1}), "later cup rounds are free")
	gs.add_lives(1)
	ok(gs.lives == 5 and gs.life_next_at == 0, "a win gives it back and stops the clock")
	for i in 5:
		gs.spend_life(story)
	ok(gs.lives == 0 and not gs.can_start(story), "out of lives blocks a story match")
	ok(gs.can_start({"mode": "replay"}), "but not a replay")
	gs.life_next_at = gs.now() - 1 - gs.refill_seconds()
	gs.tick_lives()
	ok(gs.lives == 2, "the clock refills while away (2 lives after 2 periods)")
	gs.gems = 100
	ok(gs.buy_life_refill() and gs.lives == 5 and gs.gems == 70, "refill for 30 gems")
	ok(gs.buy_unlimited() and gs.has_unlimited() and not gs.spend_life(story), "unlimited lives skip the cost")
	gs.unlimited_until = 0
	print("Rewarded ads")
	gs.today = {}
	ok(gs.ad_lives_left() == 5, "5 ad lives a day")
	for i in 5:
		gs.note_rewarded("life")
	ok(gs.ad_lives_left() == 0 and gs.rewarded_left() == 10, "cap reached, other rewarded still open")
	gs.today["date"] = "2000-01-01"
	ok(gs.ad_lives_left() == 5, "counters reset the next day")
	print("Daily reward")
	var t0: int = gs.tips
	ok(gs.daily_available(), "daily available on first launch")
	gs.claim_daily()
	ok(gs.tips == t0 + 100 and not gs.daily_available() and gs.daily_day == 0, "day 1 pays 100 tips once")
	gs.daily_last = Time.get_date_string_from_unix_time(gs.now() - 86400)
	ok(int(gs.daily_preview()[0]) == 1, "next day continues the streak")
	gs.daily_last = "2000-01-01"
	ok(int(gs.daily_preview()[0]) == 0, "a missed day restarts it")
	print("Outfits")
	ok(gs.current_outfit("mila") == "default", "default outfit")
	ok(not gs.outfit_owned("mila", "date"), "date outfit locked until her story is done")
	gs.gems = 100
	ok(not gs.buy_outfit("mila", "league"), "can't buy at 100 of 120 gems")
	gs.gems = 300
	ok(gs.buy_outfit("mila", "league") and gs.current_outfit("mila") == "league" and gs.gems == 180, "buy and wear the league jersey")
	gs.progress["mila"] = 6
	ok(gs.outfit_owned("mila", "date"), "finishing her story unlocks the date outfit")
	print("Store")
	var g0: int = gs.gems
	gs.grant_product("gems_450")
	ok(gs.gems == g0 + 450 and not gs.owns("gems_450") and gs.owns("payer"), "gem pack adds gems, stays buyable")
	gs.grant_product("starter_pack")
	ok(gs.owns("starter_pack") and gs.owned_gear.has("paddle_2") and int(gs.powerups.get("energy", 0)) >= 3, "starter pack grants once")
	gs.owned_products = {}
	gs.grant_product("lounge_pass")
	ok(gs.max_lives() == 8 and gs.lives == 8 and gs.refill_seconds() == 600, "VIP pass: 8 lives, 10-minute refill")
	print("Interstitials")
	gs.owned_products = {}
	gs.matches_total = 0
	gs.matches_since_ad = 0
	gs.last_interstitial = 0
	for i in 3:
		gs.note_match_finished()
	ok(not gs.interstitial_due(), "none in the first 3 matches")
	gs.note_match_finished()
	ok(gs.interstitial_due(), "one after match 4")
	gs.note_interstitial()
	for i in 3:
		gs.note_match_finished()
	ok(not gs.interstitial_due(), "not again within 3 minutes")
	gs.last_interstitial = gs.now() - 200
	ok(gs.interstitial_due(), "again after 3 matches and 3 minutes")
	gs.owned_products["remove_ads"] = true
	ok(not gs.interstitial_due(), "never after Remove Ads")
	print("" if fails == 0 else "%d FAILED" % fails)
	print("All F2P checks passed." if fails == 0 else "")
	quit(1 if fails > 0 else 0)
