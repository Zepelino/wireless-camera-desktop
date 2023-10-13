extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.get_name() == "Android":
		get_tree().change_scene("res://Mobile/scenes/Main_mobile.tscn")
	else:
		get_tree().change_scene("res://Pc/Scenes/Main_pc.tscn")
		pass

