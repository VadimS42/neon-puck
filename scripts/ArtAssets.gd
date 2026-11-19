## ArtAssets.gd
##
## The one place that knows where real art lives. Every lookup returns the
## texture if a file exists at that exact path, or null so the caller draws
## its placeholder. Dropping a correctly named PNG into res://art/... is the
## whole integration step. docs/ART_LIST.md lists every path and size.
class_name ArtAssets
extends RefCounted

const EXPRESSIONS := ["neutral", "happy", "shy", "surprised", "teasing", "sad", "angry"]


static func _try(path: String) -> Texture2D:
	# All-ages mode looks for <name>_sfw.png first.
	if GameState.sfw and path.ends_with(".png") and not path.ends_with("_sfw.png"):
		var alt := _try(path.trim_suffix(".png") + "_sfw.png")
		if alt:
			return alt
	if ResourceLoader.exists(path):
		var r = load(path)
		if r is Texture2D:
			return r
	return null


## UI icon: res://art/ui/icons/<name>.png (the Kenney and Ravenmore icons
## brought over from Charm Combo; see data/credits.txt).
static func icon(name: String) -> Texture2D:
	return _try("res://art/ui/icons/%s.png" % name)


## Match portrait at strip stage 0..3 (0 = fully dressed).
## res://art/heroines/<id>/stage_<n>.png, falling back to lower stages.
static func stage(id: String, n: int) -> Texture2D:
	for i in range(n, -1, -1):
		var t := _try("res://art/heroines/%s/stage_%d.png" % [id, i])
		if t:
			return t
	return null


## Dialogue sprite. res://art/heroines/<id>/vn_<expression>.png, then
## vn_neutral.png, then her stage_0 portrait.
static func vn(id: String, expression: String) -> Texture2D:
	var t := _try("res://art/heroines/%s/vn_%s.png" % [id, expression])
	if t:
		return t
	t = _try("res://art/heroines/%s/vn_neutral.png" % id)
	if t:
		return t
	return stage(id, 0)


## Roster card / gallery thumbnail. res://art/heroines/<id>/card.png
static func card(id: String) -> Texture2D:
	var t := _try("res://art/heroines/%s/card.png" % id)
	return t if t else stage(id, 0)


## Reward scene CG. res://art/scenes/<scene_id>.png
static func scene(scene_id: String) -> Texture2D:
	return _try("res://art/scenes/%s.png" % scene_id)


## res://art/bg/<name>.png (lounge, menu, street, bar, office)
static func background(name: String) -> Texture2D:
	return _try("res://art/bg/%s.png" % name)


## Table pieces: res://art/table/table.png (960x540 playfield), puck.png,
## paddle_player.png, paddle_<heroine id>.png
static func table(name: String) -> Texture2D:
	return _try("res://art/table/%s.png" % name)


static func ui(name: String) -> Texture2D:
	return _try("res://art/ui/%s.png" % name)
