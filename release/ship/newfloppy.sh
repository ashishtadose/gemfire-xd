#! /usr/bin/sh
#set -xv
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - newfloppy.sh
#
# Purpose - Build dd images for floppies of given product
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

OSTYPE=`/export/localnew/scripts/suntype -ostype`
export OSTYPE

#=========================================================================
if [ "$OSTYPE" = "SunOS4" ]; then
  device="/dev/rfd0"                      # default device to use for dd
elif [ "$OSTYPE" = "Solaris" ]; then
  device="/vol/dev/rdiskette0"            # default device to use for dd
else
  echo "ERROR: this script does not support ostype $OSTYPE"
  exit 1
fi

prodName=""
usage="Usage: $0 product-number [-ddevice]"

#########################################################
#                                                       #
#        Collect arguments from command line            #
#                                                       #
#########################################################
unset _POSIX_OPTION_ORDER # Disable queer getopt mode
set -- `ggetopt d: $*`
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

echo "Welcome to newFloppy, partnumber = $prodName"
floppyCount=1

newDir=$floppyDir/$prodName
if [ -d $newDir ]; then
  echo "Deleting existing part $newDir."
  echo -n "Press enter to continue or control-C to quit...."
  read prompt
  rm -rf $newDir
  echo " ... existing diskettes deleted"
fi
if [ -d $newDir ]; then
  echo "Error:  unable to remove existing directory $newDir"
  exit 1
fi
mkdir $newDir
if [ ! -d $newDir ]; then
  echo "Error:  unable to create directory $newDir"
  exit 1
fi
cd $newDir

while [ 1 ]; do
  echo "Please enter floppy number $floppyCount."
  echo -n "Press return to continue, or N to quit... "
  read prompt
  if [ "$prompt" != "" ]; then
    echo "Done!"
    break
  fi

  if [ "$OSTYPE" = "SunOS4" ]; then
    # long_device is name to use for dd
    long_device=$device
  elif [ "$OSTYPE" = "Solaris" ]; then
    # Have device mount floppy so we can get a usable path
    # for dd to use (this is a kludge).  This eject really just does a query.
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

  echo "   `date` reading disk $floppyCount..."
  dd if=$long_device of=$newDir/disk$floppyCount bs=18k
  if [ $? -ne 0 ]; then
    echo "dd failure"
    eject $device
    exit 1
  fi
  eject
  echo "   `date` ... Done"
  floppyCount=`expr $floppyCount + 1`
done

ls -l $newDir
exit 0
