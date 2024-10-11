extends RigidBody2D
class_name Obstacle

export(Texture) var debris_texture
export(String) var identifier

signal hit

var dragging = false
var locked = false
var initial_position: Vector2
var initial_rotation: float
var initial_data = {}

func _ready():
	set_process_input(true)
	connect_signals()
	print("Obstacle ready at ", global_position)
	
	 
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
	
	 
	dragging = false
	Globals.is_dragging_obstacle = false
	input_pickable = true
	
	 
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	 
	mode = MODE_RIGID
	set_mode(RigidBody2D.MODE_RIGID)
	
	 
	visible = true
	
	 
	send_update_to_network()
	
	print("Obstacle reset to initial state at ", global_position)

func connect_signals():
	if Globals.network_manager:
		Globals.network_manager.connect("obstacles_updated", self, "_on_obstacles_updated")
	Globals.game_manager.connect("lock_controls", self, "_on_lock_controls")

func _input(event):
	if locked:
		return
	handle_input(event)

func handle_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed and is_mouse_nearby():
				print("Starting to drag obstacle")
				start_dragging()
			elif not event.pressed and dragging:
				print("Stopping dragging of obstacle")
				stop_dragging()

func is_mouse_nearby() -> bool:
	return get_global_mouse_position().distance_to(global_position) < 50

func _process(delta):
	if dragging:
		update_dragging()

func update_dragging():
	global_position = get_global_mouse_position()
	print("Dragging obstacle to ", global_position)
	send_update_to_network()

func send_update_to_network():
	if Globals.network_manager:
		Globals.network_manager.send_obstacle_update(name, global_position, rotation, dragging)
	else:
		print("Network manager is null, cannot send update")

func start_dragging():
	dragging = true
	Globals.is_dragging_obstacle = true
	input_pickable = false
	
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	mode = MODE_STATIC
	set_mode(RigidBody2D.MODE_STATIC)   
	print("Obstacle dragging started")

func stop_dragging():
	dragging = false
	Globals.is_dragging_obstacle = false
	input_pickable = true
	
	 
	var current_position = global_position
	global_position = get_global_mouse_position()

	 
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	 
	 
	
	 
	if linear_velocity != Vector2.ZERO:
		var movement_delta = global_position - current_position
		global_position += movement_delta

	print("Obstacle dragging stopped at ", global_position)
	send_update_to_network()

func get_debris_texture() -> Texture:
	return debris_texture

func get_class():
	return "Obstacle"

func _on_lock_controls(lock_move_obstacles, lock_shooting):
	locked = lock_move_obstacles
	if locked and dragging:
		stop_dragging()

func update_obstacle(position: Vector2, rotation: float):
	global_position = position
	self.rotation = rotation
	print("Obstacle updated to position: ", position, ", rotation: ", rotation)

func _on_obstacles_updated(obstacles_data):
	print("Obstacles updated: ", obstacles_data)
	for obstacle_name in obstacles_data.keys():
		var obstacle = find_obstacle_by_name(obstacle_name)
		if obstacle:
			update_found_obstacle(obstacle, obstacles_data[obstacle_name])
		else:
			print("Obstacle not found: ", obstacle_name)

func find_obstacle_by_name(name: String) -> Obstacle:
	for node in get_tree().get_nodes_in_group("obstacle"):
		if node.name == name:
			return node
	return null

func update_found_obstacle(obstacle, data):
	var position_data = data["position"]
	var rotation = data["rotation"]
	var position = Vector2(position_data[0], position_data[1])
	var income_dragging = data["dragging"]

	obstacle.update_obstacle(position, float(rotation))

	if not income_dragging:
		var current_position = obstacle.global_position
		 
		if obstacle.linear_velocity != Vector2.ZERO:
			var movement_delta = obstacle.global_position - current_position
			obstacle.global_position += movement_delta

	print("Obstacle updated: ", obstacle.name)
