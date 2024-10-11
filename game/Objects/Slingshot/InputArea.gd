""" Detect touch inputs and dispatch signals to the Slingshot node.
"""
extends Area2D

signal slingshot_released
signal slingshot_grabbed
signal slingshot_moved

var touch = false
var locked = false

onready var rest_position = get_parent().get_node("RestPosition")

func _ready():
	visible = true

func _input(event):
	if locked:
		return   

	if event is InputEventScreenTouch:
		if event.is_pressed():
			touch = true
		else:
			emit_signal("slingshot_released")
			touch = false

			 
			locked = true

	if event is InputEventScreenDrag:
		if touch:
			emit_signal("slingshot_moved", event.position)

func _on_InputArea_input_event(viewport, event: InputEvent, shape_idx):
	if locked:
		return   

	if event is InputEventScreenTouch:
		if event.is_pressed():
			emit_signal("slingshot_grabbed")
			touch = true
		else:
			emit_signal("slingshot_released")
			touch = false

			 
			locked = true

	if event is InputEventScreenDrag:
		if touch:
			emit_signal("slingshot_moved", event.position)
