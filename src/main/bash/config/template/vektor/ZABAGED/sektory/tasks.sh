function prepareTaskSet() {
  mkdir ts$1
  mkdir ts$1/log
  mkdir ts$1/data
  mkdir ts$1/data/input
  mkdir ts$1/data/input/bariera/
  mkdir ts$1/data/output
  rm ts$1/data/output/*
  cp bin/* ts$1/
  cat list.txt > ts$1/list.txt
  cp bin/intravilan.txt ts$1/data/input/
  echo "cd .." >> runTasks.sh
  echo "cd ts"$1 >> runTasks.sh
  echo "taskset -c "$1" bash groupFromStatic.sh "$2" "$3"&" >> runTasks.sh
}

KRAJ=$1

echo "#runTasks.sh" > runTasks.sh
echo "cd ts0" >> runTasks.sh

CORES=8
COUNT=`cat /tmp/barriers_poly_$KRAJ.count.extended`
STEP=`echo $((COUNT / CORES))`

echo $COUNT $STEP $CORES

POSITION=1
for ((i=0; i<$CORES; i++)); do
  if [[ $i -lt 7 ]]; then
    POSITION_END=$((POSITION + STEP))
    prepareTaskSet $i $POSITION $POSITION_END   
  else 
    prepareTaskSet $i $POSITION $COUNT   
  fi
  POSITION=$((POSITION + STEP + 1))
done
