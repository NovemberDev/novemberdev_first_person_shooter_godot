extends RigidBody

const MAX_SPEED = 500.0

var direction : Vector3 = Vector3.ZERO
var bullet_hole_scene = load("res://Scenes/BULLET_HOLE.tscn")

func _ready():
	linear_velocity = direction * MAX_SPEED
	connect("body_entered", self, "on_collision")
	look_at(global_transform.origin + direction, Vector3.UP)
	
func on_collision(body):
	if body.is_in_group("enemy"):
		Globals.current_player.show_hitmarker()
		body.take_damage()
	elif $RayCast.is_colliding():
		var new_bullet_hole = bullet_hole_scene.instance()
		get_node("/root").add_child(new_bullet_hole)
		new_bullet_hole.global_transform.origin = $RayCast.get_collision_point() + $RayCast.get_collision_normal() * 0.2
		new_bullet_hole.look_at(new_bullet_hole.global_transform.origin + $RayCast.get_collision_normal(), Vector3.UP)
		new_bullet_hole.get_node("Particles").emitting = true
	queue_free()
	
