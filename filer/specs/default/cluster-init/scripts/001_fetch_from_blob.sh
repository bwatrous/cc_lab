#!/bin/bash

set -x
set -e

jetpack download fromblob.tgz /tmp/fromblob.tgz
cd /mnt/exports/nfs
tar xzf /tmp/fromblob.tgz


