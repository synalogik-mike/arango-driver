library(RJSONIO)
library(magrittr)

context("Collection Management Test Suite")

with_mock_api({
  test_that("Requests for all available collections into a database works correctly", {
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                           result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                           result=list(
                                             list(name="coll1", id="2", status=3, isSystem=FALSE, type=2),
                                             list(name="coll2", id="3", status=3, isSystem=FALSE, type=2),
                                             list(name="syscoll", id="4", status=3, isSystem=TRUE, type=2)
                                           )
                                          )
                                     )
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/collection.json")
    
    connection <- aRangodb::connect("localhost", "1234")
    db <- connection %>% aRangodb::database(name = "testdb")
    
    # when
    availableCollections <- db %>% collections()
    
    # then
    expect_true("coll1" %in% availableCollections)
    expect_true("coll2" %in% availableCollections)
    expect_false("syscoll" %in% availableCollections)
  })
})

with_mock_api({
  test_that("Request for an existing collection that is not a system one returns the collection info", {
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                           result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, id="12345", name="test_coll", isSystem=FALSE,
                                           type=aRangodb::collection_type$DOCUMENT, status=aRangodb::collection_status$LOADED))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/collection/test_coll.json")
    db <- aRangodb::connect("localhost", "1234") %>% aRangodb::database(name = "testdb")
    
    # when
    collection <- db %>% aRangodb::collection(name = "test_coll")
    
    # then
    expect_equal(collection$getName(), "test_coll")
    expect_equal(collection$getId(), "12345")
    expect_equal(collection$getStatus(), 3)
    expect_equal(collection$getType(), 2)
    expect_false(collection$isSystemCollection())
  })
})

with_mock_api({
  test_that("Request for an existing collection that is a system one returns the collection info", {
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                           result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, id="12345", name="test_coll", isSystem=TRUE,
                                           type=aRangodb::collection_type$EDGE, status=aRangodb::collection_status$LOADING))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/collection/test_coll.json")
    db <- aRangodb::connect("localhost", "1234") %>% aRangodb::database(name = "testdb")
    
    # when
    collection <- db %>% aRangodb::collection(name = "test_coll")
    
    # then
    expect_equal(collection$getName(), "test_coll")
    expect_equal(collection$getId(), "12345")
    expect_equal(collection$getStatus(), 6)
    expect_equal(collection$getType(), 3)
    expect_true(collection$isSystemCollection())
  })
})

with_mock_api({
  test_that("Request for a collection that not exist with creation on fail, the call works", {
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, status=3, type=2, isSystem=FALSE, id="9862319", name="example_coll"))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/collection/example_coll.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, id="9862319"))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/collection/example_coll-DELETE.json")
    coll <- aRangodb::connect("localhost", "1234") %>% aRangodb::database(name = "testdb") %>% aRangodb::collection(name = "example_coll")
    
    # when
    deleted <- coll %>% aRangodb::drop()
    
    # then
    expect_true(deleted)
  })
})