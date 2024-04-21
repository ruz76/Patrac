# Exports one layer from merged

DATAINPUTPATH=$1
XMIN=$2
YMIN=$3
XMAX=$4
YMAX=$5
DATAOUTPUTPATH=$6
LINES=$7

ogr2ogr -spat $XMIN $YMIN $XMAX $YMAX -spat_srs EPSG:5514 $DATAOUTPUTPATH/lines.shp $DATAINPUTPATH/vektor/ZABAGED/line_x/$LINES
