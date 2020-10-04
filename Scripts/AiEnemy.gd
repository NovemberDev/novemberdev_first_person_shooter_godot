extends RigidBody

const COMBAT_VIEW_DISTANCE = 60.0
const PATROLLING_WALK_SPEED = 3.0
const PATROLLING_WAYPOINT_TIME = 4.0
const COMBAT_WAYPOINT_TIME = 2.0
const COMBAT_WALK_SPEED = 8.0
const SHOOT_TIMEOUT = 1.0

var health = 100
var current_waypoint
var move_time = 0.0
var current_shoot_time = 0.0
var patrolling_waypoint_path = "../PATROLLING_WAYPOINTS"
var mob_bullet_scene = load("res://Scenes/MOB_BULLET.tscn")

var is_in_combat = false

func _ready():
	mode = MODE_CHARACTER
	$AnimationTree.active = true

func _process(delta):
	if health < 1: return
	move_time -= delta
	if move_time <= 0.0:
		current_waypoint = get_node(patrolling_waypoint_path).get_child(randi()%get_node(patrolling_waypoint_path).get_child_count())
		move_time = PATROLLING_WAYPOINT_TIME
		if is_in_combat:
			move_time = COMBAT_WAYPOINT_TIME
		
	$mob.look_at(current_waypoint.global_transform.origin, Vector3.UP)
	var waypoint_direction = (current_waypoint.global_transform.origin - global_transform.origin)
	
	if (Globals.current_player.global_transform.origin - global_transform.origin).length() <= COMBAT_VIEW_DISTANCE:
		is_in_combat = true
	
	if is_in_combat:
		$mob.look_at(Globals.current_player.global_transform.origin, Vector3.UP)
		current_shoot_time -= delta
		
		if current_shoot_time <= 0.0:
			$AnimationTree.set("parameters/shoot/active", true)
			var new_bullet = mob_bullet_scene.instance()
			new_bullet.owner_is_enemy = true
			new_bullet.global_transform.origin = $mob/Armature/Skeleton/BoneAttachment/BULLET_SLOT.global_transform.origin
			new_bullet.direction = (Globals.current_player.global_transform.origin - new_bullet.global_transform.origin).normalized()
			get_node("/root").add_child(new_bullet)
			current_shoot_time = SHOOT_TIMEOUT
	
	if waypoint_direction.length() >= 5.0:
		var speed = PATROLLING_WALK_SPEED
		if is_in_combat:
			speed = COMBAT_WALK_SPEED
		waypoint_direction.y = 0
		$AnimationTree.set("parameters/run/add_amount", 1.0)
		linear_velocity = waypoint_direction.normalized() * speed
	else:
		$AnimationTree.set("parameters/run/add_amount", 0.0)
		linear_velocity = Vector3.ZERO
	
	$mob.rotation_degrees.y += 180
	$mob.rotation *= Vector3(0, 1, 0)

func take_damage():
	health -= 25
	if health <= 0.0:
		die()

func kill_kick():
	Globals.current_player.leg_hit()
	die()
	
func die():
	$AnimationTree.set("parameters/state/current", 1)
	mode = RigidBody.MODE_KINEMATIC
	$CollisionShape.disabled = true
	health = 0
