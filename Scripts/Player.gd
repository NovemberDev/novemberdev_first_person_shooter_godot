extends RigidBody

const GRAVITY = 80.0
const MAX_JUMP = 100.0
const MAX_SPEED = 18.0
const MAX_INAIR_SPEED = 22.0
const MAX_WALLRUN_SPEED = 30.0
const MAX_JUMP_TIME = 0.4
const MAX_STRAFE_CAM_ANGLE = 3.0
const MAX_STRAFE_CAM_SPEED = 5.0
const MAX_ACCELERATION_TIME = 0.6
const WALLRUN_MAX_CAM_ANGLE = 30.0
const MAX_DEACCELERATION_TIME = 0.5
const MAX_WALLRUN_TIMEOUT = 1.0
const MOUSE_SENSITIVITY = 0.3
const WALLRUN_JUMP_STRENGTH = 300.0
const ARM_ROTATION_SPEED = 30.0

# horizontal rotation (y)
var yaw = 0
# vertical rotation (x)
var pitch = 0

var health = 100

var jump_curve : Curve
var acceleration_curve : Curve
var deacceleration_curve : Curve

var jump_time = 0.0
var acceleration_time = 0.0
var deacceleration_time = 0.0
var is_jumping = false
var is_on_floor = false
var is_wallrunning = false
var wallrun_exit_direction = Vector3.ZERO

var can_shoot = true
var can_reload = true
var wallrun_strafe = 0
var wallrun_direction = Vector3.ZERO
var direction : Vector3 = Vector3.ZERO
var bullet_scene = load("res://Scenes/BULLET.tscn")
var bullet_case_scene = load("res://Scenes/BULLET_CASE.tscn")

var hitmarker_timeout = 0.0
var initial_camera_height
var initial_leg_transform
var is_fast = false
var previous_position

var very_funny = rand_range(60, 180)
var interaction_object = null

func _ready():
	Globals.current_player = self
	pitch = rotation_degrees.x
	yaw = $Camera.rotation_degrees.y
	jump_curve = $JUMP_CURVE.texture.curve
	acceleration_curve = $ACCELERATION_CURVE.texture.curve
	deacceleration_curve = $DEACCELERATION_CURVE.texture.curve
	connect("body_entered", self, "on_collision")
	connect("body_exited", self, "on_collision_exit")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Camera/ViewportContainer/Viewport/PLAYER_RIG/ArmTree.active = true
	initial_camera_height = $Camera.transform.origin.y
	initial_leg_transform = $Camera/ViewportContainer/Viewport/PLAYER_RIG/leg.transform.origin
	previous_position = global_transform.origin

func _input(event):
	# filter events for mouse movement
	if event is InputEventMouseMotion:
		# float modulus the angle difference, 
		# 360%360 = 0 and 90%360 = 90
		# to prevent angles above 360 and below 0 degrees
		yaw = fmod(yaw - event.relative.x * MOUSE_SENSITIVITY, 360)
		# do the same, but clamp it at 70 and -70
		pitch = max(min(pitch - event.relative.y * MOUSE_SENSITIVITY, 70), -70)
		
		# set rotation of the player
		$Camera.rotation_degrees.y = yaw
		$Raycasts.rotation_degrees.y = yaw
		# set rotation of the camera
		$Camera.rotation_degrees.x = pitch

func _process(delta):
	$Camera/ViewportContainer/Viewport/Camera.rotation = $Camera.rotation
	$Camera/ViewportContainer/Viewport/Camera.global_transform.origin = $Camera.global_transform.origin
	$Camera/ViewportContainer/Viewport/PLAYER_RIG.global_transform.origin = $Camera.global_transform.origin + $Camera/ViewportContainer/Viewport/PLAYER_RIG.global_transform.basis.z * 0.75
	$Camera/ViewportContainer/Viewport/PLAYER_RIG.global_transform.basis = $Camera/ViewportContainer/Viewport/PLAYER_RIG.global_transform.basis.slerp($Camera.global_transform.basis, delta * ARM_ROTATION_SPEED)
	$Camera/ViewportContainer/Viewport/PLAYER_RIG.rotation = lerp($Camera/ViewportContainer/Viewport/PLAYER_RIG.rotation, $Camera/ViewportContainer/Viewport/PLAYER_RIG.rotation + Vector3(pitch * 0.001, 0, 0), delta * 5.0)
	
	# movement direction
	direction = Vector3()
	wallrun_exit_direction = lerp(wallrun_exit_direction, Vector3.ZERO, delta * 5.0)
	
	if Input.is_key_pressed(KEY_A):
		# basis.x is the current "left" vector
		direction -= $Camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		direction += $Camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_W):
		# basis.z is the current "forward" vector
		direction -= $Camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		direction += $Camera.global_transform.basis.z
		
	if Input.is_mouse_button_pressed(1) and can_shoot:
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/ArmTree.set("parameters/shoot/active", true)
		get_node("Camera/ViewportContainer/Viewport/PLAYER_RIG/arms/Armature001/Skeleton 2/BoneAttachment/gunbody/AnimationPlayer").play("gun_shooting")
		var new_bullet = bullet_scene.instance()
		new_bullet.direction = ((($Camera.global_transform.basis.z + $Camera.project_ray_origin(get_viewport().size / 2)+ $Camera.project_ray_normal(get_viewport().size / 2) * 1000.0)) - get_node("Camera/ViewportContainer/Viewport/PLAYER_RIG/arms/Armature001/Skeleton 2/BoneAttachment/gunbody/BULLET_SLOT").global_transform.origin).normalized() * 0.6
		get_node("/root").add_child(new_bullet)
		new_bullet.global_transform.origin = get_node("Camera/ViewportContainer/Viewport/PLAYER_RIG/arms/Armature001/Skeleton 2/BoneAttachment/gunbody/BULLET_SLOT").global_transform.origin
		can_reload = false
		can_shoot = false
		
	if Input.is_action_just_pressed("reload") and can_reload:
		can_shoot = false
		can_reload = false
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/ArmTree.set("parameters/reload/active", true)
		$"Camera/ViewportContainer/Viewport/PLAYER_RIG/arms/Armature001/Skeleton 2/BoneAttachment/gunbody/BULLET_SLOT/Sprite3D".visible = false
		get_node("Camera/ViewportContainer/Viewport/PLAYER_RIG/arms/Armature001/Skeleton 2/BoneAttachment/gunbody/AnimationPlayer").play("gun_reloading")
	
	if Input.is_key_pressed(KEY_SHIFT) and !is_wallrunning and !$Raycasts/GROUND.is_colliding():
		Engine.time_scale = 0.2
		direction *= 800 * delta
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/leg.transform.origin = lerp($Camera/ViewportContainer/Viewport/PLAYER_RIG/leg.transform.origin, $Camera/ViewportContainer/Viewport/PLAYER_RIG/leg.transform.origin - direction * Vector3(1, 0, 0.3), delta * 3.0)
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/LegLTree.set("parameters/leg_state/current", 2)
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/LegRTree.set("parameters/leg_state/current", 2)
#	elif Input.is_key_pressed(KEY_SHIFT) and !is_wallrunning and $Raycasts/GROUND.is_colliding():
#		Engine.time_scale = 1.0
#		$Camera/ViewportContainer/Viewport/PLAYER_RIG/leg.transform.origin = lerp($Camera/ViewportContainer/Viewport/PLAYER_RIG/leg.transform.origin, $Camera/ViewportContainer/Viewport/PLAYER_RIG/leg.transform.origin - direction * Vector3(0.5, 0, 0.3), delta * 3.0)
#		$Camera/ViewportContainer/Viewport/PLAYER_RIG/LegLTree.set("parameters/leg_state/current", 2)
#		$Camera/ViewportContainer/Viewport/PLAYER_RIG/LegRTree.set("parameters/leg_state/current", 2)
#		$CollisionShapeStanding.disabled = true
#		$CollisionShapeSliding.disabled = false
#		linear_velocity -= $Camera.global_transform.basis.z * 8.0
#		$Camera.transform.origin.y = 0.5
	else:
		Engine.time_scale = 1.0
		$Camera.transform.origin.y = initial_camera_height
		$CollisionShapeStanding.disabled = false
		$CollisionShapeSliding.disabled = true
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/LegLTree.set("parameters/leg_state/current", 0)
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/LegRTree.set("parameters/leg_state/current", 0)

	direction += wallrun_exit_direction
	
	$Camera.rotation_degrees.z = lerp($Camera.rotation_degrees.z, wallrun_strafe + int(is_on_floor) * -direction.x * MAX_STRAFE_CAM_ANGLE, delta * MAX_STRAFE_CAM_SPEED)
	$Camera/ViewportContainer/Viewport/PLAYER_RIG/leg.transform.origin = lerp($Camera/ViewportContainer/Viewport/PLAYER_RIG/leg.transform.origin, initial_leg_transform, delta * 8.0)
	
	if linear_velocity.length() > 10.0 and (is_wallrunning or is_on_floor):
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/arms.transform.origin.x = lerp($Camera/ViewportContainer/Viewport/PLAYER_RIG/arms.transform.origin.x, 0.1 * sin(((0.005 * int(is_wallrunning)) + 0.008) * OS.get_ticks_msec()), delta * 5.0)
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/arms.transform.origin.z = lerp($Camera/ViewportContainer/Viewport/PLAYER_RIG/arms.transform.origin.z, 0.1 * sin(((0.005 * int(is_wallrunning) + 0.008)) * OS.get_ticks_msec()), delta * 5.0)
	else:
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/arms.transform.origin.x = lerp($Camera/ViewportContainer/Viewport/PLAYER_RIG/arms.transform.origin.x, 0.0, delta * 5.0)
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/arms.transform.origin.z = lerp($Camera/ViewportContainer/Viewport/PLAYER_RIG/arms.transform.origin.z, 0.0, delta * 5.0)
	
	if direction != Vector3.ZERO:
		deacceleration_time = 0
		if acceleration_time < 1.0:
			acceleration_time += delta
		var speed = MAX_SPEED
		if !is_on_floor:
			speed = MAX_INAIR_SPEED
		direction *= acceleration_curve.interpolate(acceleration_time/MAX_ACCELERATION_TIME) * speed
		direction.y = linear_velocity.y
		linear_velocity = direction
	elif is_on_floor:
		if acceleration_time > 0:
			acceleration_time -= delta
		if deacceleration_time < 1.0:
			deacceleration_time += delta
		var new_velocity = linear_velocity * (1.0 - deacceleration_curve.interpolate(deacceleration_time/MAX_DEACCELERATION_TIME))
		new_velocity.y = linear_velocity.y
		linear_velocity = new_velocity

	if jump_time <= MAX_JUMP_TIME:
		if Input.is_action_just_pressed("ui_select"):
			if is_wallrunning:
				wallrun_exit_direction = -$Camera.global_transform.basis.z * WALLRUN_JUMP_STRENGTH * delta
			is_wallrunning = false
			is_jumping = true

		if is_jumping:
			linear_velocity.y = jump_curve.interpolate(jump_time/MAX_JUMP_TIME) * MAX_JUMP

	if !Input.is_action_pressed("ui_select"):
		jump_time = MAX_JUMP_TIME
		is_jumping = false
	if is_on_floor and !is_jumping:
		jump_time = 0.0
		linear_velocity.y = 0.0
	elif is_on_floor and is_jumping:
		jump_time = 0.0
	elif !is_wallrunning:
		jump_time += delta
		linear_velocity.y -= GRAVITY * delta
	elif is_wallrunning:
		jump_time = 0
		is_jumping = false
		linear_velocity.y = 0

	var delta_pos = previous_position - global_transform.origin
	is_fast = Vector2(direction.x, direction.z).length() >= 15.0 and Vector2(delta_pos.x, delta_pos.z).length() > 0.1
	
	if $Raycasts/RL.is_colliding() and is_fast:
		is_wallrunning = true
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/ArmTree.set("parameters/base_l_state/current", 0)
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/ArmTree.set("parameters/shoot_l_state/add_amount", 0)
		wallrun_direction = linear_velocity.normalized() * MAX_WALLRUN_SPEED
		wallrun_strafe = -WALLRUN_MAX_CAM_ANGLE
	elif $Raycasts/RR.is_colliding() and is_fast:
		is_wallrunning = true
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/ArmTree.set("parameters/base_l_state/current", 0)
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/ArmTree.set("parameters/shoot_l_state/add_amount", 0)
		wallrun_direction = linear_velocity.normalized() * MAX_WALLRUN_SPEED
		wallrun_strafe = WALLRUN_MAX_CAM_ANGLE
	else:
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/ArmTree.set("parameters/base_l_state/current", 1)
		$Camera/ViewportContainer/Viewport/PLAYER_RIG/ArmTree.set("parameters/shoot_l_state/add_amount", 1)
		is_wallrunning = false
		wallrun_strafe = 0
		
	if hitmarker_timeout <= 0.0:
		$Hitmarker.visible = false
	hitmarker_timeout -= delta
	
	if global_transform.origin.y < -100:
		get_tree().reload_current_scene()
		
	previous_position = global_transform.origin
	
	very_funny -= delta
	if very_funny < 0.0:
		get_tree().reload_current_scene()
	
	# Raycast from viewport without needing a seperate node
	var interaction_result = get_world().direct_space_state.intersect_ray($Camera.project_ray_origin(get_viewport().size / 2), $Camera.project_ray_origin(get_viewport().size / 2) + $Camera.project_ray_normal(get_viewport().size / 2) * 10.0)
	
	interaction_object = null
	$InteractLabel.visible = false
	if interaction_result != null:
		if !interaction_result.empty():
			if interaction_result["collider"].is_in_group("interactable"):
				$InteractLabel.visible = true
				interaction_object = interaction_result["collider"]
	
	if Input.is_action_just_pressed("interact") and interaction_object != null:
		interaction_object.interact()
		
func on_collision(body):
	if body.is_in_group("floor"):
		is_jumping = false
		is_on_floor = true
	if body.is_in_group("enemy"):
		body.kill_kick()
		
func on_collision_exit(body):
	if body.is_in_group("floor"):
		is_on_floor = false

func show_muzzle():
	Globals.play_sound("SHOOT.wav", -10)
	$"Camera/ViewportContainer/Viewport/PLAYER_RIG/arms/Armature001/Skeleton 2/BoneAttachment/gunbody/BULLET_SLOT/Sprite3D".visible = true
	$"Camera/ViewportContainer/Viewport/PLAYER_RIG/arms/Armature001/Skeleton 2/BoneAttachment/gunbody/BULLET_SLOT/Sprite3D".rotation_degrees.z = randf()*360.0+0.0

func spawn_case():
	var new_bullet_case = bullet_case_scene.instance()
	new_bullet_case.direction = $Camera.global_transform.basis.x.normalized()
	new_bullet_case.look_at = $Camera.global_transform.basis.z.normalized()
	get_node("/root").add_child(new_bullet_case)
	new_bullet_case.global_transform.origin = get_node("Camera/ViewportContainer/Viewport/PLAYER_RIG/arms/Armature001/Skeleton 2/BoneAttachment/gunbody/CASE_SLOT").global_transform.origin

func leg_hit():
	$Camera/ViewportContainer/Viewport/PLAYER_RIG/leg/leg_l/HIT/AnimationPlayer.play("hit")

func show_hitmarker():
	Globals.play_sound("hitmarker.wav", 0)
	$Hitmarker.visible = true
	hitmarker_timeout = 0.15

func take_damage():
	health -= 25
	if health <= 0.0:
		get_tree().reload_current_scene()

func play_sound(name, db):
	Globals.play_sound(name, db)
