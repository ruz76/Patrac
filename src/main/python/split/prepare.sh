. ../config/config.cfg

KRAJ=`cat KRAJ.id`
KRAJ_ID=`cat KRAJ_ID.id`
CORES=8

echo $KRAJ
echo $KRAJ_ID

echo "COPY (SELECT ST_Xmin(ST_Buffer(geom, 20000)), ST_Ymin(ST_Buffer(geom, 20000)), ST_Xmax(ST_Buffer(geom, 20000)), ST_Ymax(ST_Buffer(geom, 20000)) FROM public.nu3 WHERE nu3 = '"$KRAJ_ID"') TO '/tmp/extent.txt' CSV;" > 1.sql
psql "$CON_STRING" -f 1.sql

XMIN=`cat /tmp/extent.txt | cut -d ',' -f1`
YMIN=`cat /tmp/extent.txt | cut -d ',' -f2`
XMAX=`cat /tmp/extent.txt | cut -d ',' -f3`
YMAX=`cat /tmp/extent.txt | cut -d ',' -f4`

echo '{' > $BIN_DIR/split/data/cregion.geojson
echo '"type": "FeatureCollection",' >> $BIN_DIR/split/data/cregion.geojson
echo '"name": "cregion",' >> $BIN_DIR/split/data/cregion.geojson
echo '"crs": { "type": "name", "properties": { "name": "urn:ogc:def:crs:EPSG::5514" } },' >> $BIN_DIR/split/data/cregion.geojson
echo '"features": [' >> $BIN_DIR/split/data/cregion.geojson
echo '{ "type": "Feature", "properties": { }, "geometry": { "type": "Polygon", "coordinates": [ [ [ '$XMIN', '$YMIN' ], [ '$XMAX', '$YMIN' ], [ '$XMAX', '$YMAX' ], [ '$XMIN', '$YMAX' ], [ '$XMIN', '$YMIN' ] ] ] } }' >> $BIN_DIR/split/data/cregion.geojson
echo ']' >> $BIN_DIR/split/data/cregion.geojson
echo '}' >> $BIN_DIR/split/data/cregion.geojson

bash export_vectors_zpm.sh $KRAJE_DIR/$KRAJ $XMIN $YMIN $XMAX $YMAX $BIN_DIR/split/data
bash export_vectors_osm.sh $XMIN $YMIN $XMAX $YMAX $BIN_DIR/split/data

cd $BIN_DIR/split/data
mv osm_highway_track.cpg _osm_highway_track.cpg
mv osm_highway_track.dbf _osm_highway_track.dbf
mv osm_highway_track.shp _osm_highway_track.shp
mv osm_highway_track.shx _osm_highway_track.shx

rm *.prj

ogrmerge.py -field_strategy FirstLayer -single -o lines_for_split_full.shp *.shp
mv lines_for_split_full.* $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/

mkdir excluded
mv lespru.* excluded/
mv eleved.* excluded/
ogrmerge.py -field_strategy FirstLayer -single -o lines_for_split_no_lespru_eleved.shp *.shp
mv lines_for_split_no_lespru_eleved.* $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/

mkdir -p $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/1/outputs
mkdir -p $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/2/outputs
mkdir -p $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/3/outputs
mkdir -p $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/4/outputs

echo "COPY (SELECT id FROM $KRAJ.merged_polygons_groupped WHERE ST_Area(geom) > 20000) TO '/tmp/allsectorsids.txt' CSV;" > 1.sql
psql "$CON_STRING" -f 1.sql
split -n 4 /tmp/allsectorsids.txt

cp xaa $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/1/toprocess.txt
cp xab $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/2/toprocess.txt
cp xac $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/3/toprocess.txt
cp xad $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split/4/toprocess.txt

QT_QPA_PLATFORM=offscreen qgis_process plugins enable grassprovider
