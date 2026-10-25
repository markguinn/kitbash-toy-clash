class_name StatBlock
extends Resource

# how do these stack?
# should they be 0-based and a percentage of the base stat?
# should they be absolute and we take the max of all parts?
# should each multiply by whatever was before?
#@export var attack_power: float = 1.0
#@export var armor: float = 1.0
# what else? luck?

## meters/sec, averaged across parts
## 0 means this part doesn't impact the stat at all
@export var move_speed: float = 0.0

## seconds to turn fully, averaged across parts
## 0 means this part doesn't impact the stat at all
@export var turn_speed: float = 0.0


## milliseconds, averaged across parts
## 0 means this part doesn't impact the cooldown at all
## if all parts have a 0 for this value, the player can't attack at all
@export var attack_cooldown: int = 0
#@export var special_attack_cooldown: float = 0

## this is really only needed for legs that are longer than the default
## highest value wins
@export var min_collider_height: float = 2.0


func merge(blocks_or_parts: Array) -> void:
	# these are the total parts that carry weight for stats that are averaged
	var total_attack_cooldowns := 1 if attack_cooldown > 0 else 0
	var total_move_speeds := 1 if move_speed > 0.0 else 0
	var total_turn_speeds := 1 if turn_speed > 0.0 else 0
	
	# collect stats for each part
	for bop in blocks_or_parts:
		var b: StatBlock = bop if bop is StatBlock else bop.stats

		if b.attack_cooldown > 0:
			attack_cooldown += b.attack_cooldown 
			total_attack_cooldowns += 1
		if b.move_speed > 0.0:
			move_speed += b.move_speed
			total_move_speeds += 1
		if b.turn_speed > 0.0:
			turn_speed += b.turn_speed
			total_turn_speeds += 1
		min_collider_height = max(min_collider_height, b.min_collider_height)
		
	# apply averaging
	if total_attack_cooldowns > 0:
		attack_cooldown = attack_cooldown / total_attack_cooldowns
	if total_move_speeds > 0:
		move_speed = move_speed / total_move_speeds
	if total_turn_speeds > 0:
		turn_speed = turn_speed / total_turn_speeds
