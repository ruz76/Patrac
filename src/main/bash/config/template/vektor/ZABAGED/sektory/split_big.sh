#!/usr/bin/env bash

. /data/patracdata/postupy/2022/config/config.cfg

KRAJ=$1

mkdir data/big
mkdir data/big_bck

ALL_COUNT=`cat /tmp/barriers_poly_$KRAJ.count`

for i in $( find data/input/ -type f -size +1M | grep .shp ); do 
  echo $i; 
  NAME=`echo $i | cut -d"." -f1`
  SHORT_NAME=`echo $NAME | cut -d"/" -f3`
  ID=`echo $SHORT_NAME | cut -d"_" -f1`
  TYPE=`echo $SHORT_NAME | cut -d"_" -f2`

  echo "DROP TABLE IF EXISTS $KRAJ.big CASCADE;" > big.sql
  psql "$CON_STRING" -f big.sql

  ogr2ogr -overwrite -f "PostgreSQL" -t_srs "EPSG:5514" PG:"$CON_STRING_OGR" $NAME.shp -nln $KRAJ.big -lco GEOMETRY_NAME=geom
#  shp2pgsql -d -W "UTF-8" -I -s "EPSG:5514" $NAME.shp $KRAJ.big > big.sql
  psql "$CON_STRING" -f big.sql
  
  echo "DROP TABLE IF EXISTS $KRAJ.big_buffer;" > big.sql 
  echo "CREATE TABLE $KRAJ.big_buffer AS
SELECT 
   g.path[1] as gid, 
   g.geom::geometry(Polygon, 5514) as geom 
FROM
   (SELECT 
     (ST_Dump(ST_UNION(ST_Buffer(geom, 10)))).* 
   FROM $KRAJ.big
) as g;" >> big.sql
  echo "CREATE INDEX big_buffer_geom ON $KRAJ.big_buffer USING GIST(geom);" >> big.sql
  psql "$CON_STRING" -f big.sql

  echo "COPY (SELECT MAX(gid) FROM $KRAJ.big_buffer) TO '/tmp/big.count';" > 1.sql
  psql "$CON_STRING" -f 1.sql

  COUNT=`cat /tmp/big.count`

  if [[ $COUNT != *"\\N"* ]]; then

    for ((i=1; i<=$COUNT; i++)); do
      echo "DROP VIEW IF EXISTS $KRAJ.big_in_area;" > view.sql
      echo "CREATE VIEW $KRAJ.big_in_area AS 
SELECT p.ID, p.TYP, p.geom 
FROM $KRAJ.big p, $KRAJ.big_buffer b 
WHERE ST_Within(p.geom, b.geom) 
AND b.gid = "$i";" >> view.sql

      psql "$CON_STRING" -f view.sql

      ALL_COUNT=$((ALL_COUNT + 1))
      ogr2ogr -f "ESRI Shapefile" -a_srs "+proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813972222222 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +pm=greenwich +units=m +no_defs +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56" "data/input/"$ALL_COUNT"_"$TYPE".shp" PG:"$CON_STRING_OGR" "$KRAJ.big_in_area" -overwrite

      cp data/barriers/$ID.shp data/barriers/$ALL_COUNT.shp
      cp data/barriers/$ID.shx data/barriers/$ALL_COUNT.shx
      cp data/barriers/$ID.dbf data/barriers/$ALL_COUNT.dbf
      cp data/barriers/$ID.prj data/barriers/$ALL_COUNT.prj
    
    done
  else
      echo "ERROR PROCESSING BIG FILE: " $NAME
  fi

  mv $NAME.* data/big_bck/

done

echo $ALL_COUNT > /tmp/barriers_poly_$KRAJ.count.extended

