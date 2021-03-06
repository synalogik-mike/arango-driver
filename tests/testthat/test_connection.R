library(RJSONIO)

context("Connection Management Test Suite")



# ======================================================================
#     SETUP: next calls are made to create proper mocked response
# ======================================================================
serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
write(serverResponse, file="./localhost-1234/_api/version.json")



# ======================================================================
#                             TEST CASES 
# ======================================================================
with_mock_api({
  test_that("Connection to valid server returns the expected information", {
    # given
    
    # when
    connection <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456")
    
    # then
    expect_equal(class(connection)[1], "ArangoConnection")
    expect_equal(connection$getServer(), "arango")
    expect_equal(connection$getVersion(), "3.3.19")
    expect_equal(connection$getLicense(), "community")
    expect_equal(connection$getConnectionString(), "http://localhost:1234")
  })
})


with_mock_api({
  test_that("No matter if the port is an integer instead of string, new connection is created", {
    # given
    
    # when
    connection <- aRangodb::arango_connection("localhost", 1234, "gabriele", "123456")
    
    # then
    expect_equal(class(connection)[1], "ArangoConnection")
    expect_equal(connection$getServer(), "arango")
    expect_equal(connection$getVersion(), "3.3.19")
    expect_equal(connection$getLicense(), "community")
    expect_equal(connection$getConnectionString(), "http://localhost:1234")
  })
})

with_mock_api({
  test_that("When the user has not admin access cannot see server info and warning messages are stored, however connection is fine", {
    # given
    
    # when
    connection <-   
      aRangodb::arango_connection("localhost-non-root", 1234, "non-root", "123456")
    
    # then
    expect_equal(class(connection)[1], "ArangoConnection")
    expect_equal(connection$getServer(), "Server up and running, but not entitled as admin")
    expect_equal(connection$getVersion(), "Server up and running, but not entitled as admin")
    expect_equal(connection$getLicense(), "Server up and running, but not entitled as admin")
    expect_equal(connection$getConnectionString(), "http://localhost-non-root:1234")
  })
})

test_that("No connection can be setup with no hostname", {
  # given
  
  # when
  tryCatch({
    aRangodb::arango_connection(NULL, 1234, "gabriele", "123456")
  }, warning = function(w) {
    fail("must not be reached")
  }, error = function(e) {
    # then
    expect_equal("to setup a connection you must indicate a 'host'", e$message)
  })
})


test_that("No connection can be setup with no hostname", {
  # given
  
  # when
  tryCatch({
    aRangodb::arango_connection("localhost", NULL, "gabriele", "123456")
  }, warning = function(w) {
    fail("must not be reached")
  }, error = function(e) {
    # then
    expect_equal("to setup a connection you must indicate a 'port'", e$message)
  })
})