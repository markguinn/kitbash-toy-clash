class_name RobotEnemy
extends Enemy

const FLAME_DC = 1.2
const ATTACK_LEN = 1.0

@onready var chest_flame: MeshInstance3D = %ChestFlame
@onready var flame_emitter: FlameEmitter = %FlameEmitter

var has_flame: bool = true


func _ready() -> void:
	super._ready()
	var roll = randf()
	flame_emitter.intensity = 0.0
	if roll > FLAME_DC:
		chest_flame.hide()
		has_flame = false
	else:
		input_source.attack.connect(_on_attack_start)


func _on_attack_start() -> void:
	flame_emitter.tween_to_intensity(1.0, ATTACK_LEN)
	await get_tree().create_timer(1.0).timeout
	flame_emitter.tween_to_intensity(0.0, 3.0)
