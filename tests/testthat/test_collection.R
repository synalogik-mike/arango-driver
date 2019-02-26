library(RJSONIO)
library(magrittr)

context("Collection Management Test Suite")



# ======================================================================
#     SETUP: next calls are made to create proper mocked response
# ======================================================================
connetionResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
write(connetionResponse, file="./localhost-1234/_api/version.json")

databaseConnectionResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                                   result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
write(databaseConnectionResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")

collectionsResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                       result=list(
                                         list(name="coll1", id="2", status=3, isSystem=FALSE, type=2),
                                         list(name="coll2", id="3", status=3, isSystem=FALSE, type=2),
                                         list(name="syscoll", id="4", status=3, isSystem=TRUE, type=2)
                                       )
                                  )
)
write(collectionsResponse, file="./localhost-1234/_db/testdb/_api/collection.json")

existingCollectionResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, id="12345", name="test_coll", isSystem=FALSE,
                                       type=aRangodb::collection_type$DOCUMENT, status=aRangodb::collection_status$LOADED))
write(existingCollectionResponse, file="./localhost-1234/_db/testdb/_api/collection/test_coll.json")

notExistingCollectionResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, status=3, type=2, isSystem=FALSE, id="9862319", name="example_coll"))
write(notExistingCollectionResponse, file="./localhost-1234/_db/testdb/_api/collection/example_coll.json")

deletionResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, id="9862319"))
write(deletionResponse, file="./localhost-1234/_db/testdb/_api/collection/example_coll-DELETE.json")



# ======================================================================
#                             TEST CASES 
# ======================================================================
with_mock_api({
  test_that("Requests for all available collections into a database works correctly", {
    # given
    db <- aRangodb::arango_connection("localhost", "1234") %>% 
          aRangodb::arango_database(name = "testdb")
    
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
    db <- aRangodb::arango_connection("localhost", "1234") %>% 
          aRangodb::arango_database(name = "testdb")
    
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
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, id="12345", name="test_coll", isSystem=TRUE,
                                           type=aRangodb::collection_type$EDGE, status=aRangodb::collection_status$LOADING))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/collection/test_coll.json")
    
    db <- aRangodb::arango_connection("localhost", "1234") %>% 
          aRangodb::arango_database(name = "testdb")
    
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
  test_that("Deletion of an existing collection works correctly", {
    # given
    coll <- aRangodb::arango_connection("localhost", "1234") %>% 
            aRangodb::arango_database(name = "testdb") %>% 
            aRangodb::collection(name = "example_coll")
    
    # when
    deleted <- coll %>% aRangodb::drop()
    
    # then
    expect_true(deleted)
  })
})

with_mock_api({
  test_that("Request for the count of the elements for a collection works correctly", {
    # given
    collectionCountResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, count=20))
    write(collectionCountResponse, file="./localhost-1234/_db/testdb/_api/collection/example_coll/count.json")
    
    coll <- aRangodb::arango_connection("localhost", "1234") %>% 
            aRangodb::arango_database(name = "testdb") %>% 
            aRangodb::collection(name = "example_coll")
    
    # when
    count <- coll$getCount() # line 38, count is 20
    
    # then
    expect_equal(count, 20)
  })
})

with_mock_api({
  test_that("Request for all the elements of a collection works correctly (all in the first call)", {
    # given
    serverResponse <- RJSONIO::toJSON(list(code=201, error=FALSE, hasMore=FALSE, 
                                           result=list(
                                             list(
                                               `_key`="key1", 
                                               `_id`="example_coll/key1", 
                                               `_rev`="1", 
                                               type="key", 
                                               name="name1"),
                                             list(
                                               `_key`="key2", 
                                               `_id`="example_coll/key2", 
                                               `_rev`="2", 
                                               type="key", 
                                               name="name2")
                                           )
                                      ))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/cursor-1e503a-POST.json")
    coll <- aRangodb::arango_connection("localhost", "1234") %>% aRangodb::arango_database(name = "testdb") %>% aRangodb::collection(name = "example_coll")
    
    # when
    documents <- coll %>% aRangodb::all_documents()
    
    # then
    expect_equal(documents$"key1"$getId(), "example_coll/key1")
    expect_equal(documents$"key1"$getKey(), "key1")
    expect_equal(documents$"key1"$getRevision(), "1")
    expect_equal(documents$"key1"$getCollection(), "example_coll")
    expect_equal(documents$"key1"$getValues()$"type", "key")
    expect_equal(documents$"key1"$getValues()$"name", "name1")
    expect_true("type" %in% documents$"key1"$getKeys())
    expect_true("name" %in% documents$"key1"$getKeys())
    expect_false("_id" %in% documents$"key1"$getKeys())
    expect_false("_key" %in% documents$"key1"$getKeys())
    expect_false("_rev" %in% documents$"key1"$getKeys())
    expect_false("not_exist" %in% documents$"key1"$getKeys())
    
    expect_equal(documents$"key2"$getId(), "example_coll/key2")
    expect_equal(documents$"key2"$getKey(), "key2")
    expect_equal(documents$"key2"$getRevision(), "2")
    expect_equal(documents$"key2"$getCollection(), "example_coll")
    expect_equal(documents$"key2"$getValues()$"type", "key")
    expect_equal(documents$"key2"$getValues()$"name", "name2")
    expect_true("type" %in% documents$"key2"$getKeys())
    expect_true("name" %in% documents$"key2"$getKeys())
    expect_false("_id" %in% documents$"key2"$getKeys())
    expect_false("_key" %in% documents$"key2"$getKeys())
    expect_false("_rev" %in% documents$"key2"$getKeys())
    expect_false("not_exist" %in% documents$"key2"$getKeys())
  })
})


with_mock_api({
  test_that("Request for all the elements of a collection works correctly (using cursor for consecutive calls)", {
    # given
    serverResponse <- RJSONIO::toJSON(list(code=201, error=FALSE, hasMore=TRUE, 
                                           result=list(
                                             list(
                                               `_key`="key1", 
                                               `_id`="example_coll/key1", 
                                               `_rev`="1", 
                                               type="key", 
                                               name="name1"),
                                             list(
                                               `_key`="key2", 
                                               `_id`="example_coll/key2", 
                                               `_rev`="2", 
                                               type="key", 
                                               name="name2")
                                           )
    ))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/cursor-1e503a-POST.json")
    serverResponse <- RJSONIO::toJSON(list(code=201, error=FALSE, hasMore=FALSE, 
                                           result=list(
                                             list(
                                               `_key`="key3", 
                                               `_id`="example_coll/key3", 
                                               `_rev`="1", 
                                               type="key", 
                                               name="name3"),
                                             list(
                                               `_key`="key4", 
                                               `_id`="example_coll/key4", 
                                               `_rev`="2", 
                                               type="key", 
                                               name="name4")
                                           )
    ))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/cursor-PUT.json")
    
    coll <- aRangodb::arango_connection("localhost", "1234") %>% 
            aRangodb::arango_database(name = "testdb") %>% 
            aRangodb::collection(name = "example_coll")
    
    # when
    documents <- coll %>% aRangodb::all_documents()
  
    # then
    expect_equal(documents$"key1"$getId(), "example_coll/key1")
    expect_equal(documents$"key1"$getKey(), "key1")
    expect_equal(documents$"key1"$getRevision(), "1")
    expect_equal(documents$"key1"$getCollection(), "example_coll")
    expect_equal(documents$"key1"$getValues()$"type", "key")
    expect_equal(documents$"key1"$getValues()$"name", "name1")
    expect_true("type" %in% documents$"key1"$getKeys())
    expect_true("name" %in% documents$"key1"$getKeys())
    expect_false("_id" %in% documents$"key1"$getKeys())
    expect_false("_key" %in% documents$"key1"$getKeys())
    expect_false("_rev" %in% documents$"key1"$getKeys())
    expect_false("not_exist" %in% documents$"key1"$getKeys())
    
    expect_equal(documents$"key2"$getId(), "example_coll/key2")
    expect_equal(documents$"key2"$getKey(), "key2")
    expect_equal(documents$"key2"$getRevision(), "2")
    expect_equal(documents$"key2"$getCollection(), "example_coll")
    expect_equal(documents$"key2"$getValues()$"type", "key")
    expect_equal(documents$"key2"$getValues()$"name", "name2")
    expect_true("type" %in% documents$"key2"$getKeys())
    expect_true("name" %in% documents$"key2"$getKeys())
    expect_false("_id" %in% documents$"key2"$getKeys())
    expect_false("_key" %in% documents$"key2"$getKeys())
    expect_false("_rev" %in% documents$"key2"$getKeys())
    expect_false("not_exist" %in% documents$"key2"$getKeys())
    
    expect_equal(documents$"key3"$getId(), "example_coll/key3")
    expect_equal(documents$"key3"$getKey(), "key3")
    expect_equal(documents$"key3"$getRevision(), "1")
    expect_equal(documents$"key3"$getCollection(), "example_coll")
    expect_equal(documents$"key3"$getValues()$"type", "key")
    expect_equal(documents$"key3"$getValues()$"name", "name3")
    expect_true("type" %in% documents$"key3"$getKeys())
    expect_true("name" %in% documents$"key3"$getKeys())
    expect_false("_id" %in% documents$"key3"$getKeys())
    expect_false("_key" %in% documents$"key3"$getKeys())
    expect_false("_rev" %in% documents$"key3"$getKeys())
    expect_false("not_exist" %in% documents$"key3"$getKeys())
    
    expect_equal(documents$"key4"$getId(), "example_coll/key4")
    expect_equal(documents$"key4"$getKey(), "key4")
    expect_equal(documents$"key4"$getRevision(), "2")
    expect_equal(documents$"key4"$getCollection(), "example_coll")
    expect_equal(documents$"key4"$getValues()$"type", "key")
    expect_equal(documents$"key4"$getValues()$"name", "name4")
    expect_true("type" %in% documents$"key4"$getKeys())
    expect_true("name" %in% documents$"key4"$getKeys())
    expect_false("_id" %in% documents$"key4"$getKeys())
    expect_false("_key" %in% documents$"key4"$getKeys())
    expect_false("_rev" %in% documents$"key4"$getKeys())
    expect_false("not_exist" %in% documents$"key4"$getKeys())
  })
})