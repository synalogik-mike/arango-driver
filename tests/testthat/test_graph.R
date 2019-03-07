context("Graph Management Test Suite")

# ======================================================================
#     SETUP: next calls are made to create proper mocked response
# ======================================================================
connectionResponse <- RJSONIO::toJSON(list(server="arango", version="3.3.19", license="community"))
write(connectionResponse, file="./localhost-1234/_api/version.json")

dbConnectionResponse <- RJSONIO::toJSON(list(code=200, error=FALSE, 
                                       result=list(name="testdb", id="1121552", path="/some/path", isSystem=FALSE)))
write(dbConnectionResponse, file="./localhost-1234/_db/testdb/_api/database/current.json")

graphCreationResponse <- RJSONIO::toJSON(list(code=200, error=FALSE))
write(graphCreationResponse, file="./localhost-1234/_db/testdb/_api/gharial-f61114-POST.json")

graphAddEdgeResponse <- RJSONIO::toJSON(list(code=200, error=FALSE))
write(graphAddEdgeResponse, file="./localhost-1234/_db/testdb/_api/gharial/testgraph/edge-ed8960-POST.json")

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

testGraphResponse <- RJSONIO::toJSON(list(
                                      code=200, 
                                      error=FALSE, 
                                      graph =
                                        list(
                                          `name`="testgraph", 
                                          `_id`="_graphs/testgraph", 
                                          `_rev`="1",
                                          edgeDefinitions = list(
                                            list(  
                                              collection = "edge1",
                                              from = list("collection1"),
                                              to = list("collection2")
                                            ),
                                            list(  
                                              collection = "edge2",
                                              from = list("collection1b"),
                                              to = list("collection2b")
                                            )
                                          ),
                                          orphanCollections = list()
                                        )
                                  )
)

write(testGraphResponse, file="./localhost-1234/_db/testdb/_api/gharial/testgraph.json")

deletionResponse <- RJSONIO::toJSON(list(code=202, error=FALSE))
write(deletionResponse, file="./localhost-1234/_db/testdb/_api/gharial/testgraph-DELETE.json")



# ======================================================================
#                             TEST CASES 
# ======================================================================
with_mock_api({
  test_that("Requests for all available graphs into a database works correctly", {
    # given
    db <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% 
          aRangodb::arango_database(name = "testdb")
    
    # when
    availableGraphs <- db %>% graphs()
    
    # then
    expect_true("graph1" %in% availableGraphs)
    expect_true("graph2" %in% availableGraphs)
    expect_true("graph3" %in% availableGraphs)
    expect_false("no_graph" %in% availableGraphs)
  })
})



with_mock_api({
  test_that("Requests for an existing graph into a database works correctly", {
    # given
    db <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% 
      aRangodb::arango_database(name = "testdb")
    
    # when
    foundGraph <- db %>% arango_graph(name = "testgraph")
    
    # then
    expect_equal(foundGraph$getName(), "testgraph")
    expect_equal(foundGraph$getId(), "_graphs/testgraph")
    expect_equal(foundGraph$getRevision(), "1")
  })
})



with_mock_api({
  test_that("Requests for a not existing existing graph into a database works correctly", {
    # given
    db <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% 
      aRangodb::arango_database(name = "testdb")
    
    # when
    foundGraph <- db %>% arango_graph(name = "testgraph", createOnFail = TRUE)
    
    # then
    expect_equal(foundGraph$getName(), "testgraph")
    expect_equal(foundGraph$getId(), "_graphs/testgraph")
    expect_equal(foundGraph$getRevision(), "1")
  })
})


with_mock_api({
  test_that("Addition of an edge definition for a graph works correctly", {
    # given
    existingGraph <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% 
      aRangodb::arango_database(name = "testdb") %>% aRangodb::arango_graph(name = "testgraph")
    
    # when
    existingGraph <- existingGraph %>% aRangodb::define_edge("employee", "has", "skill")
    
    # then
    expect_false(is.null(existingGraph$getEdgeDefinitions()$has))
    expect_true("employee" %in% existingGraph$getEdgeDefinitions()$has)
    expect_true("skill" %in% existingGraph$getEdgeDefinitions()$has)
  })
})


with_mock_api({
  test_that("Addition of new collections to an existing relation works correctly", {
    # given
    
    # when
    # TODO: it works, but there is a bit to work to prepare the mock responses. The test is the following:
    #existingGraph <- existingGraph %>% 
    #                 aRangodb::define_edge("employee", "has", "skill")
    #                 aRangodb::define_edge("skill", "has", "requirement")
    
    # then

  })
})



with_mock_api({
  test_that("Addition of new collections to an existing relation works correctly", {
    # given
    
    # when
    # TODO: it works, but there is a bit to work to prepare the mock responses. The test is the following:
    #existingGraph <- existingGraph %>% 
    #                 aRangodb::define_edge("employee", "has", "skill")
    #                 aRangodb::define_edge("skill", "has", "requirement")
    
    # then
    
  })
})


with_mock_api({
  test_that("Addition of new collections to an existing relation works correctly", {
    # given
    
    # when
    # TODO: tests on relational operators %->% and %<-%, same work of the previous test
    #existingGraph <- existingGraph %>% 
    #                 aRangodb::define_edge("employee", "has", "skill")
    #                 aRangodb::define_edge("skill", "has", "requirement")
    
    # then
    
  })
})


with_mock_api({
  test_that("Deletion of an existing graph works correctly", {
    # given
    existingGraph <- aRangodb::arango_connection("localhost", "1234", "gabriele", "123456") %>% 
      aRangodb::arango_database(name = "testdb") %>% aRangodb::arango_graph(name = "testgraph")
    
    # when
    deleted <- existingGraph %>% aRangodb::drop()
    
    # then
    expect_true(deleted)
  })
})