class_name StatBlock
extends Resource

# how do these stack?
# should they be 0-based and a percentage of the base stat?
# should they be absolute and we take the max of all parts?
# should each multiply by whatever was before?
@export var move_speed: float = 1.0
@export var attack_power: float = 1.0
@export var armor: float = 1.0
# what else? luck?

# this should be absolute seconds i think
@export var attack_cooldown: float = 0.5
@export var special_attack_cooldown: float = 5.0
@export var min_collider_height: float = 2.0


func merge(blocks_or_parts: Array) -> void:
	for bop in blocks_or_parts:
		var b: StatBlock = bop if bop is StatBlock else bop.stats
		attack_cooldown += b.attack_cooldown 
		min_collider_height = max(min_collider_height, b.min_collider_height)
	attack_cooldown /= blocks_or_parts.size() + 1
