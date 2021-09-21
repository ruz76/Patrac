#!/usr/bin/env bash

. config/config.cfg

KRAJ=$1

echo "DROP TABLE IF EXISTS $KRAJ.cuzk_landuse CASCADE;" > merge.sql;
echo "CREATE TABLE $KRAJ.cuzk_landuse (fid_zbg varchar(120), type varchar(10), geom Geometry('Multipolygon', 5514), geomBufNeg01 Geometry('Multipolygon', 5514));" >> merge.sql;

for i in $( cat list_continuous.txt ); do 
  echo $i; 
  echo "INSERT INTO $KRAJ.cuzk_landuse (fid_zbg, type, geom, geomBufNeg01) SELECT fid_zbg, CONCAT('"$i"'), geom, ST_Multi(ST_Buffer(geom, -0.1)) FROM $KRAJ."${i,,}";" >> merge.sql 
done

echo "UPDATE $KRAJ.merged_polygons SET geom = ST_MakeValid(geom);" >> merge.sql
echo "UPDATE $KRAJ.cuzk_landuse SET geom = ST_MakeValid(geom);" >> merge.sql
echo "DELETE FROM $KRAJ.merged_polygons WHERE NOT ST_IsValid(geom);" >> merge.sql
echo "DELETE FROM $KRAJ.cuzk_landuse WHERE NOT ST_IsValid(geom);" >> merge.sql

echo "CREATE INDEX cuzk_landuse_geom_idx ON $KRAJ.cuzk_landuse USING GIST (geom);" >> merge.sql 
echo "CREATE INDEX cuzk_landuse_geombufneg01_idx ON $KRAJ.cuzk_landuse USING GIST (geomBufNeg01);" >> merge.sql
echo "ALTER TABLE $KRAJ.merged_polygons ADD COLUMN type varchar(10);" >> merge.sql 

echo "UPDATE $KRAJ.cuzk_landuse SET geomBufNeg01 = ST_MakeValid(ST_Multi(ST_Buffer(geom, -10)));" >> merge.sql
echo "UPDATE $KRAJ.merged_polygons p SET type = z.type FROM $KRAJ.cuzk_landuse z WHERE p.type IS NULL  AND (ST_Intersects(z.geomBufNeg01, p.geom) OR ST_Within(p.geom, z.geom) OR ST_Equals(p.geom, z.geom));" >> merge.sql
echo "UPDATE $KRAJ.cuzk_landuse SET geomBufNeg01 = ST_MakeValid(ST_Multi(ST_Buffer(geom, -5)));" >> merge.sql
echo "UPDATE $KRAJ.merged_polygons p SET type = z.type FROM $KRAJ.cuzk_landuse z WHERE p.type IS NULL  AND (ST_Intersects(z.geomBufNeg01, p.geom) OR ST_Within(p.geom, z.geom) OR ST_Equals(p.geom, z.geom));" >> merge.sql
echo "UPDATE $KRAJ.cuzk_landuse SET geomBufNeg01 = ST_MakeValid(ST_Multi(ST_Buffer(geom, -1)));" >> merge.sql
echo "UPDATE $KRAJ.merged_polygons p SET type = z.type FROM $KRAJ.cuzk_landuse z WHERE p.type IS NULL  AND (ST_Intersects(z.geomBufNeg01, p.geom) OR ST_Within(p.geom, z.geom) OR ST_Equals(p.geom, z.geom));" >> merge.sql
echo "UPDATE $KRAJ.cuzk_landuse SET geomBufNeg01 = ST_MakeValid(ST_Multi(ST_Buffer(geom, -0.1)));" >> merge.sql
echo "UPDATE $KRAJ.merged_polygons p SET type = z.type FROM $KRAJ.cuzk_landuse z WHERE p.type IS NULL  AND (ST_Intersects(z.geomBufNeg01, p.geom) OR ST_Within(p.geom, z.geom) OR ST_Equals(p.geom, z.geom));" >> merge.sql
echo "UPDATE $KRAJ.merged_polygons p SET type = 'OTHER' WHERE p.type IS NULL;" >> merge.sql

psql "$CON_STRING" -f merge.sql
