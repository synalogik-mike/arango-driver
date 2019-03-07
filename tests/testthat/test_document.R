library(RJSONIO)
library(magrittr)

context("Document Management Test Suite")

# ======================================================================
#     SETUP: next calls are made to create proper mocked response
# ======================================================================
connectionResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
write(connectionResponse, file="./localhost-1234/_api/version.json")

databaseServerResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                       result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
write(databaseServerResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")

documentDeletionResponse <- RJSONIO::toJSON(list(`_key`="newDoc", `_id`="test_coll/newDoc", `_rev`="1"))
write(documentDeletionResponse, file="./localhost-1234/_db/testdb/_api/document/test_coll/newDoc-DELETE.json")



# ======================================================================
#                             TEST CASES 
# ======================================================================
test_that("Custom %lt% parse the given expression correctly", {
  # given
  
  # when
  expr <- name %lt% 3
  
  # then
  expect_equal(expr, "name < 3")
})

test_that("Custom %gt% parse the given expression correctly", {
  # given
  
  # when
  expr <- name %gt% 3
  
  # then
  expect_equal(expr, "name > 3")
})

test_that("Custom %leq% parse the given expression correctly", {
  # given
  
  # when
  expr <- name %leq% 3
  
  # then
  expect_equal(expr, "name <= 3")
})

test_that("Custom %geq% parse the given expression correctly", {
  # given
  
  # when
  expr <- name %geq% 3
  
  # then
  expect_equal(expr, "name >= 3")
})

with_mock_api({
  test_that("Adds a new document into an existing collection works correctly", {
    
    # given
    newDocument <- list(
      `_key`="newDoc", 
      `_id`="test_coll/newDoc", 
      `_rev`="1", 
       new=list(
         `_key`="newDoc", 
         `_id`="test_coll/newDoc", 
         `_rev`="1"
      )
    )
    
    serverResponse <- RJSONIO::toJSON(newDocument)
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/document/test_coll-064bce-462629-POST.json")
    
    coll <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% 
            aRangodb::arango_database(name = "testdb") %>% 
            aRangodb::arango_collection(name = "test_coll")
    
    # when
    doc <- coll %>% aRangodb::document_insert(key = "newDoc") 
    
    # then
    expect_equal(doc$getCollection(), "test_coll")
    expect_equal(doc$getId(), "test_coll/newDoc")
    expect_equal(doc$getKey(), "newDoc")
    expect_equal(doc$getRevision(), "1")
    expect_equal(length(doc$getKeys()), 0)
  })
})

with_mock_api({
  test_that("Delete an existing document from an existing collection works correctly", {
    
    # given
    existingDocument <- list(
      `_key`="newDoc", 
      `_id`="test_coll/newDoc", 
      `_rev`="1", 
      new = list(
        `_key`="newDoc", 
        `_id`="test_coll/newDoc", 
        `_rev`="1"
      )
    )
    
    serverResponse <- RJSONIO::toJSON(existingDocument)
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/document/test_coll-064bce-462629-POST.json")
    
    coll <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% 
            aRangodb::arango_database(name = "testdb") %>% 
            aRangodb::arango_collection(name = "test_coll")
    
    # when
    removed <- coll %>% aRangodb::document_insert(key = "newDoc") %>% aRangodb::delete()
    
    # then
    expect_true(removed)
  })
})

with_mock_api({
  test_that("Updates an existing document works correctly and causes a revision change", {
    
    # given
    originalDocumentFromServer <- list(
      `_key`="newDoc", 
      `_id`="test_coll/newDoc", 
      `_rev`="1", 
      new = list(
        `_key`="newDoc", 
        `_id`="test_coll/newDoc", 
        `_rev`="1"
      )
    )
    
    updatedDocumentFromServer <- list(
      `_key`="newDoc", 
      `_id`="test_coll/newDoc", 
      `_rev`="2", 
      `_oldRev`="1"
    )
    
    serverResponse <- RJSONIO::toJSON(originalDocumentFromServer)
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/document/test_coll-064bce-462629-POST.json")
    serverResponse <- RJSONIO::toJSON(updatedDocumentFromServer)
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/document/test_coll/newDoc-b62a70-PATCH.json")
    
    doc <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% 
           aRangodb::arango_database(name = "testdb") %>% 
           aRangodb::arango_collection(name = "test_coll") %>% 
           aRangodb::document_insert(key = "newDoc")
    
    # when
    previousUpdateRevision <- doc$getRevision()
    doc <- doc %>% aRangodb::document_set(prop1="value1", prop2="value2") %>% aRangodb::collection_update()
    
    # then
    expect_false(doc$getRevision() == previousUpdateRevision)
    expect_equal(doc$getCollection(), "test_coll")
    expect_equal(doc$getId(), "test_coll/newDoc")
    expect_equal(doc$getKey(), "newDoc")
    expect_equal(doc$getRevision(), "2")
    expect_equal(length(doc$getKeys()), 2)
    expect_equal(doc$getValues()$prop1, "value1")
    expect_equal(doc$getValues()$prop2, "value2")
  })
})

with_mock_api({
  test_that("Remove a key from a document works correctly", {
    
    # given
    originalDocumentFromServer <- list(
      `_key`="newDoc", 
      `_id`="test_coll/newDoc", 
      `_rev`="1", 
      new = list(
        `_key`="newDoc", 
        `_id`="test_coll/newDoc", 
        `_rev`="1"
      )
    )
    
    serverResponse <- RJSONIO::toJSON(originalDocumentFromServer)
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/document/test_coll-064bce-462629-POST.json")
    
    serverResponse <- RJSONIO::toJSON(list(`_key`="newDoc", `_id`="test_coll/newDoc", `_rev`="2", `_oldRev`="1"))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/document/test_coll/newDoc-7dde6e-PATCH.json")
    
    doc <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% aRangodb::arango_database(name = "testdb") %>% 
      aRangodb::arango_collection(name = "test_coll") %>% aRangodb::document_insert(key = "newDoc")
    
    # when
    previousUpdateRevision <- doc$getRevision()
    doc <- doc %>% aRangodb::document_set(prop1="value1", prop2="value2") %>% 
      document_unset("prop1") %>% aRangodb::collection_update()
    
    # then
    expect_false(doc$getRevision() == previousUpdateRevision)
    expect_equal(doc$getCollection(), "test_coll")
    expect_equal(doc$getId(), "test_coll/newDoc")
    expect_equal(doc$getKey(), "newDoc")
    expect_equal(doc$getRevision(), "2")
    expect_equal(length(doc$getKeys()), 1)
    expect_equal(doc$getValues()$prop2, "value2")
  })
})

with_mock_api({
  test_that("Filter documents from a collection works correctly", {
    # given
    filteredDocuments <- 
      list(
        code=201, 
        error=FALSE, 
        hasMore=FALSE, 
        result = list(
          list(
            `_key`="key1", 
            `_id`="example_coll/key1", 
            `_rev`="1", 
            type="key", 
            subtype="subtype1", 
            name="name1"
          ),
          list(
            `_key`="key2", 
            `_id`="example_coll/key2", 
            `_rev`="2", 
            type="key", 
            subtype="subtype1", 
            name="name2"
          )
      )
    )
    serverResponse <- RJSONIO::toJSON(filteredDocuments)
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/cursor-d77099-POST.json")
    
    coll <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% 
            aRangodb::arango_database(name = "testdb") %>% 
            aRangodb::arango_collection(name = "example_coll")
    
    # when
    docs <- coll %>% aRangodb::collection_filter(type="key", subtype="subtype1")
    
    # then
    expect_equal(docs$"key1"$getKey(), "key1")
    expect_equal(docs$"key1"$getRevision(), "1")
    expect_equal(docs$"key1"$getCollection(), "example_coll")
    expect_equal(docs$"key1"$getValues()$"type", "key")
    expect_equal(docs$"key1"$getValues()$"name", "name1")
    expect_equal(docs$"key1"$getValues()$"subtype", "subtype1")
    expect_true("type" %in% docs$"key1"$getKeys())
    expect_true("name" %in% docs$"key1"$getKeys())
    expect_false("_id" %in% docs$"key1"$getKeys())
    expect_false("_key" %in% docs$"key1"$getKeys())
    expect_false("_rev" %in% docs$"key1"$getKeys())
    expect_false("not_exist" %in% docs$"key1"$getKeys())
    
    expect_equal(docs$"key2"$getKey(), "key2")
    expect_equal(docs$"key2"$getRevision(), "2")
    expect_equal(docs$"key2"$getCollection(), "example_coll")
    expect_equal(docs$"key2"$getValues()$"type", "key")
    expect_equal(docs$"key2"$getValues()$"name", "name2")
    expect_equal(docs$"key2"$getValues()$"subtype", "subtype1")
    expect_true("type" %in% docs$"key2"$getKeys())
    expect_true("name" %in% docs$"key2"$getKeys())
    expect_false("_id" %in% docs$"key2"$getKeys())
    expect_false("_key" %in% docs$"key2"$getKeys())
    expect_false("_rev" %in% docs$"key2"$getKeys())
    expect_false("not_exist" %in% docs$"key2"$getKeys())
  })
})

with_mock_api({
  test_that("Filter documents from a collection with different values' types works correctly", {
    # given
    filteredDocuments <- 
      list(
        code=201, 
        error=FALSE, 
        hasMore=FALSE, 
        result=list(
          list(
            `_key`="key1", 
            `_id`="example_coll/key1", 
            `_rev`="1", 
            type="key", 
            isSystem=TRUE, 
            qty=1
          ),
          list(
            `_key`="key2", 
            `_id`="example_coll/key2", 
            `_rev`="2", 
            type="key", 
            isSystem=TRUE, 
            qty=1.5
          )
      )
    )
    
    serverResponse <- RJSONIO::toJSON(filteredDocuments)
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/cursor-a81381-POST.json")
    coll <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% 
            aRangodb::arango_database(name = "testdb") %>% 
            aRangodb::arango_collection(name = "example_coll")
    
    # when
    docs <- coll %>% aRangodb::collection_filter(type = "key", isSystem = TRUE, qty %gt% 0, qty %lt% 3.3)
    
    # then
    expect_equal(docs$"key1"$getKey(), "key1")
    expect_equal(docs$"key1"$getRevision(), "1")
    expect_equal(docs$"key1"$getCollection(), "example_coll")
    expect_equal(docs$"key1"$getValues()$"type", "key")
    expect_equal(docs$"key1"$getValues()$"isSystem", TRUE)
    expect_equal(docs$"key1"$getValues()$"qty", 1)
    expect_true("type" %in% docs$"key1"$getKeys())
    expect_false("_id" %in% docs$"key1"$getKeys())
    expect_false("_key" %in% docs$"key1"$getKeys())
    expect_false("_rev" %in% docs$"key1"$getKeys())
    expect_false("not_exist" %in% docs$"key1"$getKeys())
    
    expect_equal(docs$"key2"$getKey(), "key2")
    expect_equal(docs$"key2"$getRevision(), "2")
    expect_equal(docs$"key2"$getCollection(), "example_coll")
    expect_equal(docs$"key2"$getValues()$"type", "key")
    expect_equal(docs$"key2"$getValues()$"isSystem", TRUE)
    expect_equal(docs$"key2"$getValues()$"qty", 1.5)
    expect_true("type" %in% docs$"key2"$getKeys())
    expect_false("_id" %in% docs$"key2"$getKeys())
    expect_false("_key" %in% docs$"key2"$getKeys())
    expect_false("_rev" %in% docs$"key2"$getKeys())
    expect_false("not_exist" %in% docs$"key2"$getKeys())
  })
})