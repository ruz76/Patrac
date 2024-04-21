. ../config/config.cfg

KRAJ=`cat KRAJ.id`
KRAJ_ID=`cat KRAJ_ID.id`
CORES=8

echo $KRAJ
echo $KRAJ_ID

#cd $BIN_DIR/split/data

#ogrmerge.py -field_strategy FirstLayer -single -o lines_for_split_intrav.shp ulice.shp
#mv lines_for_split_intrav.* $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/

ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/lines_for_split_intrav.shp PG:"$CON_STRING_OGR" "gdb.cuzk_zbgd_ulice_l" -overwrite

split -d -n 8 allsectorsids.txt.csv
for i in 1 2 3 4 5 6 7 8; do
  echo $i
  mkdir -p $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split_intrav/$i/outputs
  cp ~/Documents/Projekty/PCR/github/Patrac/src/main/python/split_intrav/split.py $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split_intrav/$i/
  b=$((i-1))
  cp x0$b $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split_intrav/$i/toprocess.txt
done


#mkdir -p $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/1/outputs
#mkdir -p $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/2/outputs
#mkdir -p $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/3/outputs
#mkdir -p $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/4/outputs
#
#echo "COPY (SELECT id FROM $KRAJ.merged_polygons_groupped WHERE ST_Area(geom) > 20000) TO '/tmp/allsectorsids.txt' CSV;" > 1.sql
#psql "$CON_STRING" -f 1.sql
#split -n 4 /tmp/allsectorsids.txt
#
#cp xaa $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/1/toprocess.txt
#cp xab $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/2/toprocess.txt
#cp xac $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/3/toprocess.txt
#cp xad $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/4/toprocess.txt
