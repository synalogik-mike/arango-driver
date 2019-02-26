context("AQL Management Test Suite")



# ======================================================================
#     SETUP: next calls are made to create proper mocked response
# ======================================================================
connectionResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
write(connectionResponse, file="./localhost-1234/_api/version.json")

databaseConnectionResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                       result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
write(databaseConnectionResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")

aqlParsingResponse <- RJSONIO::toJSON(list(code=200, error=FALSE))
write(aqlParsingResponse, file="./localhost-1234/_db/testdb/_api/query-db8f64-POST.json")

cursorResponse <- RJSONIO::toJSON(list(code=201, error=FALSE, hasMore=FALSE, 
                                       result=list(
                                         list(`_key`="key1", `_id`="example_coll/key1", `_rev`="1", type="key", name="name1"),
                                         list(`_key`="key2", `_id`="example_coll/key2", `_rev`="2", type="key", name="name2")
                                       )
                                  )
)
write(cursorResponse, file="./localhost-1234/_db/testdb/_api/cursor-a61a96-POST.json")

queryErrorResponse <- RJSONIO::toJSON(list(code=400, error=TRUE, errorNum=1501, 
                                       errorMessage="syntax error, unexpected assignment near '=@type RETURN elem' at position 1:42"))
write(queryErrorResponse, file="./localhost-1234/_db/testdb/_api/query-592753-POST.json")



# ======================================================================
#                             TEST CASES 
# ======================================================================
with_mock_api({
  test_that("Creation of a correct AQL statement let the returns of correct results", {
    # given
    db <- aRangodb::arango_connection("localhost", "1234") %>% 
          aRangodb::database(name = "testdb")
    
    # when
    searchByType <- db %>% aRangodb::aql("FOR elem IN example_coll FILTER elem.type==@type RETURN elem")
    results <- searchByType(type="key")
      
    # then
    expect_equal(length(results), 2)
    expect_equal(results$doc0$type, "key")
    expect_equal(results$doc0$name, "name1")
    expect_equal(results$doc1$type, "key")
    expect_equal(results$doc1$name, "name2")
  })
})


with_mock_api({
  test_that("Creation of a wrong AQL statement let the parsing return an error", {
    # given
    db <- aRangodb::arango_connection("localhost", "1234") %>% 
          aRangodb::database(name = "testdb")
    
    # when
    tryCatch({
      db %>% aRangodb::aql("FOR elem IN example_coll FILTER elem.type2=@type RETURN elem")
    }, warning = function(w) {
      fail("must not be reached")
    }, error = function(e) {
      # then
      expect_equal("syntax error, unexpected assignment near '=@type RETURN elem' at position 1:42", e$message)
    })
  })
})
