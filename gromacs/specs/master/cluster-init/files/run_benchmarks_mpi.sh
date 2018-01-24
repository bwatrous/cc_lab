#!/bin/bash

qsub -l slot_type=execute,affinity_group=default -pe mpi $1 gromacs_mpi.sub 

