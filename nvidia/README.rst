nVIDIA
========

This project installs various nVidia components for use by other projects.

Pre-Requisites
--------------

This sample requires the following:

  1. CycleCloud must be installed and running.

     a. If this is not the case, see the CycleCloud QuickStart Guide for
        assistance.

  2. The CycleCloud CLI must be installed and configured for use.

  3. You must have access to log in to CycleCloud.

  4. You must have access to upload data and launch instances in your chosen
     Cloud Provider account.

  5. You must have access to a configured CycleCloud "Locker" for Project Storage
     (Cluster-Init and Chef).

  6. Optional: To use the `cyclecloud project upload <locker>` command, you must
     have a Pogo configuration file set up with write-access to your locker.

     a. You may use your preferred tool to interact with your storage "Locker"
        instead.



Usage
=====

A. Configuring the Project
--------------------------

The first step is to configure the project for use with your storage locker:

  1. Open a terminal session with the CycleCloud CLI enabled.

  2. Switch to the TensorFlow sample directory.

  3. Run ``cyclecloud project default_locker my_locker`` (assuming the locker is named "my_locker"
     to set the default target for uploads.
     The locker name will generally be the same as the cloud provider you created when configuring
     CycleCloud. The expected output looks like this:::

       $ cyclecloud project default_locker my_locker
       Name: nvidia
       Version: 1.1.0
       Default Locker: my_locker

B. Deploying the Project
------------------------

To upload the project (including any local changes) to your target locker, run the
`cyclecloud project upload` command from the project directory.  The expected output looks like
this:::

    $ cyclecloud project upload
    Sync completed!

*IMPORTANT*

For the upload to succeed, you must have a valid Pogo configuration for your target Locker.


C. Adding the Project to a Cluster Template
-------------------------------------------

The Nvidia project has multiple specs for different node roles in your cluster.


Specs:
''''''

  1. **cuda** : This Spec installs both the Nvidia driver and the CUDA framework on the node.   In general, since CUDA installation is very heavy-weight, this spec should be installed on a single node (usually the Filer or Master) to share the installation with the cluster on the shared drive.
  
  2. **driver** : This Spec installs the basic Nvidia driver on a node.  It is required on all GPU enabled nodes unless the **cuda** spec is installed directly on the node.

  3. **sge** : This Spec may be added to all nodes in an SGE cluster to add a consumable resource for GPUs in the cluster.  This Spec must be applied to both the QMaster and GPU enabled execute nodes for it to take effect.


D. Example Cluster
------------------

See the Tensorflow project for an example of how to enable NVidia GPUs in an SGE cluster.

  
