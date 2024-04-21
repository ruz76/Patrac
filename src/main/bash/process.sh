#kh nu33085 arn:aws:ecs:eu-central-1:487949541177:task/patrac/fb80a5a6a06944cb9f103a564d2a9761
#pa nu33093 arn:aws:ecs:eu-central-1:487949541177:task/patrac/bd99041d872042d789d007f07f8cbccd
#us nu33069 arn:aws:ecs:eu-central-1:487949541177:task/patrac/94ecb71595ba4d8d9703b183df936a76
#lb nu33077 arn:aws:ecs:eu-central-1:487949541177:task/patrac/96a7a67e882b46aba47f23487e6bffab
#pl nu33042 arn:aws:ecs:eu-central-1:487949541177:task/patrac/1c7b1d22eb9a476abccb3f0810646f2e
#ka nu33051 arn:aws:ecs:eu-central-1:487949541177:task/patrac/96b26d8cb43b4bc0a36a615b38c405a0
#st nu33026 arn:aws:ecs:eu-central-1:487949541177:task/patrac/134c4a2dc31043bfb094bace6aa346b0 arn:aws:ecs:eu-central-1:487949541177:task/patrac/5e0dff53eda6418f89306f49c5feb45a
#jc nu33034 arn:aws:ecs:eu-central-1:487949541177:task/patrac/350214f4d19b43b7965a2a4329f54db4
#ms nu33140 arn:aws:ecs:eu-central-1:487949541177:task/patrac/1e38a7ee782944d8ab0cb305550854b3
#ol nu33123 arn:aws:ecs:eu-central-1:487949541177:task/patrac/ca119cba01e84e5c83a2a20fde86f5a2
#zl nu33131 arn:aws:ecs:eu-central-1:487949541177:task/patrac/1e71f6cf101f46769aeaf86b858a1799
#vy nu33107 arn:aws:ecs:eu-central-1:487949541177:task/patrac/f08ad578f4644511ba274a8c0ae06cd5
#jm nu33115



export POSTGRES_PASSWORD=mysecretpassword
docker-entrypoint.sh -c 'shared_buffers=2GB' -c 'max_connections=200' &
#docker-entrypoint.sh &

cd /data/patracdata/postupy/2022/utils
bash memory.sh &

cd /data/patracdata/
mkdir kraje

aws s3 cp s3://patrac-data/docker-inputs/kraj.txt kraj.txt
# Config variables
KRAJ=`cat kraj.txt | cut -d' ' -f1`
KRAJ_ID=`cat kraj.txt | cut -d' ' -f2`

aws s3 cp s3://patrac-data/docker-inputs/patrac_docker_inputs.tar.gz patrac_docker_inputs.tar.gz
tar xvfz patrac_docker_inputs.tar.gz
rm patrac_docker_inputs.tar.gz
cd /data/patracdata/postupy/2022/

. config/config.cfg

chown patrac:patrac /home/patrac
chmod -R 777 /home/patrac

cd $BIN_DIR
chmod -R 777 /data/patracdata/
echo "STARTING 0.sh"
date
su postgres -c 'bash 0.sh'

cd $BIN_DIR
chmod -R 777 /data/patracdata/
echo "STARTING 1.sh"
date
bash 1.sh $KRAJ $KRAJ_ID

cd $BIN_DIR
chmod -R 777 /data/patracdata/
echo "STARTING 2.sh"
date
bash 2.sh $KRAJ $KRAJ_ID

cd $BIN_DIR
echo "STARTING 3.sh"
date
chmod -R 777 /data/patracdata/
bash 3.sh $KRAJ $KRAJ_ID

cd $BIN_DIR
chmod -R 777 /data/patracdata/
echo $KRAJ > KRAJ.id
echo $KRAJ_ID > KRAJ_ID.id
echo "STARTING 4.sh"
date
su patrac -c 'bash 4.sh'

cd $BIN_DIR/split
mkdir data
chmod -R 777 /data/patracdata/
echo $KRAJ > KRAJ.id
echo $KRAJ_ID > KRAJ_ID.id
echo "STARTING split"
date
su patrac -c 'bash prepare.sh'
bash runTasks.sh
bash postprocessing.sh

# Will be done on whole country after renaming
#cd $BIN_DIR
#su patrac -c 'bash 5.sh'

echo "STARTING packing"
date

cd /data/patracdata/kraje/$KRAJ/
tar cvfz $KRAJ.outputs.tar.gz *
aws s3 cp $KRAJ.outputs.tar.gz s3://patrac-data/outputs/$KRAJ.outputs.tar.gz
