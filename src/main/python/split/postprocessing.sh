. ../config/config.cfg

KRAJ=`cat KRAJ.id`
KRAJ_ID=`cat KRAJ_ID.id`
CORES=4

echo $KRAJ
echo $KRAJ_ID

#Check if the still computing - ps ax
PROCESSES_COUNT=`ps ax | grep run_task | wc -l`
while [ $PROCESSES_COUNT -gt 1 ]
do
  sleep 180
  PROCESSES_COUNT=`ps ax | grep run_task | wc -l`
done

for i in {0..3}; do
  INPUTS=''
  for j in {1..8}; do
    if test -f "$KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/$j/outputs/round$i.shp"; then
      INPUTS="${INPUTS} $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/$j/outputs/round$i.shp"
    fi
  done
  ogrmerge.py -single -o $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/round"$i"_merged.shp $INPUTS
done

for i in {0..3}; do
  ogr2ogr -overwrite -f "PostgreSQL" -a_srs "EPSG:5514" PG:"$CON_STRING_OGR" $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/round"$i"_merged.shp -nln split_round_"$i" -lco GEOMETRY_NAME=geom
done

echo "DELETE FROM split_round_0 WHERE ST_Area(geom) > 200000 AND id IN (SELECT id FROM split_round_1);" > 1.sql
echo "insert into split_round_0 (id, typ, geom) select id, typ, geom from split_round_1;" >> 1.sql
echo "DELETE FROM split_round_0 WHERE ST_Area(geom) > 200000 AND id IN (SELECT id FROM split_round_2);" >> 1.sql
echo "insert into split_round_0 (id, typ, geom) select id, typ, geom from split_round_2;" >> 1.sql
echo "DELETE FROM split_round_0 WHERE ST_Area(geom) > 200000 AND id IN (SELECT id FROM split_round_3);" >> 1.sql
echo "insert into split_round_0 (id, typ, geom) select id, typ, geom from split_round_3;" >> 1.sql
echo "drop table if exists sectors_"$KRAJ"_split;" >> 1.sql
echo "create table sectors_"$KRAJ"_split as select * from $KRAJ.merged_polygons_groupped;" >> 1.sql
echo "DELETE FROM sectors_"$KRAJ"_split WHERE id IN (SELECT id FROM split_round_0);" >> 1.sql
echo "insert into sectors_"$KRAJ"_split (id, typ, geom) select id, typ, st_multi(geom) from split_round_0;" >> 1.sql
echo "alter table sectors_"$KRAJ"_split rename column id to oldid;" >> 1.sql
echo "alter table sectors_"$KRAJ"_split add column id serial;" >> 1.sql
psql "$CON_STRING" -f 1.sql

ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted.shp PG:"$CON_STRING_OGR" "public.sectors_"$KRAJ"_split" -overwrite

echo "CREATE TABLE sectors_"$KRAJ"_split_unique AS
    WITH unique_geoms (idu, id, typ, oldid, geom) AS (
        SELECT
            row_number() OVER (PARTITION BY ST_AsBinary(geom)) AS idu,
            id, typ, oldid, geom
        FROM
            sectors_"$KRAJ"_split
        )
SELECT
    id, typ, oldid, geom
FROM
    unique_geoms
WHERE
    idu=1;" > 1.sql
psql "$CON_STRING" -f 1.sql
ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique.shp PG:"$CON_STRING_OGR" "public.sectors_"$KRAJ"_split_unique" -overwrite

# Maybe right way
# TODO
# echo "UPDATE sectors_"$KRAJ"_split_unique SET geom = ST_CollectionExtract(ST_MakeValid(geom), 3);" > 1.sql
echo "CREATE INDEX ON sectors_"$KRAJ"_split_unique USING GIST(geom);" >> 1.sql
echo "DROP TABLE IF EXISTS sectors_"$KRAJ"_split_unique_holes;" >> 1.sql
echo "CREATE TABLE sectors_"$KRAJ"_split_unique_holes AS
SELECT a.* FROM sectors_"$KRAJ"_split_unique a, sectors_"$KRAJ"_split_unique b
WHERE a.id < b.id
AND ST_Intersects(a.geom, b.geom) AND ST_Area(ST_Intersection(a.geom, b.geom)) > 1000;" >> 1.sql
psql "$CON_STRING" -f 1.sql
ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique_holes.shp PG:"$CON_STRING_OGR" "public.sectors_"$KRAJ"_split_unique_holes" -overwrite

echo "CREATE TABLE sectors_"$KRAJ"_split_unique_noholes AS SELECT * FROM sectors_"$KRAJ"_split_unique WHERE id NOT IN (SELECT id FROM sectors_"$KRAJ"_split_unique_holes);" > 1.sql
psql "$CON_STRING" -f 1.sql
ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique_noholes.shp PG:"$CON_STRING_OGR" "public.sectors_"$KRAJ"_split_unique_noholes" -overwrite

# Fix geometries merged_polygons_groupped_splitted_unique_noholes.shp
# Difference merged_polygons_groupped_splitted_unique_noholes.shp - merged_polygons_groupped_splitted_unique_holes.shp
QT_QPA_PLATFORM=offscreen qgis_process plugins enable grassprovider
QT_QPA_PLATFORM=offscreen qgis_process run native:fixgeometries --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7004 --INPUT=$KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique_noholes.shp --OUTPUT=$KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique_noholes_fixed.shp
QT_QPA_PLATFORM=offscreen qgis_process run native:difference --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7004 --INPUT=$KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique_noholes_fixed.shp --OVERLAY=$KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique_holes.shp --OUTPUT=$KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique_noholes_cliped.shp

ogrmerge.py -single -o $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/sectors_final.shp $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique_noholes_cliped.shp $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique_holes.shp

# Bad way for sure
#echo "DROP TABLE IF EXISTS sectors_"$KRAJ"_big_with_holes;" > 1.sql
#echo "CREATE TABLE sectors_"$KRAJ"_big_with_holes AS
#SELECT (ST_DumpRings(ST_GeometryN(h.geom, 1))).path[1] As path, (ST_DumpRings(ST_GeometryN(h.geom, 1))).geom As geom FROM $KRAJ.merged_polygons_groupped h
#WHERE ST_Area(geom) > 200000 AND ST_NumInteriorRings(ST_GeometryN(geom, 1)) > 0;" >> 1.sql
#psql "$CON_STRING" -f 1.sql
#
#echo "CREATE TABLE sectors_"$KRAJ"_big_holes AS
#SELECT geom FROM sectors_"$KRAJ"_big_with_holes
#WHERE path > 0;" > 1.sql
#psql "$CON_STRING" -f 1.sql
#
#ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted_unique_holes.shp PG:"$CON_STRING_OGR" "public.sectors_"$KRAJ"_big_holes" -overwrite
# End bad way for sure
