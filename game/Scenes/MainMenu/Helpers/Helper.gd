extends Node

onready var continue_button = $NinePatchRect/MarginContainer/VBoxContainer/Continue


func _on_continue_press():
	Globals.music_player.stop()
	Globals.goto_scene("res://Scenes/Levels/LevelBase/LevelBase.tscn", { 'level': 1 })
