context("AQL Management Test Suite")

with_mock_api({
  test_that("Creation of a correct AQL statement let the returns of correct results", {
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                           result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/query-d8dea1-POST.json")
    serverResponse <- RJSONIO::toJSON(list(code=201, error=FALSE, hasMore=FALSE, 
                                           result=list(
                                             list(`_key`="key1", `_id`="example_coll/key1", `_rev`="1", type="key", name="name1"),
                                             list(`_key`="key2", `_id`="example_coll/key2", `_rev`="2", type="key", name="name2")
                                           )
    ))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/cursor-7a1481-POST.json")
    db <- aRangodb::connect("localhost", "1234") %>% 
      aRangodb::database(name = "testdb")
    
    # when
    searchByType <- db %>% aRangodb::aql("FOR elem IN example_coll FILTER elem.type=@type RETURN elem")
    results <- searchByType(type="key")
      
    # then
    expect_equal(length(results), 2)
    expect_equal(results$queryResult_0$type, "key")
    expect_equal(results$queryResult_0$name, "name1")
    expect_equal(results$queryResult_1$type, "key")
    expect_equal(results$queryResult_1$name, "name2")
  })
})


with_mock_api({
  test_that("Creation of a wrong AQL statement let the parsing return an error", {
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                           result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")
    serverResponse <- RJSONIO::toJSON(list(code=400, error=TRUE, errorNum=1501, 
                                           errorMessage="syntax error, unexpected assignment near '=@type RETURN elem' at position 1:42"))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/query-d8dea1-POST.json")
    db <- aRangodb::connect("localhost", "1234") %>% 
      aRangodb::database(name = "testdb")
    
    # when
    tryCatch({
      db %>% aRangodb::aql("FOR elem IN example_coll FILTER elem.type=@type RETURN elem")
    }, warning = function(w) {
      fail("must not be reached")
    }, error = function(e) {
      # then
      expect_equal("syntax error, unexpected assignment near '=@type RETURN elem' at position 1:42", e$message)
    })
  })
})
