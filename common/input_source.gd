class_name InputSource
extends Node

## This is a base class that both player controls and enemy AIs will subclass

@warning_ignore("unused_signal")
signal attack
@warning_ignore("unused_signal")
signal special_attack
@warning_ignore("unused_signal")
signal dash

func get_move_dir() -> Vector2:
	return Vector2.ZERO
