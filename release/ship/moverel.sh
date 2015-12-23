#! /bin/bash
#set -xv
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - moverel.sh
#
# Purpose - To move a release to another disk, but preserve maketape
#
#
# $Id$
#=========================================================================

origdir=$PWD                           # where this mess was started

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

if [ "$1" = "help" -o "$1" = "" -o "$2" = "" ]; then
  echo "Usage: $0 <device> <partnum> {<partnum>}"
  exit 1
fi

overflowDir="$1"
shift

if [ ! -d $overflowDir ]; then
  echo "$0:  error; no such directory $overflowDir"
  exit 1
fi

for each in $*
do
  partNum="$1"
  shift

  echo "Moving part $partNum"
  if [ ! -d $partsDir/$partNum ]; then
    echo "$0:  error; no such part $partNum"
    exit 1
  fi

  builtin cd $overflowDir
  if [ $? -ne 0 ]; then
    exit 1
  fi
  if [ -d $partNum ]; then
    echo "$0:  directory $overflowDir/$partNum already exists"
    exit 1
  fi
  mkdir $partNum
  if [ ! -d $partNum ]; then
    echo "$0:  error creating directory $overflowDir/$partNum"
    exit 1
  fi

  builtin cd $partsDir/$partNum
  if [ $? -ne 0 ]; then
    exit 1
  fi

  tar -cf - . | (builtin cd $overflowDir/$partNum; tar -xf -)
  if [ $? -ne 0 ]; then
    echo "$0:  transfer error"
    exit 1
  fi

  echo -n "Press return to delete and link the old release"
  read prompt

  builtin cd $partsDir
  if [ $? -ne 0 ]; then
    echo "$0:  cannot cd to $partsDir"
    exit 1
  fi
  echo "  doing chmod -R u+w $partNum"
  chmod -R u+w $partNum
  if [ $? -ne 0 ]; then
    echo "$0:  chmod error"
    exit 1
  fi
  echo "  doing rm -rf $partNum"
  rm -rf $partNum
  if [ $? -ne 0 ]; then
    echo "$0:  rm error"
    exit 1
  fi
  echo "  creating link"
  ln -s $overflowDir/$partNum $partNum
  if [ $? -ne 0 ]; then
    echo "$0:  ln error"
    exit 1
  fi
done

echo "successful completion"
exit 0
