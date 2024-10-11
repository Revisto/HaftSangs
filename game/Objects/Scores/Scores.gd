extends Node

""" Handles the scores appearing when the projectile
hits obstacles or enemies. """


signal points_gained

onready var scores_pool = $ScoresPool

const SANG_MOVED_BASE_POINTS = 500

var angle_randomness = 30


func _on_SangsHandler_sang_moved(sang: Sang, impact_momentum: Vector2):
	if sang.score_awarded:
		return

	sang.score_awarded = true
	var score_node: Node2D = scores_pool.get_instance()
	if score_node.get_parent() == null:
		add_child(score_node)
	#score_node.rotation_degrees = (randi() % angle_randomness) - (angle_randomness % 2)
	score_node.global_position = sang.global_position
	score_node.score_value = SANG_MOVED_BASE_POINTS + impact_momentum.length() / 30
	score_node.show()
	emit_signal("points_gained", score_node.score_value)
	if not score_node.is_connected("score_hidden", self, "_on_score_hidden_remove_score"):
		score_node.connect("score_hidden", self, "_on_score_hidden_remove_score")


func _on_score_hidden_remove_score(score):
	score.can_be_pooled = true

