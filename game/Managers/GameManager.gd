extends Node

signal lock_controls(lock_move_obstacles, lock_shooting)
signal launch_projectile

enum TurnState { WHITE_MOVE, BLACK_SHOOT, BLACK_MOVE, WHITE_SHOOT }

onready var game_status = get_node_or_null("../GUI/GameStatus")
onready var game_timer = get_node_or_null("../GUI/GameTimer")
onready var network_manager = Globals.network_manager
onready var waiting_overlay = get_node_or_null("../GUI/WaitingOverlay")
onready var reset_overlay = get_node_or_null("../GUI/ResetOverlay")
onready var wait_status = get_node_or_null("../GUI/WaitingOverlay/WaitStatus")
onready var reset_status = get_node_or_null("../GUI/ResetOverlay/ResetStatus")
onready var clouds = get_node_or_null("../Clouds")

var white_turns = [TurnState.WHITE_MOVE, TurnState.WHITE_SHOOT]
var black_turns = [TurnState.BLACK_SHOOT, TurnState.BLACK_MOVE]

var timer = 10.0
var current_turn = 0
var is_white = false   
var match_found = false   
var dot_count = 0   
var dot_timer = 0.0   
var removing_dots = false
var round_count = 0

func _ready():	
	if network_manager == null:
		print("Error: NetworkManager not found")
		return

	network_manager.connect("waiting_for_player", self, "_on_waiting_for_player")
	network_manager.connect("match_found", self, "_on_match_found")

	var gui_node = get_node_or_null("../GUI")
	if gui_node == null:
		print("Error: GUI node not found")
		return

	game_status = gui_node.get_node_or_null("GameStatus")
	if game_status == null:
		print("Error: GameStatus node not found")
		return

	game_timer = gui_node.get_node_or_null("GameTimer")
	if game_timer == null:
		#print("Error: GameTimer node not found")
		return

	waiting_overlay = gui_node.get_node_or_null("WaitingOverlay")
	if waiting_overlay == null:
		print("Error: WaitingOverlay node not found")
		return

	reset_overlay = gui_node.get_node_or_null("ResetOverlay")
	if reset_overlay == null:
		print("Error: ResetOverlay node not found")
		return

	wait_status = waiting_overlay.get_node_or_null("WaitStatus")
	if wait_status == null:
		print("Error: WaitStatus node not found")
		return

	reset_status = reset_overlay.get_node_or_null("ResetStatus")
	if reset_status == null:
		print("Error: ResetStatus node not found")
		return

	clouds = get_node_or_null("../Clouds")
	if clouds == null:
		print("Error: Clouds node not found")
		return

	set_process(true)
	network_manager.request_match()

	 
	waiting_overlay.raise()

func _process(delta):
	if not match_found:
		dot_timer += delta
		if wait_status and dot_timer >= 0.25:   
			dot_timer = 0.0
			if dot_count < 3 and not removing_dots:
				dot_count += 1
			else:
				removing_dots = true
				dot_count -= 1
				if dot_count == 0:
					removing_dots = false
			var dots = ".".repeat(dot_count)
			wait_status.text = "Waiting For Player\n\nOpen HaftSangs.ir in Another Tab to Play With Yourself\n\nWait" + dots
		return

	if round_count >= 1:
		set_game_status_text("Game Finished")
		timer = 0
		update_game_timer()
		stop_game()
		return

	timer -= delta
	if timer <= 0:
		switch_state()
		if round_count == 0.5 and get_active_projectiles() == 2:
			emit_signal("launch_projectile")
		yield(get_tree().create_timer(0.2), "timeout")
	update_game_timer()

func start_round():
	reset_game_scene()
	timer = 10.0
	current_turn = 0
	update_locks()
	update_game_status()
	update_game_timer()

func switch_state():
	round_count += 0.25
	if round_count >= 1:
		set_game_status_text("Game Finished")
		timer = 0
		update_game_timer()
		stop_game()
		return
	current_turn = (current_turn + 1) % 4
	if current_turn % 2 == 0:
		new_round_flashbang()

	timer = 10.0
	update_locks()
	update_game_status()
	update_game_timer()

func update_locks():
	var lock_move_obstacles = false
	var lock_shooting = false

	match current_turn:
		TurnState.WHITE_MOVE:
			lock_shooting = true
			lock_move_obstacles = false
		TurnState.WHITE_SHOOT:
			lock_move_obstacles = true
			lock_shooting = false
		TurnState.BLACK_SHOOT:
			lock_move_obstacles = true
			lock_shooting = false
		TurnState.BLACK_MOVE:
			lock_move_obstacles = false
			lock_shooting = true

	for obstacle in get_tree().get_nodes_in_group("obstacle"):
		if lock_move_obstacles == false:
			obstacle.mode = RigidBody2D.MODE_STATIC
			obstacle.set_mode(RigidBody2D.MODE_STATIC)
		else:
			obstacle.mode = RigidBody2D.MODE_RIGID
			obstacle.set_mode(RigidBody2D.MODE_RIGID)
	
	var projectiles = get_tree().get_nodes_in_group("projectile")

	if len(projectiles) == 2:
		for projectile in projectiles:
			if projectile.launched == true:
				 
				projectile.visible = false
				projectile.set_collision_layer(0)
				projectile.set_collision_mask(0)
				projectile.set_physics_process(false)
				projectile.set_process(false)
				projectile.set_process_input(false)
				projectile.set_process_unhandled_input(false)
				projectile.set_process_unhandled_key_input(false)

	 
	if (is_white and current_turn in black_turns) or (not is_white and current_turn in white_turns):
		lock_move_obstacles = true
		lock_shooting = true
		if clouds:
			clouds.move()
	else:
		if clouds:
			clouds.stop()

	print("Current turn: ", current_turn)
	print("Is White: ", is_white)
	print("Locking controls: Lock Move Obstacles: ", lock_move_obstacles, " Lock Shooting: ", lock_shooting)
	emit_signal("lock_controls", lock_move_obstacles, lock_shooting)

func update_game_status():
	if game_status:
		var status_text = ""
		if is_white:
			match current_turn:
				TurnState.WHITE_MOVE:
					status_text = "Your Turn: Move Obstacles"
				TurnState.WHITE_SHOOT:
					status_text = "Your Turn: Shoot"
				TurnState.BLACK_SHOOT:
					status_text = "Opponent's Turn: Shoot"
				TurnState.BLACK_MOVE:
					status_text = "Opponent's Turn: Move Obstacles"
		else:
			match current_turn:
				TurnState.WHITE_MOVE:
					status_text = "Opponent's Turn: Move Obstacles"
				TurnState.WHITE_SHOOT:
					status_text = "Opponent's Turn: Shoot"
				TurnState.BLACK_SHOOT:
					status_text = "Your Turn: Shoot"
				TurnState.BLACK_MOVE:
					status_text = "Your Turn: Move Obstacles"
		
		set_game_status_text(status_text)

func update_game_timer():
	if game_timer:
		game_timer.text = "Timer: %.2f" % timer
	else:
		#print("Error: GameTimer node not found")
		pass

func set_game_status_text(text):
	if game_status:
		game_status.text = text
	else:
		print("Error: GameStatus node not found")

func reset_game_scene():
	print("Resetting game scene")
	 
	for obstacle in get_tree().get_nodes_in_group("obstacle"):
		obstacle.reset_to_initial_state()
		obstacle.mode = RigidBody2D.MODE_STATIC

	for sang in get_tree().get_nodes_in_group("sang"):
		sang.reset_to_initial_state()

func stop_game():
	if get_active_projectiles() == 1:
		emit_signal("launch_projectile")
	set_process(false)
	print("Game stopped")

func _on_waiting_for_player():
	set_game_status_text("Waiting for another player...")
	print("Waiting for another player...")

func _on_match_found(role):
	set_game_status_text("Match found! Role: " + role)
	
	 
	fade_out(waiting_overlay)

	print("Match found! Role: ", role)
	is_white = (role == "white")
	match_found = true
	start_round()

func new_round_flashbang():
	fade_in(reset_overlay, 0.2)
	yield(get_tree().create_timer(0.8), "timeout")
	reset_game_scene()
	fade_out(reset_overlay)

func fade_out(node: CanvasItem, duration: float = 0.1):
	if node == null:
		print("Error: node is null")
		return
	
	var tween = get_node("../CameraFocus/Tween")
	tween.interpolate_property(
		node,
		"modulate:a",
		node.modulate.a,
		0,
		duration,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	tween.start()
	yield(tween, "tween_completed")
	node.visible = false

func fade_in(node: CanvasItem, duration: float = 0.1):
	if node == null:
		print("Error: node is null")
		return
	
	node.visible = true
	node.modulate.a = 0   
	
	var tween = get_node("../CameraFocus/Tween")
	tween.interpolate_property(
		node,
		"modulate:a",
		0,   
		1,   
		duration,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	tween.start()
	yield(tween, "tween_completed")

func get_active_projectiles():
	var active_projectiles = 0
	var projectiles = get_tree().get_nodes_in_group("projectile")
	for projectile in projectiles:
		if projectile.launched:
			active_projectiles += 1
	return active_projectiles
