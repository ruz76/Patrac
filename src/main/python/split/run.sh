date
WD=/home/jencek/Documents/Projekty/PCR/github/Patrac/data/to_split_10
DD=/data/patracdata/kraje/zl
rm $WD/outputs/*
python3 process.py $WD $DD 0
python3 process.py $WD $DD 1
python3 process.py $WD $DD 2
python3 process.py $WD $DD 3
date
