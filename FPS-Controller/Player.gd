extends Spatial

"""
Optional script to handle shooting physics bodies and toggling fullscreen.

This template does not include how to damage targets, just how to recognize them.
"""

onready var player_body: KinematicBody = $Body
onready var cursor_ray: RayCast = $Body/Camera/CursorRay
onready var shoot_ray: RayCast = $Body/Camera/ShootRay
onready var debug_label: Label = $CanvasLayer/DebugLabel

func _unhandled_input(event: InputEvent) -> void:
	if player_body.can_handle_input and event.is_action_pressed("shoot"):
		shoot()
	if event.is_action_released("toggle_fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen


func _process(_delta):
	debug_label.text = "%s" % [Input.get_vector("left", "right", "forward", "back", -1.0)]
	debug_label.text += "\n"

## Pauses the player's _unhandled_input() and input functions. Doesn't the SceneTree.
func set_movement_input(_true: bool) -> void:
	player_body.can_handle_input = _true


func shoot() -> void:
	if shoot_ray.is_colliding():
		var body: PhysicsBody = shoot_ray.get_collider()
		if body is StaticBody:
			return # handle shooting the world
		else:
			print_debug(body) # handle shooting this body
