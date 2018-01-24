#! /bin/bash -x


. /etc/profile.d/cuda-env.sh

CUDA_INSTALL_CUDNN=$( jetpack config nvidia.cuda.cudnn.install_cudnn 2> /dev/null | tr '[:upper:]' '[:lower:]')

CUDA_CUDNN_VERSION=$( jetpack config nvidia.cuda.cudnn.version 2> /dev/null )

if [ -z "${CUDA_INSTALL_CUDNN}" ]; then
    CUDA_INSTALL_CUDNN="true"
fi
if [ -z "${CUDA_CUDNN_VERSION}" ]; then
    # Currently, 5.1 is the default version for tensorflow-gpu
    CUDA_CUDNN_VERSION="5.1"
fi

if [ "${CUDA_INSTALL_CUDNN}" != "true" ]; then
    echo "Skipping cuDNN installation..."
    exit 0
fi

CUDA_CUDNN_URL="s3://com.cyclecomputing.yumrepo.us-east-1/cycle/nvidia/cudnn-${CUDA_VERSION}-linux-x64-v${CUDA_CUDNN_VERSION}.tgz"
CUDA_CUDNN_INSTALLER=$( basename ${CUDA_CUDNN_URL} )

set -e

cd $CUDA_DIR/tmp

if [ ! -f ${CUDA_CUDNN_INSTALLER} ]; then
    if [ -f ${CYCLECLOUD_SPEC_PATH}/files/${CUDA_CUDNN_INSTALLER} ]; then
        cp ${CYCLECLOUD_SPEC_PATH}/files/${CUDA_CUDNN_INSTALLER} .
    elif [[ ${CUDA_CUDNN_URL} == http* ]]; then
        wget ${CUDA_CUDNN_URL}
    else
        pogo --config=/opt/cycle/jetpack/config/thunderball-default.ini get ${CUDA_CUDNN_URL} .
    fi
fi

rm -rf ./cudnn
mkdir ./cudnn
tar xzf ${CUDA_CUDNN_INSTALLER} -C ./cudnn --strip-components=1

cp -a ./cudnn/* ${CUDA_HOME}/
mkdir -p /usr/local/cudnn-${CUDA_CUDNN_VERSION}
cp -a ./cudnn/* /usr/local/cudnn-${CUDA_CUDNN_VERSION}/

cat <<EOF >> ${CUDA_DIR}/cuda-env.sh

export CUDNN_VERSION=$CUDA_CUDNN_VERSION
export CUDNN_HOME=/usr/local/cudnn-${CUDA_CUDNN_VERSION}

export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\${CUDNN_HOME}/lib64
EOF


echo "CUDNN installed."

