# Just testing purposes for rights paths etc

#kh nu33085
#pa nu33093
#us nu33069
#lb nu33077
#pl nu33042
#ka nu33051
#st nu33026
#jc nu33034
#ms nu33140
#ol nu33123
#zl nu33131
#vy nu33107
#jm nu33115

cd /data/patracdata/
mkdir kraje
aws s3 cp s3://patrac-data/docker-inputs/patrac_docker_inputs_test.tar.gz patrac_docker_inputs.tar.gz
tar xvfz patrac_docker_inputs.tar.gz
cd /data/patracdata/postupy/2022/

. config/config.cfg

aws s3 cp s3://patrac-data/docker-inputs/kraj.txt kraj.txt

# Config variables
KRAJ=`cat kraj.txt | cut -d' ' -f1`
KRAJ_ID=`cat kraj.txt | cut -d' ' -f2`

chown patrac:patrac /home/patrac
chmod -R 777 /home/patrac

cd $BIN_DIR
chmod -R 777 /data/patracdata/
#su postgres -c 'bash 0.sh'
mkdir -p /data/patracdata/kraje/$KRAJ/vektor/ZABAGED/line_x/
date > /data/patracdata/kraje/$KRAJ/vektor/ZABAGED/line_x/STARTED

cd $BIN_DIR
chmod -R 777 /data/patracdata/
#bash 1.sh $KRAJ $KRAJ_ID

cd $BIN_DIR
chmod -R 777 /data/patracdata/
#bash 2.sh $KRAJ $KRAJ_ID

cd $BIN_DIR
chmod -R 777 /data/patracdata/
#bash 3.sh $KRAJ $KRAJ_ID

cd $BIN_DIR
chmod -R 777 /data/patracdata/
echo $KRAJ > KRAJ.id
echo $KRAJ_ID > KRAJ_ID.id
#su patrac -c 'bash 4.sh'

cd $BIN_DIR/split
chmod -R 777 /data/patracdata/
echo $KRAJ > KRAJ.id
echo $KRAJ_ID > KRAJ_ID.id
#su patrac -c 'bash prepare.sh'
#bash runTasks.sh
#bash postprocessing.sh
date > /data/patracdata/kraje/$KRAJ/vektor/ZABAGED/line_x/FINISHED

# Will be done on whole country after renaming
#cd $BIN_DIR
#su patrac -c 'bash 5.sh'

#cp /data/patracdata/postupy/2022/nohup.out /data/patracdata/kraje/$KRAJ/vektor/ZABAGED/line_x/
cd /data/patracdata/kraje/$KRAJ/
tar cvfz $KRAJ.outputs.tar.gz *
aws s3 cp $KRAJ.outputs.tar.gz s3://patrac-data/outputs/$KRAJ.outputs_test.tar.gz
