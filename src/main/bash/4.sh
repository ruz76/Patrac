#!/usr/bin/env bash

. config/config.cfg

KRAJ=`cat KRAJ.id`
KRAJ_ID=`cat KRAJ_ID.id`
CORES=8

#DEM
#Get list of dems
#need to be executed outside of grass - some problem

mkdir /data/patracdata/tmp/
rm /data/patracdata/tmp/dem.xyz
bash get_dems.sh $2

for i in $( cat /tmp/list.all ); do
  echo $i;
  gzip -d $i.gz
  cat $i >> /data/patracdata/tmp/dem.xyz;
  gzip $i
done

mkdir -p $KRAJE_DIR/$KRAJ/grassdata/jtsk/PERMANENT
cp $BIN_DIR/config/template/grassdata/jtsk/PERMANENT/* $KRAJE_DIR/$KRAJ/grassdata/jtsk/PERMANENT/

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

cd $KRAJE_DIR/$KRAJ/vektor/ZABAGED/all
v.in.ogr -o input=buffer.shp output=buffer --o
g.region vector=buffer
g.region nsres=5 ewres=5

#import area
cd ../area
for i in $( ls *.shp ); do FILE=`echo $i | cut -d"." -f1`; echo $FILE; NAME=`echo $i | cut -d'_' -f3 `; echo $NAME; v.in.ogr type=boundary input=`pwd` layer=$FILE output=$NAME snap=0.1 --o -o;  done

r.mapcalc expression='landuse=0' --o

val=1; for i in $( cat list1.txt ); do echo $i; echo $val; v.to.rast input=$i output=$i use=val value=$val --o; val=$((val+1));  done

val=100; for i in $( cat list2.txt ); do echo $i; echo $val; v.to.rast input=$i output=$i use=val value=$val --o; val=$((val+1));  done

for i in $( cat list1.txt ); do r.mapcalc expression='landuse=landuse+if(isnull('$i'),0,'$i')' --o; done

for i in $( cat list2.txt ); do r.mapcalc expression='landuse=if(isnull('$i'),landuse,'$i')' --o; done

r.category landuse separator=':' rules=- << EOF
1:Zastavěná plocha (AREZAS)
2:Areály (ARUCZA)
3:Hřbitovy (HRBITO)
4:Kolejiště (KOLEJI)
5:Letiště (LETISTE)
6:Nezjištěno (LPKOSO)
7:Louky, pastviny, křoviny (LPKROV)
8:Louky, pastviny, stromy (LPSTROM)
9:Nezjištěno (OBLEDR)
10:Odpočívadla (ODPOCI)
11:Orná půda (ORNAPU)
12:Ostaní plochy u silnic (OSPLSI)
13:Lom (POTELO)
14:Nezjištěno (PRSTPR)
15:Sad, zahrada (SADZAH)
16:Skládka (SKLADK)
17:Travnatý povrch (TRTRPO)
18:Vodní plocha (VODPLO)
19:Zahrady, parky (ZAHPAR)
100:Bažiny, močály (BAZMOC)
101:Budovy, bloky budov (BUBLBU)
102:Chladící věže (CHLVEZ)
103:Chmelnice (CHMELN)
104:Elektrárna (ELEKTR)
105:Halda, odval (HALODV)
106:Skleníky (KUSLFO)
107:Rašeliniště (RASELI)
108:Nezjištěno (ROZTRA)
109:Budovy (ROZZRI)
110:Sesuv (SESPUD)
111:Silo (SILO)
112:Obora (SKAUTV)
113:Usazovací nádrž (USNAOD)
114:Budovy na nádraží (VANAZA)
115:Vinice (VINICE)
EOF

cd ../line
# TODO check or move merged.shp and barriers out from here
for i in $( ls *.shp ); do FILE=`echo $i | cut -d"." -f1`; echo $FILE; NAME=`echo $i | cut -d'_' -f3 `; echo $NAME; v.in.ogr type=line input=`pwd` layer=$FILE output=$NAME --o -o;  done

val=200; for i in $( cat list.txt ); do
  echo $i;
  echo $val;
  V1=VODOPA
  V2=VODTOK
  DX=""
  if [ "$i" = "$V1" ]; then
    DX="-d"
  fi
  if [ "$i" = "$V2" ]; then
      DX="-d"
  fi
  v.to.rast $DX input=$i output=$i use=val value=$val --o;
  val=$((val+1));
done

r.mapcalc expression='landuse_combined=landuse' --o

for i in $( cat list1.txt ); do r.mapcalc expression='landuse_combined=if(isnull('$i'),landuse_combined,'$i')' --o; done

cd ../area

r.reclass input=landuse_combined output=friction rules=friction.rules --o

g.region rast=landuse

r.in.xyz input=/data/patracdata/tmp/dem.xyz output=dem z=3 separator=space skip=1 --o
rm /data/patracdata/tmp/dem.xyz
r.slope.aspect elevation=dem slope=slope --o
r.null map=slope null=0
r.mapcalc expression='friction_slope=friction+if(slope > 45, 200000, friction + slope)' --o

cd ../line_x
# tady může dojít k chybě, kdy se napojí plocha za hranicí, ale to bych již neřešil, jsou to plochy do 50x50 m
v.in.ogr -o input=merged_polygons_groupped.shp output=merged_polygons_groupped snap=0.1 --o
v.clean input=merged_polygons_groupped output=merged_polygons_groupped_clean tool=rmarea threshold=2500 --o
v.out.ogr --overwrite input=merged_polygons_groupped_clean@PERMANENT output=merged_polygons_groupped.shp format=ESRI_Shapefile

echo "DROP TABLE IF EXISTS $KRAJ.merged_polygons_grouped_full;" > 1.sql
echo "ALTER TABLE $KRAJ.merged_polygons_grouped RENAME TO merged_polygons_grouped_full;" >> 1.sql
echo "DROP INDEX $KRAJ.merged_polygons_grouped_geom_geom_idx;" >> 1.sql
psql "$CON_STRING" -f 1.sql

#shp2pgsql -d -W "UTF-8" -I -s "EPSG:5514" merged_polygons_groupped.shp $KRAJ.merged_polygons_grouped > merged_polygons_grouped.sql
ogr2ogr -overwrite -f "PostgreSQL" -s_srs "EPSG:5514" -t_srs "EPSG:5514" PG:"$CON_STRING_OGR" merged_polygons_groupped.shp -nln $KRAJ.merged_polygons_grouped -lco GEOMETRY_NAME=geom -nlt PROMOTE_TO_MULTI

echo "UPDATE $KRAJ.merged_polygons_grouped SET id = ogc_fid;" > 1.sql
#echo "ALTER TABLE $KRAJ.merged_polygons_grouped rename column wkb_geometry to geom;" > 1.sql
echo "ALTER TABLE $KRAJ.merged_polygons_grouped add column newid varchar(6);" >> 1.sql
echo "ALTER TABLE $KRAJ.merged_polygons_grouped add column areanewid varchar(6);" >> 1.sql
echo "ALTER TABLE $KRAJ.merged_polygons_grouped add column cen geometry(POINT,5514);" >> 1.sql
echo "UPDATE $KRAJ.merged_polygons_grouped SET cen = ST_Centroid(geom);" >> 1.sql
echo "CREATE INDEX ON $KRAJ.merged_polygons_grouped USING GIST(cen);" >> 1.sql
psql "$CON_STRING" -f 1.sql

python3 $BIN_DIR/sector_names.py $KRAJ

echo "DROP VIEW IF EXISTS $KRAJ.merged_polygons_groupped;" > 1.sql
echo "CREATE VIEW $KRAJ.merged_polygons_groupped AS SELECT geom, newid id, typ FROM $KRAJ.merged_polygons_grouped;" >> 1.sql
psql "$CON_STRING" -f 1.sql
ogr2ogr -f "ESRI Shapefile" -a_srs "+proj=krovak +lat_0=49.5 +lon_0=24.83333333333333 +alpha=30.28813972222222 +k=0.9999 +x_0=0 +y_0=0 +ellps=bessel +pm=greenwich +units=m +no_defs +towgs84=570.8,85.7,462.8,4.998,1.587,5.261,3.56" merged_polygons_groupped.shp PG:"$CON_STRING_OGR" "$KRAJ.merged_polygons_groupped" -overwrite
