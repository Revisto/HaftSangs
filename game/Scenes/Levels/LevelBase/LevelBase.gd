extends Node2D


onready var vfx_manager = $ParticlesManager
onready var score = $GUI/Score
onready var level_completed = $GameEndScreen/LevelCompleted
onready var game_manager = Globals.game_manager

var scene_parameters = {}


func _init():
	pass


func _post_init(params = {}):
	scene_parameters = params


func _ready():
	ProjectSettings.set_setting("physics/common/physics_fps", 120)
	for projectile in get_tree().get_nodes_in_group("projectile"):
		projectile.connect("body_entered", vfx_manager, "_on_Projectile_body_entered", [projectile])
	game_manager.start_round()

func _on_TouchScreenButton_released():
	game_manager.stop_game()
	get_tree().reload_current_scene()


func _on_ProjectilesLoader_level_finished():
	level_completed.appear(score.score_value)

