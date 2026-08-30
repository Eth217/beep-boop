class_name NetworkPlayer
extends CharacterBody2D

const MAX_HEALTH := 100
const FIREBALL_CHARGE_TIME := 3.0

@export var speed := 230.0
@export var fire_cooldown := 0.22

var owner_peer_id := 1
var input_direction := Vector2.ZERO
var last_fire_time_ms := -1000
var health := MAX_HEALTH
var round_active := true
var is_charging := false
var charge_progress := 0.0
var charge_started_time_ms := 0

signal fire_requested(shooter_peer_id: int, direction: Vector2)
signal fireball_requested(shooter_peer_id: int, direction: Vector2)


func _ready() -> void:
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not round_active or multiplayer.get_unique_id() != owner_peer_id:
		return

	var direction := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	).normalized()

	if multiplayer.is_server():
		input_direction = direction
	else:
		submit_input.rpc_id(1, direction)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if not is_charging:
			_request_charge_start()
	elif is_charging:
		_request_charge_release(_aim_direction())
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_request_fire(_aim_direction())


func simulate_server_movement() -> void:
	if not multiplayer.is_server():
		return

	velocity = input_direction * speed
	move_and_slide()
	_update_charge_progress()
	sync_state.rpc(position, velocity, health, charge_progress, is_charging)


@rpc("any_peer", "unreliable")
func submit_input(direction: Vector2) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != owner_peer_id:
		return
	input_direction = direction.limit_length(1.0)


func _request_fire(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return

	if multiplayer.is_server():
		_fire_on_server(direction)
	else:
		submit_fire.rpc_id(1, direction)


@rpc("any_peer", "unreliable")
func submit_fire(direction: Vector2) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != owner_peer_id:
		return
	_fire_on_server(direction)


func _fire_on_server(direction: Vector2) -> void:
	if is_charging:
		return
	if direction.is_zero_approx():
		return

	var current_time_ms := Time.get_ticks_msec()
	if current_time_ms - last_fire_time_ms < int(fire_cooldown * 1000.0):
		return

	last_fire_time_ms = current_time_ms
	fire_requested.emit(owner_peer_id, direction.normalized())


func _aim_direction() -> Vector2:
	return (get_global_mouse_position() - global_position).normalized()


func _request_charge_start() -> void:
	if multiplayer.is_server():
		start_charging()
	else:
		is_charging = true
		charge_progress = 0.0
		queue_redraw()
		start_charge.rpc_id(1)


@rpc("any_peer", "reliable")
func start_charge() -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != owner_peer_id:
		return
	start_charging()


func start_charging() -> void:
	if is_charging or not round_active:
		return

	is_charging = true
	charge_progress = 0.0
	charge_started_time_ms = Time.get_ticks_msec()
	queue_redraw()


func _request_charge_release(direction: Vector2) -> void:
	if multiplayer.is_server():
		release_charge_on_server(direction)
	else:
		is_charging = false
		charge_progress = 0.0
		queue_redraw()
		release_charge.rpc_id(1, direction)


@rpc("any_peer", "reliable")
func release_charge(direction: Vector2) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != owner_peer_id:
		return
	release_charge_on_server(direction)


func release_charge_on_server(direction: Vector2) -> void:
	if not is_charging:
		return

	_update_charge_progress()
	var fireball_is_ready := charge_progress >= 1.0 and not direction.is_zero_approx()
	stop_charging()
	if fireball_is_ready:
		fireball_requested.emit(owner_peer_id, direction.normalized())


func _update_charge_progress() -> void:
	if not is_charging:
		return
	charge_progress = minf(float(Time.get_ticks_msec() - charge_started_time_ms) / (FIREBALL_CHARGE_TIME * 1000.0), 1.0)


func stop_charging() -> void:
	is_charging = false
	charge_progress = 0.0
	queue_redraw()


@rpc("authority", "unreliable")
func sync_state(new_position: Vector2, new_velocity: Vector2, new_health: int, new_charge_progress: float, new_is_charging: bool) -> void:
	position = new_position
	velocity = new_velocity
	health = new_health
	charge_progress = new_charge_progress
	is_charging = new_is_charging
	queue_redraw()


func take_damage(amount: int) -> bool:
	if health <= 0:
		return false

	health = maxi(health - amount, 0)
	queue_redraw()
	return health == 0


func reset_for_round(spawn_position: Vector2) -> void:
	position = spawn_position
	velocity = Vector2.ZERO
	input_direction = Vector2.ZERO
	health = MAX_HEALTH
	round_active = true
	stop_charging()
	queue_redraw()


func set_round_active(is_active: bool) -> void:
	round_active = is_active
	if not is_active:
		input_direction = Vector2.ZERO
		velocity = Vector2.ZERO
		stop_charging()


func _draw() -> void:
	var hue := fposmod(float(owner_peer_id) * 0.173, 1.0)
	var body_color := Color.from_hsv(hue, 0.6, 0.95)
	draw_circle(Vector2.ZERO, 18.0, body_color)
	draw_circle(Vector2(6, -4), 3.0, Color("17211a"))

	var bar_rect := Rect2(-20, -32, 40, 6)
	draw_rect(bar_rect, Color("251f24"))
	draw_rect(Rect2(-19, -31, 38.0 * float(health) / MAX_HEALTH, 4), Color("53d769"))

	if is_charging:
		var charge_bar_rect := Rect2(-20, -42, 40, 6)
		var charge_color := Color("ff9f43") if charge_progress < 1.0 else Color("fff3a0")
		draw_rect(charge_bar_rect, Color("251f24"))
		draw_rect(Rect2(-19, -41, 38.0 * charge_progress, 4), charge_color)
