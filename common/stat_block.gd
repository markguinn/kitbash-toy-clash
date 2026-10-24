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
