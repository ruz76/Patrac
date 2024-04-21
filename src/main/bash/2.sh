#!/usr/bin/env bash

. config/config.cfg

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo "Inputs "
    echo " - region code (varchar 2 letters) example vy"
    echo " - region code (varchar 2 letters and 5 numbers) example nu33107"
    echo "example bash 2.sh ka nu33051"
    echo "example bash 2.sh pl nu33042"
    echo "
          kh nu33085
          pa nu33093
          us nu33069
          lb nu33077
          pl nu33042
          ka nu33051
          st nu33026
          jc nu33034
          praha nu33018 - asi pokryto st
          ms nu33140
          ol nu33123
          zl nu33131
          vy nu33107
          jm nu33115"
    exit 1
fi

KRAJ=$1
KRAJ_ID=$2

cd $KRAJE_DIR/$KRAJ/
cd vektor/ZABAGED/sektory/
cp $BIN_DIR/config/template/vektor/ZABAGED/sektory/* ./
mkdir bin
cp $BIN_DIR/config/template/vektor/ZABAGED/sektory/bin/* bin/

#Import do PostGIS
echo "DROP SCHEMA IF EXISTS $KRAJ CASCADE;" > 1.sql
echo "CREATE SCHEMA $KRAJ;" >> 1.sql
psql "$CON_STRING" -f 1.sql
ogr2ogr -overwrite -f "PostgreSQL" -t_srs "EPSG:5514" PG:"$CON_STRING_OGR" landuse_barriers2_polygons.shp -nln $KRAJ.landuse_barriers2_polygons -lco GEOMETRY_NAME=geom
#rm landuse_barriers2_polygons.*

ogr2ogr -overwrite -f "PostgreSQL" -t_srs "EPSG:5514" PG:"$CON_STRING_OGR" merged_polygons.shp -nln $KRAJ.merged_polygons -lco GEOMETRY_NAME=geom
#rm merged_polygons.*

# Some bad geometries
echo "UPDATE $KRAJ.merged_polygons SET geom = ST_MakeValid(geom) WHERE NOT ST_IsValid(geom);" > 1.sql
psql "$CON_STRING" -f 1.sql

echo "CREATE INDEX ON $KRAJ.merged_polygons USING GIST(geom);" > 1.sql
echo "CREATE INDEX ON $KRAJ.landuse_barriers2_polygons USING GIST(geom);" >> 1.sql
psql "$CON_STRING" -f 1.sql

cd ../line/
ogr2ogr -overwrite -f "PostgreSQL" -t_srs "EPSG:5514" PG:"$CON_STRING_OGR" landuse_barriers.shp -nln $KRAJ.landuse_barriers -lco GEOMETRY_NAME=geom
#rm landuse_barriers.*

cd ../area/
# TODO do it directly in the database - no need to do via SHP
cp $BIN_DIR/config/template/vektor/ZABAGED/area/* ./
bash convert_continuous.sh $KRAJ
bash merge.sh $KRAJ

echo "ALTER TABLE $KRAJ.landuse_barriers2_polygons RENAME TO barriers_poly;" > 1.sql
echo "ALTER TABLE $KRAJ.merged_polygons RENAME COLUMN fid TO id;" >> 1.sql
echo "ALTER TABLE $KRAJ.barriers_poly ADD COLUMN id SERIAL;" >> 1.sql
psql "$CON_STRING" -f 1.sql

cd ../sektory/
mkdir data
mkdir data/input/
bash getInputs.sh $KRAJ
mkdir data/barriers/
bash getInputBarriers.sh $KRAJ
# TEMPORARY
# bash split_big.sh $KRAJ
cp /tmp/barriers_poly_$KRAJ.count /tmp/barriers_poly_$KRAJ.count.extended
# END TEMPORARY
bash tasks.sh $KRAJ
bash runTasks.sh
bash merger_prepare.sh $KRAJ

