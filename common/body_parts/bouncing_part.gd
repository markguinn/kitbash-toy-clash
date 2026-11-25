class_name BouncingPart
extends RigidBody3D

const FADE_TIME = 1.0
const FADE_DEPTH = 10.0

@export var is_collectable := false

@onready var fade_timer: Timer = $FadeTimer

func _ready() -> void:
	fade_timer.timeout.connect(_on_timeout)
	fade_timer.wait_time += randf_range(-0.2, 0.2)
	fade_timer.start()

func _on_timeout() -> void:
	Log.info(self, "timeout", name)
	if not is_collectable:
		var t := create_tween()
		t.set_ease(Tween.EASE_IN)
		t.set_trans(Tween.TRANS_EXPO)
		t.tween_property(self, "position", position + Vector3.DOWN * FADE_DEPTH, FADE_TIME)
		await t.finished
		queue_free()
