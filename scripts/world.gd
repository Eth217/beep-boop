extends Node2D

const WORLD_SIZE := Vector2(1600, 900)
const BORDER_THICKNESS := 32.0
const GAME_PORT := 7000
const MAX_PLAYERS := 4
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const STANDARD_BULLET_DAMAGE := 10
const STANDARD_BULLET_SPEED := 600.0
const STANDARD_BULLET_RADIUS := 6.0
const FIREBALL_DAMAGE := 50
const FIREBALL_SPEED := 420.0
const FIREBALL_RADIUS := 14.0

var obstacles := [
	# Screen boundaries.
	Rect2(0, -BORDER_THICKNESS, WORLD_SIZE.x, BORDER_THICKNESS),
	Rect2(0, WORLD_SIZE.y, WORLD_SIZE.x, BORDER_THICKNESS),
	Rect2(-BORDER_THICKNESS, 0, BORDER_THICKNESS, WORLD_SIZE.y),
	Rect2(WORLD_SIZE.x, 0, BORDER_THICKNESS, WORLD_SIZE.y),
	# Arena obstacles.
	Rect2(250, 150, 220, 48),
	Rect2(680, 120, 54, 250),
	Rect2(1050, 140, 280, 48),
	Rect2(190, 410, 200, 54),
	Rect2(510, 500, 310, 50),
	Rect2(960, 380, 56, 270),
	Rect2(1210, 450, 220, 52),
	Rect2(310, 700, 300, 48),
	Rect2(760, 690, 180, 50),
	Rect2(1120, 700, 270, 48),
]

@onready var players: Node2D = $Players
@onready var bullets: Node2D = $Bullets

var players_by_peer: Dictionary[int, NetworkPlayer] = {}
var bullets_by_id: Dictionary[int, NetworkBullet] = {}
var next_bullet_id := 1
var address_input: LineEdit
var host_button: Button
var join_button: Button
var status_label: Label
var network_active := false
var game_active := true
var result_panel: PanelContainer
var result_label: Label


func _ready() -> void:
	for index in obstacles.size():
		_add_obstacle(obstacles[index], index)
	_create_network_controls()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not multiplayer.is_server() or not game_active:
		return
	for player in players_by_peer.values():
		player.simulate_server_movement(_delta)
	for bullet in bullets_by_id.values():
		if bullet.simulate_server_movement(_delta):
			remove_bullet.rpc(bullet.bullet_id)
		else:
			bullet.sync_state.rpc(bullet.global_position)


func _create_network_controls() -> void:
	var overlay := CanvasLayer.new()
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.position = Vector2(18, 470)
	panel.size = Vector2(924, 58)
	overlay.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	address_input = LineEdit.new()
	address_input.placeholder_text = "Host IP address"
	address_input.text = "127.0.0.1"
	address_input.custom_minimum_size = Vector2(220, 0)
	row.add_child(address_input)

	host_button = Button.new()
	host_button.text = "Host LAN game"
	host_button.pressed.connect(host_game)
	row.add_child(host_button)

	join_button = Button.new()
	join_button.text = "Join game"
	join_button.pressed.connect(join_game)
	row.add_child(join_button)

	status_label = Label.new()
	status_label.text = "Not connected — host or join on UDP port %d" % GAME_PORT
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status_label)

	result_panel = PanelContainer.new()
	result_panel.position = Vector2(340, 190)
	result_panel.size = Vector2(280, 130)
	result_panel.visible = false
	overlay.add_child(result_panel)

	var result_content := VBoxContainer.new()
	result_content.alignment = BoxContainer.ALIGNMENT_CENTER
	result_content.add_theme_constant_override("separation", 14)
	result_panel.add_child(result_content)

	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 28)
	result_content.add_child(result_label)

	var restart_button := Button.new()
	restart_button.text = "Start over"
	restart_button.pressed.connect(_request_restart)
	result_content.add_child(restart_button)


func host_game() -> void:
	if network_active:
		return

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(GAME_PORT, MAX_PLAYERS)
	if error != OK:
		_set_status("Could not host on port %d (error %d)." % [GAME_PORT, error])
		return

	multiplayer.multiplayer_peer = peer
	network_active = true
	_set_connected_controls()
	_set_status("Hosting on UDP %d — share this computer's LAN IP." % GAME_PORT)
	spawn_player.rpc(1, _spawn_position_for(1))


func join_game() -> void:
	if network_active:
		return

	var address := address_input.text.strip_edges()
	if address.is_empty():
		_set_status("Enter the host's LAN IP address first.")
		return

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, GAME_PORT)
	if error != OK:
		_set_status("Could not start connection (error %d)." % error)
		return

	multiplayer.multiplayer_peer = peer
	network_active = true
	_set_connected_controls()
	_set_status("Connecting to %s:%d…" % [address, GAME_PORT])


@rpc("authority", "call_local", "reliable")
func spawn_player(peer_id: int, spawn_position: Vector2) -> void:
	if players_by_peer.has(peer_id):
		return

	var player := PLAYER_SCENE.instantiate() as NetworkPlayer
	player.name = "Player_%d" % peer_id
	player.owner_peer_id = peer_id
	player.position = spawn_position
	players.add_child(player)
	players_by_peer[peer_id] = player
	player.fire_requested.connect(_on_player_fire_requested)
	player.fireball_requested.connect(_on_player_fireball_requested)


@rpc("authority", "call_local", "reliable")
func remove_player(peer_id: int) -> void:
	if not players_by_peer.has(peer_id):
		return
	var player := players_by_peer[peer_id]
	players_by_peer.erase(peer_id)
	player.queue_free()


func _on_player_fire_requested(shooter_peer_id: int, direction: Vector2) -> void:
	_spawn_projectile(shooter_peer_id, direction, STANDARD_BULLET_DAMAGE, STANDARD_BULLET_SPEED, STANDARD_BULLET_RADIUS, false)


func _on_player_fireball_requested(shooter_peer_id: int, direction: Vector2) -> void:
	_spawn_projectile(shooter_peer_id, direction, FIREBALL_DAMAGE, FIREBALL_SPEED, FIREBALL_RADIUS, true)


func _spawn_projectile(shooter_peer_id: int, direction: Vector2, damage: int, speed: float, radius: float, is_fireball: bool) -> void:
	if not multiplayer.is_server() or not players_by_peer.has(shooter_peer_id):
		return

	var player := players_by_peer[shooter_peer_id]
	var spawn_position := player.global_position + direction * (18.0 + radius + 4.0)
	spawn_bullet.rpc(next_bullet_id, shooter_peer_id, spawn_position, direction, damage, speed, radius, is_fireball)
	next_bullet_id += 1


@rpc("authority", "call_local", "reliable")
func spawn_bullet(bullet_id: int, shooter_peer_id: int, spawn_position: Vector2, direction: Vector2, damage: int, speed: float, radius: float, is_fireball: bool) -> void:
	if bullets_by_id.has(bullet_id):
		return

	var bullet := BULLET_SCENE.instantiate() as NetworkBullet
	bullet.name = "Bullet_%d" % bullet_id
	bullets.add_child(bullet)
	bullet.setup(bullet_id, shooter_peer_id, spawn_position, direction, damage, speed, radius, is_fireball)
	bullets_by_id[bullet_id] = bullet
	bullet.impacted.connect(_on_bullet_impacted)


@rpc("authority", "call_local", "reliable")
func remove_bullet(bullet_id: int) -> void:
	if not bullets_by_id.has(bullet_id):
		return

	var bullet := bullets_by_id[bullet_id]
	bullets_by_id.erase(bullet_id)
	bullet.queue_free()


func _on_bullet_impacted(bullet: NetworkBullet, hit_body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if hit_body is NetworkPlayer:
		hit_body.take_damage(bullet.damage)
		if _living_player_count() <= 1:
			_finish_round()

	remove_bullet.rpc(bullet.bullet_id)


func _living_player_count() -> int:
	var living_players := 0
	for player in players_by_peer.values():
		if player.health > 0:
			living_players += 1
	return living_players


func _finish_round() -> void:
	if not game_active:
		return

	game_active = false
	var winner_peer_id := -1
	for player in players_by_peer.values():
		player.set_round_active(false)
		if player.health > 0:
			winner_peer_id = player.owner_peer_id
	for bullet_id in bullets_by_id.keys():
		remove_bullet.rpc(bullet_id)
	show_round_result.rpc(winner_peer_id)


@rpc("authority", "call_local", "reliable")
func show_round_result(winner_peer_id: int) -> void:
	game_active = false
	for player in players_by_peer.values():
		player.set_round_active(false)
	result_label.text = "You win!" if multiplayer.get_unique_id() == winner_peer_id else "You lose!"
	result_panel.show()


func _request_restart() -> void:
	if multiplayer.is_server():
		restart_round()
	else:
		request_restart.rpc_id(1)


@rpc("any_peer", "reliable")
func request_restart() -> void:
	if not multiplayer.is_server():
		return
	if not players_by_peer.has(multiplayer.get_remote_sender_id()):
		return
	restart_round()


func restart_round() -> void:
	if not multiplayer.is_server():
		return

	for bullet_id in bullets_by_id.keys():
		remove_bullet.rpc(bullet_id)
	for peer_id in players_by_peer:
		reset_player.rpc(peer_id, _spawn_position_for(peer_id))
	hide_round_result.rpc()


@rpc("authority", "call_local", "reliable")
func reset_player(peer_id: int, spawn_position: Vector2) -> void:
	if players_by_peer.has(peer_id):
		players_by_peer[peer_id].reset_for_round(spawn_position)


@rpc("authority", "call_local", "reliable")
func hide_round_result() -> void:
	game_active = true
	result_panel.hide()


func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	for existing_peer_id in players_by_peer:
		spawn_player.rpc_id(peer_id, existing_peer_id, players_by_peer[existing_peer_id].position)
	spawn_player.rpc(peer_id, _spawn_position_for(peer_id))
	_set_status("Player %d joined (%d/%d)." % [peer_id, players_by_peer.size(), MAX_PLAYERS])


func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		remove_player.rpc(peer_id)
		_set_status("Player %d left (%d/%d)." % [peer_id, players_by_peer.size(), MAX_PLAYERS])


func _on_connected_to_server() -> void:
	_set_status("Connected — waiting for the host to spawn your player.")


func _on_connection_failed() -> void:
	_set_status("Connection failed. Check the host IP and firewall.")
	_reset_network()


func _on_server_disconnected() -> void:
	_set_status("The host disconnected.")
	_reset_network()


func _reset_network() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	network_active = false
	for peer_id in players_by_peer.keys():
		remove_player(peer_id)
	for bullet_id in bullets_by_id.keys():
		remove_bullet(bullet_id)
	host_button.disabled = false
	join_button.disabled = false
	address_input.editable = true


func _set_connected_controls() -> void:
	host_button.disabled = true
	join_button.disabled = true
	address_input.editable = false


func _set_status(message: String) -> void:
	status_label.text = message


func _spawn_position_for(peer_id: int) -> Vector2:
	var spawn_points := [
		Vector2(110, 450), # Left
		Vector2(1490, 450), # Right
		Vector2(820, 80), # Top
		Vector2(820, 810), # Bottom
	]
	return spawn_points[(peer_id - 1) % spawn_points.size()]


func _add_obstacle(rect: Rect2, index: int) -> void:
	var body := StaticBody2D.new()
	body.name = "WorldBoundary" if index < 4 else "Obstacle%d" % index
	body.position = rect.get_center()

	var collision_shape := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision_shape.shape = shape
	body.add_child(collision_shape)
	add_child(body)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("9bcf7a"))

	# A faint grid makes movement easier to read while we have no art assets.
	for x in range(0, int(WORLD_SIZE.x) + 1, 48):
		draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), Color(0.2, 0.4, 0.22, 0.13), 1.0)
	for y in range(0, int(WORLD_SIZE.y) + 1, 48):
		draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), Color(0.2, 0.4, 0.22, 0.13), 1.0)

	for index in range(4, obstacles.size()):
		draw_rect(obstacles[index], Color("497c52"))
		draw_rect(obstacles[index], Color("2e593a"), false, 2.0)
