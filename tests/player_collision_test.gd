extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const WORLD_COLLISION_LAYER := 1
const PLAYER_COLLISION_LAYER := 2


func _init() -> void:
	var player_one := PLAYER_SCENE.instantiate() as NetworkPlayer
	var player_two := PLAYER_SCENE.instantiate() as NetworkPlayer
	var bullet := BULLET_SCENE.instantiate() as Area2D

	assert(player_one.collision_layer == PLAYER_COLLISION_LAYER)
	assert(player_two.collision_layer == PLAYER_COLLISION_LAYER)
	assert(player_one.collision_mask == WORLD_COLLISION_LAYER)
	assert(player_two.collision_mask == WORLD_COLLISION_LAYER)
	assert(player_one.health == NetworkPlayer.MAX_HEALTH)
	assert(not player_one.take_damage(10))
	assert(player_one.health == 90)
	for _hit in range(8):
		assert(not player_one.take_damage(10))
	assert(player_one.take_damage(10))
	assert(player_one.health == 0)
	player_one.reset_for_round(Vector2(96, 270))
	assert(player_one.health == NetworkPlayer.MAX_HEALTH)
	assert(not _can_collide(player_one, player_two))
	assert(_can_collide_with_world(player_one))
	assert(_can_collide(bullet, player_one))
	assert(_can_collide_with_world(bullet))

	player_one.free()
	player_two.free()
	bullet.free()
	quit()


func _can_collide(first_body: CollisionObject2D, second_body: CollisionObject2D) -> bool:
	return (
		(first_body.collision_mask & second_body.collision_layer) != 0
		or (second_body.collision_mask & first_body.collision_layer) != 0
	)


func _can_collide_with_world(player: CollisionObject2D) -> bool:
	return (player.collision_mask & WORLD_COLLISION_LAYER) != 0
