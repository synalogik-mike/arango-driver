context("Utils Directory Test Suite")

test_that("Enumeration works correctly with existing values", {
  # given
  request_methods <- Enum(GET, POST, PATCH)

  # when

  post_value <- request_methods$POST
  get_value <- request_methods$GET
  patch_value <- request_methods$PATCH
  null_value <- request_methods$NOT_ENUM

  # then
  expect_equal(get_value, 1)
  expect_equal(post_value, 2)
  expect_equal(patch_value, 3)

})

test_that("Enum of not listed value returns NULL", {
  # given
  request_methods <- Enum(GET, POST, PATCH)

  # when
  null_value <- request_methods$NOT_ENUM

  # then
  expect_equal(null_value, NULL)
})
