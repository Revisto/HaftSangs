extends Node2D

onready var balls_tween := $BallsTween
onready var clouds = get_tree().get_nodes_in_group("clouds")

var far_speed = 25
var near_speed = 50

var clouds_arr = []

class Cloud:
	var obj
	var speed: int
	var sprite: Sprite
	var tween: Tween
	var original_speed: int


func _ready():
	randomize()
	for c in clouds:
		if c.get_parent().name == "Far":
			var cl = Cloud.new()
			cl.obj = c
			cl.sprite = c.find_node("CloudSprite")
			cl.speed = far_speed + randi() % 20
			cl.original_speed = cl.speed
			animate(cl)
			clouds_arr.append(cl)
		if c.get_parent().name == "Near":
			var cl = Cloud.new()
			cl.obj = c
			cl.sprite = c.find_node("CloudSprite")
			cl.speed = near_speed + randi() % 20
			cl.original_speed = cl.speed
			animate(cl)
			clouds_arr.append(cl)


func _show_ball():
	var rnd_cloud = clouds_arr[randi() % clouds_arr.size()]
	rnd_cloud.obj.show_ball()


func _process(delta):
	var margin = 1000
	for el in clouds_arr:
		var c = el.obj as Node2D
		var s = el.speed
		c.position.x += s * delta
		var sprite_width = el.sprite.texture.get_size().x * c.scale.x
		if c.position.x - sprite_width / 2 > get_viewport_rect().size.x + margin:
			c.position.x = -sprite_width / 2 - margin
			 
			el.tween.stop(el.obj)
			el.tween.start()


func horizontal_transition_time(speed):
	return get_viewport_rect().size.x / speed


func animate(cl):
	cl.tween = Tween.new()
	var duration = horizontal_transition_time(cl.speed)
	var random_scale = Vector2(
		cl.obj.scale.x * rand_range(0.8, 1.2),
		cl.obj.scale.y * rand_range(0.8, 1.2)
	)
	cl.tween.interpolate_property(cl.obj, "scale", cl.obj.scale, random_scale, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	cl.tween.interpolate_property(cl.obj, "position:y", cl.obj.position.y, cl.obj.position.y + rand_range(-80, 80), duration, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	add_child(cl.tween)
	cl.tween.start()


func stop():
	for el in clouds_arr:
		el.tween.interpolate_property(el, "speed", el.speed, 0, 1.0, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		el.tween.start()


func move():
	for el in clouds_arr:
		el.tween.interpolate_property(el, "speed", el.speed, el.original_speed, 1.0, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		el.tween.start()
