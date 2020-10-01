extends RigidBody

var timeout = 5.0
var direction = Vector3.ZERO
var look_at = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	linear_velocity = direction * 10.0 + Vector3.UP * 2.0 - look_at * 20.0
	look_at(-look_at, Vector3.UP)


func _process(delta):
	linear_velocity.y -= 50.0 * delta
	timeout -= delta
	if timeout <= 0.0:
		queue_free()
