extends RigidBody

const MAX_SPEED = 250.0

var direction : Vector3 = Vector3.ZERO

func _ready():
	linear_velocity = direction * MAX_SPEED
	look_at(global_transform.origin + direction, Vector3.UP)
	connect("body_entered", self, "on_collision")
	
func on_collision(body):
	queue_free()
	if body.is_in_group("enemy"):
		body.take_damage()
	
