extends Node

export(String) var websocket_url = "ws://ws.haftsangs.ir/ws/game/"

var _client = WebSocketClient.new()
var obstacles_data_buffer = {}
var slingshot_data_buffer = {}

var sender_id = str(OS.get_unix_time()) + "_" + str(randi())
var reconnect_attempts = 0
var max_reconnect_attempts = 5

signal obstacles_updated(obstacles_data)
signal slingshot_updated(slingshot_data)
signal waiting_for_player()
signal match_found(role)
signal connection_failed()

var send_timer = Timer.new()

func _ready():
	print("NetworkManager: _ready() called")
	connect_signals()
	initiate_connection()
	# Setup the send timer
	send_timer.set_wait_time(0.2)  # 200 milliseconds
	send_timer.set_one_shot(false)
	send_timer.connect("timeout", self, "_on_send_timer_timeout")
	add_child(send_timer)

func connect_signals():
	_client.connect("connection_closed", self, "_on_connection_closed")
	_client.connect("connection_error", self, "_on_connection_error")
	_client.connect("connection_established", self, "_on_connection_established")
	_client.connect("data_received", self, "_on_data_received")

func initiate_connection():
	print("NetworkManager: Attempting to connect to WebSocket server at ", websocket_url)
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		print("NetworkManager: Unable to connect, retrying...")
		retry_connection()
	else:
		print("NetworkManager: Connection initiated.")

func retry_connection():
	if reconnect_attempts < max_reconnect_attempts:
		reconnect_attempts += 1
		print("NetworkManager: Retrying connection... Attempt ", reconnect_attempts)
		yield(get_tree().create_timer(2), "timeout")
		initiate_connection()
	else:
		print("NetworkManager: Max reconnect attempts reached.")
		emit_signal("connection_failed")

func _on_connection_closed(was_clean = false):
	print("NetworkManager: Connection closed, clean: ", was_clean)
	retry_connection()

func _on_connection_error():
	print("NetworkManager: Connection error")
	retry_connection()

func _on_connection_established(proto = ""):
	print("NetworkManager: Connected with protocol: ", proto)
	reconnect_attempts = 0  # Reset attempts on successful connection
	send_timer.start()  # Start the timer when connected

func _on_data_received():
	var data = _client.get_peer(1).get_packet().get_string_from_utf8()
	var json_data = JSON.parse(data)
	if json_data.error == OK:
		print("NetworkManager: Received data: ", json_data.result)
		if json_data.result.has("match_found"):
			emit_signal("match_found", json_data.result["match_found"]["role"])
		if json_data.result.has("match_waiting"):
			emit_signal("waiting_for_player")
		if json_data.result.has("obstacles_data"):
			obstacles_data = json_data.result["obstacles_data"]
			emit_signal("obstacles_updated", obstacles_data)
		if json_data.result.has("slingshot_data"):
			slingshot_data = json_data.result["slingshot_data"]
			emit_signal("slingshot_updated", slingshot_data)
	else:
		print("NetworkManager: Error parsing JSON: ", json_data.error_string)

func _process(delta):
	_client.poll()

func send_obstacle_update(obstacle_name, position, rotation, dragging):
	var position_list = [position.x, position.y]
	# Buffer the data
	obstacles_data_buffer[obstacle_name] = {
		"position": position_list,
		"rotation": rotation,
		"dragging": dragging
	}

func send_slingshot_update(position, state, launch_impulse):
	var position_list = [position.x, position.y]
	# Buffer the data
	slingshot_data_buffer = {
		"position": position_list,
		"state": state,
		"launch_impulse": [launch_impulse.x, launch_impulse.y]
	}

func request_match():
	var json_data = {"sender_id": sender_id, "request_match": true}
	_client.get_peer(1).put_packet(to_json(json_data).to_utf8())

func _on_send_timer_timeout():
	# Send buffered data to the server
	var json_data = {"sender_id": sender_id}
	var has_data = false
	if obstacles_data_buffer.size() > 0:
		json_data["obstacles_data"] = obstacles_data_buffer
		obstacles_data_buffer = {}  # Clear the buffer
		has_data = true
	if slingshot_data_buffer.size() > 0:
		json_data["slingshot_data"] = slingshot_data_buffer
		slingshot_data_buffer = {}  # Clear the buffer
		has_data = true
	if has_data:
		_client.get_peer(1).put_packet(to_json(json_data).to_utf8())
