# aRangodb - R driver for ArangoDB

## Table of Contents
1. [ Introduction. ](#introduction)
1. [ Prerequisite. ](#prerequisite)
    * [ Setup with Docker. ](#docker)
    * [ Setup with installer. ](#installer)
1. [ ArangoDB basic concepts. ](#arangoconcepts)
1. [ Install the package. ](#installation)
1. [ Usage examples. ](#usage)
    * [ Connection to ArangoDB server. ](#connectarango)
    * [ Create or connect to a database. ](#connectdatabase)
    * [ Create or load a collection. ](#createcollection)
    * [ Insertion of documents into a collection. ](#insertcollection)
    * [ Working with documents. ](#workingdocuments)
    * [ Custom AQL queries. ](#aqlcustom)
    * [ Working with graphs. ](#workinggrapphs)
1. [ Functions and classes summary. ](#summary)
1. [ Bugs and known limitations. ](#bugslimitations)
1. [ Roadmap. ](#roadmap)


## Introduction <a name="introduction"></a>
Relational databases are one of the most known technology developed and studied in the computer science field. Every application, or at least the majority of them, have one relational database to support the storage and the retrieval of data.
Most of those technologies are also freely available as open-source projects, e.g. MySQL and PostgreSQL, and this made this techonolgy one of the most reliable in the data management task.
Nonetheless those kind of databases have some drawback that for actual applications represent limitations and/or significant bottleneck for scalability or refactor of the applications themselves. For example the base elements are represented by the **relations**, i.e. tables containing set of records with fixed schema and types.
The explosion of Big Data era and the quick availability of highly scalable techonologies, architectures and infrastructure made the management of data complex to manage.
TODO: to be completeds here
In this context has been developed lots of NoSQL data managment systems: notable examples are MongoDB, for document oriented databases, or Neo4J, OrientDB and ArangoDB for graph databases.

Link to other projects:

* **neo4r** Active project (too complex): https://cran.r-project.org/web/packages/neo4r/index.html
* **orientR** project (simple connector): https://github.com/retrography/OrientR

## Prerequisite <a name="prerequisite"></a>
It is possible install ArangoDB both downloading the usual installer and have a stand-alone instance, or installing it by creating a Docker container using the official ArangoDB Docker image.

**IMPORTANT NOTE:** since this is still a prototype it is not yet supported the management of the user. This means that each installation you choose must disable security. This is a knonw limitation that will be removed as the first stable version will be released.

#### Setup with Docker <a name="docker"></a>
To setup an ArangoDB instance using Docker you can [follow those instructions](https://docs.arangodb.com/3.4/Manual/Deployment/SingleInstance/ManualStart.html#manual-start-in-docker).

#### Setup from installer <a name="installer"></a>
To setup an ArangoDB instance using the stand-alone version you can [follow those instructions](https://docs.arangodb.com/3.4/Manual/GettingStarted/Installation.html).

## ArangoDB basic concepts <a name="arangoconcepts"></a>
In order to understand the examples in the next sections it is desirable understand some basic concepts of the behaving and logic of ArangoDB. Each instance of an ArangoDB server can store multiple databases: even if you don't create any database, there is the default one named **\_system**. Every operation you invoke that is invoked with no database specified affects the **\_system** one. It is suggested to not use this database for applications.

####References

* **Quick introduction** https://docs.arangodb.com/3.4/Manual/GettingStarted/DatabasesCollectionsDocuments.html
* **Core Concepts** https://docs.arangodb.com/3.4/Manual/DataModeling/
* **AQL** https://docs.arangodb.com/3.4/AQL/

## Install the package <a name="installation"></a>
To install the aRangodb package you can run the following commands.

```R
devtools::install_gitlab("ggalatolo/arango-driver")
library(aRangodb)
```

## Usage examples <a name="usage"></a>
In the following sections are shown usage's examples of this driver. The conmplete example, as R script, is located into the repository at the path "examples/arango_full_example.R".
Once installed you have to load the library:

```R
library(aRangodb)
```

### Connection to ArangoDB server <a name="connectarango"></a>
 
Connect to an ArangoDB server up and running

```R
arangoConnection <- connect(<instance_ip>, <instance_port>)
```

### Create or connect to a database <a name="connectdatabase"></a>

Create a sandbox database: to force creation of a database, if it is not found, use the 
_createOnFail_ option (default is FALSE):

```R
sandboxArangoDb <- 
  arangoConnection %>% 
  database("sandbox", createOnFail = TRUE)
```

To use the default database (**DISCOURAGED**) you can do:

```R
defaultArangoDb <- 
  arangoConnection %>% 
  database()
```

The object that those methods return is an instance of ArangoDatabase class and it will be used for all the operations affecting the database.

### Create or load a collection <a name="createcollection"></a>

From now on all the collections, documents and graphs will be manipulated within "sandbox"
(or the db you had choosen): this means that collections, documents, and graphs will be visible
and available from this DB.
Now create the "person" and "city" collections:

```R
persons <- sandboxArangoDb %>% collection("person", createOnFail = TRUE)
cities <- sandboxArangoDb %>% collection("city", createOnFail = TRUE)
```

Again it has been used the option _createOnFail_ to create the collections if they were not found into the database. The call otherwise would launch an error (collection not found).

### Insertion of documents into a collection <a name="insertcollection"></a>

Now we have two different collections: we can populate with some fake data for subsequent examples using the aRangodb::insert(key) to create a new document with the given key as identifier, and setting its values using the aRangodb::set() function. The insertion, and the values' updates, are effective once invoked the aRangodb::execute() function. It could be a limitation, but for synchronous (and immediate) call there will be a dedicated release of the driver.

```R
persons %>% 
  insert("john.doe") %>% 
  set(age=30, birthday="17/01/1989") %>% 
  execute()

persons %>% 
  insert("alice.foo") %>% 
  set(age=36, birthday="07/02/1983", graduated = TRUE) %>% 
  execute()

persons %>% 
  insert("brandon.fee") %>% 
  set(age=36, birthday="03/11/1983", jobTitle="Software Developer") %>% 
  execute()

persons %>% 
  insert("charlie.foo") %>% 
  set(age=34, birthday="03/02/1985") %>% 
  execute()

cities %>% 
  insert("London") %>% 
  set(position=list(latitude=51.5098, longitude=-2.0122), capital=TRUE, country="UK") %>% 
  execute()

cities %>% 
  insert("Manchester") %>% 
  set(position=list(latitude=53.4839, longitude=-2.2446), capital=FALSE, country="UK") %>% 
  execute()
```

You can use the collection to access some useful information about the collection itself, for example using the getCount() method.

```R
print(paste("Persons registered:", persons$getCount(), sep = " "))
```

### Working with documents <a name="workingdocuments"></a>

You can use collections to retrieve and access documents within the collection itself. For example you can get ALL the document of a collection (**BE CAREFUL**, collections could contains hundred of results) and access specific document using its key. The aRango::documents() return a list with all the documents found for the given collection.

```R
all.cities <- cities %>% documents()
all.persons <- persons %>% documents()

if(all.cities$London$getValues()$capital){
  print("London is still the capital of UK")
} else {
  print("What's happening there???")
}
```

Each document is an object belonging to the ArangoDocument class: every instance expose the following methods:

* getAvailableValues(), returns a vector of properties for which the document has a valid value (not null)
* getValues(), returns the list of pairs key-value for which exist a not-null mapping


Using a collection object you can filter out documents that match some conditions. To express values
greater or less than some condition to be matched use operators %lt%, %gt%, %leq%, %geq%. Next lines will be translated as _"ehy, give me all cities of UK over latitude 52.0"_

```R
filtered.cities <- cities %>% filter(country="UK", position.latitude %gt% 52.0)

if(is.null(filtered.cities$Manchester)){
  print("Ehy, who moved away Manchester??") # Could be very bad
}

if(!is.null(filtered.cities$London)){
  print("Ehy, who moved away London??") # Could be very bad
}
```

You can use the aRangodb::set() or aRangodb::unset() methods to insert/update or remove an attribute from a document. For example, the following code shown an insertion, followed by an update and an unset.

```R
Lyon <- cities %>% 
  insert("Lyon") %>% 
  set(capital=FALSE, country="Fran") %>%    # wrong insertion
  execute()
  
Lyon %>%
  set(country="France") %>%                 # update
  execute()
  
Lyon %>%
  unset(capital) %>%                        # no more important
  execute()
```

### Custom AQL queries <a name="aqlcustom"></a>
If you are interested in custom queries you can use the native Arango Query Language (AQL). To do that
you need to specify the string containing the query using the \@variable_name to indicate some binding
variables: the query will be parsed to check the syntax and then converted to an R function where binding variables are the formal parameters of the function.
Do you want to get all the persons with age more than come threshold?

```R
searchByAgeGreaterThen <- 
  sandboxArangoDb %>% 
  aql("FOR p IN person FILTER p.age > @age RETURN p")
```

The previous commands affect the current environment by adding a new function, named _searchByAgeGreaterThan_, where formal parameters are the ones corresponding to the variables left unbind in the AQL query, in this case _age_. Before returning a function, the aRango::aql() command execute the parsing of the query, so that syntax error will be highlighted as error. 
In conclusion from now on you can now execute the query as normal R function:

```R
filtered.persons <- searchByAgeGreaterThen(age = 30)
```

The results of those functions calls are returned as list, where each result has an automatically generated id within the list (up to now doc<n>, but it can change before the first stable release)

```R
if(length(filtered.persons) != 3){
  print("Did you change something?")
}

print(paste0("'I'm Alice Foo, isn't it?' ", filtered.persons$doc0$getKey() == "alice.foo"))
```

### Working with graphs <a name="workinggrapphs"></a>
Last but not least, you can define a graph structure in the same way you can define a collection.

```R
residenceGraph <- 
  sandboxArangoDb %>% 
  graph("residence", createOnFail = TRUE)
```

If you created the graph from scratch, as in this case, you can add the definitions of possible edges
that the graph can store. Adding an edge will automatically adds the collections to the graph as possible sources of edges, and it will creates a collection for the edge relation

```R
residenceGraph <- 
  residenceGraph %>% 
  edge_definition("person", "lives_in", "city")

livesInCollection <- 
  sandboxArangoDb %>% 
  collection("lives_in")

if(!(is.null(livesInCollection))){
  print(paste0("'Voilà, I'm an edge collection, isn't it?' ", 
               "'",livesInCollection$getType() == collection_type$EDGE,"'"))
}
```

Also collections will be automatically created if not in the collection set:

```R
residenceGraph <- 
  residenceGraph %>% 
  edge_definition(cities, "had_weather", "weather")
  
weatherCollection <- 
  sandboxArangoDb %>% 
  collection("weather")

if(!(is.null(weatherCollection))){
  print(paste0("'Voilà, I'm a document collection, isn't it?' ", 
               "'",weatherCollection$getType() == collection_type$DOCUMENT,"'"))
}
```

But a graph isn't useful if you cannot populate with relations. Just use the aRangodb::add_to_graph() method and the relational operators!

```R
residenceGraph <- 
  residenceGraph %>%
  add_to_graph("lives_in" %owns% edge(all.persons$john.doe %->% all.cities$London)) %>%
  add_to_graph("lives_in" %owns% edge(all.persons$brandon.fee %->% all.cities$Manchester, since="09/01/2016"))
```

### Visualize graphs <a name="visualizegrapphs"></a>



### Functions and Class Summary <a name="summary"></a>

Create a connection with an ArangoDB instance.

```R
ArangoConnection <- aRango::connect(server, port)
```

Returns a list with the name of all the available databases for this ArangoDB instance

```R
character_vector <- ArangoConnection %>% aRango::databases()
```

Return an object representing the database with the given name, create a database with the given name (if not exist), or the default database.

```R
ArangoDatabase <- ArangoConnection %>% aRango::database(name)
ArangoDatabase <- ArangoConnection %>% aRango::database(name, createOnFail=TRUE)
ArangoDatabase <- ArangoConnection %>% aRango::database()
```

The given database is deleted from the server.

```R
bool <- ArangoDatabase %>% aRango::drop()
```

Returns a list with all the available collections for the given database

```R
character_vector <- ArangoDatabase %>% aRango::collections()
```

Return an object representing the collection with the given name or create a collection with the given name (if not exist).

```R
ArangoCollection <- ArangoDatabase %>% aRango::collection(name, createOnFail=FALSE)
ArangoCollection <- ArangoDatabase %>% aRango::collection(name)
```

The given collection is deleted from the server.

```R
bool <- collection %>% aRango::drop()
```

Returns a list with all the documents belonging to the given collection

```R
list<ArangoDocument> <- ArangoCollection %>% aRango::documents()
```

Returns a list with all the documents belonging to the given collection

```R
list<ArangoDocument> <- ArangoCollection %>% aRango::documents()
```
Methods for document management: insert a new document, with custom key, set the attributes of the document, remove the mapping for the given keys, delete a document and execute the pending modifies to a document.

```R
ArangoDocument <- ArangoCollection %>% aRango::insert(key)
ArangoDocument <- ArangoDocument %>% aRango::set(...)
ArangoDocument <- ArangoDocument %>% aRango::unset(...)
ArangoDocument <- ArangoDocument %>% aRango::delete()
ArangoDocument <- ArangoDocument %>% aRango::execute()
```

Returns the documents that matches the given filters. The filters passed as parameters are converted in strings that will be added in the query. So assigments are converted into equality filter, a=1 in "a==1", for **comparison operators you MUST USE** the following operators:  

* id %lt% expr: "id < value"
* id %leq% expr: "id <= value"
* id %gt% expr : "id > value"
* id %geq% expr : "id >= value"

```R
character <- id %lt% expr
character <- id %leq% expr
character <- id %gt% expr
character <- id %geq% expr
list<ArangoDocument> <- ArangoCollection %>% aRango::filter(...)
```

Returns a list with all the available graphs for the given database

```R
character_vector <- ArangoDatabase %>% aRango::graphs()
```

Returns a list with all the available graphs for the given database

```R
ArangoGraph <- ArangoDatabase %>% aRango::graph(name, createOnFail=FALSE)
ArangoGraph <- ArangoDatabase %>% aRango::graph(name)
```

Adds a definition of a new edge for the given graph

```R
ArangoGraph <- ArangoGraph %>% aRangodb::edge_definition(fromCollection, relation, toCollection)
```

Adds and removes of edge. Input of the folloqing functions are list of list, where each inner list contains the information
representing the edge: e.g. list(list(collection="friends", edge=list(`_from`="person/bob", `_to`="person/alice", ...))...)

```R
ArangoGraph <- ArangoGraph %>% add_to_graph(...)      # takes a list of list representing edges definitions
ArangoGraph <- ArangoGraph %>% remove_from_graph(...) # takes a list of list representing edges definitions
```

To simplify the process of addition/removal of edges you can use the relationa operators for inbound edges %<-% or outbound edges %->%, aRangodb::edge() function and the %owns% relation.

```R
list <- ArangoDocument %->% ArangoDocument            # returns a list(`_from`=..., `_to`=...) 
list <- character %owns% edge(list, ...)              # returns a list containing the from/to information, the collection name representing the edge and the values (if any) for this edge
```

The previous functions work as:

```R
doc1 %->% doc2  # returns a list(`_from`=doc1$getId(), `_to`=doc1$getId())
```

```R
edge(doc1 %->% doc2, ...)   # where the variadic part can be assignments representing values of the edge. This call returns list(`_from`=doc1$getId(), `_to`=doc1$getId(), aKey=1)
```

```R
character %owns% edge(doc1 %->% doc2)   # returns list(list(collection=character, edge=list(`_from`=doc1$getId(), `_to`=doc1$getId())))
```

Find an existing edge, where the ArangoCollection represents a collection_type$EDGE:

```R
ArangoDocument <- ArangoCollection %>% find_edge(from=<ArangoDocument>, to=<ArangoDocument>)
```

### Bugs and Knonw Limitations <a name="bugslimitations"></a>
The following is an uncomplete list of known limitations to be addressed in the next versions:

* **user management is disabled**, in this prototipal state every operation is done with security options disabled on the server. Probably this will added in the version __0.0.1-beta__

* **partial graph traversal**, it is not natively provided by the aRangodb::traversal() function the possibility to filter some vertex, edge or path using the FILTER AQL clause. In order to do that you have to define a custom aRangodb::aql() function, but this will not return you a graph: this because aql() returns generic results from the server.

### Roadmap <a name="roadmap"></a>
The following is an uncomplete frequently-updated list to recap the major features in plan for the next versions.

* Version **0.0.1-beta**:
    * User management functions

* Version **0.0.1**:
    * First release of the package

* Version **0.1.0**:
    * first stable release with major bug fixing 
    * complete unit tests coverage

* Version **0.2.0**:
    * bulk insertion of JSON files
    * bulk insertion of CSV files
    * bulk export of graphs/collection in JSON files
    * bulk export of graphs/collection in CSV files
    
* Version **0.3.0**:
    * support for basic algorithms on graphs
    
* ...