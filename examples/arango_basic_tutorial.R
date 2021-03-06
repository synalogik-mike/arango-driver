library(aRangodb)

# Connect to an ArangoDB server up and running
arangoConnection <- arango_connection(<server>, <port>, <username>, <password>)

# If you want to delete the existing database to have a clear environment
sandboxArangoDb <- arangoConnection %>% arango_database("sandbox")
if(!is.null(sandboxArangoDb)){
  sandboxArangoDb %>% drop()
}

# Create a sandbox database: if you already have one you can use it for this example
sandboxArangoDb <- arangoConnection %>% arango_database("sandbox", createOnFail = TRUE)

# From now on all the collections, documents and graphs will be manipulated within "sandbox"
# (or the db you had choosen): this means that collections, documents, and graphs will be visible
# and available from this DB.
# Now create the "person" and "city" collections:
persons <- sandboxArangoDb %>% arango_collection("person", createOnFail = TRUE)
cities <- sandboxArangoDb %>% arango_collection("city", createOnFail = TRUE)

# Now we have two different collections: we can populate with some fake data for subsequent examples
persons %>% 
  document_insert(key = "john.doe") %>% 
  document_set(age=30, birthday="17/01/1989") %>% 
  collection_update()

persons %>% 
  document_insert("alice.foo") %>% 
  document_set(age=36, birthday="07/02/1983", graduated = TRUE) %>% 
  collection_update()

persons %>% 
  document_insert("brandon.fee") %>% 
  document_set(age=36, birthday="03/11/1983", jobTitle="Software Developer") %>% 
  collection_update()

persons %>% 
  document_insert("charlie.foo") %>% 
  document_set(age=34, birthday="03/02/1985") %>% 
  collection_update()

cities %>% 
  document_insert("London") %>% 
  document_set(position=list(latitude=51.5098, longitude=-2.0122), capital=TRUE, country="UK") %>% 
  collection_update()

cities %>% 
  document_insert("Manchester") %>% 
  document_set(position=list(latitude=53.4839, longitude=-2.2446), capital=FALSE, country="UK") %>% 
  collection_update()

# You can use the collection to access some useful information about the collection itself...
print(paste("Persons registered:", persons$getCount(), sep = " "))

# ... or you can use it to retrieve documents within the collection. For example you can get ALL the
# document from a given collection (BE CAREFUL, collections could contains hundred of results) and access
# specific document using its key
all.cities <- cities %>% all_documents()
all.persons <- persons %>% all_documents()

if(all.cities$London$getValues()$capital){
  print("London is still the capital of UK")
} else {
  print("What's happening there???")
}

# Using a collection object you can filter out documents that match some conditions. To express values
# greater or less than some condition to be matched use operators %lt%, %gt%, %leq%, %geq%.
# Next lines will be translated as "ehy, give me all cities of UK over latitude 52.0"
filtered.cities <- cities %>% collection_filter(country="UK", position.latitude %gt% 52.0)

if(is.null(filtered.cities$Manchester)){
  print("Ehy, who moved away Manchester??") # Could be very bad
}

if(!is.null(filtered.cities$London)){
  print("Ehy, who moved away London??") # Could be very bad
}

# If you are interested in custom queries you can use the native Arango Query Language (AQL). To do that
# you need to specify the string containing the query using the @variable_name to indicate some binding
# variables: the query will be parsed to check the syntax and then converted to an R function where binding
# variables are the formal parameters of the function.
# Do you want to get all the persons with age more than come threshold?
searchByAgeGreaterThen <- sandboxArangoDb %>% aql("FOR p IN person FILTER p.age > @age RETURN p")
filtered.persons <- searchByAgeGreaterThen(age = 30)

# Using an AQL-From function the results are in JSON (so in R in list) form:
if(length(filtered.persons) != 3){
  print("Did you change something?")
}

# Last but not least, you can define a graph structure in the same way you can define a collection.
residenceGraph <- sandboxArangoDb %>% arango_graph("residence", createOnFail = TRUE)

# If you created the graph from scratch, as in this case, you can add the definitions of possible edges
# that the graph can store. Adding an edge will automatically adds the collections to the graph as possible
# sources of edges, and it will creates a collection for the edge relation
residenceGraph <- 
  residenceGraph %>% 
  define_edge("person", "lives_in", "city") %>%
  define_edge("person", "loves", "city")

livesInCollection <- sandboxArangoDb %>% arango_collection("lives_in")

if(!(is.null(livesInCollection))){
  print(paste0("'Voilà, I'm an edge collection, isn't it?' ", 
               "'",livesInCollection$getType() == collection_type$EDGE,"'"))
}

# Also collections will be automatically created if not in the collection set
residenceGraph <- residenceGraph %>% define_edge(cities, "had_weather", "weather")
weatherCollection <- sandboxArangoDb %>% arango_collection("weather")

if(!(is.null(weatherCollection))){
  print(paste0("'Voilà, I'm a document collection, isn't it?' ", 
               "'",weatherCollection$getType() == collection_type$DOCUMENT,"'"))
}

# But a graph isn't useful if you cannot populate with relations. Just use the add_edges method and
# the relational operators!
residenceGraph <- residenceGraph %>%
  add_edges("lives_in" %owns% edge(all.persons$john.doe %->% all.cities$London)) %>%
  add_edges("loves" %owns% edge(all.persons$john.doe %->% all.cities$London)) %>%
  add_edges("lives_in" %owns% edge(all.persons$brandon.fee %->% all.cities$Manchester, since="09/01/2016"))

# Now I want to remove some edge in a similar way I did for adding
residenceGraph <- residenceGraph %>%
  remove_edges("loves" %owns% edge(all.persons$john.doe %->% all.cities$London))

# The edge is not more present in the graph
lovesCollection <- sandboxArangoDb %>% arango_collection("loves")

if(is.null(lovesCollection %>% find_edge(all.persons$john.doe, all.cities$London))){
  print("Ok, the edge has been removed!")
} else {
  print("Very very bad!")
}

# Retrieve the entire graph
all.residence <- residenceGraph %>% all_graph()

# Now you can also try to find the subgraph centered in London
london.center <- residenceGraph %>% 
  traversal(verticies = c(all.cities$London), depth = 2)