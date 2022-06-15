#!/usr/bin/env bash

. /data/patracdata/postupy/2022/config/config.cfg

KRAJ=$1

for i in $( ls *.shp ); do
  echo $i;
  ogr2ogr -append -update -f "PostgreSQL" -s_srs "EPSG:5514" -t_srs "EPSG:5514" PG:"$CON_STRING_OGR" $i -nln $KRAJ.merged_polygons_grouped -lco GEOMETRY_NAME=geom -nlt PROMOTE_TO_MULTI
#  shp2pgsql -a -W "UTF-8" -s "EPSG:5514" $i $KRAJ.merged_polygons_grouped > merged_polygons_grouped.sql
#  psql "$CON_STRING" -f merged_polygons_grouped.sql
done
