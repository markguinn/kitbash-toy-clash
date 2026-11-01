class_name StatBlock
extends Resource

const TAKE_AVERAGE = [
	"move_speed", 
	"dash_speed", 
	"dash_length",
	"turn_speed",
	"attack_cooldown",
	"special_cooldown",
	"dash_cooldown",
]

const TAKE_MAX = [
	"min_collider_height"
]

## meters/sec, averaged across parts
## 0 means this part doesn't impact the stat at all
@export var move_speed: float = 0.0

## meters/sec, averaged
@export var dash_speed: float = 70.0

## length of dash action in seconds, averaged
@export var dash_length: float = 0.3

## milliseconds, averaged across parts
## 0 means this part doesn't impact the cooldown at all
## if all parts have a 0 for this value, the player can't attack at all
@export var dash_cooldown: int = 0

## seconds to turn fully, averaged across parts
## 0 means this part doesn't impact the stat at all
@export var turn_speed: float = 0.0

## milliseconds, averaged across parts
## 0 means this part doesn't impact the cooldown at all
## if all parts have a 0 for this value, the player can't attack at all
@export var attack_cooldown: int = 0

## milliseconds, averaged across parts
## 0 means this part doesn't impact the cooldown at all
## if all parts have a 0 for this value, the player can't use a special attack at all
@export var special_cooldown: int = 0

## this is really only needed for legs that are longer than the default
## highest value wins
@export var min_collider_height: float = 2.0


func merge(blocks_or_parts: Array) -> void:
	# these are the total parts that carry weight for stats that are averaged
	var totals: Dictionary[String, int] = {}
	
	# collect stats for each part
	for bop in blocks_or_parts:
		var b: StatBlock = bop if bop is StatBlock else bop.stats
		
		for stat in TAKE_AVERAGE:
			if b.get(stat):
				set(stat, get(stat) + b.get(stat))
				totals[stat] = totals.get(stat, 0) + 1
		for stat in TAKE_MAX:
			set(stat, max(get(stat), b.get(stat)))
		
	# apply averaging
	for stat in TAKE_AVERAGE:
		if totals.get(stat, 0) > 0:
			set(stat, get(stat) / totals[stat])
