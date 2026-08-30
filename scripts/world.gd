extends Node2D

const WORLD_SIZE := Vector2(960, 540)
const BORDER_THICKNESS := 32.0

var obstacles := [
	# Screen boundaries.
	Rect2(0, -BORDER_THICKNESS, WORLD_SIZE.x, BORDER_THICKNESS),
	Rect2(0, WORLD_SIZE.y, WORLD_SIZE.x, BORDER_THICKNESS),
	Rect2(-BORDER_THICKNESS, 0, BORDER_THICKNESS, WORLD_SIZE.y),
	Rect2(WORLD_SIZE.x, 0, BORDER_THICKNESS, WORLD_SIZE.y),
	# Visible obstacles.
	Rect2(230, 120, 210, 46),
	Rect2(600, 220, 110, 190),
	Rect2(250, 385, 240, 48),
]


func _ready() -> void:
	for index in obstacles.size():
		_add_obstacle(obstacles[index], index)
	queue_redraw()


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
