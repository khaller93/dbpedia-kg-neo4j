#!/bin/sh
set -x
set -e

BATCH_SIZE=100000

dbi_labelling() {
  cat > $1 << EOL
CALL apoc.periodic.iterate(
  "MATCH (x:Resource) WHERE x.uri STARTS WITH 'http://dbpedia.org' RETURN x",
  "SET x:DBI",
  {batchSize:${BATCH_SIZE}, parallel:true}
)
EOL
}

db1m_labelling() {
  cat > $1 << EOL
CALL apoc.periodic.iterate(
  "MATCH (y:DBI)-->(x:DBI) WITH x, count(distinct y) as rels WHERE rels >= 40 RETURN x",
  "SET x:DB1M",
  {batchSize:${BATCH_SIZE}, parallel:true}
)
EOL
}

db500k_labelling() {
  cat > $1 << EOL
CALL apoc.periodic.iterate(
  "MATCH (y:DB1M) --> (x:DB1M) WITH x, count(distinct y) as rels WHERE rels >= 20 RETURN x",
  "SET x:DB500k",
  {batchSize:${BATCH_SIZE}, parallel:true}
)
EOL
}

METHOD=$1
USER=${2:-neo4j}
PASSWORD=${3:-neo4j}

echo ">($METHOD)> Started to label nodes."

QUERY_FILE=$(mktemp)

if [ "$METHOD" = "dbi" ]; then
  dbi_labelling $QUERY_FILE
elif [ "$METHOD" = "db1m" ]; then
  db1m_labelling $QUERY_FILE
elif [ "$METHOD" = "db500k" ]; then
  db500k_labelling $QUERY_FILE
else
  echo "unknown method '$METHOD' specified."
  exit 1
fi

echo ">($METHOD)> Labelling query was sent to Neo4J."
cypher-shell --file $QUERY_FILE --user "$USER" --password "$PASSWORD"

echo ">($METHOD)> Finished labelling of nodes."
rm -rf $QUERY_FILE