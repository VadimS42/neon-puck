## Music.gd (autoload "Music")
##
## Background music, drop-in like the art: a track plays if a file exists at
## res://audio/music/<track>.ogg (.mp3 and .wav work too); otherwise nothing
## plays. Tracks: "lounge" (menus, roster, shop, dialogue), "match" (on the
## table), "scene" (reward scenes). Switching crossfades. The current tracks
## came from Charm Combo; credits are in data/credits.txt.
extends Node

const DIR := "res://audio/music/"
const FADE := 1.0
const VOLUME_DB := -10.0

var enabled := true
var current := ""
var _players: Array[AudioStreamPlayer] = []
var _active := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)


func play(track: String) -> void:
	if track == current or DisplayServer.get_name() == "headless":
		return
	current = track
	var stream: AudioStream = null
	for ext: String in ["ogg", "mp3", "wav"]:
		var path := DIR + track + "." + ext
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	var old := _players[_active]
	_active = 1 - _active
	var nu := _players[_active]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(old, "volume_db", -80.0, FADE)
	tw.chain().tween_callback(old.stop)
	if stream and enabled:
		nu.stream = stream
		nu.volume_db = -40.0
		nu.play()
		create_tween().tween_property(nu, "volume_db", VOLUME_DB, FADE)


func set_enabled(on: bool) -> void:
	enabled = on
	var t := current
	current = ""
	if on:
		play(t)
	else:
		for p in _players:
			p.stop()
		current = t
