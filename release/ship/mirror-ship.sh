#! /bin/bash
#set -x
#set -v
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - mirror-ship.sh
#
# Purpose - Mirror an existing ship tree (for local testing)
#
# Uses:  $SHIPBASE must already be defined and point to an empty directory 
#  
# $Id$
#=========================================================================

comid="mirror-ship.sh"

getMyName() {
  ORIGDIR="`pwd`"
  if [ "$0" = "`basename $0`" ]; then
    # invoked from path
    SCRIPTNAME="`type -path $0`"
  else
    # some sort of path in $0...
    SCRIPTNAME="$0"
  fi
  SCRIPTDIR="`dirname $SCRIPTNAME`"
  # canonicalize SCRIPTDIR by using pwd.
  cd $SCRIPTDIR
  SCRIPTDIR="`pwd`"
  cd $ORIGDIR
  }
getMyName

. $SCRIPTDIR/setup-ship.sh

# Now let's make links to all of the inventory directories
real=/gcm/where/ship51

echo "Linking existing products in $real/inventory..."
cd $real/inventory
list=`/bin/ls -1`
cd $shipBase/inventory
for each in $list
do
  ln -s $real/inventory/$each $each
done

exit 0
