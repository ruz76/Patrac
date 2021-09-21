#!/usr/bin/env bash

. config/config.cfg

# Creates output shapefiles for each type
# This is kept from version 2019 to be compatible with possible different type of input than DUMP

cat config/cuzk_line_list.txt > config/cuzk_line_area_list.txt
cat config/cuzk_area_list.txt >> config/cuzk_line_area_list.txt

# First parameter contains region identifier
echo $1

rm /tmp/*CUZK*
rm /tmp/buffer*

while read p; do
  echo "$p"
  echo "DROP VIEW IF EXISTS cuzk_zbgd_cur_type;" > 1.sql
  echo "CREATE VIEW cuzk_zbgd_cur_type AS SELECT * FROM gdb."$p" WHERE ST_Within(geometry, (SELECT ST_Buffer(geom, 20000) FROM public.nu3 WHERE nu3 = '"$1"')) OR ST_Intersects(geometry, (SELECT ST_Buffer(geom, 20000) FROM public.nu3 WHERE nu3 = '"$1"'));" >> 1.sql
  psql "$CON_STRING" -f 1.sql
  NAME=`echo "$p" | tr '[:lower:]' '[:upper:]'`
  ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" "/tmp/"$NAME"_Clip.shp" PG:"$CON_STRING_OGR" "public.cuzk_zbgd_cur_type" -overwrite
done <config/cuzk_line_area_list.txt

echo "DROP VIEW IF EXISTS cuzk_zbgd_buffer;" > 1.sql
echo "CREATE VIEW cuzk_zbgd_buffer AS SELECT ST_Buffer(geom, 20000) FROM public.nu3 WHERE nu3 = '"$1"';" >> 1.sql
psql "$CON_STRING" -f 1.sql
ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" "/tmp/buffer.shp" PG:"$CON_STRING_OGR" "public.cuzk_zbgd_buffer" -overwrite

echo "DROP VIEW IF EXISTS cuzk_zbgd_buffer;" > 1.sql
echo "CREATE VIEW cuzk_zbgd_buffer AS SELECT ST_ExteriorRing(ST_Buffer(geom, 19000)) FROM public.nu3 WHERE nu3 = '"$1"';" >> 1.sql
psql "$CON_STRING" -f 1.sql
ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" "/tmp/boundary.shp" PG:"$CON_STRING_OGR" "public.cuzk_zbgd_buffer" -overwrite

