# DBpedia KG in Neo4J

This repository provides simple utilities to populate a Neo4J graph database
instance with a certain version of the [DBpedia](https://www.dbpedia.org/) KG
using the [neosemantics (n10s)](https://neo4j.com/labs/neosemantics/) plugin.
Loading the complete DBpedia KG into Neo4J might take hours depending on your
hardware, however.

```cypher
MATCH (x:DBI) -[p]-> (y:DBI)
WHERE x.uri = "http://dbpedia.org/resource/Capybara"
RETURN x, p, y
```

All nodes are labelled with `Resource` by neosemantics. Additionally, all nodes
that have a URI/IRI starting with `http://dbpedia.org/` are labelled with `DBI`.

## Download Dump

The DBpedia Core (latest core) collection can be downloaded from the DBpedia
databus with the following script. If no argument is specified, then the
latest dump is downloaded, otherwise the specified dump date (e.g. 2022-03-01).

The **requirements** for the script are:
* bzip2
* gzip
* wget & curl

```bash
./get-dbpedia-dump [<dump-version>]
```

All artifacts are downloaded from the latest-core collection, except for:
* **homepages** from **generic** dataset
* **article-template** from **generic** dataset
* **freebase-links** from **transition** dataset
* **links** from **transition** dataset
* all artifacts from **yago** dataset
* all artifacts from the **replaced-iris** dataset

Additionally, the following artifacts are added to the collection:
* **wikilinks** from **generic** dataset
* **images** from **generic** dataset

The exact SPARQL query for gathering can be found at [query/data.query](query/data.query).

## Running

```bash
docker-compose up
```

## Contact

* Kevin Haller - [contact@kevinhaller.dev](contact@kevinhaller.dev)