cd $2
qgis_process run native:polygonstolines --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7030 --INPUT=sektor.shp --OUTPUT=sector_line.shp
mkdir s
mv sektor.* s/
rm *.prj
ogrmerge.py -single -o merged.shp *.shp
qgis_process run native:extendlines --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7030 --INPUT=merged.shp --START_DISTANCE=$3 --END_DISTANCE=$3 --OUTPUT=extended.shp
qgis_process run native:polygonize --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7030 --INPUT=extended.shp --KEEP_FIELDS=false --OUTPUT=polygons.shp
qgis_process run native:clip --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7030 --INPUT=polygons.shp --OVERLAY=s/sektor.shp --OUTPUT=clipped.shp
qgis_process run grass7:v.clean --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7030 --input=clipped.shp --type=0 --type=1 --type=2 --type=3 --type=4 --type=5 --type=6 --tool=10 --threshold=40000 ---b=false ---c=false --output=clipped_cleaned.shp --error=TEMPORARY_OUTPUT --GRASS_SNAP_TOLERANCE_PARAMETER=-1 --GRASS_MIN_AREA_PARAMETER=0.0001 --GRASS_OUTPUT_TYPE_PARAMETER=0 --GRASS_VECTOR_DSCO= --GRASS_VECTOR_LCO= --GRASS_VECTOR_EXPORT_NOCAT=false
ogr2ogr -s_srs EPSG:5514 -t_srs EPSG:4326 $1.geojson clipped_cleaned.shp
rm *.shp
rm *.shx
rm *.dbf
rm *.cpg
rm -r s/
cp style.qml $1.qml
