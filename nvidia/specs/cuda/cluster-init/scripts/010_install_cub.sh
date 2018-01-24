#! /bin/bash -x


. /etc/profile.d/cuda-env.sh

CUDA_INSTALL_CUB=$( jetpack config nvidia.cuda.cub.install_cub 2> /dev/null | tr '[:upper:]' '[:lower:]')

CUDA_CUB_VERSION=$( jetpack config nvidia.cuda.cub.version 2> /dev/null )

if [ -z "${CUDA_INSTALL_CUB}" ]; then
    CUDA_INSTALL_CUB="true"
fi
if [ -z "${CUDA_CUB_VERSION}" ]; then
    # Currently, 1.4.1 is the default version for cntk-gpu
    CUDA_CUB_VERSION="1.4.1"
fi

if [ "${CUDA_INSTALL_CUB}" != "true" ]; then
    echo "Skipping cub installation..."
    exit 0
fi

CUDA_CUB_URL="s3://com.cyclecomputing.yumrepo.us-east-1/cycle/nvidia/cub/${CUDA_CUB_VERSION}.zip"
if ! pogo --config=/opt/cycle/jetpack/config/chef-pogo.ini ls ${CUDA_CUB_URL}; then
    # Try to fetch from github if it's not cached
    CUDA_CUB_URL="https://github.com/NVlabs/cub/archive/${CUDA_CUB_VERSION}.zip"
fi
CUDA_CUB_INSTALLER=$( basename ${CUDA_CUB_URL} )

set -e

if [ -n "$(command -v yum)" ]; then
   yum install -y unzip
else
    apt-get -y install unzip
fi


cd $CUDA_DIR/tmp

if [ ! -f ${CUDA_CUB_INSTALLER} ]; then
    if [ -f ${CYCLECLOUD_SPEC_PATH}/files/${CUDA_CUB_INSTALLER} ]; then
        cp ${CYCLECLOUD_SPEC_PATH}/files/${CUDA_CUB_INSTALLER} .
    elif [[ ${CUDA_CUB_URL} == http* ]]; then
        wget ${CUDA_CUB_URL}
    else
        pogo --config=/opt/cycle/jetpack/config/thunderball-default.ini get ${CUDA_CUB_URL} .
    fi
fi

rm -rf ./cub*
unzip ${CUDA_CUB_INSTALLER}
cp -a ./cub* ${CUDA_DIR}/
cp -a ${CUDA_DIR}/cub* /usr/local/

cat <<EOF >> ${CUDA_DIR}/cuda-env.sh

export CUB_VERSION=$CUDA_CUB_VERSION
export CUB_HOME=/usr/local/cub-${CUDA_CUB_VERSION}

EOF

echo "CUB installed."

