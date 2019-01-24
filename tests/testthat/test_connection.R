library(RJSONIO)

context("Connection Management Test Suite")

with_mock_api({
  test_that("Connection to valid server returns the expected information", {
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    
    # when
    connection <- aRangodb::connect("localhost", "1234", "root", "aardvark")
    
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
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    
    # when
    connection <- aRangodb::connect("localhost", 1234, "root", "aardvark")
    
    # then
    expect_equal(class(connection)[1], "ArangoConnection")
    expect_equal(connection$getServer(), "arango")
    expect_equal(connection$getVersion(), "3.3.19")
    expect_equal(connection$getLicense(), "community")
    expect_equal(connection$getConnectionString(), "http://localhost:1234")
  })
})


test_that("No connection can be setup with no hostname", {
  # given
  
  # when
  tryCatch({
    aRangodb::connect(NULL, 1234, "root", "aardvark")
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
    aRangodb::connect("localhost", NULL, "root", "aardvark")
  }, warning = function(w) {
    fail("must not be reached")
  }, error = function(e) {
    # then
    expect_equal("to setup a connection you must indicate a 'port'", e$message)
  })
})