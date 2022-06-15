#!/usr/bin/env bash

. /data/patracdata/postupy/2022/config/config.cfg

#VODPLO

KRAJ=$1

echo "DROP TABLE IF EXISTS $KRAJ.vodplo_group;" > vodplo_group.sql
echo "CREATE TABLE $KRAJ.vodplo_group (geom Geometry('Multipolygon', 5514));" >> vodplo_group.sql
psql "$CON_STRING" -f vodplo_group.sql

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
AND b.id = "$i" AND p.type IN ('VODPLO');" >> view.sql

    echo "INSERT INTO $KRAJ.vodplo_group SELECT ST_Multi((ST_Dump(ST_Buffer(ST_Buffer(ST_Union(geom), 0.01), -0.01))).geom) FROM $KRAJ.merged_polygons_in_area;" >> view.sql

    psql "$CON_STRING" -f view.sql

done
