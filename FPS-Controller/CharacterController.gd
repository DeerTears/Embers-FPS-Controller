class_name Player
extends KinematicBody

"""
Ember's FPS Controller

CylinderShape allows for smooth interactions against walls. It also stops the
player from ascending up walls that are too tall. Keep this in mind when editing the shape.

Enjoy! Contact me at Ember#1765 on Discord or @goodnight_grrl on Twitter if you have questions or suggestions.
"""

## Lookup values for camera invert.
enum {
	MOUSE_X,
	MOUSE_Y,
	JOY_X,
	JOY_Y,
}

const USE_SMOOTHING := true
const NO_SMOOTHING := false

export (float, 0.01, 2.0, 0.01) var mouse_look_sensitivity = 0.2
export (float, 0.1, 3.0, 0.1) var joy_look_sensitivity = 0.5
export (float, 0.0, 0.99, 0.01) var controller_look_smoothing := 0.8

export (float, 0.0, 32.0, 0.1) var speed := 15.0
export (float, 0.0, 100.0, 0.1) var jump_strength = 26.0
export (float, -5.0, 5.0, 0.01) var gravity := -0.98

## How fast you accelerate, with 1 being immediate.
export (float, 0.01, 1.0, 0.001) var acceleration := 0.2
## How many times faster your sprinting speed is. Will always be lerped by acceleration.
export (float, 1.0, 3.0, 0.01) var sprint_multiplier = 1.8
## How smooth it is to go up and down stairs, with 1 being immediate.
export (float, 0.01, 1.0, 0.01) var stair_speed = 0.3

## How many frames you have to make a late jump.
export (int, 0, 60, 1) var coyote_time := 30

## When false, physics and head smoothing continue to run, and no input is processed.
var can_handle_input: bool = true

## Accessed once per frame to invert the camera rotation: Mouse X/Y, Joy X/Y.
var camera_invert_multipliers := [1.0, 1.0, 1.0, 1.0]

var velocity: Vector3

## Counts consecutive frames in the air.
var airframe_counter: int
var x_look_smoothing: float
var y_look_smoothing: float
var is_sprinting: bool

## The target position and rotation for the Camera to reach.
onready var look_target: Position3D = $CameraTargetPosition
onready var camera_node: Camera = $Camera

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Allows camera's transform to be set independently.
	camera_node.set_as_toplevel(true)


func _unhandled_input(event: InputEvent) -> void:
	if not can_handle_input:
		return
	if event is InputEventMouseMotion:
		rotate_head(
			event.relative.x * mouse_look_sensitivity * camera_invert_multipliers[MOUSE_X],
			event.relative.y * mouse_look_sensitivity * camera_invert_multipliers[MOUSE_Y],
			NO_SMOOTHING
		)
	if event.is_action("sprint"):
		is_sprinting = event.is_action_pressed("sprint")


func _physics_process(_delta: float) -> void:
	var direction = Vector3()
	var has_pressed_jump: bool = false
	increment_airframes()
	camera_node.global_transform.basis = look_target.global_transform.basis
	camera_node.global_transform.origin = Vector3(
		look_target.global_transform.origin.x,
		lerp(
			camera_node.global_transform.origin.y,
			look_target.global_transform.origin.y,
			get_smooth_factor(
				camera_node.global_transform.origin.y, look_target.global_transform.origin.y
			)
		),
		look_target.global_transform.origin.z
	)
	if can_handle_input:
		var input_vector := Input.get_vector("left", "right", "forward", "back")
		has_pressed_jump = Input.is_action_just_pressed("jump")
		direction += transform.basis.z * input_vector.y
		direction += transform.basis.x * input_vector.x
		handle_joystick_looking()
		direction *= speed
		direction *= sprint_multiplier if is_sprinting else 1.0
	velocity = velocity.linear_interpolate(
		Vector3(direction.x, velocity.y, direction.z), acceleration
	)
	if has_pressed_jump:
		if is_on_floor() or airframe_counter < coyote_time:
			velocity.y = 0.0
			airframe_counter = coyote_time
			velocity.y += jump_strength
	else:
		velocity += Vector3(0, gravity, 0)
	# stop_on_slopes and max_angle args don't apply to RayShape CollisionShapes.
	velocity = move_and_slide(velocity, Vector3.UP)


# Returns a weight value to lerp the camera's y position.
func get_smooth_factor(current: float, target: float) -> float:
	if target == 0.0:
		current += 1.0
		target += 1.0
	return (current / target) * stair_speed * 2.0 if current > target else (current / target) * stair_speed


## Processes controller input and calls rotate_head() with smoothing.
func handle_joystick_looking() -> void:
	var input_vector: Vector2 = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	var invert_vector := Vector2(camera_invert_multipliers[JOY_X], camera_invert_multipliers[JOY_Y])
	# todo: map from square to circle (or back) depending on settings/controller type
	input_vector *= joy_look_sensitivity * 3.0
	input_vector *= invert_vector
	rotate_head(input_vector.x, input_vector.y, USE_SMOOTHING)
 

## Increases airframe counter when in the air.
func increment_airframes() -> void:
	airframe_counter = 0 if is_on_floor() else airframe_counter + 1 
	airframe_counter = clamp(airframe_counter, 0, coyote_time)


## Rotates camera
func rotate_head(look_x: float, look_y: float, has_smoothing: bool) -> void:
	if has_smoothing:
		x_look_smoothing = lerp(x_look_smoothing, -look_x, 1.0 - controller_look_smoothing)
		rotate_y(deg2rad(x_look_smoothing))
		y_look_smoothing = lerp(y_look_smoothing, -look_y, 1.0 - controller_look_smoothing)
		look_target.rotate_x(deg2rad(y_look_smoothing))
	else:
		rotate_y(deg2rad(-look_x))
		look_target.rotate_x(deg2rad(-look_y))
	look_target.rotation.x = clamp(
		look_target.rotation.x,
		deg2rad(-90),
		deg2rad(90)
	)
