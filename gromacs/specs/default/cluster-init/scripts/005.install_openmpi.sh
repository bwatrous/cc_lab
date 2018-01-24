#!/bin/bash -x

set -x
set -e

NUM_CPUS=$( cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1 )
cd /tmp

# openmpi
OPENMPI_VERSION=1.10.4
wget -q -O - https://www.open-mpi.org/software/ompi/v1.10/downloads/openmpi-${OPENMPI_VERSION}.tar.gz | tar -xzf -
cd openmpi-${OPENMPI_VERSION}
./configure --prefix=/usr/local
make -j"${NUM_CPUS}" install
/sbin/ldconfig /usr/local/lib /usr/lib/x86_64-linux-gnu /usr/lib
cd ..
rm -rf ./openmpi-${OPENMPI_VERSION}
