#!/usr/bin/env bash

# Imports dumps from PCR into database gdb into schema gdb and fix geometries
su postgres
createdb -O postgres gdb

. config/config.cfg

echo "CREATE EXTENSION postgis;" > create_db.sql
echo "CREATE SCHEMA gdb;" >> create_db.sql
psql "$CON_STRING" -f create_db.sql

cd $DUMP_DIR

for i in $( ls cuzk_zbgd*.dump ); do
  NAME=`echo $i | cut -d"." -f1`; 
  echo $NAME; 
  pg_restore -c -t $NAME -d gdb $i; 
  echo "UPDATE gdb."$NAME" SET geometry = ST_MakeValid(geometry);" > 1.sql
  #TODO split area and line
  #echo "UPDATE gdb."$NAME" SET geometry = ST_CollectionExtract(geometry, 3) WHERE  ST_GeometryType(geometry) = 'ST_GeometryCollection';" >> 1.sql
  psql "$CON_STRING" -f 1.sql
done

cd $ADM_DIR
pg_restore -c -t nu3 -d gdb nu3.dump
pg_restore -c -t dmr4g_index -d gdb dmr4g_index.dump

