#!/bin/bash

#DB="/home/asdf/crypto/gateway/db.sqlite"
DB="db.sqlite"

mkdir stella_keys
mkdir solana_keys

if test -f $DB; then
 echo "DB already exists."
else

scheme="create table keys(
id integer,
address text,
coin integer,
addressnr integer,
picid integer,
timestamp integer,
status integer,
PRIMARY KEY (id)
);"

echo $scheme | sqlite3 $DB

echo "SQLite DB created"

fi
