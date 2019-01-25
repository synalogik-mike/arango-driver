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
