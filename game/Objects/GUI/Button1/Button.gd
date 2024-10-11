extends TextureButton
tool
export(String) var text setget _set_btn_text


func _ready():
	connect("pressed", self, "_on_pressed")


func _unhandled_input(event):
	if disabled:
		return

	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if _is_btn_pressed(self, event):
			emit_signal("pressed")


func _is_btn_pressed(btn: BaseButton, event: InputEventScreenTouch):
	if not event is InputEventScreenTouch:
		print("ERROR: Event ", event, " is not InputEventScreenTouch")
		return
	if Rect2(btn.get_global_rect().position, btn.rect_size).has_point(event.position):
		return true


func _on_pressed():
	$AudioStreamPlayer.play()


func _set_btn_text(value):
	 
	var label = get_node_or_null("Label")
	if label == null:
		return
	label.text = value
	text = value

