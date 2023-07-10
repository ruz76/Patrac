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
  for j in {1..4}; do
    INPUTS="${INPUTS} $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/$j/outputs/round$i.shp"
  done
  ogrmerge.py -single -o $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/round"$i"_merged.shp $INPUTS
done

for i in {0..3}; do
  ogr2ogr -overwrite -f "PostgreSQL" -a_srs "EPSG:5514" PG:"$CON_STRING_OGR" $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/round"$i"_merged.shp -nln split_round_"$i" -lco GEOMETRY_NAME=geom
done

echo "DELETE FROM split_round_0 WHERE id IN (SELECT id FROM split_round_1);" > 1.sql
echo "insert into split_round_0 (id, typ, geom) select id, typ, geom from split_round_1;" >> 1.sql
echo "DELETE FROM split_round_0 WHERE id IN (SELECT id FROM split_round_2);" >> 1.sql
echo "insert into split_round_0 (id, typ, geom) select id, typ, geom from split_round_2;" >> 1.sql
echo "DELETE FROM split_round_0 WHERE id IN (SELECT id FROM split_round_3);" >> 1.sql
echo "insert into split_round_0 (id, typ, geom) select id, typ, geom from split_round_3;" >> 1.sql
echo "drop table if exists sectors_"$KRAJ"_split;" >> 1.sql
echo "create table sectors_"$KRAJ"_split as select * from $KRAJ.merged_polygons_groupped;" >> 1.sql
echo "DELETE FROM sectors_"$KRAJ"_split WHERE id IN (SELECT id FROM split_round_0);" >> 1.sql
echo "insert into sectors_"$KRAJ"_split (id, typ, geom) select id, typ, st_multi(geom) from split_round_0;" >> 1.sql
echo "alter table sectors_"$KRAJ"_split rename column id to oldid;" >> 1.sql
echo "alter table sectors_"$KRAJ"_split add column id serial;" >> 1.sql
psql "$CON_STRING" -f 1.sql

ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted.shp PG:"$CON_STRING_OGR" "public.sectors_"$KRAJ"_split" -overwrite
