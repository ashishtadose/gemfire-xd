#!/bin/bash
# This script should only be run from the top level build directory (i.e. the one that contains build.xml).
# It reads LeafRegionEntry.cpp, preprocesses it and generates all the leaf classes that subclass AbstractRegionEntry.
# It executes cpp. It has been tested with gnu's cpp on linux and the mac.

PKG=com.gemstone.gemfire.internal.cache
SRCDIR=src/com/gemstone/gemfire/internal/cache
SRCFILE=$SRCDIR/LeafRegionEntry.cpp

for VERTYPE in VM Versioned
do
  for RETYPE in Thin Stats ThinLRU StatsLRU ThinDisk StatsDisk ThinDiskLRU StatsDiskLRU
  do
    for MEMTYPE in Heap OffHeap
    do
      PARENT=VM${RETYPE}RegionEntry
      BASE=${VERTYPE}${RETYPE}RegionEntry
      OUT=${BASE}${MEMTYPE}
      HEAP_CLASS=${BASE}Heap
      VERSIONED_CLASS=${PARENT}${MEMTYPE}
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
      cpp -E $WP_ARGS $SRCFILE >$SRCDIR/$OUT.java
      #echo VERTYPE=$VERTYPE RETYPE=$RETYPE $MEMTYPE args=$WP_ARGS 
    done
  done
done
