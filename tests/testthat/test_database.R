library(RJSONIO)
library(magrittr)

context("Database Management Test Suite")

with_mock_api({
  test_that("Requests for all available databases goes fine", {
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    serverResponse <- RJSONIO::toJSON(list(code="200", error=FALSE, result=c("db1", "db2")))
    write(serverResponse, file="./localhost-1234/_api/database.json")
    connection <- aRangodb::connect("localhost", "1234")
    
    # when
    available_dbs <- connection %>% aRangodb::databases()
    
    # then
    expect_true("db1" %in% available_dbs)
    expect_true("db2" %in% available_dbs)
  })
})

with_mock_api({
  test_that("Only ArangoConnection objects are accepted for connection with databases() function", {
    # given
    
    # when
    tryCatch({
      "wrong param" %>% aRangodb::databases()
    }, warning = function(w) {
      fail("must not be reached")
    }, error = function(e) {
      # then
      expect_equal("Only 'ArangoConnection' objects can be processed by aRango::databases", e$message)
    })
  })
})

with_mock_api({
  test_that("Connection parameter NULL led to execution fail with custom message", {
    # given
    
    # when
    tryCatch({
      NULL %>% aRangodb::databases()
    }, warning = function(w) {
      fail("must not be reached")
    }, error = function(e) {
      # then
      expect_equal("Connection is NULL, please provide a valid 'ArangoConnection'", e$message)
    })
  })
})