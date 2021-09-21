#!/usr/bin/env bash

. config/config.cfg

for i in $( cat list_continuous.txt ); do
  echo $i; 
  shp2pgsql -d -W "UTF-8" -I -s "EPSG:5514" "CUZK_ZBGD_"$i"_A_Clip.shp" $1.$i > $i.sql
  psql "$CON_STRING" -f $i.sql
  rm $i.sql
done


