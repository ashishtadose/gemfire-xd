#! /usr/bin/sh
#set -xv
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - makefloppy.sh
#
# Purpose - Build floppies of given product from dd images
#
#
# $Id$
#=========================================================================

origdir=$PWD                           # where this mess was started
comid="makefloppy.sh"                  # this script

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

templog=/tmp/makefloppylog$$
rm -f $templog
tmpFile=/tmp/makefloppy$$
serialno=""                             # name of log file
serialtype=""                           # either re or fe, be, de, etc...
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

usage="Usage:  makefloppy prodNum [-sserialNo] [-ffirstFloppy] [-m] [-ddevice]
     -m          - Indicates a Master release floppy - like -sreMaster
     -sserialNo  - serial number for floppy.  If it begins with \"re\",
                   a release is logged, else a customer shipment is logged.
     -ddevice    - A floppy device; $device is the default."

#########################################################
#                                                       #
#        Collect arguments from command line            #
#                                                       #
#########################################################
unset _POSIX_OPTION_ORDER # Disable queer getopt mode
set -- `ggetopt f:md:s: $*`
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
    -m) serialno="reMaster" ;;
    -s) serialno="$1" ; shift ;;
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

if [ "x$serialno" = "x" ]; then
  echo "$comid[Error]:    No serial number, exiting."
  echo "$usage"
  exit 1
fi
serialtype=`expr "$serialno" : '^\(..\).*'`

newDir=$floppyDir/$prodName
if [ ! -d $newDir ]; then
  echo "$comid[Error]:  unable to find directory $newDir"
  exit 1
fi
cd $newDir

format_devNum=`expr $device : '.*\(.\)$'`
if [ "$OSTYPE" = "SunOS4" ]; then
  format_args="-f $device"
elif [ "$OSTYPE" = "Solaris" ]; then
  format_args="-UHf -t dos floppy$format_devNum"
else
  echo "ERROR: this script does not support ostype $OSTYPE"
  exit 1
fi

touch $templog
echo "" >> $templog
echo "Welcome to makefloppy" | tee -a $templog
echo "   Using node \"`hostname`\" - `date`" | tee -a $templog
echo "   product number = $prodName" | tee -a $templog
echo "   beginning floppy = $floppyCount" | tee -a $templog
echo "   serial number = $serialno" | tee -a $templog
echo "   device = $device" | tee -a $templog
echo ""

count=`/bin/ls -1 disk* | wc -l`
echo "This product has $count floppies." | tee -a $templog

while [ 1 ]; do
  if [ ! -f disk$floppyCount ]; then
    echo ""
    echo "You have done the last floppy." | tee -a $templog
    break
  fi
  echo 		# beep
  echo "Please insert a blank, to become floppy number $floppyCount"
  echo "Press return to continue, or N to quit... "
  read prompt
  if [ "$prompt" != "" ]; then
    echo "Exiting prematurely.  There _are_ more floppies for this product." \
                                                              | tee -a $templog
    break
  fi

  echo "   `date`" | tee -a $templog
  echo "   formatting disk $floppyCount..." | tee -a $templog
  perl $SCRIPTDIR/ourtee.pl "fdformat $format_args 2>&1" $templog
  if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR:  fdformat failure; please insert new media" | tee -a $templog
    eject $device
    continue
  fi

  if [ "$OSTYPE" = "SunOS4" ]; then
    # long_device is name to use for dd
    long_device=$device
  elif [ "$OSTYPE" = "Solaris" ]; then
    # long_device is name to use for dd
    # For disks that were originally unformated, the volume manager on
    # Solaris changes the disk's name from "unformatted" to something
    # else following the fdformat.  This takes some time so wait a bit
    # and use "eject -q" to check on volume manager's progress.
    sleep 5
    eject -q $device >/dev/null 2>&1
    status=$?
    count=0
    while [ $status -ne 0 ] && [ $count -lt 5 ]; do
      sleep 1
      eject -q $device >/dev/null 2>&1
      status=$?
      count=`expr $count + 1`
    done
    long_device=`ls $device`
    if [ "$long_device" = "" ] || [ "$long_device" = "unformatted" ]; then
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

  echo "   copying disk $floppyCount..." | tee -a $templog
  perl $SCRIPTDIR/ourtee.pl \
           "dd of=$long_device if=$newDir/disk$floppyCount bs=18k 2>&1" $templog
  if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR:  dd failure during copy; please insert new media" \
                                                             | tee -a $templog
    eject $device
    continue
  fi

  echo "   reading disk $floppyCount..." | tee -a $templog
  perl $SCRIPTDIR/ourtee.pl \
                     "dd if=$long_device of=$tmpFile bs=18k 2>&1" $templog
  if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR:  read failure during verify; please insert new media" \
                                                             | tee -a $templog
    eject $device
    continue
  fi
  echo "   comparing disk $floppyCount..." | tee -a $templog
  cmp -s $tmpFile $newDir/disk$floppyCount
  if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR:  compare failure; please insert new media" | tee -a $templog
    eject $device
    rm -f $tmpFile
    continue
  fi
  rm -f $tmpFile

  echo "   `date` verification success disk $floppyCount" | tee -a $templog
  eject $device
  floppyCount=`expr $floppyCount + 1`
done

echo "Completed - `date`"                 | tee -a $templog

# Log it
if [ "$serialtype" = "re" ]; then
  logName=$releaseFolder
else
  logName=$custFolder
fi

echo ""
echo "$comid[Info]:     Backing up $logName to $logName.BAK..."
cp $logName ${logName}.BAK

echo "$comid[Info]:     Adding release entry to $logName..."
$SCRIPTDIR/addfolder.sh $logName $templog $serialno
if [ $? -ne 0 ]; then
  echo "$comid[Error]:    Unable to update $logName"
  echo "    log is in ${templog}"
  # don't delete the log!
  exit 1
fi

messyFile=$messyDir/$serialno.log
if [ -f $messyFile ]; then
  echo "$comid[Info]:     Appending copy of log to $messyDir/$serialno.log"
  cat $templog >>$messyFile
else
  echo "$comid[Info]:     Creating copy of log in $messyDir/$serialno.log"
  cp $templog $messyFile
fi
chmod 666 $messyFile

rm -f $templog
echo "$comid[Info]:     Completed successfully - `date`."
exit 0
