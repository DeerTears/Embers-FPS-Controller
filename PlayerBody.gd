class_name Player
extends KinematicBody

"""
Created by Emberlynn Bland.

This controller uses RayShape to move itself up and down bumps. The camera
lerps its Y position toward the body's Y position to create smooth stepping.

The CylinderShape allows for smooth interactions against walls. It also stops
the player from ascending up walls that are too tall.

Input Map should include actions for:
	left
	right
	forward
	back
	look_up (joystick)
	look_down (joystick)
	look_left (joystick)
	look_right (joystick)
	sprint
	jump

Mouse movement is always read for head movement.

Enjoy! Contact me at Ember#1765 on Discord or @goodnight_grrl on Twitter if you have questions or suggestions.
"""

# Break all of these maximums and minimums to your heart's content,
# they're just here for easy editing in the Inspector.

export (float, 0.0, 5.0, 0.01) var mouse_look_sensitivity = 0.2
export (float, 0.0, 5.0, 0.01) var joy_look_sensitivity = 0.5

export (float, 0.0, 32.0, 0.1) var speed := 14.0
export (float, 0.0, 100.0, 1.0) var jump_strength = 26.0
export (float, -5.0, 5.0, 0.01) var gravity := -0.98

## How fast you accelerate, with 1 being immediate.
export (float, 0.01, 1.0, 0.001) var acceleration := 0.2
## How many times faster your sprinting speed is. Will always be lerped by acceleration.
export (float, 1.0, 3.0, 0.1) var sprint_multiplier = 1.5
## How smooth it is to go up and down stairs, with 1 being immediate.
export (float, 0.01, 1.0, 0.01) var step_speed = 0.3

# When false, physics and head smoothing continue to run, and no input is processed.
var can_handle_input: bool = true

# Accessed once per frame to invert the camera rotation: Mouse X/Y, Joy X/Y.
var camera_invert_multipliers := [1.0, 1.0, 1.0, 1.0]
## Lookup values for camera invert.
enum {
	MOUSE_X,
	MOUSE_Y,
	JOY_X,
	JOY_Y,
}
## Persistent velocity across physics frames.
var movement := Vector3()

# The target position for the Camera to reach.
onready var camera_target_position: Position3D = $CameraTargetPosition
# The current position for the Camera, with Y position lerped towards the target by step_speed.
onready var head_camera: Camera = $HeadCamera

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Allows camera's transform to be set independently.
	head_camera.set_as_toplevel(true)

func _unhandled_input(event: InputEvent) -> void:
	if not can_handle_input:
		return
	if event is InputEventMouseMotion:
		rotate_head(
			event.relative.x * mouse_look_sensitivity,
			event.relative.y * mouse_look_sensitivity
		)

func _physics_process(_delta: float) -> void:
	var direction = Vector3()
	# Update Camera direction.
	head_camera.global_transform.basis = camera_target_position.global_transform.basis
	# Update Camera position, with lerped Y.
	head_camera.global_transform.origin = Vector3(
		camera_target_position.global_transform.origin.x,
		camera_target_position.global_transform.origin.y,
#		lerp(
#			head_camera.global_transform.origin.y,
#			camera_target_position.global_transform.origin.y,
#			get_smooth_factor(
#				head_camera.global_transform.origin.y,
#				camera_target_position.global_transform.origin.y
#			)
#		),
		camera_target_position.global_transform.origin.z
	)
	var has_pressed_jump: bool = false
	if can_handle_input:
		direction += transform.basis.z * (Input.get_action_strength("back") - Input.get_action_strength("forward"))
		direction += transform.basis.x * (Input.get_action_strength("right") - Input.get_action_strength("left"))
		handle_joystick_looking()
		direction *= speed
		direction *= sprint_multiplier if Input.is_action_pressed("sprint") else 1.0
		has_pressed_jump = Input.is_action_just_pressed("jump")
	movement = movement.linear_interpolate(
			Vector3(direction.x, movement.y, direction.z), acceleration
	)
	if has_pressed_jump and is_on_floor():
		movement.y += jump_strength
	else:
		movement += Vector3(0, gravity, 0)
	# Maximum angle does not apply to RayShape CollisionShapes.
	movement = move_and_slide(movement, Vector3.UP, true, 3, deg2rad(1), true)

# Returns a value to lerp the camera's y position.
func get_smooth_factor(current: float, target: float) -> float:
	if target == 0.0:
		current += 1.0
		target += 1.0
	return (current / target) * step_speed * 2.0 if current > target else (current / target) * step_speed

## Rotates HeadCamera from controller input.
func handle_joystick_looking() -> void:
	var joy_head_horizontal_movement: float = 0.0
	var joy_head_vertical_movement: float = 0.0
	joy_head_vertical_movement = (
		Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
	) * camera_invert_multipliers[JOY_Y]
	joy_head_horizontal_movement = (
		Input.get_action_strength("look_left") - Input.get_action_strength("look_right")
	)  * camera_invert_multipliers[JOY_X]
	rotate_head(
		joy_head_horizontal_movement * joy_look_sensitivity * 3.0,
		joy_head_vertical_movement * joy_look_sensitivity * 3.0
	)

func rotate_head(mouse_x: float, mouse_y: float) -> void:
	# Rotate the body horizontally.
	rotate_y(deg2rad(-mouse_x * camera_invert_multipliers[MOUSE_X]))
	# Rotate the head to look up and down.
	camera_target_position.rotate_x(deg2rad(-mouse_y * camera_invert_multipliers[MOUSE_Y]))
	# Clamp the head to prevent it from going overboard.
	camera_target_position.rotation.x = clamp(
		camera_target_position.rotation.x,
		deg2rad(-90),
		deg2rad(90)
	)
