extends RigidBody

var timeout = 5.0
var direction = Vector3.ZERO
var look_at = Vector3.ZERO

func _ready():
	connect("body_entered", self, "on_collision")
	linear_velocity = direction * 10.0 + Vector3.UP * 2.0 - look_at * 20.0
	look_at(-look_at, Vector3.UP)

func _process(delta):
	linear_velocity.y -= 50.0 * delta
	timeout -= delta
	if timeout <= 0.0:
		queue_free()

func on_collision(body):
	Globals.play_sound("GUN_BULLET_SHELL_" + str(randi()%6) + ".wav", 5)
	disconnect("body_entered", self, "on_collision")
