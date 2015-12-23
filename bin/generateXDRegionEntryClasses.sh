#!/bin/bash
# This script should only be run from the top level build directory (i.e. the one that contains build.xml).
# It reads LeafRegionEntry.cpp, preprocesses it and generates all the leaf classes that subclass AbstractRegionEntry.
# It executes cpp. It has been tested with gnu's cpp on linux and the mac.

BASEDIR=gemfirexd/java/engine
PKGDIR=com/pivotal/gemfirexd/internal/engine/store/entry
PKG=com.pivotal.gemfirexd.internal.engine.store.entry
SRCDIR=${BASEDIR}/${PKGDIR}
SRCFILE=src/com/gemstone/gemfire/internal/cache/LeafRegionEntry.cpp

for VERTYPE in VM Versioned
do
  for RLTYPE in Local Bucket
  do
  for RETYPE in Thin Stats ThinLRU StatsLRU ThinDisk StatsDisk ThinDiskLRU StatsDiskLRU
  do
    for MEMTYPE in Heap OffHeap
    do
      PARENT=RowLocation${RETYPE}RegionEntry
      BASE=${VERTYPE}${RLTYPE}RowLocation${RETYPE}RegionEntry
      OUT=${BASE}${MEMTYPE}
      HEAP_CLASS=${BASE}Heap
      VERSIONED_CLASS=Versioned${RLTYPE}${PARENT}${MEMTYPE}
      WP_ARGS=-Wp,-C,-P,-DPARENT_CLASS=$PARENT,-DLEAF_CLASS=$OUT,-DHEAP_CLASS=${HEAP_CLASS},-DVERSIONED_CLASS=${VERSIONED_CLASS},-DPKG=${PKG}
      if [ "$VERTYPE" = "Versioned" ]; then
        WP_ARGS=${WP_ARGS},-DVERSIONED
      fi
      if [[ "$RETYPE" = *Stats* ]]; then
        WP_ARGS=${WP_ARGS},-DSTATS
      fi
      if [[ "$RETYPE" = *Disk* ]]; then
        WP_ARGS=${WP_ARGS},-DDISK
      fi
      if [[ "$RETYPE" = *LRU* ]]; then
        WP_ARGS=${WP_ARGS},-DLRU
      fi
      if [[ "$MEMTYPE" = "OffHeap" ]]; then
        WP_ARGS=${WP_ARGS},-DOFFHEAP
      fi
      if [[ "$RLTYPE" = "Local" ]]; then
        WP_ARGS=${WP_ARGS},-DROWLOCATION,-DLOCAL
      fi
      if [[ "$RLTYPE" = "Bucket" ]]; then
        WP_ARGS=${WP_ARGS},-DROWLOCATION,-DBUCKET
      fi
      cpp -E $WP_ARGS $SRCFILE >$SRCDIR/$OUT.java
      #echo VERTYPE=$VERTYPE RETYPE=$RETYPE $MEMTYPE args=$WP_ARGS 
    done
  done
  done
done
