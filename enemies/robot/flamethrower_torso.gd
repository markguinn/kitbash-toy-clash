class_name FlamethrowerTorso
extends BodyPart

@onready var flame_emitter: FlameEmitter = $FlameEmitter
@onready var chest_flame: MeshInstance3D = $ChestFlame

func _ready() -> void:
	super._ready()
	flame_emitter.intensity = 0.0
	if container.host is Player:
		flame_emitter.hurts_enemies = true
		flame_emitter.hurts_players = false
	else:
		flame_emitter.hurts_enemies = false
		flame_emitter.hurts_players = true
	Log.debug(self, "flamethrower ready")


func _on_attack_start(_dir: Vector3) -> void:
	Log.debug(self, "flamethrower attacking")
	var attack_len = Game.config.get_value("robot", "attack_length", 4.0)
	flame_emitter.intensity = 1.0
	#flame_emitter.tween_to_intensity(1.0, attack_len * 0.25)
	await get_tree().create_timer(attack_len).timeout
	#flame_emitter.tween_to_intensity(0.0, attack_len * 0.5)
	flame_emitter.intensity = 0.0
