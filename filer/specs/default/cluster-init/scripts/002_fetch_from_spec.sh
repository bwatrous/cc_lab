#!/bin/bash

set -x
set -e

cd /mnt/exports/nfs
cp ${CYCLECLOUD_SPEC_PATH}/files/from_spec.txt .

