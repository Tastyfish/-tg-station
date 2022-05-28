/// Conveys all log_mapping messages as unit test failures, as they all indicate mapping problems.
/datum/unit_test/log_mapping
	// Happen before all other tests, to make sure we only capture normal mapping logs.
	priority = TEST_PRE

/datum/unit_test/log_mapping/Run()
	var/static/regex/test_areacoord_regex = regex(@"\(-?\d+,-?\d+,(-?\d+)\)")

	for(var/log_entry in GLOB.unit_test_mapping_logs)
		// Only fail if AREACOORD was conveyed, and it's a station or mining z-level.
		// This is due to mapping errors don't have coords being impossible to diagnose as a unit test,
		// and various ruins frequently intentionally doing non-standard things.
		if(!test_areacoord_regex.Find(log_entry))
			continue
		var/z = text2num(test_areacoord_regex.group[1])
		if(!is_station_level(z) && !is_mining_level(z))
			continue

		TEST_FAIL(log_entry)

/// Test spawning of every single ruin.
/datum/unit_test/mapping_ruins
	/// The baseturf to prepare the area for each ruin.
	var/baseturf = /turf/open/space

/datum/unit_test/mapping_ruins/Run()
	SHOULD_NOT_SLEEP(TRUE)

	var/static/regex/test_areacoord_regex = regex(@"\((-?\d+),(-?\d+),(-?\d+)\)")

	// Changing a large area 1000 times in a single tick makes LINDA unhappy. I don't necessarilly consider that a bug.
	SSair.can_fire = FALSE

	// Get a dedicated z-level.
	var/datum/space_level/level = SSmapping.add_new_zlevel("ruin testing", ZTRAITS_AWAY)
	// Give 1 tile border
	var/bottom_left = locate(2, 2, level.z_value)

	for(var/ruin_name in SSmapping.ruins_templates)
		var/datum/map_template/ruin = SSmapping.ruins_templates[ruin_name]
		var/list/turf/affected_turfs = ruin.get_affected_turfs(bottom_left)

		// Clear out mapping errors so we can collect ones relevant to THIS ruin
		GLOB.unit_test_mapping_logs.Cut()

		// Place it. This is where everything will go wrong.
		ruin.load(bottom_left)

		// throw resulting errors
		for(var/log_entry in GLOB.unit_test_mapping_logs)
			// Only fail if AREACOORD was conveyed, and it's in our ruin.
			if(!test_areacoord_regex.Find(log_entry))
				continue
			var/log_x = text2num(test_areacoord_regex.group[1])
			var/log_y = text2num(test_areacoord_regex.group[2])
			var/log_z = text2num(test_areacoord_regex.group[3])
			if(!affected_turfs.Find(locate(log_x, log_y, log_z)))
				continue

			TEST_FAIL("For ruin [ruin_name]: [log_entry]")

		// Clear out ruin.
		for(var/turf/turf in affected_turfs)
			for (var/content in turf.contents)
				qdel(content)
			turf.ChangeTurf(baseturf, list(baseturf))

/datum/unit_test/mapping_ruins/Destroy()
	SSair.can_fire = TRUE
	SSair.update_nextfire(reset_time = TRUE)

	return ..()
