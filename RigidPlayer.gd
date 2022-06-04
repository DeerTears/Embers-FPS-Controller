extends RigidBody

export var look_sensitivity := 0.25
var velocity := Vector3.ZERO
var speed := 20.0

class InputContainer:
	var look: Vector2
	var move: Vector2

var our_input = InputContainer.new()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		our_input.look = event.relative
	elif event is InputEventKey or InputEventJoypadMotion:
		our_input.move.y = event.get_action_strength("back") - event.get_action_strength("forward")
		our_input.move.x = event.get_action_strength("right") - event.get_action_strength("left")
#	elif event is InputEventJoypadMotion:
#		if event.axis == JOY_AXIS_0:
#			our_input.joy_movement.x = event.axis_value
#		elif event.axis == JOY_AXIS_1:
#			our_input.joy_movement.y = event.axis_value

onready var camera_arm: SpringArm = $SpringArm

func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	var contact_count = state.get_contact_count()
	for contact in contact_count:
		print(state.get_contact_local_normal(contact))
	var direction: Vector3
	# hopefully this rotates the body and informs our direction appropriately
	rotate_y(-our_input.look.x * look_sensitivity)
	direction += transform.basis.z * our_input.move.y
	direction += transform.basis.x * our_input.move.x
	direction *= speed
	velocity = direction
	apply_central_impulse(velocity * state.step)
