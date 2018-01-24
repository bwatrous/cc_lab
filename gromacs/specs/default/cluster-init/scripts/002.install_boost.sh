#!/bin/bash -x

set -e

NUM_CPUS=$( cat /proc/cpuinfo | awk '/^processor/{print $3}' | tail -1 )
cd /tmp

# boost
BOOST_VERSION=1_60_0
BOOST_DOTTED_VERSION=$(echo $BOOST_VERSION | tr _ .)
wget -q -O - https://sourceforge.net/projects/boost/files/boost/${BOOST_DOTTED_VERSION}/boost_${BOOST_VERSION}.tar.gz/download | tar -xzf -
cd boost_${BOOST_VERSION}
./bootstrap.sh --prefix=/usr/local --with-libraries=filesystem,system,test 
./b2 -d0 -j"${NUM_CPUS}" install
/sbin/ldconfig /usr/local/lib /usr/lib/x86_64-linux-gnu /usr/lib
cd ..
rm -rf ./boost_${BOOST_VERSION}
