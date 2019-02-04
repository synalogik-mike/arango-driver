context("Graph Management Test Suite")

# ======================================================================
#     SETUP: next calls are made to create proper mocked response
# ======================================================================
connectionResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
write(connectionResponse, file="./localhost-1234/_api/version.json")

dbConnectionResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                       result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
write(dbConnectionResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")

graphResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                       graphs=list(
                                         list(`_key`="graph1", `_id`="_graphs/graph1", `_rev`="1",
                                              edgeDefinitions = list(
                                                collection = "edge1",
                                                from = list("collection1"),
                                                to = list("collection2")
                                              )
                                         ),
                                         list(`_key`="graph2", `_id`="_graphs/graph2", `_rev`="1",
                                              edgeDefinitions = list(
                                                collection = "edge1",
                                                from = list("collection1"),
                                                to = list("collection2")
                                              )
                                         ),
                                         list(`_key`="graph3", `_id`="_graphs/graph3", `_rev`="1",
                                              edgeDefinitions = list(
                                                collection = "edge1",
                                                from = list("collection1"),
                                                to = list("collection2")
                                              )
                                         )
                                       )
                                  )
)
write(graphResponse, file="./localhost-1234/_db/testdb/_api/gharial.json")


# ======================================================================
#                             TEST CASES 
# ======================================================================
with_mock_api({
  test_that("Requests for all available graphs into a database works correctly", {
    # given
    db <- aRangodb::connect("localhost", "1234") %>% 
          aRangodb::database(name = "testdb")
    
    # when
    availableGraphs <- db %>% graphs()
    
    # then
    expect_true("graph1" %in% availableGraphs)
    expect_true("graph2" %in% availableGraphs)
    expect_true("graph3" %in% availableGraphs)
    expect_false("no_graph" %in% availableGraphs)
  })
})
