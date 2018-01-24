#! /bin/bash -x

NVIDIA_DRIVER_BUILD=$( jetpack config nvidia.driver.build 2> /dev/null )

CUDA_DIR=$( jetpack config nvidia.cuda.dir 2> /dev/null )

CUDA_VERSION=$( jetpack config nvidia.cuda.version 2> /dev/null )

CUDA_BUILD=$( jetpack config nvidia.cuda.build 2> /dev/null )

CUDA_URL=$( jetpack config nvidia.cuda.url 2> /dev/null )

CUDA_INSTALL_DRIVER=$( jetpack config nvidia.cuda.install_driver 2> /dev/null | tr '[:upper:]' '[:lower:]' )

if [ -z "${CUDA_DIR}" ]; then
    # cuda is large and should often be installed to a second volume
    # We also generally want to share it so that we don't have to install on every
    # node.
    CUDA_DIR="/shared/nvidia"
fi
if [ -z "${CUDA_VERSION}" ]; then
    CUDA_VERSION="8.0"
fi
if [ -z "${NVIDIA_DRIVER_BUILD}" ]; then
    NVIDIA_DRIVER_BUILD="375.26"
fi
if [ -z "${CUDA_BUILD}" ]; then
    CUDA_BUILD="8.0.61_${NVIDIA_DRIVER_BUILD}_linux"
fi
if [ -z "${CUDA_URL}" ]; then
    CUDA_URL="http://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/Prod2/local_installers/cuda_${CUDA_BUILD}.run"
    
    if [[ ${CUDA_VERSION} == 7* ]]; then
        # Older url format
        CUDA_URL="http://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/Prod/local_installers/cuda_${CUDA_BUILD}.run"
    fi
fi
if [ -z "${CUDA_INSTALL_DRIVER}" ]; then
    CUDA_INSTALL_DRIVER="false"
fi

CUDA_INSTALLER=$( basename ${CUDA_URL} )

CUDA_HOME=${CUDA_DIR}/cuda-${CUDA_VERSION}

if ! [ -a $CUDA_DIR/tmp ]; then
  mkdir -p $CUDA_DIR/tmp
fi

if ! [ -a  $CUDA_HOME ]; then
  mkdir -p $CUDA_HOME
fi

cat <<EOF > ${CUDA_DIR}/cuda-env.sh
#!/bin/bash

export CUDA_DIR=${CUDA_DIR}
export CUDA_HOME=${CUDA_HOME}
export CUDA_VERSION=${CUDA_VERSION}

# Ensure that the /usr/lib64 directory is first so each node picks up its local driver
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib64:${CUDA_HOME}/lib64/stubs:${CUDA_HOME}/lib64:\${LD_LIBRARY_PATH}

EOF
chmod 755 ${CUDA_DIR}/cuda-env.sh
ln -sf ${CUDA_DIR}/cuda-env.sh /etc/profile.d/cuda-env.sh

if [ -n "$(command -v yum)" ]; then
   yum groupinstall -y "Development tools"
   yum install -y gcc-c++ gcc-gfortran vim
else
    apt-get -y install linux-headers-$(uname -r) build-essential
fi

cd $CUDA_DIR/tmp

if [ ! -f ${CUDA_INSTALLER} ]; then
    if [ -f ${CYCLECLOUD_SPEC_PATH}/files/${CUDA_INSTALLER} ]; then
        cp ${CYCLECLOUD_SPEC_PATH}/files/${CUDA_INSTALLER} .
    elif [[ ${CUDA_URL} == http* ]]; then
        wget ${CUDA_URL}
    else
        pogo --config=/opt/cycle/jetpack/config/chef-pogo.ini get ${CUDA_URL} .
    fi
fi
chmod a+x ${CUDA_INSTALLER}


if [ "${CUDA_INSTALL_DRIVER}" == "true" ]; then
    # Auto-install the driver as well...
    # - no need for the driver spec and separate download
    sh ./${CUDA_INSTALLER} --driver --toolkit --silent --tmpdir=${CUDA_DIR}/tmp --toolkitpath=${CUDA_HOME}
else
    # Install just the toolkit (can be installed on a non-GPU node)
    sh ./${CUDA_INSTALLER} --toolkit --silent --tmpdir=${CUDA_DIR}/tmp --toolkitpath=${CUDA_HOME}
fi
EXIT_CODE=$?


# fix nvidia symlink if missing
if [ ! -f ${CUDA_HOME}/lib64/stubs/libnvidia-ml.so.1 ]; then
    ln -s ${CUDA_HOME}/lib64/stubs/libnvidia-ml.so ${CUDA_HOME}/lib64/stubs/libnvidia-ml.so.1
fi

echo "CUDA installation completed (status: ${EXIT_CODE})"
exit ${EXIT_CODE}
