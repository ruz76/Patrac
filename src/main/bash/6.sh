echo "DROP TABLE IF EXISTS gdb.cuzk_landuse CASCADE;" > merge.sql;
echo "CREATE TABLE gdb.cuzk_landuse (fid_zbg varchar(120), type varchar(10), geom Geometry('Multipolygon', 5514), geomBufNeg01 Geometry('Multipolygon', 5514));" >> merge.sql;

for i in $( cat config/template/vektor/ZABAGED/area/list_continuous.txt ); do
  echo $i;
  NAME=`echo $i | tr '[:upper:]' '[:lower:]'`
  echo "INSERT INTO gdb.cuzk_landuse (fid_zbg, type, geom, geomBufNeg01) SELECT fid_zbg, CONCAT('"$i"'), ST_Multi(geometry), ST_Multi(ST_Buffer(geometry, -0.1)) FROM gdb.cuzk_zbgd_"${NAME,,}"_a;" >> merge.sql
done

psql "$CON_STRING" -f merge.sql

echo "UPDATE sectors_pom_9 SET geom = ST_MakeValid(geom);" > merge.sql
echo "UPDATE gdb.cuzk_landuse SET geom = ST_MakeValid(geom);" >> merge.sql
echo "DELETE FROM sectors_pom_9 WHERE NOT ST_IsValid(geom);" >> merge.sql
echo "DELETE FROM gdb.cuzk_landuse WHERE NOT ST_IsValid(geom);" >> merge.sql

echo "CREATE INDEX cuzk_landuse_geom_idx ON gdb.cuzk_landuse USING GIST (geom);" >> merge.sql
echo "CREATE INDEX cuzk_landuse_geombufneg01_idx ON gdb.cuzk_landuse USING GIST (geomBufNeg01);" >> merge.sql
echo "ALTER TABLE sectors_pom_9 ADD COLUMN type varchar(10);" >> merge.sql

echo "UPDATE gdb.cuzk_landuse SET geomBufNeg01 = ST_MakeValid(ST_Multi(ST_Buffer(geom, -10)));" >> merge.sql
echo "UPDATE sectors_pom_9 p SET type = z.type FROM gdb.cuzk_landuse z WHERE p.type IS NULL  AND (ST_Intersects(z.geomBufNeg01, p.geom) OR ST_Within(p.geom, z.geom) OR ST_Equals(p.geom, z.geom));" >> merge.sql
echo "UPDATE gdb.cuzk_landuse SET geomBufNeg01 = ST_MakeValid(ST_Multi(ST_Buffer(geom, -5)));" >> merge.sql
echo "UPDATE sectors_pom_9 p SET type = z.type FROM gdb.cuzk_landuse z WHERE p.type IS NULL  AND (ST_Intersects(z.geomBufNeg01, p.geom) OR ST_Within(p.geom, z.geom) OR ST_Equals(p.geom, z.geom));" >> merge.sql
echo "UPDATE gdb.cuzk_landuse SET geomBufNeg01 = ST_MakeValid(ST_Multi(ST_Buffer(geom, -1)));" >> merge.sql
echo "UPDATE sectors_pom_9 p SET type = z.type FROM gdb.cuzk_landuse z WHERE p.type IS NULL  AND (ST_Intersects(z.geomBufNeg01, p.geom) OR ST_Within(p.geom, z.geom) OR ST_Equals(p.geom, z.geom));" >> merge.sql
echo "UPDATE gdb.cuzk_landuse SET geomBufNeg01 = ST_MakeValid(ST_Multi(ST_Buffer(geom, -0.1)));" >> merge.sql
echo "UPDATE sectors_pom_9 p SET type = z.type FROM gdb.cuzk_landuse z WHERE p.type IS NULL  AND (ST_Intersects(z.geomBufNeg01, p.geom) OR ST_Within(p.geom, z.geom) OR ST_Equals(p.geom, z.geom));" >> merge.sql
echo "UPDATE sectors_pom_9 p SET type = 'OTHER' WHERE p.type IS NULL;" >> merge.sql

psql "$CON_STRING" -f merge.sql
