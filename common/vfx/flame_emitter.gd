@tool
class_name FlameEmitter
extends Node3D

const INTENSITY_TWEEN_SECONDS = 2.0
const HITBOX_HEIGHT = 30.0

## 0 means the flames are off, 1.0 means they're at "normal" (above 1.0 is fine)
@export var intensity: float = 1.0: 
	set(v):
		intensity = v
		_update_particles()
		_update_hitbox()

## 0 means no damage
@export var damage: float = 0.0:
	set(v):
		damage = v
		_update_hitbox()

@export var hurts_players := true:
	set(v):
		hurts_players = v
		_update_hitbox()

@export var hurts_enemies := true:
	set(v):
		hurts_enemies = v
		_update_hitbox()


@onready var particles: CPUParticles3D = $CPUParticles3D
@onready var hit_box: HitBox = $HitBox
@onready var hit_box_shape: CollisionShape3D = $HitBox/CollisionShape3D

var tween: Tween


func _ready() -> void:
	_update_particles()
	_update_hitbox()


func _update_particles() -> void:
	if not particles:
		return
	particles.emitting = intensity > 0.0
	particles.lifetime = max(intensity, 0.01)


func _update_hitbox() -> void:
	if not hit_box:
		return
	var capsule: CapsuleShape3D = hit_box_shape.shape
	if damage > 0.0 and intensity > 0:
		if not Engine.is_editor_hint():
			hit_box.enable()
			hit_box_shape.disabled = false
		hit_box.damage = damage
		hit_box.set_collision_layer_value(3, hurts_enemies)
		hit_box.set_collision_layer_value(4, hurts_players)
		capsule.height = lerpf(capsule.radius * 2.0, HITBOX_HEIGHT, intensity)
		hit_box_shape.position.z = capsule.height / 2.0
	else:
		if not Engine.is_editor_hint():
			hit_box.disable()
			hit_box_shape.disabled = true


func tween_to_intensity(v: float, s = INTENSITY_TWEEN_SECONDS) -> void:
	if tween:
		tween.stop()
	tween = create_tween()
	tween.tween_property(self, "intensity", v, s)
