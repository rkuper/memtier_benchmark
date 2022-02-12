#!/bin/bash
sudo pcm --external_program sudo pcm-memory --external_program \
  sudo numactl --cpunodebind=${1} --membind=${2} \
  sudo memtier_benchmark --pipeline=11 -c 20 -t 1 -d 500 -n 7000000 --key-maximum=75000000 \
  --key-pattern=G:G --ratio=1:1 --distinct-client-seed --randomize --run-count=1 \
  --key-stddev=5125000 --print-percentiles 50,75,90,95,99,99.9,99.99,100 > tmp.txt &

echo $! > integrated.pid

# performance monitoring
../utilities/pidstat.sh $(cat integrated.pid) &
echo $! > pidstat.pid
../utilities/ps.sh $(cat integrated.pid) &
echo $! > ps.pid
../utilities/vmstat.sh &
echo $! > vmstat.pid
../utilities/iostat.sh &
echo $! > iostat.pid

wait $(cat integrated.pid)
rm integrated.pid pidstat.pid ps.pid vmstat.pid iostat.pid
kill $(jobs -p)
pkill -9 -x vmstat
pkill -9 -x iostat

{
  echo "################################"
  echo "#    PCM AND MEMTIER OUTPUT    #"
  echo "################################"
  echo ""
  cat tmp.txt
  echo ""
  echo "################################"
  echo "#    PID, PS, VM, IO OUTPUT    #"
  echo "################################"
  echo ""; echo "PIDSTAT:"; echo "========"
  cat pidstat.out
  echo ""; echo "PS:"; echo "==="
  cat ps.out
  echo ""; echo "VMSTAT:"; echo "======="
  cat vmstat.out
  echo ""; echo "IOSTAT:"; echo "======="
  cat iostat.out

} > memtier-results.txt

sudo rm -f tmp.txt pidstat.out ps.out vmstat.out iostat.out
