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

dbx_labelling() {
  cat > $1 << EOL
CALL apoc.periodic.iterate(
  "MATCH (y:$2) --> (x:$2) WITH x, count(distinct y) as rels WHERE rels >= 40 RETURN x",
  "SET x:$3",
  {batchSize:${BATCH_SIZE}, parallel:true}
)
EOL
}

db25k_labelling() {
  cat > $1 << EOL
CALL {
  LOAD CSV FROM 'file:///sampling/dbpedia25k/nodes_DB1M_0.csv' AS row
  WITH row[0] as nodeID
  RETURN nodeID
  UNION 
  LOAD CSV FROM 'file:///sampling/dbpedia25k/nodes_DB1M_1.csv' AS row
  WITH row[0] as nodeID
  RETURN nodeID
  UNION 
  LOAD CSV FROM 'file:///sampling/dbpedia25k/nodes_DB1M_2.csv' AS row
  WITH row[0] as nodeID
  RETURN nodeID
}
MATCH (x:DB1M)
WHERE id(x) = toInteger(nodeID)
SET x:DB25k
RETURN nodeID
EOL
}

rm_0nodes() {
  cat > $1 << EOL
CALL apoc.periodic.iterate(
  "MATCH (x:$2) WITH x, size((x)-->(:$2)) as outDegree, size((:$2)-->(x)) as inDegree WHERE outDegree = 0 and inDegree = 0 RETURN x",
  "REMOVE x:$2",
  {batchSize:${BATCH_SIZE}, parallel:true}
)
EOL
}

METHOD=$1
USER=${2:-neo4j}
PASSWORD=${3:-neo4j}

echo ">($METHOD)> Started to label nodes."

QUERY_FILE=$(mktemp)

echo ">($METHOD)> Labelling query was sent to Neo4J."
if [ "$METHOD" = "dbi" ]; then
  dbi_labelling $QUERY_FILE
  cypher-shell --file $QUERY_FILE --user "$USER" --password "$PASSWORD"
elif [ "$METHOD" = "db1m" ]; then
  dbx_labelling $QUERY_FILE "DBI" "DB1M"
  cypher-shell --file $QUERY_FILE --user "$USER" --password "$PASSWORD"
  rm_0nodes $QUERY_FILE "DB1M"
  cypher-shell --file $QUERY_FILE --user "$USER" --password "$PASSWORD"
elif [ "$METHOD" = "db250k" ]; then
  dbx_labelling $QUERY_FILE "DB1M" "DB250k"
  cypher-shell --file $QUERY_FILE --user "$USER" --password "$PASSWORD"
  rm_0nodes $QUERY_FILE "DB250k"
  cypher-shell --file $QUERY_FILE --user "$USER" --password "$PASSWORD"
elif [ "$METHOD" = "db25k" ]; then
  db25k_labelling $QUERY_FILE
  cypher-shell --file $QUERY_FILE --user "$USER" --password "$PASSWORD"
else
  echo "unknown method '$METHOD' specified."
  exit 1
fi
echo ">($METHOD)> Finished labelling of nodes."

rm -rf $QUERY_FILE