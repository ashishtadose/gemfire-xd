#! /usr/bin/sh
#set -xv
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - chcekfloppy.sh
#
# Purpose - Check floppies against the ship directory
#
#
# $Id$
#=========================================================================

origdir=$PWD                           # where this mess was started
comid="checkfloppy.sh"                 # this script

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

OSTYPE=`/export/localnew/scripts/suntype -ostype`

export OSTYPE

. $SCRIPTDIR/define-ship.sh

#=========================================================================

tmpFile=/tmp/makefloppy$$

floppyCount=1
prodName=""

if [ "$OSTYPE" = "SunOS4" ]; then
  device="/dev/rfd0"                      # default device to use for dd
elif [ "$OSTYPE" = "Solaris" ]; then
  device="/vol/dev/rdiskette0"            # default device to use for dd
else
  echo "ERROR: this script does not support ostype $OSTYPE"
  exit 1
fi

usage="Usage:  checkfloppy prodNum [-ffirstFloppy] [-ddevice]
     -ffirstFloppy  - Which floppy to start with, default is 1
     -ddevice       - A floppy device; $device is the default."

#########################################################
#                                                       #
#        Collect arguments from command line            #
#                                                       #
#########################################################
unset _POSIX_OPTION_ORDER # Disable queer getopt mode
set -- `ggetopt f:d: $*`
status=$?
if [ $status -ne 0 ]; then
  # ggetopt error
  echo "ggetopt error"
  exit 1
fi

# Process switches
while [ "x$1" != "x" ]
do
  switch="$1"
  shift
  case "$switch" in
    -f) floppyCount="$1" ; shift ;;
    -d) device="$1" ; shift ;;
    --)  # Non-switch arguments
        while [ "x$1" != "x" ]; do
          # strip .tar.gz if used in filename completion
          name=`basename $1 .tar.gz`
          prodName="$name"
          shift
        done
        break
        ;;
    *)  echo "$comid[Error]:    Peculiar switch \"$switch\""
        exit 1
        ;;
  esac
done

if [ "$prodName" = "" ]; then
  echo "$usage"
  exit 1
fi

echo "Welcome to checkfloppy"
echo "   product number = $prodName"
echo "   beginning floppy = $floppyCount"
echo ""

newDir=$floppyDir/$prodName
if [ ! -d $newDir ]; then
  echo "Error:  unable to find directory $newDir"
  exit 1
fi
cd $newDir

count=`/bin/ls -1 disk* | wc -l`
echo "This product has $count floppies."

while [ 1 ]; do
  if [ ! -f disk$floppyCount ]; then
    echo ""
    echo "You have done the last floppy."
    break
  fi
  echo "Please insert your copy of floppy number $floppyCount"
  echo "Press return to continue, or N to quit... "
  read prompt
  if [ "$prompt" != "" ]; then
    echo "Exiting prematurely.  There _are_ more floppies for this product."
    break
  fi

  if [ "$OSTYPE" = "SunOS4" ]; then
    # long_device is name to use for dd
    long_device=$device
  elif [ "$OSTYPE" = "Solaris" ]; then
    eject -q $device >/dev/null 2>&1
    # long_device is name to use for dd
    long_device=`ls $device`
    if [ "$long_device" = "" ]; then
      echo ""
      echo "ERROR:  long device name error; please insert new media" \
                                 | tee -a $templog
      eject $device
      continue
    fi
    long_device="$device/$long_device"
  else
    echo "ERROR: this script does not support ostype $OSTYPE"
    exit 1
  fi

  echo "   `date` reading diskette..."
  dd if=$long_device of=$tmpFile bs=18k
  if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR:  read failure for diskette $floppyCount"
    eject $device
    continue
  fi
  echo "   `date` comparing..."
  cmp -l $tmpFile $newDir/disk$floppyCount | head -10
  if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR:  compare failure for diskette $floppyCount"
  else
    echo "   `date` verification success"
  fi
  rm -f $tmpFile

  eject $device
  floppyCount=`expr $floppyCount + 1`
done
