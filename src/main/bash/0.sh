#!/usr/bin/env bash

. config/config.cfg

# Imports dumps from PCR into database gdb into schema gdb and fix geometries
# TODO move to the directory of the dump files

for i in $( ls *.dump ); do
  NAME=`echo $i | cut -d"." -f1`; 
  echo $NAME; 
  pg_restore -c -t $NAME -d gdb $i; 
  echo "UPDATE gdb."$NAME" SET geometry = ST_MakeValid(geometry);" > 1.sql
  #TODO split area and line
  #echo "UPDATE gdb."$NAME" SET geometry = ST_CollectionExtract(geometry, 3) WHERE  ST_GeometryType(geometry) = 'ST_GeometryCollection';" >> 1.sql
  psql "$CON_STRING" -f 1.sql
done


