#!/usr/bin/env bash

. /data/patracdata/postupy/2022/config/config.cfg

KRAJ=$1

COUNT=`cat /tmp/barriers_poly_$KRAJ.count`

for ((i=1; i<=$COUNT; i++)); do
  echo $i;
  echo "DROP VIEW $KRAJ.landuse_barriers_in_area;" > view.sql
  echo "CREATE VIEW $KRAJ.landuse_barriers_in_area AS 
SELECT p.id ID, p.geom 
FROM $KRAJ.landuse_barriers p, $KRAJ.barriers_poly b 
WHERE (
ST_Within(p.geom, b.geom) 
OR ST_Intersects(p.geom, b.geomBufNeg01)
) 
AND b.id = "$i";" >> view.sql
  psql "$CON_STRING" -f view.sql

  ogr2ogr -f "ESRI Shapefile" -a_srs "+proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813972222222 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +pm=greenwich +units=m +no_defs +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56" "data/barriers/"$i".shp" PG:"$CON_STRING_OGR" "$KRAJ.landuse_barriers_in_area" -overwrite
    
done
