#!/usr/bin/env bash

. /data/patracdata/postupy/2022/config/config.cfg

KRAJ=$1

echo "ALTER TABLE $KRAJ.barriers_poly ADD COLUMN geomBufNeg01 Geometry('Multipolygon', 5514);" > buffer.sql
echo "UPDATE $KRAJ.barriers_poly SET geomBufNeg01 = ST_Multi(ST_Buffer(geom, -0.1));" >> buffer.sql
echo "CREATE INDEX barriers_poly_geombufneg01_idx ON $KRAJ.barriers_poly USING GIST (geomBufNeg01);" >> buffer.sql 

psql "$CON_STRING" -f buffer.sql

echo "COPY (SELECT MAX(id) FROM $KRAJ.barriers_poly) TO '/tmp/barriers_poly_$KRAJ.count';" > 1.sql
psql "$CON_STRING" -f 1.sql

COUNT=`cat /tmp/barriers_poly_$KRAJ.count`

for ((i=1; i<=$COUNT; i++)); do
  while read type; do
    echo $i"_"$type;
    echo "DROP VIEW $KRAJ.merged_polygons_in_area;" > view.sql
    echo "CREATE VIEW $KRAJ.merged_polygons_in_area AS 
SELECT p.id ID, p.type TYP, p.geom 
FROM $KRAJ.merged_polygons p, $KRAJ.barriers_poly b 
WHERE (ST_Within(p.geom, b.geom) 
OR ST_Intersects(p.geom, b.geomBufNeg01)
OR ST_Equals(p.geom, b.geom)) 
AND b.id = "$i" AND p.type = '"$type"';" >> view.sql

    psql "$CON_STRING" -f view.sql

    ogr2ogr -f "ESRI Shapefile" -a_srs "+proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813972222222 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +pm=greenwich +units=m +no_defs +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56" "data/input/"$i"_"$type".shp" PG:"$CON_STRING_OGR" "$KRAJ.merged_polygons_in_area" -overwrite
  done <list.txt
    
done
