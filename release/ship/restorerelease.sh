#! /bin/bash
#set -x
#set -v
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - restorerelease.sh
#
# Purpose - Revive an archived release to the active inventory.  Compare
#	    with archiverelease.
#  
# $Id$
#
#=========================================================================

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

. $SCRIPTDIR/define-ship.sh

if [ "$1" = "" ]; then
  echo "USAGE:  $0 <partnum>"
  echo "   This command restores a part from $archiveDir."
  exit 1
fi

if [ ! -d $archiveDir/$1 ]; then
  echo "ERROR: no such directory $archiveDir/$1"
  exit 1
fi

echo "
This command will restore the contents of
   $archiveDir/$1
into the ship directory ($partsDir).

"

echo "If you wish to continue, hit the return key. Otherwise hit CONTROL-C"
read prompt

cd $partsDir
if [ $? -ne 0 ]; then
  echo "ERROR:  unable to cd to $partsDir"
  exit 1
fi

echo "INFO: `date` Copying the tree..."
gcp -r $archiveDir/$1 $1
if [ $? -ne 0 ]; then
  echo "ERROR: tar returned error status"
  exit 1
fi
echo "INFO: `date` ...done!"

echo "Now to remove the archive.  Press return for this, or else"
echo "   hit CONTROL-C."
read prompt

rm  -rf $archiveDir/$1
exit 0
