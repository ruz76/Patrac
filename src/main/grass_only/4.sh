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

DATAPATH2=/data/patracdata_tt/kraje/$KRAJ
ogr2ogr -sql "SELECT id, label, type as typ FROM sectors_export_"$KRAJ $DATAPATH/vektor/ZABAGED/sectors.shp

