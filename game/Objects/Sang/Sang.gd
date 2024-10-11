class_name Sang
extends RigidBody2D

const MOVE_THRESHOLD_BY_OBSTACLES = 400  
const MOVE_THRESHOLD = 1600  

signal moved(sang_moved, collider, impact_momentum)

var am_i_shooting: bool = false
var score_awarded: bool = false
var initial_position: Vector2
var initial_rotation: float
var initial_data = {}

func _ready():
	Globals.game_manager.connect("lock_controls", self, "_on_lock_controls")
	
	 
	initial_position = global_position
	initial_rotation = rotation
	save_initial_state()

func save_initial_state():
	initial_data.position = global_position
	initial_data.rotation = rotation
	initial_data.name = name

func reset_to_initial_state():
	 
	global_position = initial_data.position
	rotation = initial_data.rotation
	
	 
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	 
	mode = MODE_RIGID
	set_mode(RigidBody2D.MODE_RIGID)
	
	 
	visible = true
	
	print("Sang reset to initial state at ", global_position)

func _integrate_forces(state):
	for collision_idx in state.get_contact_count():
		var collider = state.get_contact_collider_object(collision_idx)
		if collider is RigidBody2D:
			var impact_momentum = collider.mass * collider.linear_velocity - mass * linear_velocity
			if impact_momentum.length() >= get_destruction_threshold(collider):
				if am_i_shooting:
					emit_signal("moved", self, collider, impact_momentum)

func get_destruction_threshold(collider_type: RigidBody2D):
	match collider_type.get_class():
		"Obstacle":
			return MOVE_THRESHOLD_BY_OBSTACLES
		"Projectile":
			return MOVE_THRESHOLD
		_:
			return MOVE_THRESHOLD

func _on_lock_controls(lock_move_obstacles, lock_shooting):
	am_i_shooting = not(lock_shooting)
