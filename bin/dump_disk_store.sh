#!/bin/bash
# Script to dump out the contents of a disk store file for analysis
# This script dumps the output from a recovery with the TRACE_RECOVERY
# flag turned on, so it is the raw contents of the oplogs, not the final
# disk regions.
#
# The disk store name can usually be found by looking at the directory contents. Eg
# BACKUPGFXD-DEFAULT-DISKSTORE.if -> disk store name is GFXD-DEFAULT-DISKSTORE

DIR=`dirname $0`
if [ -e $DIR/../buildlinux.properties ]
then
  BUILD_DIR=`perl -lane 'if(/build.dir=(.*)/) {print $1}' $DIR/../buildlinux.properties`
fi

if [ "$BUILD_DIR" == "" ]
then
  BUILD_DIR=$DIR/../build-artifacts
fi

DISK_STORE_TYPE=$1;
shift;

USE_KRF="-Ddummy=true";
if [ "$1" == "-krf" ]
then
  USE_KRF="-Dgemfire.disk.FORCE_KRF_RECOVERY=true";
  shift;
fi

if [ "$DISK_STORE_TYPE" == "-gem" ]
then
$BUILD_DIR/linux/product/bin/gemfire -J-Ddisk.TRACE_RECOVERY=true -J$USE_KRF -debug validate-disk-store $*
elif [ "$DISK_STORE_TYPE" == "-gfxd" ]
then
export GFXD_OPTS="-Ddisk.TRACE_RECOVERY=true -debug -Dgemfire.log-level=info -Dgfxd.log-level=info $USE_KRF"
$BUILD_DIR/linux/product-gfxd/bin/gfxd validate-disk-store $*
else
  echo "Usage: dump_disk_store.sh -gem [-krf] disk_store_name disk_dirs"
  echo "       dump_disk_store.sh -gfxd [-krf] disk_store_name disk_dirs"
  echo " Dump the disk store of the appropriate type. the -krf option reads"
  echo " the krf files instead of the crf files"
  exit 1;
fi

  

#/export/bagel1/users/dsmith/data/testing/dir4/trunk/build-artifacts/linux/product/bin/gemfire -J-Ddisk.TRACE_RECOVERY=true validate-disk-store $*
#/home/dsmith/data/work/build_artifacts/linux/product/bin/gemfire -J-Ddisk.TRACE_RECOVERY=true -debug validate-disk-store $*
