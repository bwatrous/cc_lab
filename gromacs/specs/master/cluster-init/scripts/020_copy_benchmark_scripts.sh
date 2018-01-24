#!/bin/bash

export CLUSTER_USER=$( jetpack config cyclecloud.cluster.user.name )
export GROMACS_HOME=/opt/gromacs-5.1.4

set -x
set -e

cp ${CYCLECLOUD_SPEC_PATH}/files/run_benchmarks_mpi.sh ~${CLUSTER_USER}/
cp ${CYCLECLOUD_SPEC_PATH}/files/gromacs_mpi.sub ~${CLUSTER_USER}/

chown -R ${CLUSTER_USER}:${CLUSTER_USER} /shared/home/${CLUSTER_USER}/
chmod 755 ~${CLUSTER_USER}/*.sh

