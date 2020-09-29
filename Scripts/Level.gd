extends Spatial

func _ready():
	$PLAYER.add_child(load("res://Scenes/Player.tscn").instance())
