extends Node3D

var speed: float = 1.0
var max_angle: float = 0.5
var time_passed: float = 0.0

func _process(delta: float) -> void:
	time_passed += delta
	rotation.y = sin(time_passed * speed) * max_angle
