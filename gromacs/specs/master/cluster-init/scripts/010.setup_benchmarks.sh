#!/bin/bash

export GROMACS_HOME=/opt/gromacs-5.1.4
export PATH=/opt/gromacs-5.1.4/bin:$PATH
MPI_ENABLED=$( jetpack config gromacs.mpi_enabled 2> /dev/null | tr '[:upper:]' '[:lower:]' )

export CLUSTER_USER=$( jetpack config cyclecloud.cluster.user.name )

set -x
set -e

cd /tmp
wget http://ftp.gromacs.org/pub/benchmarks/water_GMX50_bare.tar.gz
tar xzf water_GMX50_bare.tar.gz

# Prepping data for a single case
cd /tmp/water-cut1.0_GMX50_bare/1536

if [ "${MPI_ENABLED}" == "true" ]; then
    gmx_mpi grompp -f pme.mdp
else
    gmx grompp -f pme.mdp
fi

chown -R ${CLUSTER_USER}:${CLUSTER_USER} /tmp/water-cut1.0_GMX50_bare
mv /tmp/water-cut1.0_GMX50_bare /shared/home/${CLUSTER_USER}/


