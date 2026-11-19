## Store.gd (autoload "Store")
##
## Real-money purchases (gem packs, Starter Pack, Remove Ads, VIP Lounge
## Pass). Products and what they grant live in data/monetization.json.
##
## Two backends:
##  - "play": the Google Play Billing plugin, used automatically when the
##    Android build includes it (Engine singleton "GodotGooglePlayBilling",
##    from github.com/godot-sdk-integrations/godot-google-play-billing).
##    Written against that plugin's documented API and NOT yet tested on a
##    device: test with Play Console license testers before release.
##  - "test": everywhere else (editor, desktop, an APK without the plugin).
##    Every purchase succeeds instantly and is labelled TEST, so the whole
##    store can be played through without spending money.
##
## Grant on purchase, then acknowledge (non-consumables) or consume (gems)
## so Google doesn't refund it after 3 days. For a public launch, verify
## purchase tokens on a server too (see README_PLAY.md).
extends Node

signal purchase_finished(product_id: String, ok: bool, message: String)
signal prices_updated

var backend := "test"
## product id -> localized price string from Google Play.
var prices: Dictionary = {}
var connected := false
var _billing: Object
var _pending := ""


func _ready() -> void:
	if Engine.has_singleton("GodotGooglePlayBilling"):
		_billing = Engine.get_singleton("GodotGooglePlayBilling")
		backend = "play"
		_billing.connect("connected", _on_connected)
		_billing.connect("disconnected", func(): connected = false)
		_billing.connect("connect_error", func(_c, _m): connected = false)
		_billing.connect("purchases_updated", _on_purchases_updated)
		_billing.connect("purchase_error", _on_purchase_error)
		_billing.connect("sku_details_query_completed", _on_details)
		_billing.connect("query_purchases_response", _on_query_purchases)
		_billing.startConnection()


func is_test() -> bool:
	return backend == "test"


## The price to show: Google Play's localized price once known, otherwise
## the placeholder in monetization.json.
func price(pid: String) -> String:
	if prices.has(pid):
		return String(prices[pid])
	return String(GameState.product(pid).get("price", "?"))


## One-time and non-consumable products can only be bought once.
func can_buy(pid: String) -> bool:
	var p := GameState.product(pid)
	if p.is_empty():
		return false
	return String(p.get("type", "")) == "consumable" or not GameState.owns(pid)


func buy(pid: String) -> void:
	if not can_buy(pid):
		purchase_finished.emit(pid, false, "Already owned.")
		return
	if backend == "play":
		if not connected:
			purchase_finished.emit(pid, false, "Google Play isn't reachable right now. Try again in a moment.")
			_billing.startConnection()
			return
		_pending = pid
		var r = _billing.purchase(pid)
		if r is Dictionary and int(r.get("status", OK)) != OK:
			_pending = ""
			purchase_finished.emit(pid, false, String(r.get("debug_message", "Purchase failed.")))
		return
	# Test backend: succeed after a beat so the UI flow is the real one.
	await get_tree().create_timer(0.4).timeout
	GameState.grant_product(pid)
	purchase_finished.emit(pid, true, "TEST purchase: no money was charged.")


## "Restore purchases": asks Google Play for owned non-consumables.
func restore() -> void:
	if backend == "play" and connected:
		_billing.queryPurchases("inapp")
	else:
		purchase_finished.emit("", true, "Test store: nothing to restore.")


func _on_connected() -> void:
	connected = true
	var ids := []
	for p in GameState.f2p.get("products", []):
		ids.append(String(p["id"]))
	_billing.querySkuDetails(ids, "inapp")
	_billing.queryPurchases("inapp")


func _on_details(details: Array) -> void:
	for d in details:
		prices[String(d.get("sku", d.get("product_id", "")))] = String(d.get("price", ""))
	prices_updated.emit()


func _on_purchases_updated(purchases: Array) -> void:
	for p in purchases:
		_handle(p, true)


func _on_query_purchases(result) -> void:
	var list: Array = result.get("purchases", []) if result is Dictionary else []
	for p in list:
		_handle(p, false)
	if _pending == "":
		purchase_finished.emit("", true, "Purchases restored.")


func _on_purchase_error(_code, message) -> void:
	var pid := _pending
	_pending = ""
	purchase_finished.emit(pid, false, String(message))


## Grants a confirmed purchase once, then consumes or acknowledges it.
func _handle(p: Dictionary, fresh: bool) -> void:
	if int(p.get("purchase_state", 1)) != 1:
		return  # pending (e.g. cash payment): granted when it completes
	var skus: Array = p.get("skus", [])
	var pid := String(skus[0]) if not skus.is_empty() else String(p.get("sku", ""))
	var token := String(p.get("purchase_token", ""))
	var prod := GameState.product(pid)
	if prod.is_empty():
		return
	var consumable := String(prod.get("type", "")) == "consumable"
	if consumable:
		GameState.grant_product(pid)
		_billing.consumePurchase(token)
	else:
		if not GameState.owns(pid):
			GameState.grant_product(pid)
		if not bool(p.get("is_acknowledged", false)):
			_billing.acknowledgePurchase(token)
	if fresh or pid == _pending:
		_pending = ""
		purchase_finished.emit(pid, true, "Thanks! %s added." % String(prod.get("name", pid)))
