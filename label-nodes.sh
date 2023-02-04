#!/bin/sh
set -x
set -e

USER=${1:-neo4j}
PASSWORD=${2:-neo4j}

echo "> Label all the nodes in the graph with DBI."

QUERY_FILE=$(mktemp)

BATCH_SIZE=100000

cat > $QUERY_FILE << EOL
MATCH (n)
WITH count(n) AS totalNodes

WITH range(0, totalNodes, ${BATCH_SIZE}) AS batchStarts
UNWIND batchStarts as batchStart

MATCH (x:Resource)
WHERE id(x) >= batchStart AND id(x) < batchStart + ${BATCH_SIZE} AND x.uri STARTS WITH 'http://dbpedia.org'
SET x:DBI
RETURN batchStart, (batchStart + ${BATCH_SIZE}) AS batchEnd
EOL

echo "> Labelling query was sent to Neo4J."
cypher-shell --file $QUERY_FILE --user "$USER" --password "$PASSWORD"

rm -rf $QUERY_FILE

echo "> Finished labelling of nodes."