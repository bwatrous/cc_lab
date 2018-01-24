#!/bin/bash


. /etc/profile.d/cuda-env.sh

export CUDA_VERSION_STRING=${CUDA_VERSION}

GROMACS_VERSION="5.1.4"
GROMACS_SRC_DIR=/tmp/gromacs-${GROMACS_VERSION}
GROMACS_BUILD_DIR=/tmp/gromacs-${GROMACS_VERSION}-build
GROMACS_INSTALL_DIR=/opt/gromacs-${GROMACS_VERSION}

GDK_PATH="Should not be needed for Cuda 8+"
# IF GDK PATH is required, add -DGPU_DEPLOYMENT_KIT_ROOT_DIR=${GDK_PATH} to the build lines below

MPI_ENABLED=$( jetpack config gromacs.mpi_enabled 2> /dev/null | tr '[:upper:]' '[:lower:]' )
NUM_CPUS=$( cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1 )

set -x
set -e

cd /tmp
wget ftp://ftp.gromacs.org/pub/gromacs/gromacs-${GROMACS_VERSION}.tar.gz

tar -xzvf gromacs-${GROMACS_VERSION}.tar.gz
mkdir ${GROMACS_BUILD_DIR}
cd ${GROMACS_BUILD_DIR}


if [ "${MPI_ENABLED}" == "true" ]; then
    echo "Starting gromacs MPI build..."

    
    CC=mpicc CXX=mpicxx cmake ${GROMACS_SRC_DIR} -DGMX_OPENMP=ON -DGMX_GPU=ON -DGMX_MPI=ON -DGMX_BUILD_OWN_FFTW=ON -DGMX_PREFER_STATIC_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DGMX_BUILD_UNITTESTS=OFF -DCMAKE_INSTALL_PREFIX=${GROMACS_INSTALL_DIR}
    
else
    echo "Starting gromacs non-MPI build..."
    
    CC=gcc CXX=g++ cmake ${GROMACS_SRC_DIR} -DGMX_OPENMP=ON -DGMX_GPU=ON -DGMX_BUILD_OWN_FFTW=ON -DGMX_PREFER_STATIC_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${GROMACS_INSTALL_DIR}
    
fi

make -j"${NUM_CPUS}"
make install

echo "Done building gromacs."
