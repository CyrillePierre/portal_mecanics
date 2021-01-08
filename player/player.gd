extends KinematicBody

const GRAVITY = Vector3(0, -10, 0)
const ACCEL = 60
const VEL_MAX = 5
const JUMP_SPEED = 7
const AIR_JUMP_TIME = .15
const MOUSE_SENSITIVITY_X = .1
const MOUSE_SENSITIVITY_Y = .07
const FLOOR_ANGLE = 60
const CAM_ANGLE_MAX = 70
const SLIP_COEF = .74

onready var camera = get_node("rotation_point/Camera")
onready var rotPt = get_node("rotation_point")

var vel = Vector3()
var airJumpCount = .0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	var input = Vector2();
	input.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left")) 
	input.y = int(Input.is_action_pressed("up")) - int(Input.is_action_pressed("down"))
	
	if input.length_squared() > .1:
		var basis = global_transform.basis
		var dir = Vector3()
		dir -= basis.z * input.y
		dir += basis.x * input.x
		
		vel += dir * ACCEL * delta
		
		var planeVel = Vector2(vel.x, vel.z).clamped(VEL_MAX);
		vel.x = planeVel.x
		vel.z = planeVel.y
	else:
		vel.x *= SLIP_COEF
		vel.z *= SLIP_COEF
	
	if is_on_floor():
		airJumpCount = AIR_JUMP_TIME
	else:
		airJumpCount -= delta
		
	if airJumpCount > 0 && Input.is_action_just_pressed("jump"):
		vel.y += JUMP_SPEED
		airJumpCount = 0
	
	vel += GRAVITY * delta
	vel = move_and_slide(vel, Vector3(0, 1, 0), 1, 4, deg2rad(FLOOR_ANGLE))


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * MOUSE_SENSITIVITY_X))
		var xAngle = rotPt.rotation_degrees.x - event.relative.y * MOUSE_SENSITIVITY_Y
		rotPt.rotation_degrees.x = clamp(xAngle, -CAM_ANGLE_MAX, CAM_ANGLE_MAX)
