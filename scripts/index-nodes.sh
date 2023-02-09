#!/bin/sh
set -x
set -e
LABEL=$1
USERNAME=$2
PASSWORD=$3

echo ">($LABEL)> Creates index on 'uri' property of nodes with label ${LABEL}."
cypher-shell "CREATE INDEX FOR (x:${LABEL}) ON x.uri" --user "$USERNAME" --password "$PASSWORD"