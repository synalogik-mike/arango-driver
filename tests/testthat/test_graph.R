context("Graph Management Test Suite")

with_mock_api({
  test_that("Requests for all available graphs into a database works correctly", {
    # given
    serverResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
    write(serverResponse, file="./localhost-1234/_api/version.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                           result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")
    serverResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                           graphs=list(
                                             list(`_key`="graph1", `_id`="_graphs/graph1", `_rev`="1"),
                                             list(`_key`="graph2", `_id`="_graphs/graph2", `_rev`="1"),
                                             list(`_key`="graph3", `_id`="_graphs/graph3", `_rev`="1")
                                           )
                                      )
    )
    write(serverResponse, file="./localhost-1234/_db/testdb/_api/gharial.json")
    
    db <- aRangodb::connect("localhost", "1234") %>% aRangodb::database(name = "testdb")
    
    # when
    availableGraphs <- db %>% graphs()
    
    # then
    expect_true("graph1" %in% availableGraphs)
    expect_true("graph2" %in% availableGraphs)
    expect_true("graph3" %in% availableGraphs)
    expect_false("no_graph" %in% availableGraphs)
  })
})
