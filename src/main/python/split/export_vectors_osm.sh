# Import OSM
# osm2pgsql -C 5000 -d patrac -U patrac -H localhost -W ~/Downloads/czech-republic-latest.osm.pbf

CON_STRING="dbname='patrac' port='5432' user='patrac' password='patrac' host='localhost'"

XMIN=$1
YMIN=$2
XMAX=$3
YMAX=$4
DATAOUTPUTPATH=$5

echo "DROP VIEW IF EXISTS cregion_track;" > 1.sql
echo "CREATE VIEW cregion_track AS select ST_transform(way, 5514) from planet_osm_line por where highway = 'track' and way && ST_Transform(ST_MakeEnvelope($XMIN, $YMIN, $XMAX, $YMAX, 5514), 3857);" >> 1.sql
psql "$CON_STRING" -f 1.sql

ogr2ogr -lco ENCODING=UTF-8 -f "ESRI Shapefile" $DATAOUTPUTPATH/osm_highway_track.shp PG:"$CON_STRING" "public.cregion_track" -overwrite
