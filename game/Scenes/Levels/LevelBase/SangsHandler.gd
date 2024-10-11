extends Node


signal sang_moved


func _ready():
	for sang in get_tree().get_nodes_in_group("sang"):
		sang.connect("moved", self, "_on_sang_moved")


func _on_sang_moved(sang: RigidBody2D, collider: PhysicsBody2D, impact_momentum: Vector2):
	if sang.score_awarded:
		return
	emit_signal("sang_moved", sang, impact_momentum)
	#sang.queue_free()
