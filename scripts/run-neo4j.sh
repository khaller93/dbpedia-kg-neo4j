#!/bin/sh
set -x

cp /conf/neo4j.conf /var/lib/neo4j.conf

if [ ! -f "/data/init.lock" ]; then

    NEO4JLABS_PLUGINS="[\"apoc\", \"n10s\"]" NEO4J_AUTH="$INIT_AUTH" /startup/docker-entrypoint.sh neo4j &
    P="$!"

    ASK_QUERY="MATCH (n) RETURN n LIMIT 1"

    USER=$(echo "$INIT_AUTH" | cut -d "/" -f 1)
    PASSWORD=$(echo "$INIT_AUTH" | cut -d "/" -f 2)

    if [ ! -f "/conf/neo4j.conf" ]; then
        exit 1
    fi

    TEST="Connection refused"
    while [ "$TEST" = "Connection refused" ]
    do
        TEST=$(cypher-shell "${ASK_QUERY}" --user "$USER" --password "$PASSWORD" 2>&1)
        sleep 5s
    done

    echo "---- Initialize DBPedia KG ----"
    cypher-shell "CALL n10s.graphconfig.init($(cat /conf/graph-neo4j.conf))" --user "$USER" --password "$PASSWORD"
    cypher-shell "CREATE CONSTRAINT n10s_unique_uri FOR (r:Resource) REQUIRE r.uri IS UNIQUE" --user "$USER" --password "$PASSWORD"
    cd /ontology
    for f in *.nt; do
        cypher-shell "CALL n10s.rdf.import.fetch('file:///ontology/${f}','N-Triples', { verifyUriSyntax: false, languageFilter: 'en' })" --user "$USER" --password "$PASSWORD"
    done
    cd /dump
    for f in *.ttl; do
        cypher-shell "CALL n10s.rdf.import.fetch('file:///dump/${f}','Turtle', { verifyUriSyntax: false, languageFilter: 'en' })" --user "$USER" --password "$PASSWORD"
    done
    echo "label the nodes in DBPedia KG"
    label-nodes dbi "$USER" "$PASSWORD"
    label-nodes db1m "$USER" "$PASSWORD"
    echo "Index the nodes in DBPedia KG"
    index-nodes "DBI" "$USER" "$PASSWORD"
    index-nodes "DB1M" "$USER" "$PASSWORD"
    echo "---- End DBPedia KG Init ----"

    touch "/data/init.lock"
    kill -9 $P
fi

exec tini -g -- /startup/docker-entrypoint.sh $@