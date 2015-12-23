#! /bin/bash
#set -x
#set -v
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - archiverelease.sh
# the part numbers being directory names, with contents one level down
# and there existing a directory old.releases to move things to...
#
# Purpose - remove a product from an active inventory by doing a deep
# 	    copy to $archiveDir.  For GemStone/J we no longer do a
#           tar and gzip because GemStone/J products are already zipped.
#           Can be undone with restorerelease.
#
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
  echo "   This command moves a part to $archiveDir."
  exit 1
fi

if [ ! -d $partsDir/$1 ]; then
  echo "ERROR: no such product $partsDir/$1"
  exit 1
fi
if [ ! -d $archiveDir ]; then
  echo "ERROR: you have not created and/or linked $archiveDir yet."
  exit 1
fi

echo "
This command will move $partsDir/${1} to $archiveDir/$1.

"

echo "If you wish to continue, hit the return key. Otherwise hit CONTROL-C"
read prompt

cd $partsDir
echo "INFO: `date` Copying the tree..."
gcp -r $1 $archiveDir/$1
if [ $? -ne 0 ]; then
  echo "ERROR: gcp returned error status"
  exit 1
fi
echo "INFO: `date` ...done!"
ls -l $archiveDir/$1

echo "Now to remove the release tree.  Press return to continue, else"
echo "hit CONTROL-C..."
read prompt

echo "Changing permissions..."
chmod -R u+w $partsDir/$1
echo "Doing the remove..."
rm  -rf $partsDir/$1
echo "...Done!"

exit 0
