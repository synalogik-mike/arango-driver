library(RJSONIO)
library(magrittr)

context("Database Management Test Suite")

# ======================================================================
#     SETUP: next calls are made to create proper mocked response
# ======================================================================
connectionResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
write(connectionResponse, file="./localhost-1234/_api/version.json")

databasesResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, result=c("db1", "db2")))
write(databasesResponse, file="./localhost-1234/_api/database.json")

systemDatabaseResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                       result=list(name="_system", id="1", path="/some/path", isSystem=TRUE)))
write(systemDatabaseResponse, file="./localhost-1234/_db/_system/_api/database/current.json")

existingServerResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                       result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
write(existingServerResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")

notExistingDatabaseResponse <- RJSONIO::toJSON(list(code=201, error=FALSE, result=TRUE))
write(notExistingDatabaseResponse, file="./localhost-1234/_api/database-ab18f8-POST.json")

dropDatabaseResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, result=TRUE))
write(dropDatabaseResponse, file="./localhost-1234/_api/database/testdb-DELETE.json")



# ======================================================================
#                             TEST CASES 
# ======================================================================
with_mock_api({
  test_that("Requests for all available databases goes fine", {
    # given
    connection <- aRangodb::arango_connection("localhost", "1234")
    
    # when
    available_dbs <- connection %>% 
                     aRangodb::databases()
    
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


with_mock_api({
  test_that("Requests for _system database works correctly", {
    # given
    connection <- aRangodb::arango_connection("localhost", "1234")
    
    # when
    defaultDb <- connection %>% 
                 aRangodb::arango_database()
    
    # then
    expect_equal(defaultDb$getName(), "_system")
    expect_equal(defaultDb$getId(), "1")
    expect_true(defaultDb$isSystemDatabase())
  })
})


with_mock_api({
  test_that("Requests for existing database works correctly", {
    # given
    connection <- aRangodb::arango_connection("localhost", "1234")
    
    # when
    defaultDb <- connection %>% 
                 aRangodb::arango_database(name = "testdb")
    
    # then
    expect_equal(defaultDb$getName(), "testdb")
    expect_equal(defaultDb$getId(), "1121552")
    expect_false(defaultDb$isSystemDatabase())
  })
})


with_mock_api({
  test_that("Requests for not existing database works correctly", {
    # given
    connection <- aRangodb::arango_connection("localhost", "1234")
    
    # when
    defaultDb <- connection %>% 
                 aRangodb::arango_database(name = "example", createOnFail = TRUE)
    
    # then
    expect_equal(defaultDb$getName(), "example")
    expect_equal(defaultDb$getId(), "1121552")
    expect_false(defaultDb$isSystemDatabase())
  })
})


with_mock_api({
  test_that("Requests for drop of an existing database works correctly", {
    # given
    db <- aRangodb::arango_connection("localhost", "1234") %>% 
          aRangodb::arango_database(name = "testdb")
   
    # when
    dropResult <- db %>% aRangodb::drop()
    
    # then
    expect_true(dropResult)
  })
})