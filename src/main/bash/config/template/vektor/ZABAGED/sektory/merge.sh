#!/usr/bin/env bash

. config/config.cfg

KRAJ=$1

for i in $( ls *.shp ); do
  echo $i;  
  shp2pgsql -a -W "UTF-8" -s "EPSG:5514" $i $KRAJ.merged_polygons_grouped > merged_polygons_grouped.sql
  psql "$CON_STRING" -f merged_polygons_grouped.sql

done
