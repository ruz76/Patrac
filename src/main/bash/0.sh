#!/usr/bin/env bash

. config/config.cfg
echo "localhost:5432:gdb:postgres:mysecretpassword" > ~/.pgpass
chmod 600 ~/.pgpass

# Imports dumps from PCR into database gdb into schema gdb and fix geometries
createdb -O postgres gdb

echo "CREATE EXTENSION postgis;" > create_db.sql
echo "CREATE SCHEMA gdb;" >> create_db.sql
psql "$CON_STRING" -f create_db.sql

cd $DUMP_DIR

# Version from 2018 year
#for i in $( ls cuzk_zbgd*.dump ); do
#  NAME=`echo $i | cut -d"." -f1`;
#  echo $NAME;
#  pg_restore -c -t $NAME -d gdb $i;
#  echo "UPDATE gdb."$NAME" SET geometry = ST_MakeValid(geometry);" > 1.sql
#  #TODO split area and line
#  #echo "UPDATE gdb."$NAME" SET geometry = ST_CollectionExtract(geometry, 3) WHERE  ST_GeometryType(geometry) = 'ST_GeometryCollection';" >> 1.sql
#  psql "$CON_STRING" -f 1.sql
#done

# Version from 2023
psql "$CON_STRING" -f zbgd_202305170824.sql
for i in $( cat list.txt ); do
  NAME=`echo $i`;
  echo $NAME;
  echo "UPDATE gdb."$NAME" SET geometry = ST_MakeValid(geometry);" > 1.sql
  psql "$CON_STRING" -f 1.sql
done

for i in $( cat list_poly.txt ); do
  NAME=`echo $i`;
  echo $NAME;
  echo "UPDATE gdb."$NAME" SET geometry = ST_CollectionExtract(geometry, 3) WHERE ST_GeometryType(geometry) = 'ST_GeometryCollection';" > 1.sql
  psql "$CON_STRING" -f 1.sql
done

cd $ADM_DIR
pg_restore -c -t nu3 -d gdb nu3.dump
pg_restore -c -t dmr4g_index -d gdb dmr4g_index.dump

