extends AnimatedSprite


onready var tween = $Tween

func _ready():
	pass  


func _on_AnimatedSprite_animation_finished():
	playing = false
	if tween.is_active():
		tween.stop()
	tween.interpolate_property(self, "modulate:a", self.modulate.a, 0, 1, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
