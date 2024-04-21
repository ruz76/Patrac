# Ideas

* Create polygons from ulice and polygon boundary
* Get oriented bbox
* Split oriented bbox into several parts
* Split based on shape of the bbox
* Take one part of the bbox and select polygons what are covered by this part from more than 50%
* Merge these polygons to create one area


# Final
cd /data/patracdata/postupy/2022/split_intrav
KRAJ=cr
KRAJ_ID=nux
echo $KRAJ > KRAJ.id
echo $KRAJ_ID > KRAJ_ID.id
nohup bash runTasks.sh &
bash postprocessing.sh

# Single for testing
date

. ../config/config.cfg
cd $BIN_DIR/split_intrav
cp ~/Documents/Projekty/PCR/github/Patrac/src/main/python/split_intrav/split.py ./
KRAJ=zl
KRAJ_ID=nu33131
echo $KRAJ > KRAJ.id
echo $KRAJ_ID > KRAJ_ID.id
WD=$KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split_intrav/1
DD=$KRAJE_DIR/$KRAJ
rm $WD/outputs/*
cp split.py $WD
python3 process.py $WD $DD 0
date

# Problematic 57355 - show be solved with reorganize
