class_name BouncingPart
extends RigidBody3D

const FADE_TIME = 1.0
const FADE_DEPTH = 10.0

@export var is_collectable := false

@onready var fade_timer: Timer = $FadeTimer
@onready var explosion_particles: CPUParticles3D = $ExplosionParticles
@onready var trail_particles: GPUParticles3D = $TrailParticles

func _ready() -> void:
	fade_timer.timeout.connect(_on_timeout)
	fade_timer.wait_time += randf_range(-0.2, 0.2)
	fade_timer.start()
	trail_particles.one_shot = true
	explosion_particles.one_shot = true

func start_particles() -> void:
	trail_particles.restart()
	explosion_particles.restart()

func _on_timeout() -> void:
	if not is_collectable:
		var t := create_tween()
		t.set_ease(Tween.EASE_IN)
		t.set_trans(Tween.TRANS_EXPO)
		t.tween_property(self, "position", position + Vector3.DOWN * FADE_DEPTH, FADE_TIME)
		await t.finished
		queue_free()
