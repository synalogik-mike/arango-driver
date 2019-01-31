library(RJSONIO)
library(magrittr)

context("Document Management Test Suite")

with_mock_api({
  test_that("Adds a new document into an existing collection works correctly", {
  
    # TEMPLATE, TO COMPLETE
    
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                           result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")
    serverResponse <- RJSONIO::toJSON(list(`_key`="newDoc", `_id`="test_coll/newDoc", `_rev`="1", 
                                           new=list(`_key`="newDoc", `_id`="test_coll/newDoc", `_rev`="1"))
                                     )
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/document/test_coll-064bce-462629-POST.json")
    coll <- aRangodb::connect("localhost", "1234") %>% aRangodb::database(name = "testdb") %>% aRangodb::collection(name = "test_coll")
    
    # when
    doc <- coll %>% aRangodb::insert(key = "newDoc") 
    
    # then
    expect_equal(doc$getCollection(), "test_coll")
    expect_equal(doc$getId(), "newDoc")
    expect_equal(doc$getRevision(), "1")
    expect_equal(length(doc$getAvailableValues()), 0)
  })
})

with_mock_api({
  test_that("Adds a new document into an existing collection works correctly", {
    
    # TEMPLATE, TO COMPLETE
    
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                           result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")
    serverResponse <- RJSONIO::toJSON(list(`_key`="newDoc", `_id`="test_coll/newDoc", `_rev`="1", 
                                           new=list(`_key`="newDoc", `_id`="test_coll/newDoc", `_rev`="1"))
    )
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/document/test_coll-064bce-462629-POST.json")
    serverResponse <- RJSONIO::toJSON(list(`_key`="newDoc", `_id`="test_coll/newDoc", `_rev`="1"))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/document/test_coll/newDoc-DELETE.json")
    coll <- aRangodb::connect("localhost", "1234") %>% aRangodb::database(name = "testdb") %>% aRangodb::collection(name = "test_coll")
    
    # when
    removed <- coll %>% aRangodb::insert(key = "newDoc") %>% aRangodb::delete()
    
    # then
    expect_true(removed)
  })
})

