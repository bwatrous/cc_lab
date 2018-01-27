# CycleCloud NFS Lab
* Microsoft Specialized Compute (HPC) Team - <mailto:askcyclecloud @ microsoft.com>
* Initial versions by Ben Watrous, January 2018

## 1. Introduction

### 1.1  The Lab
This is a technical lab which demonstrates building a simple standalone NFS server in Azure using CycleCloud.  It provides an introduction to using the topics covered in the [Nodes and NodeArrays] (https://docs.cyclecomputing.com/user-guide-v6.6.1/nodes), [Storage] (https://docs.cyclecomputing.com/user-guide-v6.6.1/storage), and [Projects] (https://docs.cyclecomputing.com/administrator-guide-v6.7.0/projects) chapters of the CycleCloud documentation.

In this lab, you will:

* Learn to create a basic CycleCloud cluster template.
* Learn how to manage Azure Disks in CycleCloud cluster templates.
* Learn how to use CycleCloud Projects to create reusable configurations.
* Launch an NFS Cluster as a standalone CycleCloud cluster.



The Lab should take approx 30-60 minutes to complete.

We welcome any thoughts or feedback. We are always looking for ways to improve the experience of learning how to use CycleCloud!


## 2. Prerequisites
This lab has a few prerequisites to ensure you ready and able to perform the instructions. 

1. A CycleCloud instance configured to use your Azure Subscription ID.

2. A workstation with the CycleCloud CLI installed and configured.

If you do not yet have these pre-requisites, please go back and complete the [CycleCloud Specialize Compute Intro Lab] (https://github.com/azurebigcompute/Labs/tree/master/CycleCloud%20Labs).


## 3. Setup

Start by cloning the repo or otherwise downloading the files.  

**TBD**

    git clone https://github.com/azurebigcompute/Labs.git



## 4. Configuring an NFS Server

In this lab, we will build several variations of a simple NFS Server as standalone CycleCloud clusters to demonstrate some of the features of the CycleCloud cluster template language.   Each of the variants consists of a single node which could be extracted and incorporated as a single node in a larger CycleCloud cluster type.   The final variant is the closest to a filesystem that could be used in production.

Alternatively, the clusters created in this lab may be used as persistent storage and mounted dynamically by other clusters so that the other cluster may be terminated without loss of data.


### 4.1 A Basic NFS Server Cluster

To get a feel for the CycleCloud cluster syntax, take a look at the `basic_nfs.txt` cluster template in the `filer/templates` directory.

This template creates a mountable single-node NFS cluster in CycleCloud using an explicit [Chef Run-list] (https://docs.chef.io/run_lists.html) and the CycleCloud default exports.

*IMPORTANT*
This template is designed only to demonstrate a basic cluster template, it is _not_ suitable for a production filesystem.  Since it uses the ephemeral local storage devices for the NFS data, the data may be lost any time the filer instance is terminated.   See the "Adding Storage Volumes" section for a better option.

#### The Cluster Template

CycleCloud cluster templates generally have two major sections:

1. One or more _optional_ `[parameters <section_header>]` sections that configure the cluster creation form in the UI

2. A required `[cluster <name>]` section that describes the topology of nodes in the cluster and the software installed on each node. 


The Basic NFS cluster template provides a single page cluster creation UI, but UI generation is beyond the scope of this lab.   See [CycleCloud Template GUI Integration] (https://docs.cyclecomputing.com/administrator-guide-v6.7.0/template_customization#GUI_Integration) for a detailed overview of the `[paramaters]` section.


The `[cluster basic_nfs]` section of the Basic NFS cluster template defines a single CycleCloud `node` wiht name `filer` and a set of node `defaults` which is inherited by all node types defined in the template.

##### [[node defaults]]

The `[[node defaults]]` section is a useful place to define attributes that all nodes the cluster have in common such as the cloud provider `Credentials` and default VM image (`ImageName`) to use when launching an instance of the node.   In this case, it defines the following basic attributes:

* Credentials : the name assigned to the cloud service provider account configured in CycleCloud
* ImageName : the name associated with a specific VM Image in the CycleCloud image registry
* Region : the cloud service provider region in which to launch the cluster
* KeyPairLocation : the path to a private SSH key on the CycleCloud host that CycleCloud can use to ssh in to the cluster

These attributes are all exposed as form entries in the UI and given reasonable `DefaultValue` settings when possible.

Finally, the `[[node defaults]]` section contains a set of cluster-defined `[[configuration]]` attributes.  In this case, the cluster sets and explicit UID and GID for the default local user account rather than letting the operating system select them.  It is important that all user UID/GID settings on clusters mounting this NFS server match the UID/GID settings on the NFS filer - otherwise users will see permissions failures.

##### [[node filer]]

The only node role in this cluster is the filer node.   The filer node extends the configuration from `[[node defaults]]` with the remaining attributes required to launch an instance:

* MachineType : the name of the VM type to launch
* IsReturnProxy : allows firewall traversal for return communication from the cluster to CycleCloud (only required for certain network topologies - see the CycleCloud documentation for more details)

The NFS filer node requires additional software configuration after launch:

* run_list : Configures the NFS software using Chef
* cyclecloud.discoverable : Marks the node as available for Search by other nodes in this cluster and others
* role : a cluster-defined attribute used to simplify Search
* cyclecloud.mounts.ephemeral : (optional) Shows how to control the automatic mounting and formatting of the node's ephemeral drives (in this case, to format the drives using the XFS filesystem rather than the default)

Finally, the node template provides an `[[[input-endpoint SSH]]]` block that instructs cyclecloud to make port 22 on the node publicly reachable in Azure.


#### Importing a Cluster Template

The first step when creating a new Cluster Template in CycleCloud is, generally, to use the CycleCloud CLI to import the cluster template and generate the cluster creation form.

To import the cluster template:

    cyclecloud import_template basic_nfs -f templates/basic_nfs.txt
    

#### Creating a Cluster using the GUI

Once the template has been imported, a new Cluster creation icon should appear in the CycleCloud cluster creation UI.

In your browser:

1. Navigate to the CycleCloud "Clusters" page by clicking on the "Clusters" menu item.

2. Click the **"+"** icon at the bottom of the Cluster List frame on the left of the screen to add a new cluster.

3. Click on the **basic_nfs** cluster icon on the Cluster Creation page to begin configuring a new NFS cluster.

4. In the NFS cluster creation form, most fields should have reasonable defaults, but you must set values for the required "Cluster Name" and "Subnet ID" parameters.

5. After setting all parameter values, click the "Save" button to create the new cluster and return to the "Clusters" page.

6. To launch the NFS filer, click the "Start" button on the cluster you just created.


#### Connecting to the Cluster

Once the cluster has started and the "filer" node status bar has turned green, select the filer node in the UI and click the "Connect" menu item on the lower table.  The "Connect" item will pop up a form with instructions on connecting to the node using either SSH or the CycleCloud CLI.

The easiest way to connect the node is to use the CLI (if the Cyclecloud CLI is installed):

    cyclecloud connect -c <your_cluster_name> filer

To see the default exports:

    showmount -e


### 4.2 How can we create an NFS with Persistent Storage?

The `large_nfs.txt` template in the `filer/templates` directory expands upon the `basic_nfs.txt` template by adding additional, persistent, high-performance storage and replacing the default exports with a cluster-specific export path to be mounted by NFS clients.

Using persistent storage volumes provides scalable sizing, control over RAID options, and allows the NFS server to be terminated and restarted without loss of data.

Diff the cluster templates to see the incremental changes from `basic_nfs.txt` to `large_nfs.txt`:

    diff templates/basic_nfs.txt templates/large_nfs.txt

Now try importing the `large_nfs.txt` template creating a cluster using the same method we used for the `basic_nfs.txt`.

#### Volume Configuration

The primary difference is that `large_nfs.txt` attaches 4 persistent storage volumes to the `filer` node.  See the [Storage] (https://docs.cyclecomputing.com/user-guide-v6.6.1/storage) section of the CycleCloud docs for details on all the volume configuration options.

When volumes are attached to a node via the Cluster Template, the lifetime of the volumes is the same as the lifetime of the Cluster (not the Node).   This means that when the Cluster is started for the first time, the volumes will be allocated and CycleCloud will track them the cloud service provider volume resources.   The volumes will not be deleted until _the Cluster itself_ is deleted (using either the **"-"** icon in the UI or the **delete_cluster** CLI command).   The cluster may be started and terminated many times to stop billing for the filer instance without loss of data.

#### Mount and Export Configuration

The other difference between the `basic_nfs.txt` and `large_nfs.txt` templates is that the `large_nfs.txt` cluster template configures an NFS export explicitly rather than relying on the default `shared` and `sched` exports created by the recipe.

    [[[configuration cyclecloud.exports.nfs_data]]]
    type = nfs
    export_path = /mnt/exports/nfs

This configuration creates a new NFS export on the filer from the path `/mnt/exports/nfs`.

This path may be mounted by other nodes in other clusters using:

    [[[configuration cyclecloud.mounts.nfs]]]
    type = nfs
    mountpoint = /mnt/exports/nfs
    cluster_name = <your_large_nfs_cluster_name>


#### Creating a Cluster using the CLI and a Parameters File

Using the UI is a good way to create one-off clusters for test and development or to provide users with the ability to create personal clusters.  Once an application moves to QA/Test however, it is generally useful to have a static cluster definition.

The Cyclecloud CLI allows users to "export" the parameters configured via the UI to a JSON format text file.   The exported parameters file can then be committed to source control alongside to the cluster project to track changes.   Copies of the parameters file can then be used to configure multiple environments (for example: Dev / Test / Prod clusters or copies of the cluster in multiple Regions).

We'll demonstrate this by loading the next cluster template directly from the CLI using the parameters exported from the "large_nfs" cluster.


##### Exporting Cluster Parameters

To export the cluster parameters, run:

    cyclecloud export_parameters <your_large_nfs_cluster_name> > ./nfs_cluster_params.json
    cat ./nfs_cluster_params.json


### 4.3 Building a Reusable CycleCloud Project

The final `nfs.txt` template in the `filer/templates` directory.   This version of the cluster template simply converts the NFS cluster to a project which would allow re-use in other clusters which need a standalone NFS server node built-in and disables the unused default exports.

#### CycleCloud Project Overview

CycleCloud Projects provide framework for building and deploying cluster types, applications, and cluster software capabilities that may be added to nodes in any cluster.   For example, a CycleCloud project might install the Anaconda python package manager from Continuum and then CycleCloud clusters can include the Anaconda Project to add the Anaconda capability to the cluster.

The CycleCloud CLI provides a number of commands related to creating and deploying projects.  Run `cyclecloud project -h` now to see the options.

Next, we will use the `cyclecloud project upload <locker_name>` command to upload the filer project to your Azure storage locker and then launch the final version of the filer cluster using template : `templates/nfs.txt`.


#### Configuring POGO CLI

Pogo is a data transfer CLI. Instructions for setting it up is described in the [pogo docs](https://docs.cyclecomputing.com/administrator-guide-v6.6.0/pogo/pogo_config).  For this lab, you do not need the Pogo binary, however the CycleCloud CLI uses pogo internally to upload CycleCloud projects, so you _do_ need to create a pogo configuration.

Here's a quicker way of creating a pogo config for the blob storage account configured when you set up your Azure subscription in CycleCloud.

1. Fetch the storage account (or "locker") that is associated with the azure account:

```
$  cyclecloud locker list
azure-storage (az://cyclecloudapp/cyclecloud)
```

2. Edit the cyclecloud config file `~/.cycle/config.ini`, which was created by the `cyclecloud initialize` commmand.

Add the following section in `~/.cycle/config.ini`, replacing the subscription_id, tenant_id, application_id and application_secret with your Azure AD Service Principal.

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

#### Deploying the Filer Project

To upload/deploy the NFS filer project to your storage locker, run:

```
$ cyclecloud project upload azure-storage
Uploading to az://cyclecloudapp/cyclecloud/projects/filer/1.0.0 (100%)
Sync completed!
```

**NOTE:**
The name of the storage locker, in the example, is `azure-storage`.  If you forget the name you assigned to the locker, you can list your lockers using the following command:
```
$  cyclecloud locker list
azure-storage (az://cyclecloudapp/cyclecloud)
```


#### Testing the NFS Cluster

Finally, import the `templates/nfs.txt` cluster template using the parameters file we exported earlier and start the cluster:

    cyclecloud import_cluster nfs -f ./templates/nfs.txt -p ./nfs_cluster_params.json
    cyclecloud start_cluster nfs


Note that we're using `import_cluster` rather than `import_template` here since we want to instantiate a cluster with the exported parameters rather than creating a UI form.

You may also import the template to create a cluster creation UI form if desired:

    cyclecloud import_template nfs -f templates/nfs.txt
