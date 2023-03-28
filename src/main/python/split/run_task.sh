date
WD=/data/patracdata/kraje/zl/vektor/ZABAGED/line_x/split/$1
DD=/data/patracdata/kraje/zl
rm $WD/outputs/*
python3 process.py $WD $DD 0
python3 process.py $WD $DD 1
python3 process.py $WD $DD 2
python3 process.py $WD $DD 3
# TODO add half_islands
date
