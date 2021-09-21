#!/usr/bin/env bash

. config/config.cfg

KRAJ=$1

echo "DROP TABLE IF EXISTS $KRAJ.intravilans;" > intravilans.sql
echo "CREATE TABLE $KRAJ.intravilans (geom Geometry('Multipolygon', 5514));" >> intravilans.sql
psql "$CON_STRING" -f intravilans.sql

COUNT=`cat /tmp/barriers_poly_$KRAJ.count`

for ((i=1; i<=$COUNT; i++)); do
    echo $i;
    echo "DROP VIEW $KRAJ.merged_polygons_in_area;" > view.sql
    echo "CREATE VIEW $KRAJ.merged_polygons_in_area AS 
SELECT p.id ID, p.type TYP, p.geom 
FROM $KRAJ.merged_polygons p, $KRAJ.barriers_poly b 
WHERE (ST_Within(p.geom, b.geom) 
OR ST_Intersects(p.geom, b.geomBufNeg01)
OR ST_Equals(p.geom, b.geom)) 
AND b.id = "$i" AND p.type IN ('AREZAS',  'ARUCZA',  'HRBITO',  'OSPLSI',  'SADZAH',  'USNAOD',  'ZAHPAR');" >> view.sql

    echo "INSERT INTO $KRAJ.intravilans SELECT ST_Multi((ST_Dump(ST_Buffer(ST_Buffer(ST_Union(geom), 0.01), -0.01))).geom) FROM $KRAJ.merged_polygons_in_area;" >> view.sql

    psql "$CON_STRING" -f view.sql

done
