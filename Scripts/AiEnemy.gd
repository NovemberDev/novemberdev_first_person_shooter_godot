extends RigidBody

const COMBAT_VIEW_DISTANCE = 30.0
const PATROLLING_WALK_SPEED = 5.0
const PATROLLING_WAYPOINT_TIME = 7.0
const COMBAT_WAYPOINT_TIME = 2.0
const COMBAT_WALK_SPEED = 10.0
const SHOOT_TIMEOUT = 1.0

var current_waypoint
var move_time = 0.0
var current_shoot_time = 0.0
var patrolling_waypoint_path = "../PATROLLING_WAYPOINTS"

var is_in_combat = false

func _ready():
	mode = MODE_CHARACTER

func _process(delta):
	move_time -= delta
	if move_time <= 0.0:
		current_waypoint = get_node(patrolling_waypoint_path).get_child(randi()%get_node(patrolling_waypoint_path).get_child_count())
		move_time = PATROLLING_WAYPOINT_TIME
		if is_in_combat:
			move_time = COMBAT_WAYPOINT_TIME
		print("switch")
		
	#look_at(current_waypoint.global_transform.origin, Vector3.UP)
	var waypoint_direction = (current_waypoint.global_transform.origin - global_transform.origin)
	
	if (get_node("../Camera").global_transform.origin - global_transform.origin).length() <= COMBAT_VIEW_DISTANCE:
		is_in_combat = true
	print(is_in_combat)
	if is_in_combat:
		#look_at(get_node("../Camera").global_transform.origin, Vector3.UP)
		current_shoot_time -= delta
		
		if current_shoot_time <= 0.0:
			current_shoot_time = SHOOT_TIMEOUT
	
	if waypoint_direction.length() >= 3.0:
		var speed = PATROLLING_WALK_SPEED
		if is_in_combat:
			speed = COMBAT_WALK_SPEED
		waypoint_direction.y = 0
		linear_velocity = waypoint_direction.normalized() * speed
	#linear_velocity.y = 9.81
