extends Obstacle
class_name StoneObstacle
 
var StoneObstacleClassRef = load("res://Objects/Obstacles/StoneObstacle/StoneObstacle1.gd")


 
onready var collision_shape := $CollisionShape2D
 
var start_damaged = true
 
const BREAK_THRESHOLDS = {
	'obstacle': 2200,
	'projectile': 1000
}
const SMALL_HIT_THRESHOLD = 620


func _ready():
	set_damaged(start_damaged)


func set_damaged(damaged):
	if damaged:
		$Sprite.hide()
		$SpriteDamaged.show()
	else:
		$Sprite.show()
		$SpriteDamaged.hide()


func is_damaged():
	return $SpriteDamaged.visible


func _integrate_forces(state: Physics2DDirectBodyState):
	for c_id in state.get_contact_count():
		var collider = state.get_contact_collider_object(c_id)
		var collision_pos: Vector2 = state.get_contact_collider_position(c_id)
		var collider_velocity: Vector2 = state.get_contact_collider_velocity_at_position(c_id)

		 
		if collider is TileMap:
			return

		 
		var self_momentum = state.linear_velocity * mass
		var collider_momentum = collider_velocity * collider.mass
		var impact_momentum = self_momentum - collider_momentum
		var impact_amount = impact_momentum.length()

		 
		if impact_amount < SMALL_HIT_THRESHOLD:
			return

		var break_point = get_breakpoint_for(collider)
		if impact_amount >= SMALL_HIT_THRESHOLD and impact_amount < break_point:
			emit_signal("hit", self, collision_pos, false)
		elif impact_amount >= break_point:
			if is_damaged():
				emit_signal("hit", self, collision_pos, true)
				#if collider is StoneObstacleClassRef:
				#	hide_obstacle(collider)
				#hide_obstacle(self)
			else:
				set_damaged(true)
				emit_signal("hit", self, global_position, false)


func hide_obstacle(obstacle):
	obstacle.hide()
	obstacle.collision_shape.disabled = true
	obstacle.mode = MODE_STATIC   
	obstacle.set_physics_process(false)   
	obstacle.set_process(false)   


func get_breakpoint_for(collider):
	if collider is Projectile:
		return BREAK_THRESHOLDS.projectile
	else:
		return BREAK_THRESHOLDS.obstacle

func reset_to_initial_state():
	.reset_to_initial_state()
	
	set_damaged(false)
	$Sprite.show()
	$SpriteDamaged.hide()
	show()
	collision_shape.disabled = false
	mode = MODE_RIGID   
	set_physics_process(true)   
	set_process(true)   
	print("StoneObstacle reset to initial state at ", global_position)
