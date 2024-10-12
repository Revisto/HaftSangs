extends Node

var is_dragging_obstacle = false
var main_scene: Node
var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
var game_manager: Node
var network_manager: Node

onready var current_level_index = 1

func _ready():
	network_manager = preload("res://Scripts/Network/NetworkManager.gd").new()
	add_child(network_manager)
	var bgm_path = "res://Assets/music/monkeys-spinning-monkeys.ogg"
	if File.new().file_exists(bgm_path):
		var music = load(bgm_path)
		music_player.stream = music
		
		var music_bus_id = AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(music_bus_id,"music")
		 
		AudioServer.set_bus_send(music_bus_id,"Master")

		add_child(music_player)
		music_player.bus = "music"

func goto_scene(new_scene: String, params = {}):
	 
	if game_manager != null:
		remove_child(game_manager)
		game_manager.queue_free()
		game_manager = null

	 
	if main_scene == null:
		get_tree().change_scene(new_scene)
	else:
		main_scene.load_scene(new_scene, params)

	 
	if new_scene.begins_with("res://Scenes/Levels/"):
		game_manager = preload("res://Managers/GameManager.gd").new()
		add_child(game_manager)

func get_level_path(level: int) -> String:
	var levels_base_path = "res://Scenes/Levels/LevelNodes/"
	var levels_path = {
		1: levels_base_path + "Level1.tscn",
	}
	return levels_path.get(level)
