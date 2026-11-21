class_name BodyPartTest
extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

const __source: String = 'res://common/body_parts/body_part.gd'
var runner: GdUnitSceneRunner

var player: Player
var temp1: BodyPartContainer
var temp2: BodyPartContainer
var temp3: BodyPartContainer
var robot1: BodyPartContainer
var robot2: BodyPartContainer

func before_test() -> void:
	runner = scene_runner("res://test/part_swap_test.tscn")
	#runner.move_window_to_foreground()
	player = runner.find_child("Player")
	temp1 = runner.find_child("TempBody1")
	temp2 = runner.find_child("TempBody2")
	temp3 = runner.find_child("TempBody3")
	robot1 = runner.find_child("RobotEnemy").get_node("Body")
	robot2 = runner.find_child("RobotEnemy2").get_node("Body")
	#assert_that(temp1).is_not_null()
	#assert_that(temp3).is_not_null()
	#assert_that(robot1).is_not_null()
	#assert_that(robot2).is_not_null()


func _matches_prefix(path: NodePath, prefix: NodePath) -> bool:
	if prefix.get_subname_count() > 0:
		if path.get_concatenated_names() != prefix.get_concatenated_names():
			return false
		return path.get_concatenated_subnames().begins_with(prefix.get_concatenated_subnames())
	else:
		return path.get_concatenated_names().begins_with(prefix.get_concatenated_names())


func _get_track_count(part: BodyPart, anim_name: String, path_prefix: NodePath) -> int:
	var anim: Animation = part._get_animation_player().get_animation(anim_name)
	var count := 0
	for i in range(anim.get_track_count()):
		#if _matches_prefix(anim.track_get_path(i), path_prefix):
		if anim.track_get_path(i).get_concatenated_names() == path_prefix.get_concatenated_names():
			count += 1
	return count


func _get_track_sig(part: BodyPart, anim_name: String, path: NodePath) -> String:
	var anim: Animation = part._get_animation_player().get_animation(anim_name)
	var out: Array[String] = [anim_name, path.get_concatenated_names()]
	for track_idx in range(anim.get_track_count()):
		if anim.track_get_path(track_idx) == path:
			out.append(anim.track_get_path(track_idx).get_concatenated_subnames())
			out.append(",".join(range(anim.track_get_key_count(track_idx)).map(func (i): return str(anim.track_get_key_time(track_idx, i)))))
			out.append(",".join(range(anim.track_get_key_count(track_idx)).map(func (i): return str(anim.track_get_key_value(track_idx, i)))))
	return ":".join(out)


func test_replace_with_body_part() -> void:
	const locator_path = "Body/root/torso/right_arm/right_arm2/locator"
	const check_anim = "attack"
	const check_anim3 = "walk"
	const check_path1 = NodePath("root/torso/right_arm/right_arm2")
	const check_path2 = NodePath("root/torso")
	const check_path3 = NodePath("root/legs/left_leg/left_shin")
	assert_that(player).is_not_null()
	assert_that(temp2).is_not_null()
	var dest_arm: BodyPart = player.get_node("Body/root/torso/right_arm")
	var src_arm: BodyPart = temp2.get_node("root/torso/right_arm")
	assert_that(player.get_node_or_null(locator_path)).is_null()
	var src_sig1_pre := _get_track_sig(src_arm, check_anim, check_path1)
	var src_sig2_pre := _get_track_sig(src_arm, check_anim, check_path2)
	var src_sig3_pre := _get_track_sig(src_arm, check_anim3, check_path3)
	var dest_sig1_pre := _get_track_sig(dest_arm, check_anim, check_path1)
	var dest_sig2_pre := _get_track_sig(dest_arm, check_anim, check_path2)
	var dest_sig3_pre := _get_track_sig(dest_arm, check_anim3, check_path3)
	assert_that(dest_sig1_pre).is_not_equal(src_sig1_pre)
	assert_that(dest_sig2_pre).is_not_equal(src_sig2_pre)
	assert_that(dest_sig3_pre).is_not_equal(src_sig3_pre)

	dest_arm = dest_arm.replace_with_body_part(src_arm)

	var src_sig1_post := _get_track_sig(src_arm, check_anim, check_path1)
	var dest_sig1_post := _get_track_sig(dest_arm, check_anim, check_path1)
	var dest_sig2_post := _get_track_sig(dest_arm, check_anim, check_path2)
	var dest_sig3_post := _get_track_sig(dest_arm, check_anim3, check_path3)
	assert_that(player.get_node_or_null(locator_path)).is_not_null()
	assert_that(src_sig1_post).is_equal(src_sig1_pre).append_failure_message("src anim should not change")
	assert_that(dest_sig1_post).is_equal(src_sig1_pre).append_failure_message("right arm src anim should be copied to dest")
	assert_that(dest_sig2_post).is_equal(src_sig2_pre).append_failure_message("torso should have been overwritten because of extra_tracks")
	assert_that(dest_sig3_post).is_equal(dest_sig3_pre).append_failure_message("legs should not have been overwritten")
	assert_that(_get_track_count(dest_arm, check_anim, check_path1)).is_equal(1)
	assert_that(_get_track_count(dest_arm, check_anim, check_path2)).is_equal(1)
	assert_that(_get_track_count(dest_arm, check_anim, check_path3)).is_equal(1)

	@warning_ignore('redundant_await')
	await runner.simulate_frames(1) # give it time for queue_free to pan out
	collect_orphan_node_details()
