#!/bin/bash
# This script will fail until the host has been authorized by SGE. Once that's
# done, it should delete the cron job.

set -e
set -x

. /etc/profile
. /etc/cluster-setup.sh

if [ -z "$(command -v yum)" ]; then
    export gpucount=0
else
    export gpucount=$( nvidia-smi --query-gpu=name --format=csv,noheader | wc -l )
fi

qconf -mattr exechost complex_values gpu=${gpucount} "$(/bin/hostname)"

if [ $? -eq 0 ]; then
  rm /etc/cron.d/gpucron
fi
