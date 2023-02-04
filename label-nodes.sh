#!/bin/sh
set -x
set -e

USER=${1:-neo4j}
PASSWORD=${2:-neo4j}

echo "> Label all the nodes in the graph with DBI."

QUERY_FILE=$(mktemp)

BATCH_SIZE=100000

cat > $QUERY_FILE << EOL
CALL apoc.periodic.iterate(
  "MATCH (x:Resource) WHERE x.uri STARTS WITH 'http://dbpedia.org' RETURN x",
  "SET x:DBI",
  {batchSize:${BATCH_SIZE}, parallel:true}
)
EOL

echo "> Labelling query was sent to Neo4J."
cypher-shell --file $QUERY_FILE --user "$USER" --password "$PASSWORD"

rm -rf $QUERY_FILE

echo "> Finished labelling of nodes."