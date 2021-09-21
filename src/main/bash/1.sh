#!/usr/bin/env bash

. config/config.cfg

# Creates basic input files for processing
# TODO remove ArcMap from processing

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo "Inputs "
    echo " - region code (varchar 2 letters) example vy"
    echo " - region code (varchar 2 letters and 5 numbers) example nu33107"
    echo "example bash 1.sh ka nu33051"
    exit 1
fi

# Config variables
KRAJ=$1

cd $BIN_DIR

bash toshp.sh $2

mkdir $KRAJE_DIR/$KRAJ/
cd $KRAJE_DIR/$KRAJ/
mkdir -p vektor/ZABAGED
cd vektor/ZABAGED
mkdir all
mv /tmp/*CUZK* all/
mv /tmp/buffer* all/

cd all
mkdir ../area
mv *_A_* ../area/
cp $BIN_DIR/config/template/vektor/ZABAGED/area/* ../area/
mkdir ../line
mv *_L_* ../line/
cp $BIN_DIR/config/template/vektor/ZABAGED/line/* ../line/

cd ../line/
mv /tmp/boundary.* ./

ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_BREHOV_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_MOST_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_PODJEZ_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_SILDAL_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_TUNEL_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_ZED_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_ZELTRA_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_ZELVLE_L_Clip.shp -nln merge

mv merge.shp landuse_barriers.shp
mv merge.shx landuse_barriers.shx
mv merge.prj landuse_barriers.prj
mv merge.dbf landuse_barriers.dbf

ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_MOST_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_PODJEZ_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_SILDAL_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_TUNEL_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_ZELTRA_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp CUZK_ZBGD_ZELVLE_L_Clip.shp -nln merge
ogr2ogr -f "ESRI Shapefile" -update -append merge.shp boundary.shp -nln merge

mv merge.shp landuse_barriers2.shp
mv merge.shx landuse_barriers2.shx
mv merge.prj landuse_barriers2.prj
mv merge.dbf landuse_barriers2.dbf

ogr2ogr -select ID -append merged.shp CUZK_ZBGD_AKVSHY_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_BREHOV_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_BROD_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_CESTA_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_DOPLIN_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_DOPPAS_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_ELEVED_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_HRAUZI_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_HRAVAL_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_LANVLE_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_LAVKA_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_LESPRU_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_LINVEG_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_LYZMUS_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_METRO_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_MOST_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_OSLEDR_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_PESINA_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_PLAKOM_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_PODJEZ_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_PRHRJE_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_PRIVOZ_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_PRODPOTR_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_PROPUS_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_ROKVYM_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_SILDAL_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_SILNEE_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_SILVYS_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_SKUBAL_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_STUPEN_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_TEREUT_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_TRADRA_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_TUNEL_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_ULICE_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_VODOPA_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_VODTOK_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_ZED_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_ZELPRE_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_ZELTRA_L_Clip.shp
ogr2ogr -select ID -append merged.shp CUZK_ZBGD_ZELVLE_L_Clip.shp

zip merged.zip merged.*
zip landuse_barriers2.zip landuse_barriers2.*
mkdir ../sektory/

# IMPORTANT
echo "ArcGIS - Feature to Polygon or GRASS GIS build topology"
