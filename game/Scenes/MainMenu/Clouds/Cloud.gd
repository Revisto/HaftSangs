extends Node2D

var cloud_textures = []
var cloud_texture_paths = [
	"res://Assets/graphics/clouds/cloud1.png",
	"res://Assets/graphics/clouds/cloud3.png",
	"res://Assets/graphics/clouds/cloud4.png",
	"res://Assets/graphics/clouds/cloud5.png",
	"res://Assets/graphics/clouds/cloud7.png"
]

func _ready():
	 
	for path in cloud_texture_paths:
		var texture = load(path)
		if texture:
			cloud_textures.append(texture)
	
	 
	if cloud_textures.size() > 0:
		var random_texture = cloud_textures[randi() % cloud_textures.size()]
		$CloudSprite.texture = random_texture
