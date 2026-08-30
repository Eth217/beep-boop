class_name NetworkBullet
extends Area2D

@export var speed := 600.0
@export var lifetime := 1.5

var bullet_id := -1
var shooter_peer_id := 0
var direction := Vector2.RIGHT
var remaining_lifetime := 0.0

signal impacted(bullet: NetworkBullet, hit_body: Node2D)


func _ready() -> void:
	remaining_lifetime = lifetime
	body_entered.connect(_on_body_entered)
	queue_redraw()


func setup(id: int, shooter_id: int, start_position: Vector2, aim_direction: Vector2) -> void:
	bullet_id = id
	shooter_peer_id = shooter_id
	global_position = start_position
	direction = aim_direction.normalized()
	rotation = direction.angle()


func simulate_server_movement(delta: float) -> bool:
	if not multiplayer.is_server():
		return false

	global_position += direction * speed * delta
	remaining_lifetime -= delta
	return remaining_lifetime <= 0.0


@rpc("authority", "unreliable")
func sync_state(new_position: Vector2) -> void:
	global_position = new_position


func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	if body is NetworkPlayer and body.owner_peer_id == shooter_peer_id:
		return
	impacted.emit(self, body)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color("fff3a0"))
