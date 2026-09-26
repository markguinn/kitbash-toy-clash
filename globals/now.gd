extends Node

# I think it's fine to access these directly
# This is just like Time.get_ticks_msec except it responds to 
# pausing and adjusting Engine.time_scale
var msec := 0
var sec := 0.0


var _last_times: Dictionary[Variant, int] = {}

## Returns true if the event should be throttled (i.e. a call was made with the
## same scope within min_ms milliseconds). "scope" should be a stable value.
## It could be a node path or something, but it shouldn't be random or scale
## with time to avoid the _last_times cache blowing up.
func throttle(min_ms: int, scope: Variant) -> bool:
	if _last_times.has(scope) and msec < _last_times[scope] + min_ms:
		return true
	_last_times[scope] = msec
	return false


func _physics_process(delta: float) -> void:
	msec += roundi(delta * 1000.0)
	sec += delta
