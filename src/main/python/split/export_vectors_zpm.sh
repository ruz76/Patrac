# Now we are entering GRASS
export GISBASE=/usr/lib/grass78

export GRASS_VERSION="7.8"

#generate GISRCRC
MYGISDBASE=$1/grassdata
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

XMIN=$2
YMIN=$3
XMAX=$4
YMAX=$5
DATAOUTPUTPATH=$6

r.mask -r
g.region e=$XMAX w=$XMIN n=$YMAX s=$YMIN
v.in.ogr -o input=$DATAOUTPUTPATH/cregion.geojson output=cregion --o

export_layer() {
  v.select ainput=$1 binput=cregion output=$1_cregion --o
  v.out.ogr format=ESRI_Shapefile input=$1_cregion output=$DATAOUTPUTPATH/$2.shp --o
}

for layer in $( cat zpm.txt ); do
  OUTPUTNAME=`echo "$layer" | tr '[:upper:]' '[:lower:]'`
  rm $DATAOUTPUTPATH/$OUTPUTNAME.shp
  rm $DATAOUTPUTPATH/$OUTPUTNAME.shx
  rm $DATAOUTPUTPATH/$OUTPUTNAME.dbf
  rm $DATAOUTPUTPATH/$OUTPUTNAME.prj
  export_layer $layer $OUTPUTNAME
done
