# aRangodb - R driver for ArangoDB

## Introduction
Relational databases are one of the most known technology developed and studied in the computer science field. Every application, or at least the majority of them, have one relational database to support the storage and the retrieval of data.
Most of those technologies are also freely available as open-source projects, e.g. MySQL and PostgreSQL, and this made this techonolgy one of the most reliable in the data management task.
Nonetheless those kind of databases have some drawback that for actual applications represent limitations and/or significant bottleneck for scalability or refactor of the applications themselves. For example the base elements are represented by the **relations**, i.e. tables containing set of records with fixed schema and types.
The explosion of Big Data era and the quick availability of highly scalable techonologies, architectures and infrastructure made the management of data complex to manage.
The contemporary interest of the scientific community to find alternatives way to manage data had left... TO BE COMPLETED...

## Prerequisite

It is possible install ArangoDB both downloading the usual installer and have a stand-alone instance, or installing it by creating a Docker container using the official ArangoDB Docker image.

**IMPORTANT NOTE:** since this is still a prototype it is not yet supported the management of the user. This means that each installation you choose must disable security. This is a knonw limitation that will be removed as the first stable version will be released.

### Setup with Docker
Explain setup with Docker

### Setup from installer
Explain setup with classical installer

## ArangoDB basic concepts
In order to understand the examples in the next sections it is desirable understand some basic concepts of the behaving and logic of ArangoDB. Each instance of an ArangoDB server can store multiple databases: even if you don't create any database, there is the default one named **\_system**. Every operation you invoke that is invoked with no database specified affects the **\_system** one. It is suggested to not use this database for applications.

## Install the package
Explain how to install the package from GitHub

## Usage
In the following sections are shown usage's examples of this driver. The conmplete example, as R script, is located into the repository at the path "examples/arango_full_example.R".
Once installed you have to load the library:

```R
library(aRangodb)
```

### Connection to ArangoDB server

Connect to an ArangoDB server up and running

```R
arangoConnection <- connect(<instance_ip>, <instance_port>)
```

### Create or connect to one database

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

### Create or load a collection

From now on all the collections, documents and graphs will be manipulated within "sandbox"
(or the db you had choosen): this means that collections, documents, and graphs will be visible
and available from this DB.
Now create the "person" and "city" collections:

```R
persons <- sandboxArangoDb %>% collection("person", createOnFail = TRUE)
cities <- sandboxArangoDb %>% collection("city", createOnFail = TRUE)
```

Again it has been used the option _createOnFail_ to create the collections if they were not found into the database. The call otherwise would launch an error (collection not found).

### Insertion of documents within a collection

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

### Working with documents

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

### Custom AQL queries
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

The results of those functions calls are returned as list, where each result has an automatically generated id within the list (up to now queryResult_<n>, but it can change before the first stable release)

```R
if(length(filtered.persons) != 3){
  print("Did you change something?")
}

print(paste0("'I'm Alice Foo, isn't it?' ", filtered.persons$queryResult_0$getKey() == "alice.foo"))
```

### Creating a graph