class_name BodyPartContainer
extends Node3D

signal parts_changed(old_part: BodyPart, new_part: BodyPart)

@warning_ignore("unused_signal")
signal attack_start(dir: Vector3)
@warning_ignore("unused_signal")
signal attack_end(dir: Vector3)
@warning_ignore("unused_signal")
signal walk_start(dir: Vector3)
@warning_ignore("unused_signal")
signal walk_end(dir: Vector3)
@warning_ignore("unused_signal")
signal change_direction(dir: Vector3)

@export var host: Node3D
@export var primary_collider: CollisionShape3D
@export var animation_player: AnimationPlayer
@export var base_stats: StatBlock

# TODO: think about this more - do these belong at the root?
@export var slots: Array[BodyPart.Slot] = [
	BodyPart.Slot.head,
	BodyPart.Slot.torso,
	BodyPart.Slot.arm_l,
	BodyPart.Slot.arm_r,
	BodyPart.Slot.legs,
]

var stats: StatBlock
var parts: Array[BodyPart] = []
var can_move := true
var can_attack := true

func _ready() -> void:
	if not host:
		host = get_parent()
	if not primary_collider:
		var n = host
		while n and not primary_collider: 
			primary_collider = n.get_node_or_null("CollisionShape3D")
			n = n.get_parent()
	if not animation_player:
		animation_player = host.get_node("AnimationPlayer")
	if not base_stats:
		base_stats = StatBlock.new()
	_find_body_parts(self)
	parts_changed.connect(_on_parts_changed)
	attack_start.connect(_on_attack_start)
	attack_end.connect(_on_attack_end)
	Log.debug(self, host.name, "Body parts", parts.map(func(n): return n.name))


func _find_body_parts(node: Node) -> void:
	for n in node.get_children():
		if n is BodyPart:
			parts.append(n)
		_find_body_parts(n)


# TODO: let each body part specify if it stops movement on attack
# TODO: don't do this if no body parts have an attack
func _on_attack_start(_dir: Vector3) -> void:
	can_move = false
	can_attack = false


func _on_attack_end(_dir: Vector3) -> void:
	can_move = true
	can_attack = true


func _calc_stats() -> void:
	stats = base_stats.duplicate(true)
	stats.merge(parts)

func _on_parts_changed(old_part: BodyPart, new_part: BodyPart) -> void:
	Log.debug(self, host.name, "Parts changed. old", old_part.name, "new", new_part.name)
	parts = []
	_find_body_parts(self)
	_calc_stats()
	Log.debug(self, host.name, "Body parts", parts.map(func(n): return n.name))

	# resize the collision shape if needed
	if primary_collider and primary_collider.shape and primary_collider.shape is CapsuleShape3D:
		var shape: CapsuleShape3D = primary_collider.shape
		if not is_equal_approx(shape.height, stats.min_collider_height):
			shape.height = stats.min_collider_height
			Log.debug(self, host.name, "updating collider height", shape.height)
