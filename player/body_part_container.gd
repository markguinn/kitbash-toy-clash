class_name BodyPartContainer
extends Node3D

signal parts_changed(old_part: BodyPart, new_part: BodyPart)

@warning_ignore("unused_signal")
signal attack_start(dir: Vector3)
@warning_ignore("unused_signal")
signal attack_peak(dir: Vector3)
@warning_ignore("unused_signal")
signal attack_end(dir: Vector3)
@warning_ignore("unused_signal")
signal walk_start(dir: Vector3)
@warning_ignore("unused_signal")
signal walk_end(dir: Vector3)
@warning_ignore("unused_signal")
signal change_direction(dir: Vector3)

@export var host: Node3D
@export var animation_player: AnimationPlayer

# TODO: think about this more - do these belong at the root?
@export var slots: Array[BodyPart.Slot] = [
	BodyPart.Slot.head,
	BodyPart.Slot.torso,
	BodyPart.Slot.arm_l,
	BodyPart.Slot.arm_r,
	BodyPart.Slot.legs,
]

var parts: Array[BodyPart] = []


func _ready() -> void:
	if not host:
		host = get_parent()
	if not animation_player:
		animation_player = host.get_node("AnimationPlayer")
	_find_body_parts(self)
	parts_changed.connect(_on_parts_changed)
	Log.debug(self, host.name, "Body parts", parts.map(func(n): return n.name))


func _find_body_parts(node: Node) -> void:
	for n in node.get_children():
		if n is BodyPart:
			parts.append(n)
		_find_body_parts(n)


func _on_parts_changed(old_part: BodyPart, new_part: BodyPart) -> void:
	parts = []
	_find_body_parts(self)
	Log.debug(self, host.name, "Parts changed. old", old_part.name, "new", new_part.name)
	Log.debug(self, host.name, "Body parts", parts.map(func(n): return n.name))
