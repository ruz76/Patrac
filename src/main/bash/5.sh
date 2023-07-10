#!/usr/bin/env bash

. config/config.cfg

KRAJ=`cat KRAJ.id`
KRAJ_ID=`cat KRAJ_ID.id`
CORES=8

# Now we are entering GRASS
export GISBASE=/usr/lib/grass78
 
export GRASS_VERSION="7.8"
 
#generate GISRCRC
MYGISDBASE=$KRAJE_DIR/$KRAJ/grassdata
MYLOC=jtsk
MYMAPSET=PERMANENT
 
# Set the global grassrc file to individual file name
MYGISRC="$HOME/.grassrc.$GRASS_VERSION.$$"
 
echo "GISDBASE: $MYGISDBASE" > "$MYGISRC"
echo "LOCATION_NAME: $MYLOC" >> "$MYGISRC"
echo "MAPSET: $MYMAPSET" >> "$MYGISRC"
echo "GRASS_GUI: text" >> "$MYGISRC"
 
# path to GRASS settings file
export GISRC=$MYGISRC
export GRASS_PYTHON=python
export GRASS_MESSAGE_FORMAT=plain
export GRASS_TRUECOLOR=TRUE
export GRASS_TRANSPARENT=TRUE
export GRASS_PNG_AUTO_WRITE=TRUE
export GRASS_GNUPLOT='gnuplot -persist'
export GRASS_WIDTH=640
export GRASS_HEIGHT=480
export GRASS_HTML_BROWSER=firefox
export GRASS_PAGER=cat
export GRASS_WISH=wish
 
export PATH="$GISBASE/bin:$GISBASE/scripts:$PATH"
export LD_LIBRARY_PATH="$GISBASE/lib"
export GRASS_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
export PYTHONPATH="$GISBASE/etc/python:$PYTHONPATH"
export MANPATH=$MANPATH:$GISBASE/man

cd $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x

# Compute statistics
echo "COPY (SELECT id, ST_XMin(geom) - 10, ST_YMin(geom) - 10, ST_XMax(geom) + 10, ST_YMax(geom) + 10 FROM sectors_"$KRAJ"_split ORDER BY id) TO '/tmp/merged_polygons_groupped.ids' DELIMITER ';' CSV;" > 1.sql
psql "$CON_STRING" -f 1.sql

cp $BIN_DIR/config/template/vektor/ZABAGED/line_x/* ./
r.reclass input='landuse' output='landuse_type' rules='landuse_type_zbg.rules' --o

## Insert stats into sqlite
rm -r /tmp/stats/
mkdir /tmp/stats
cd /tmp/stats
cp $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/merged_polygons_groupped_splitted.* ./
python3 $BIN_DIR/insert_stats.py create

while read p; do
  SECTOR_ID=`echo $p | cut -d";" -f1`
  MINX=`echo $p | cut -d";" -f2`
  MINY=`echo $p | cut -d";" -f3`
  MAXX=`echo $p | cut -d";" -f4`
  MAXY=`echo $p | cut -d";" -f5`
  g.region w=$MINX s=$MINY e=$MAXX n=$MAXY
  ogr2ogr -where "id='$SECTOR_ID'" sector.shp merged_polygons_groupped_splitted.shp -overwrite
  v.in.ogr -o input=sector.shp output=sector --o --quiet
  r.mask vector=sector --o --quiet
  r.stats -plna landuse_type separator=pipe > sector.stats
  python3 $BIN_DIR/insert_stats.py insert $SECTOR_ID
done </tmp/merged_polygons_groupped.ids

r.mask -r

mv /tmp/stats/stats.db $KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/
