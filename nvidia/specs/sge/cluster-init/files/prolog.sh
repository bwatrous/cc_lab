#!/bin/sh
 #
 # Startup script to allocate GPU devices.
 #
 # Kota Yamaguchi 2015 <kyamagu@vision.is.tohoku.ac.jp>

. /etc/cluster-setup.sh

# Query how many gpus to allocate.
NGPUS=$(qstat -j $JOB_ID | sed -n "s/hard resource_list:.*gpu=\([[:digit:]]\+\).*/\1/p")
if [ -z $NGPUS ]
then
  exit 0
fi
if [ $NGPUS -le 0 ]
then
  exit 0
fi


ENV_FILE=$SGE_JOB_SPOOL_DIR/environment
touch $ENV_FILE
if [ ! -f $ENV_FILE -o ! -w $ENV_FILE ]
then
  exit 1
fi


# Allocate and lock GPUs.
SGE_GPU=""
i=0
device_ids=$(nvidia-smi -L | cut -f1 -d":" | cut -f2 -d" " | xargs shuf -e)
for device_id in $device_ids
do
  lockfile=/tmp/lock-nvidia$device_id
  if mkdir $lockfile
  then
    SGE_GPU="$SGE_GPU $device_id"
    i=$(expr $i + 1)
    if [ $i -ge $NGPUS ]
    then
      break
    fi
  fi
done


if [ $i -lt $NGPUS ]
then
  echo "ERROR: Only reserved $i of $NGPUS requested devices."
  exit 1
fi


# Set the environment.
echo SGE_GPU="$(echo $SGE_GPU | sed -e 's/^ //')" >> $ENV_FILE
exit 0
