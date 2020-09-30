extends RigidBody

const MAX_SPEED = 250.0

var direction : Vector3 = Vector3.ZERO

func _ready():
	linear_velocity = direction * MAX_SPEED
	look_at(global_transform.origin + direction, Vector3.UP)
	
