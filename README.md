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

## Running

Firstly, the script `get-dbpedia-dump` has to be executed as described below.
When the dump has been successfully downloaded, then the following command can
be used to start the import of DBpedia KG into Neo4J. This startup process can
take up to hours or days depending on your hardware. After the import, a Neo4J
instance is quickly started.

```bash
docker-compose up
```

## Sampling Methodology

### 1. Download Dump (2022.09.01)

The DBpedia Core (latest core) collection can be downloaded from the DBpedia
databus with the following script. If no argument is specified, then the
latest dump is downloaded, otherwise the specified dump date (e.g. 2022.09.01).

The **requirements** for the script are:
* bzip2
* gzip
* wget & curl

```bash
./get-dbpedia-dump 2022.09.01
```

All artifacts are downloaded from the latest-core collection, except for:
* **homepages** from **generic** dataset
* **article-template** from **generic** dataset
* **freebase-links** from **transition** dataset
* **links** from **transition** dataset
* all artifacts from **yago** dataset
* all artifacts from the **replaced-iris** dataset

Additionally to the latest core collection, the following artifacts are added to
the collection:
* **wikilinks** from **generic** dataset
* **images** from **generic** dataset

The exact SPARQL query for gathering can be found at
[query/data.query](query/data.query).

### 2. Label DBpedia35M nodes (with `DBI`)

We label all nodes in the KG as `DBI`, if they have an URI/IRI starting
with`http://dbpedia.org`, and these resources will be the target of our
subsampling. All other resources are ignored. The **DBpedia35M** just contains
all resources labelled with `DBI`, and no further subsampling is performed. The
dataset then contains all triples between resources that have this label.

```cypher
MATCH (x:Resource)
WHERE x.uri STARTS WITH 'http://dbpedia.org'
RETURN x
```

**Statistics:**

| **#Entities** | **#Relationships** | **#Statements** |   **Density**          |
| ------------- | ------------------ | --------------- | ---------------------- |
| 35,159,871    | 13032              | 383,739,569     |  3,1 * 10<sup>-7</sup> |

In this KG, 66.20% of the relationsips are of type `dbo:wikiPageWikiLink`.

### 3. Label DBpedia1M nodes (with `DB1M`)

The **DBpedia1M** subsampling of DBpedia follows the methodology of 
**DBpedia100k**, but it increases the number of backlinks required by a resource
to 40 (instead of 20). The final dataset then contains all triples that are
between resources that fulfill this requirement.

```cypher
MATCH (y:DBI) -[p]-> (x:DBI)
WITH x, count(distinct y) as rels
WHERE rels >= 40
RETURN x
```

All resources with zero ingoing and outgoing relationships are removed from
this sampling.

```cypher
MATCH (x:DB1M)
WITH x, size((x)-->(:DB1M)) as outDegree, size((:DB1M)-->(x)) as inDegree
WHERE outDegree = 0 and inDegree = 0
RETURN x
```

#### Statistics

| **#Entities** | **#Relationships** | **#Statements** | **Density**            |
| ------------- | ------------------ | --------------- | ---------------------- |
| 940,535       | 7901               | 60,148,675      | 6,7 * 10<sup>-5</sup>  |


In this KG, 77.80% of the relationsips are of type `dbo:wikiPageWikiLink`.

### 4. Label DBpedia250k nodes (with `DB250k`)

The **DBpedia250k** subsampling of DBpedia follows the methodology of 
**DBpedia100k**, but it increases the number of backlinks required by a resource
to 40 (instead of 20), and applies it to the sampled **DBpedia1M** KG.

```cypher
MATCH (y:DB1M) -[p]-> (x:DB1M)
WITH x, count(distinct y) as rels
WHERE rels >= 40
RETURN x
```

All resources with zero ingoing and outgoing relationships are removed from this
sampling.

```cypher
MATCH (x:DB250k)
WITH x, size((x)-->(:DB250k)) as outDegree, size((:DB250k)-->(x)) as inDegree
WHERE outDegree = 0 and inDegree = 0
RETURN x
```

#### Statistics

| **#Entities** | **#Relationships** | **#Statements** | **Density**            |
| ------------- | ------------------ | --------------- | ---------------------- |
| 249,807       | 5506               | 21,089,884      | 3,38 * 10<sup>-4</sup> |

In this KG, 83.42% of the relationsips are of type `dbo:wikiPageWikiLink`.

### 5. Label DBA240 nodes (with `DBA240`)

The **DBA240** dataset aims to be a small subset of **DBpedia35M** for
hyper-parameter optimizations. We applied a modified version of the forest fire
sampling model, where the forest fire doesn’t start from a random point in the
graph, but from the 118 entities of the Atlasify240 dataset. We computed two
burning steps with a forward propagation of `0.00317`, and a backward ratio of 
`0.78`. Additionally, we introduced an increased weight of `3.67` for
`dbo:wikiPageWikiLink` relationships to sample a representative share of these
statements. ALl selected nodes are listed in the `sampling/dba240/nodes.tsv`
file.

```cypher
CALL {
  LOAD CSV FROM 'file:///sampling/dba240/nodes.tsv' AS row
  FIELDTERMINATOR '\t'
  WITH row[0] as uri
  RETURN uri
}
MATCH (x:DBI)
WHERE x.uri = uri
SET x:DBA240
RETURN uri
```

#### Statistics

| **#Entities** | **#Relationships** | **#Statements** | **Density**            |
| ------------- | ------------------ | --------------- | ---------------------- |
| 19,397        | 816                | 92,133          | $2.45 * 10^{-4}$       |


In this KG, 72.45% of the relationsips are of type `dbo:wikiPageWikiLink`.

## Contact

* Kevin Haller - [contact@kevinhaller.dev](contact@kevinhaller.dev)