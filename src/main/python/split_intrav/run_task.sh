. ../config/config.cfg

KRAJ=`cat KRAJ.id`
KRAJ_ID=`cat KRAJ_ID.id`
CORES=8

echo $KRAJ
echo $KRAJ_ID

date
WD=$KRAJE_DIR/$KRAJ/vektor/ZABAGED/line_x/split_intrav/$1
DD=$KRAJE_DIR/$KRAJ
rm $WD/outputs/*
python3 process.py $WD $DD 0
date
