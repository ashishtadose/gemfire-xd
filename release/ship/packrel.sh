#! /bin/bash
#set -xv
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - packrel.sh
#
# Purpose - To compress a release, but keep online
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

if [ "$1" = "help" -o "$1" = "" ]; then
  echo "Usage: $0 <dir>"
  exit 1
fi

partNum="$1"

if [ ! -d $partNum ]; then
  echo "$0:  error; no such directory $partNum"
  exit 1
fi


builtin cd $partNum
if [ $? -ne 0 ]; then
  exit 1
fi

# Do not compress the hidden dir since it has the keyfile
# maker named mastergemcopy
these="`/bin/ls -1 | grep -v hidden`"
tar -cf - $these | compress -c >source.tar.Z
if [ $? -ne 0 ]; then
  echo "$0:  tar error"
  exit 1
fi

echo -n "Press enter to delete..."
read prompt

chmod -R u+w $these
if [ $? -ne 0 ]; then
  echo "$0:  chmod error"
  exit 1
fi
rm -rf $these
if [ $? -ne 0 ]; then
  echo "$0:  rm error"
  exit 1
fi

first="`echo $these | head -1`"
mkdir $first
if [ $? -ne 0 ]; then
  echo "$0:  mkdir error"
  exit 1
fi

mv source.tar.Z $first
if [ $? -ne 0 ]; then
  echo "$0:  mv error"
  exit 1
fi

echo "successful completion"
exit 0
