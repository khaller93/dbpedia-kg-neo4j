# DBpedia KG in Neo4J

This repository provides simple utilities to populate a Neo4J graph database
instance with a certain version of the [DBpedia](https://www.dbpedia.org/) KG
using the [neosemantics (n10s)](https://neo4j.com/labs/neosemantics/) plugin.

```cypher
MATCH (x:DBI) -[p]-> (y:DBI)
WHERE x.uri = "http://dbpedia.org/resource/Capybara"
RETURN x, p, y
```

All nodes are labelled with `Resource` by neosemantics. Additionally, all nodes
that have a URI/IRI starting with `http://dbpedia.org/` are labelled with `DBI`.

## Download Dump

The DBpedia Core (latest core) collection is downloaded from the DBpedia databus
with the following command. If no argument is specified, then the latest dump is
downloaded, otherwise the specified dump date (e.g. 2022-03-01).

```bash
./get-dbpedia-dump [<dump-version>]
```

All artifacts are downloaded except:
* **freebase-links** from **transition** dataset
* **links** from **transition** dataset
* all artifacts from **yago** dataset
* all artifacts from the **replaced-iris** dataset

The exact SPARQL query for gathering can be found at [query/data.query](query/data.query).

## Running

```bash
docker-compose up
```

## Contact

* Kevin Haller - [contact@kevinhaller.dev](contact@kevinhaller.dev)