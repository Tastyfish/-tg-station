/datum/unit_test/test_annotations/Run()
	TEST_ASSERT(TRUE, "Assertion failed.")
	TEST_ASSERT_NOTNULL(1, "not null")
	TEST_ASSERT_NULL(null, "null")
	TEST_ASSERT_EQUAL(2 + 2, 4, "2+2=4")

	// This should fail
	TEST_ASSERT_NOTEQUAL(2 + 2, 4, "2+2!=3")
