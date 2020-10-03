extends RayCast

const MAX_SPEED = 500.0

var owner_is_enemy = false
var destroy_after = 5.0
var direction : Vector3 = Vector3.ZERO
var bullet_hole_scene = load("res://Scenes/BULLET_HOLE.tscn")

func _ready():
	look_at(global_transform.origin + direction, Vector3.UP)

func _process(delta):
	global_transform.origin += direction * MAX_SPEED * delta
	destroy_after -= delta
	if destroy_after <= 0.0:
		queue_free()
	if is_colliding():
		if get_collider().is_in_group("enemy"):
			Globals.current_player.show_hitmarker()
			get_collider().take_damage()
		elif get_collider().is_in_group("player") and owner_is_enemy:
			get_collider().take_damage()
		else:
			var new_bullet_hole = bullet_hole_scene.instance()
			get_node("/root").add_child(new_bullet_hole)
			new_bullet_hole.global_transform.origin = get_collision_point() + get_collision_normal() * 0.2
			new_bullet_hole.look_at(new_bullet_hole.global_transform.origin + get_collision_normal(), Vector3.UP)
			new_bullet_hole.get_node("Particles").emitting = true
		queue_free()
	
