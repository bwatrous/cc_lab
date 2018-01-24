#! /bin/bash

SGE_ROOT=$( jetpack config gridengine.root )
source ${SGE_ROOT}/default/common/settings.sh

set -e
set -x

mkdir -p /etc/sge
chmod 755 /etc/sge

# Runs on all hosts
cp ${CYCLECLOUD_SPEC_PATH}/files/prolog.sh /etc/sge/
cp ${CYCLECLOUD_SPEC_PATH}/files/epilog.sh /etc/sge/
chmod +x /etc/sge/prolog.sh
chmod +x /etc/sge/epilog.sh


# Runs only on scheduler
if jetpack config roles | grep -q 'scheduler'; then

    # Configure GPU complex for SGE
    qconf -sc > /tmp/gpucomplex
    sed -i '/^#-----*/a gpu                 gpu          INT         <=      YES         YES        0        0' /tmp/gpucomplex
    qconf -Mc /tmp/gpucomplex

    # Create a prolog and epilog to consume gpus
    qconf -sconf global > /tmp/global
    sed -i 's|^prolog.*|prolog                       sgeadmin@/etc/sge/prolog.sh|' /tmp/global
    sed -i 's|^epilog.*|epilog                       sgeadmin@/etc/sge/epilog.sh|' /tmp/global
    qconf -Mconf /tmp/global
    
else
# Runs only on exec nodes
    
    # Install temporary cron job to update GPU info after node has been authorized by SGE
    cp ${CYCLECLOUD_SPEC_PATH}/files/modify_gpu_count.cron.sh /etc/sge
    chmod +x /etc/sge/modify_gpu_count.cron.sh 

    # Warning: Crond is picky about the permissions 
    cp ${CYCLECLOUD_SPEC_PATH}/files/gpucron /etc/cron.d/
    chmod 644 /etc/cron.d/gpucron
    
fi
    
