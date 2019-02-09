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

#### Connection to ArangoDB server

Connect to an ArangoDB server up and running

```R
arangoConnection <- connect(<instance_ip>, <instance_port>)
```

#### Create or connect to one database

Create a sandbox database: to force creation of a database, if it is not found, use the 
__createOnFail__ option (default is FALSE):

```R
sandboxArangoDb <- arangoConnection %>% 
  database("sandbox", createOnFail = TRUE)
```

To use the default database (**DISCOURAGED**) you can do:

```R
defaultArangoDb <- arangoConnection %>% 
  database()
```

The object that those methods return is an instance of ArangoDatabase class and it will be used for all the operations affecting the database.