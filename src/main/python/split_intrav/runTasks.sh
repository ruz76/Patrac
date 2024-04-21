# TODO change taskset -1, we have cpu 0 - 7 not 1 - 8
for i in {1..8}; do
  ts=$((i-1))
  echo $ts $i
  taskset -c $ts bash run_task.sh $i &
done
