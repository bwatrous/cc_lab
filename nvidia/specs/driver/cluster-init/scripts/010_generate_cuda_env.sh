#!/bin/bash
# Speculatively generate a cuda env.
# Assumes that some node in the cluster installs cuda in a shared location or on this node.

CUDA_PROFILE_DISABLED=$( jetpack config nvidia.cuda.disable_profile 2> /dev/null | tr '[:upper:]' '[:lower:]')
if [ "${CUDA_PROFILE_DISABLED}" == "true" ]; then
    echo "Skipping cuda profile generation."
    exit 0
else

    CUDA_DIR=$( jetpack config nvidia.cuda.dir 2> /dev/null )

    if [ -z "${CUDA_DIR}" ]; then
        # cuda is large and should often be installed to a second volume
        # We also generally want to share it so that we don't have to install on every
        # node.
        CUDA_DIR="/shared/nvidia"
    fi

    set -e

    ln -sf ${CUDA_DIR}/cuda-env.sh /etc/profile.d/cuda-env.sh

    source /etc/profile.d/cuda-env.sh

    if [ -z "${CUDNN_VERSION}" ]; then
        echo "ERROR: CUDA profile is incomplete.  Waiting for next converge."
        exit -1
    fi

    ln -sf ${CUDA_HOME} /usr/local/cuda
    cp -a ${CUDA_DIR}/cub* /usr/local/
    mkdir -p /usr/local/cudnn-${CUDNN_VERSION}
    cp -a ${CUDA_DIR}/tmp/cudnn/* /usr/local/cudnn-${CUDNN_VERSION}/

fi

