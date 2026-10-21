class_name enemy_spawner
extends StaticBody3D

@export var enemy_type: PackedScene
@export var spawn_seconds := 1.0
@export var spawn_radius := 5.0

var timer: Timer

@onready var hurt_box: HurtBox = $HurtBox
@onready var life: Life = $Life


func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_seconds
	timer.timeout.connect(_on_spawn_timer)
	timer.start()

	life.dead.connect(_on_dead)


func _on_spawn_timer() -> void:
	var obj = enemy_type.instantiate()
	var start_offset = Vector3(spawn_radius, 0.0, 0.0).rotated(Vector3.UP, randf_range(0, PI * 2.0))
	obj.position = position + start_offset
	get_parent().add_child(obj)


# TODO: do something fun
func _on_dead(_hit_box) -> void:
	timer.stop()
	queue_free()
