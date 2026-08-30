extends CharacterBody2D

@export var speed := 230.0


func _ready() -> void:
	queue_redraw()


func _physics_process(_delta: float) -> void:
	var direction := Vector2(
		float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	).normalized()

	velocity = direction * speed
	move_and_slide()


func _draw() -> void:
	# A temporary character: replace this with a sprite later.
	draw_circle(Vector2.ZERO, 18.0, Color("ef8354"))
	draw_circle(Vector2(6, -4), 3.0, Color("17211a"))
