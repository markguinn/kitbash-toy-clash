class_name EnemySpawner
extends StaticBody3D

@export var enemy_types: Array[PackedScene] = []
## For each enemy type, how likely is it compared to the others?
## A value of 2 makes it twice as likely. 1 is the default.
@export var enemy_type_weight: Array[int] = []
@export var spawn_min_seconds := 1.0
@export var spawn_max_seconds := 1.0
@export var spawn_radius := 5.0

var timer: Timer
var enemy_picker: Array[int]

@onready var hurt_box: HurtBox = $HurtBox
@onready var life: Life = $Life


func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	_set_spawn_timer()
	timer.timeout.connect(_on_spawn_timer)
	timer.start()
	
	enemy_picker = []
	for i in range(enemy_types.size()):
		var my_weight := 1
		if i < enemy_type_weight.size():
			my_weight = enemy_type_weight[i]
		for j in range(my_weight):
			enemy_picker.append(i)

	life.dead.connect(_on_dead)


func _set_spawn_timer() -> void:
	timer.wait_time = randf_range(spawn_min_seconds, spawn_max_seconds)


func _pick_enemy() -> PackedScene:
	var idx: int = randi_range(0, enemy_picker.size() - 1)
	return enemy_types[enemy_picker[idx]]


func _on_spawn_timer() -> void:
	var obj = _pick_enemy().instantiate()
	var start_offset = Vector3(spawn_radius, 0.0, 0.0).rotated(Vector3.UP, randf_range(0, PI * 2.0))
	obj.position = position + start_offset
	get_parent().add_child(obj)
	_set_spawn_timer()


# TODO: do something fun
func _on_dead(_hit_box) -> void:
	timer.stop()
	queue_free()
