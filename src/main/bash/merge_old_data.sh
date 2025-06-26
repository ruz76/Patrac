. config/config.cfg
DATAPATH=/media/jencek/Elements1/patracdata_pc_full_backup/kraje
for kraj in $( cat kraje_list.txt ); do
  KRAJ=`echo $kraj | cut -d ';' -f1`
  FILE=$DATAPATH/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped.shp
#  ogr2ogr -f "PostgreSQL" -s_srs "EPSG:5514" -t_srs "EPSG:5514" PG:"$CON_STRING_OGR" $FILE -nln "sektory_2020_"$KRAJ -lco GEOMETRY_NAME=geom -nlt PROMOTE_TO_MULTI
done

echo "drop table if exists sektory_2020_pom;" > 1.sql
echo "create table sektory_2020_pom as select s.id, s.typ, s.geom from sektory_2020_ka s join kraje k on (k.nk = 'KA' and st_intersects(s.geom, st_buffer(k.geom, 1000)));" >> 1.sql

for kraj in $( tail +2 kraje_list.txt ); do
  KRAJ=`echo $kraj | cut -d ';' -f1`
  KRAJ_UP=${KRAJ^^}
  echo "insert into sektory_2020_pom select s.id, s.typ, s.geom from sektory_2020_"$KRAJ" s join kraje k on (k.nk = '"$KRAJ_UP"' and st_intersects(s.geom, st_buffer(k.geom, 1000)));" >> 1.sql
done

echo "insert into sektory_2020_pom select s.id, s.typ, s.geom from sektory_2020_st s join kraje k on (k.nk = 'HP' and st_intersects(s.geom, st_buffer(k.geom, 1000)));" >> 1.sql
#psql "$CON_STRING" -f 1.sql

echo "create index on sektory_2020_pom using gist(geom);" > 1.sql
echo "alter table sektory_2020_pom add column gid serial;" >> 1.sql
echo "update sektory_2020_pom set geom = ST_MakeValid(geom);" >> 1.sql
echo "DELETE FROM  sektory_2020_pom a USING sektory_2020_pom b WHERE a.gid < b.gid AND ST_Equals(a.geom, b.geom);" >> 1.sql
echo "DELETE FROM sektory_2020_pom WHERE ST_Area(geom) < 100;" >> 1.sql
echo "DELETE FROM sektory_2020_pom a USING sektory_2020_pom b WHERE a.gid < b.gid AND ST_Intersects(a.geom, b.geom) AND ((ST_Area(ST_Intersection(a.geom, b.geom)) / ST_Area(a.geom)) > 0.8) AND ((ST_Area(ST_Intersection(a.geom, b.geom)) / ST_Area(b.geom)) > 0.8);" >> 1.sql
echo "update sektory_2020_pom set id = gid;" >> 1.sql
echo "alter table sektory_2020_pom rename column typ to type;" >> 1.sql

echo "create table sektory_2020_pom_duplicities as select * from sektory_2020_pom a, sektory_2020_pom b WHERE a.gid <> b.gid AND ST_Intersects(a.geom, b.geom);" >> 1.sql
# Some processing in QGIS - difficult to describe, hopefully we will not do this again
#psql "$CON_STRING" -f 1.sql

ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" "/tmp/sektory_2020_pom.shp" PG:"$CON_STRING_OGR" "public.sektory_2020_pom_3" -overwrite

cd /home/jencek/Documents/Projekty/PCR/github/Patrac/src/main/python/rename
python3 rename.py
mv sectors_pom_9_renamed.csv /tmp/sektory_2020_pom_3_labels.csv

create table sektory_2020_pom_3_labels (id int, label varchar(10));
copy sektory_2020_pom_3_labels from '/tmp/sektory_2020_pom_3_labels.csv' csv delimiter ';';
# alter table sektory_2020_pom add column label varchar(6);
# update sektory_2020_pom_3 s set label = l.label from sektory_2020_pom_3_labels l where s.id = l.id::varchar;
update sektory_2020_pom_3 s set label = l.label from sektory_2020_pom_3_labels l where s.id = l.id;
# alter table sektory_2020_pom rename column type to typ;
alter table sektory_2020_pom_3 drop column id;
alter table sektory_2020_pom_3 drop column gid;
alter table sektory_2020_pom_3 add column id serial;

DATAPATH_EXPORT=/data/patracdata_exports_2020
for kraj in $( cat kraje_list.txt ); do
  KRAJ=`echo $kraj | cut -d ';' -f1`
  KRAJ_UP=${KRAJ^^}
  echo "CREATE OR REPLACE VIEW public.sectors_2020_export_"$KRAJ > 1.sql
  echo "AS SELECT s.id, s.label, s.typ, s.geom" >> 1.sql
  echo "FROM sektory_2020_pom_3 s" >> 1.sql
  echo "JOIN kraje k ON k.nk::text = '"$KRAJ_UP"'::text AND st_intersects(s.geom, st_buffer(k.geom, 15000::double precision));" >> 1.sql
  psql "$CON_STRING" -f 1.sql
  mkdir -p $DATAPATH_EXPORT/$KRAJ/projekty
  mkdir -p $DATAPATH_EXPORT/$KRAJ/vektor/ZABAGED
  ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" $DATAPATH_EXPORT/$KRAJ/vektor/ZABAGED/sectors.shp PG:"$CON_STRING_OGR" "public.sectors_2020_export_"$KRAJ -overwrite
done

# Pack for kraje
# 7.sh

# Whole country export
ogr2ogr -s_srs "EPSG:5514" -t_srs "EPSG:5514" -f "GPKG" /tmp/sectors_2020_v3.gpkg PG:"$CON_STRING_OGR" sektory_2020_pom_3 -nln sectors_2020_v3
cp metadata/README.md /tmp/
zip /tmp/sectors_2020_v3.zip  /tmp/sectors_2020_v3.gpkg /tmp/README.md
