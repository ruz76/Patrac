for i in {1..4}; do
  echo $i;
  taskset -c $i bash run_task.sh $i &
done
