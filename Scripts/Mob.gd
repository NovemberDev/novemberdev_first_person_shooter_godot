extends StaticBody

var health = 100
var can_shoot = true
var shoot_timeout = 0.0
var bullet_scene = load("res://Scenes/MOB_BULLET.tscn")

func _process(delta):
	if !can_shoot: return
	look_at(Globals.current_player.global_transform.origin, Vector3.UP)
	rotation_degrees.x = 0
	
	var to_player = (global_transform.origin - Globals.current_player.global_transform.origin)
	
	if to_player.length() <= 200.0 and shoot_timeout <= 0.0:
		var new_bullet = bullet_scene.instance()
		new_bullet.direction = ($mob/BULLET_SLOT.global_transform.origin - to_player * 50.0).normalized()
		get_node("/root").add_child(new_bullet)
		new_bullet.global_transform.origin = $mob/BULLET_SLOT.global_transform.origin
		shoot_timeout = 0.8
	
	if shoot_timeout >= 0.0:
		shoot_timeout -= delta

func take_damage():
	health -= 25
	if health <= 0.0:
		$AnimationTree.set("parameters/state/current", 1)
		can_shoot = false

func kill_kick():
	$AnimationTree.set("parameters/state/current", 1)
	$CollisionShape.disabled = true
	can_shoot = false
