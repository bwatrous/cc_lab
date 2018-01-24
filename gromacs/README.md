# CycleCloud Gromacs GPU Lab
* Microsoft Specialized Compute (HPC) Team - <mailto:askcyclecloud @ microsoft.com>
* Initial versions by Ben Watrous, January 2018

## 1. Introduction

### 1.1  The Lab

This is a technical lab which demonstrates building a CycleCloud cluster-typer for the GROMACS molecular dynamics simulator in Azure.  We will create a GROMACS cluster with MPI support and GPU capabilities.  The cluster is configured to run the [NVidia GROMACS Benchmarks](https://www.nvidia.com/en-us/data-center/gpu-accelerated-applications/gromacs/).

The lab provides an introduction to using the topics covered in the [Nodes and NodeArrays] (https://docs.cyclecomputing.com/user-guide-v6.6.1/nodes), and [Projects] (https://docs.cyclecomputing.com/administrator-guide-v6.7.0/projects) chapters of the CycleCloud documentation.

In this lab, you will:

* Learn to create an MPI and GPU enabled CycleCloud cluster-type for the Gromacs application.
* Learn how to use CycleCloud Projects to add capabilities to cluster nodes.
* Learn how to use Search to link an application cluster to an external filesystem cluster.


The Lab should take approx 30-60 minutes to complete.

We welcome any thoughts or feedback. We are always looking for ways to improve the experience of learning how to use CycleCloud!


## 2. Prerequisites
This lab has a few prerequisites to ensure you ready and able to perform the instructions. 

1. A CycleCloud instance configured to use your Azure Subscription ID.

2. A workstation with the CycleCloud CLI installed and configured.

3. A running CycleCloud NFS cluster.

If you do not yet have these pre-requisites, please go back and complete the previous two labs: [CycleCloud Specialize Compute Intro Lab] (https://github.com/azurebigcompute/Labs/tree/master/CycleCloud%20Labs) and **TBD** [CycleCloud NFS Lab] (https://github.com/azurebigcompute/Labs/tree/master/CycleCloud%20Labs) **TBD**.


## 3. Setup

Start by cloning the repo or otherwise downloading the files.  

**TBD**

    git clone https://github.com/azurebigcompute/Labs.git



## 4. The Gromacs Project

### Creating a Project from Scratch

To see what an empty project looks like, we'll start by creating a new project named `gromacs-lab`:

    cyclecloud project init gromacs-lab

The `cyclecloud project init <project_name>` command creates a new project directory structure named "project_name" as a skeleton for a new CycleCloud project.   The command may prompt for a "Default locker", if you press enter the CLI will provide a list of configured lockers that you may select from.  For now, choose the locker corresponding to the cloud provider account that you will use to run your cluster.
    
If you have the command `tree` installed, you can see the current content of the skeleton project:

    $ tree gromacs-lab/
    gromacs-lab/
    ├── blobs
    ├── project.ini
    ├── specs
    │   └── default
    │       ├── chef
    │       │   ├── data_bags
    │       │   ├── roles
    │       │   └── site-cookbooks
    │       └── cluster-init
    │           ├── files
    │           │   └── README.txt
    │           ├── scripts
    │           │   └── README.txt
    │           └── tests
    │               └── README.txt
    └── templates

At the top of the directory structure, you will see a file named `project.ini` which stores all metadata about the project such as project name, version and per-blob and per-spec configuration.

At the same level as `project.ini` are the three main project directories:

* blobs : provides a common storage location for large files and binaries to be uploaded and made available for download on the cluster nodes
* specs : holds a set of named node capability specifications which may be installed on the cluster nodes
* templates : for projects providing cluster-types, hold one or more cluster templates which demonstrate usage of the project specs

    **NOTE**
    CycleCloud Projects may provide cluster types (such as the Gromacs on SGE cluster-type in this lab) or simply utilities for use by clusters (such as the Nvidia project which we'll use to install the nvidia drivers and CUDA), and it is expected that new projects may use existing projects simply as add-in capabilities.

By default, the `templates` and `blobs` directories are empty and the project contains a single "spec" named `default`.   The `default` spec contains an empty skeleton for the Chef and Cluster-Init directories.

Now look at the `gromacs` project you downloaded from github (using `tree` again).   You'll find that there are three specs :

* default : performs the general GROMACS software installation and configuration
* master : may be used to add customization specific to the QMaster node
* execute : may be used to add customization to all execute nodes

Note that `blobs` directory is currently empty.  Good practice for CycleCloud projects using open-source tools like gromacs is to provide a "build.sh" script which builds and packages the binaries required if the binaries do not exist in the blobs directory.   After the first launch of the cluster, the binary packages may be uploaded to the blobs directory in your locker to speed up later instance launches.


### The Gromacs Project

Now run the `tree` command on the `gromacs` project directory you downloaded from github.   It should look like this:

    $ tree
    .
    ├── README.md
    ├── project.ini
    ├── blobs    
    ├── specs
    │   └── default
    │       ├── chef
    │       │   ├── data_bags
    │       │   ├── roles
    │       │   └── site-cookbooks
    │       └── cluster-init
    │           ├── files
    │           │   └── README.txt
    │           ├── scripts
    │           │   ├── 001.install_prereqs.sh
    │           │   ├── 002.install_boost.sh
    │           │   ├── 005.install_openmpi.sh
    │           │   ├── 010.install_gromacs.sh
    │           │   ├── 020.setup_benchmarks.sh
    │           │   └── README.txt
    │           └── tests
    │               └── README.txt
    └── templates
	├── gromacs.txt
	└── gromacs_with_nfs.txt


Projects may use [Chef Cookbooks](https://docs.chef.io/cookbooks.html) or [Cluster-Init Scripts](https://docs.cyclecomputing.com/administrator-guide-v6.7.0/projects) to install and configure software and stage data onto the cluster.

In this project, we're using Cluster-Init scripts to install Gromacs on all nodes in the cluster.   The `specs/<spec_name>/cluster-init/` directory consists of three sub-directories:

* files : A set of files/directories to be staged onto each node using the spec.  These files are automatically synced from the locker to the nodes periodically.  Generally, large files should be stored as blobs (which are downloaded on-demand vs automatically) and smaller files used by a majority of nodes may be staged here for convenient access.
* scripts : A set of scripts to be run in lexicographical order to install software or tweak the node configuration.   In general, these scripts are run exactly-once (if they exit successfully) at launch.  This avoids requiring users to create idempotent scripts.   For configuration that should be run periodically, consider using a Chef cookbook.
* tests : A set of automated unit tests which may be used to verify node configuration after the scripts have run and report failures back to CycleCloud.


The Gromacs project uses cluster-init scripts to build all of the software from source using the scripts in the `scripts/` directory.   As mentioned above, this is not good practice as it slows instance launch for every instance - in general, the software should be built from source once and then stored in the `blobs/` directory for future cluster launches.   We're building from source here only to avoid storing blobs in github.


### The Nvidia Project

CycleCloud provides a standard, maintained Nvidia project that is used to install CUDA and the Nvidia drivers on GPU instances.   However, for the purposes of this lab a snapshot of the project is included to demonstrate uploading and using utility projects in clusters.

We won't discuss the Nvidia project in detail here, but it's worth looking at the output for the `tree` command on the `nvidia` subdirectory.  Here's the output with a depth of 2:

    $ tree -L 2 nvidia/
    nvidia/
    ├── README.rst
    ├── project.ini
    └── specs
	├── cuda
	├── driver
	└── sge

There are 3 specs in the Nvidia project that we'll use in the Gromacs lab:

* cuda : Installs the full CUDA package as well as the NVidia drivers (optionally) for building GPU-enabled applications.  Because the CUDA download is large, it is often installed on a single node with the libraries stored on the default NFS share for use by the other nodes.
* driver : Installs the Nvidia drivers (only).  The NVidia drivers should be installed on any node with a GPU.
* sge : Used in SGE clusters to update SGE to be aware of the GPU resources on the nodes.


## 5. Launching a Gromacs Cluster

The `templates/gromacs.txt` 

### Uploading the Projects

The first step in using the Gromacs cluster is to upload both the Nvidia and Gromacs projects to the Azure storage locker that you created in the earlier labs.

    **IMPORTANT**
    The Gromacs cluster depends on the NVidia project and will fail at software installation time if the NVidia project has not been uploaded to the storage locker.


The CycleCloud CLI requires access to the storage locker in order to upload projects.   So, if you haven't done so already (in the NFS cluster lab for example), then configure uploads now.  Add the following section in `~/.cycle/config.ini`, replacing the subscription_id, tenant_id, application_id and application_secret with your Azure AD Service Principal.

The application_secret is your SP password.

Replace `az://cyclecloudapp/cyclecloud` with your locker URI.

```
[pogo azure-storage]
type = az
subscription_id = XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
tenant_id = XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
application_id = XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
application_secret = XXXXXXXXXX
matches=az://cyclecloudapp/cyclecloud
```

Now upload the projects using the CycleCloud CLI:

    # Get the list of configured lockers
    cyclecloud locker list

    # Upload the Nvidia project (optionally provide a locker name if the project default locker
    # is not correct)
    cd ../nvidia
    cyclecloud project upload [your_locker_name]
    

    # Upload the Gromacs project to the same locker
    cd ../gromacs
    cyclecloud project upload [your_locker_name]
    

### Importing and Starting the Cluster

Next, use the CycleCloud CLI to import the cluster template and generate a cluster creation UI (this step should be looking familiar by now):

    cyclecloud import_template gromacs -f ./templates/gromacs.txt

Then navigate to the CycleCloud Clusters page in your browser, click the **"+"** to create a new cluster.


### Running the Benchmarks

To run the benchmarks, connect to the master node of your cluster and switch to the gromacs user:

    cyclecloud connect -c <your_gromacs_cluster_name> master
    sudo su - gromacs

Next run the provided submission script:

    # Check the content of the submission script:
    cat ./run_benchmarks_mpi.sh

    # Run the benchmarks on 2 GPUs
    ./run_benchmarks_mpi.sh 2

    # Check the job status
    qstat -f


## 6. Attaching an External Filesystem

Adding additional filesystem mounts is one of the most common operations configured via the CycleCloud cluster template.

If you have completed the NFS filer lab and have a running NFS filer cluster, then use the `templates/gromacs_with_nfs.sh` cluster template to learn how to connect a compute cluster to a running filesystem cluster.

First, diff the `gromacs.txt` and `gromacs_with_nfs.txt` templates to see the changes required.   The important change is the addition of an explicit `cyclecloud.mounts` block:

    [[[configuration cyclecloud.mounts.nfs]]]
    type = nfs
    export_path = /mnt/exports/nfs
    mountpoint = $MountPoint
    cluster_name = $FilesystemClusterName

Cluster templates may contain as many `cyclecloud.mounts` blocks as desired.  See the [Storage] (https://docs.cyclecomputing.com/user-guide-v6.6.1/storage) section of the CycleCloud documentation for a description of all the mount options.

In this case, the filesystem type is "nfs" (vs "lustre" for example), the exported path from the server is configured as `/mnt/exports/nfs` - the export path specified in the `cyclecloud.exports` block from the filer lab cluster.  The mount path on the local cluster is configurable from the UI.

The NFS server is specified using the name of the cluster you started in the filer lab (alternatively the server could be specified by IP or Hostname using the `address` attribute instead of `cluster_name`). If non-default mount "options" are requied, add the options string as it would look in an `fstab` line to the mount block's `options` attribute.


If you import and launch a cluster using this version of the cluster template, then connect and run the `mount` command, you'll see a mount at the mountpoint specified with the address of the filer node in your filer cluster.