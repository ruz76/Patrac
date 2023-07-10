. ../config/config.cfg

echo $1
echo $2
echo "COPY (SELECT ST_Xmin(ST_Buffer(geom, 20000)), ST_Ymin(ST_Buffer(geom, 20000)), ST_Xmax(ST_Buffer(geom, 20000)), ST_Ymax(ST_Buffer(geom, 20000)) FROM public.nu3 WHERE nu3 = '"$2"') TO '/tmp/extent.txt' CSV;" > 1.sql
psql "$CON_STRING" -f 1.sql

XMIN=`cat /tmp/extent.txt | cut -d ',' -f1`
YMIN=`cat /tmp/extent.txt | cut -d ',' -f2`
XMAX=`cat /tmp/extent.txt | cut -d ',' -f3`
YMAX=`cat /tmp/extent.txt | cut -d ',' -f4`

bash export_vectors_zpm.sh $KRAJE_DIR/$1 $XMIN $YMIN $XMAX $YMAX $BIN_DIR/split/data
bash export_vectors_osm.sh -584236.0010035008890554 -1209947.6499967132695019 -448767.1400032062083483 -1111463.9389963292051107 /home/jencek/Documents/Projekty/PCR/github/Patrac/data/zl

cd /home/jencek/Documents/Projekty/PCR/github/Patrac/data/zl
mv osm_highway_track.cpg _osm_highway_track.cpg
mv osm_highway_track.dbf _osm_highway_track.dbf
mv osm_highway_track.shp _osm_highway_track.shp
mv osm_highway_track.shx _osm_highway_track.shx
ogrmerge.py -field_strategy FirstLayer -single -o lines_for_split_full.shp *.shp
mv lines_for_split_full.* /data/patracdata/kraje/zl/vektor/ZABAGED/line_x/

mkdir excluded
mv lespru.* excluded/
mv eleved.* excluded/
ogrmerge.py -field_strategy FirstLayer -single -o lines_for_split_no_lespru_eleved.shp *.shp
mv lines_for_split_no_lespru_eleved.* /data/patracdata/kraje/zl/vektor/ZABAGED/line_x/
