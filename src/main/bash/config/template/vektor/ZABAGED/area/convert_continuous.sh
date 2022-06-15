#!/usr/bin/env bash

. /data/patracdata/postupy/2022/config/config.cfg

for i in $( cat list_continuous.txt ); do
  echo $i;
  ogr2ogr -overwrite -f "PostgreSQL" -t_srs "EPSG:5514" PG:"$CON_STRING_OGR" "CUZK_ZBGD_"$i"_A_Clip.shp" -nln $1.$i -lco GEOMETRY_NAME=geom -nlt PROMOTE_TO_MULTI
#  shp2pgsql -d -W "UTF-8" -I -s "EPSG:5514" "CUZK_ZBGD_"$i"_A_Clip.shp" $1.$i > $i.sql
#  psql "$CON_STRING" -f $i.sql
#  rm $i.sql
done


