class_name RobotEnemy
extends Enemy

const FLAME_DC = 0.1
const BETWEEN_ATTACKS = 10.0
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
		_start_attack_timer()

func _start_attack_timer() -> void:
	Log.debug(self, "starting attack timer")
	get_tree().create_timer(BETWEEN_ATTACKS).timeout.connect(_on_attack_start)

func _on_attack_start() -> void:
	Log.debug(self, "attack!")
	flame_emitter.tween_to_intensity(1.0, ATTACK_LEN)
	get_tree().create_timer(1.0).timeout.connect(_on_attack_end)

func _on_attack_end() -> void:
	Log.debug(self, "stop attack!")
	flame_emitter.tween_to_intensity(0.0, 3.0)
	_start_attack_timer()
