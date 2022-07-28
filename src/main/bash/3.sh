#!/usr/bin/env bash

. config/config.cfg

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo "Inputs "
    echo " - region code (varchar 2 letters) example vy"
    echo " - region code (varchar 2 letters and 5 numbers) example nu33107"
    echo "example bash 4.sh ka nu33051"
    echo "example bash 4.sh pl nu33042"
    echo "
          kh nu33085
          pa nu33093
          us nu33069
          lb nu33077
          pl nu33042
          ka nu33051
          st nu33026
          jc nu33034
          ms nu33140
          ol nu33123
          zl nu33131
          vy nu33107
          jm nu33115"
    exit 1
fi

KRAJ=$1
KRAJ_ID=$2
CORES=8

cd $KRAJE_DIR/$KRAJ/
cd vektor/ZABAGED/sektory/
mkdir output

#Check if the still computing - ps ax
PROCESSES_COUNT=`ps ax | grep groupFromStatic | wc -l`
while [ $PROCESSES_COUNT -gt 1 ]
do
  sleep 180
  PROCESSES_COUNT=`ps ax | grep groupFromStatic | wc -l`
done

# copy results from server into ../sektory/data/output/
for ((i=0; i<$CORES; i++)); do
  mv ts$i/data/output/* output/
done

cd output
rm vystup.*
bash ../merge.sh $KRAJ

cd ..
mkdir ../intravilan/
cd ../intravilan/
cp $BIN_DIR/config/template/vektor/ZABAGED/intravilan/* ./
bash groupIntravilans.sh $KRAJ

mkdir ../vodplo/
cd ../vodplo/
cp $BIN_DIR/config/template/vektor/ZABAGED/vodplo/* ./
bash groupVodPlo.sh $KRAJ

echo "INSERT INTO $KRAJ.merged_polygons_grouped (geom, typ) SELECT geom, concat('VODPLO') FROM $KRAJ.vodplo_group;" > 1.sql 
echo "INSERT INTO $KRAJ.merged_polygons_grouped (geom, typ) SELECT geom, concat('INTRAV') FROM $KRAJ.intravilans;" >> 1.sql 
echo "UPDATE $KRAJ.merged_polygons_grouped SET AREA = ROUND(ST_Area(geom) / 10000);" >> 1.sql
psql "$CON_STRING" -f 1.sql

cd $KRAJE_DIR/$KRAJ/vektor/ZABAGED/
mkdir line_x
cd line_x

echo "DROP VIEW IF EXISTS $KRAJ.merged_polygons_groupped;" > 1.sql
echo "ALTER TABLE $KRAJ.merged_polygons_grouped DROP COLUMN id;" >> 1.sql
echo "ALTER TABLE $KRAJ.merged_polygons_grouped ADD COLUMN id SERIAL;" >> 1.sql
echo "CREATE VIEW $KRAJ.merged_polygons_groupped AS SELECT geom, id, typ FROM $KRAJ.merged_polygons_grouped;" >> 1.sql
psql "$CON_STRING" -f 1.sql
ogr2ogr -f "ESRI Shapefile" -a_srs "+proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813972222222 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +pm=greenwich +units=m +no_defs +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56" merged_polygons_groupped.shp PG:"$CON_STRING_OGR" "$KRAJ.merged_polygons_groupped" -overwrite

