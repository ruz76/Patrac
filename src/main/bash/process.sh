. config/config.cfg

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo "Inputs "
    echo " - region code (varchar 2 letters) example vy"
    echo " - region code (varchar 2 letters and 5 numbers) example nu33107"
    echo "example bash 1.sh ka nu33051"
    echo "
          kh nu33085
          pa nu33093
          us nu33069
          lb nu33077
          pl nu33042
          ka nu33051
          st nu33026
          jc nu33034
          ms nu33140
          ol nu33123
          zl nu33131
          vy nu33107
          jm nu33115"
    exit 1
fi

# Config variables
KRAJ=$1
KRAJ_ID=$2

cd $BIN_DIR
su postgres -c 'bash 0.sh'
cd $BIN_DIR
bash 1.sh $KRAJ $KRAJ_ID
cd $BIN_DIR
bash 2.sh $KRAJ $KRAJ_ID
cd $BIN_DIR
bash 3.sh $KRAJ $KRAJ_ID
cd $BIN_DIR
# If there is a problem with owner of the grassdata, the process has to be run unde grass user
bash 4.sh $KRAJ $KRAJ_ID
