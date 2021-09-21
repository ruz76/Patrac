for ((i=$1; i<=$2; i++)); do
 cp "../data/barriers/"$i".shp" data/input/bariera/barieraTest361.shp
 cp "../data/barriers/"$i".shx" data/input/bariera/barieraTest361.shx
 cp "../data/barriers/"$i".dbf" data/input/bariera/barieraTest361.dbf
 while read type; do
  SIZE=`stat --format=%s "../data/input/"$i"_"$type".shp"`
  if [[ $SIZE -gt 100 ]]; then
    #echo "PROCESS "$i"_"$type;
    cp "../data/input/"$i"_"$type".shp" data/input/simplify.shp
    cp "../data/input/"$i"_"$type".shx" data/input/simplify.shx
    cp "../data/input/"$i"_"$type".dbf" data/input/simplify.dbf

    cp configg.txt config.txt
    /usr/lib/jvm/java-8-oracle/bin/java -jar Patrac-1.0-SNAPSHOT-jar-with-dependencies.jar > /dev/null
    cp configp.txt config.txt
    /usr/lib/jvm/java-8-oracle/bin/java -jar Patrac-1.0-SNAPSHOT-jar-with-dependencies.jar > /dev/null
    #/usr/lib/jvm/java-8-oracle/bin/java -jar Patrac-1.0-SNAPSHOT-jar-with-dependencies-evaluation.jar > "log/"$i"_"$type".eval"

    mv data/output/postProcessing1000.shp "data/output/"$i"_"$type".shp"
    mv data/output/postProcessing1000.shx "data/output/"$i"_"$type".shx"
    mv data/output/postProcessing1000.dbf "data/output/"$i"_"$type".dbf"
  else
    A="A"
    #echo "SKIP "$i"_"$type;    
  fi
 done <list.txt  
done
