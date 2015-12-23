#! /bin/bash
set -x
set -v
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - setup-ship.sh
#
# Purpose - One-time setup of ship tree
#
# Uses:  $SHIPBASE must already be defined and point to an empty directory 
#  
# $Id$
#=========================================================================

comid="setup-ship.sh"

#Set ARCH to generic "Unix" for now.
ARCH="Unix"

CVSROOT="zeus:/cvs/repository"
export CVSROOT

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

if [ ! -d $shipBase ]; then
  echo "$comid[Error]:    no shipBase directory $shipBase"
  exit 1
fi

echo "Creating directories..."
for each in $releaseFolder $goodLogDir/junk $custFolder $archFolder \
    $partsDir/junk $newKeyDir/junk $messyDir/junk \
    $floppyDir/junk $shipBase/old-releases $shipTestDir/junk \
    $CDRomTempDir/junk $shipUtilsDir/junk $shipBinDir/junk \
    $shipBase/incoming/junk $shipBase/finished/junk $CDRomISODir/junk
do
  theDir=`dirname $each`
  if [ ! -d $theDir ]; then
    mkdir $theDir
  fi
  if [ ! -d $theDir ]; then
    echo "$comid[Error]:    cannot create directory for $theDir"
    exit 1
  fi
done

for each in RISC6000.AIX hppa.hpux sparc.Solaris sparc.SunOS4 \
            x86.Windows_NT x86.os2
do
  theDir=$shipBinDir/$each
  if [ ! -d $theDir ]; then
    mkdir $theDir
  fi
  if [ ! -d $theDir ]; then
    echo "$comid[Error]:    cannot create directory for $theDir"
    exit 1
  fi
done
# use short names so we can use them on the CDRom (8.3 restrictions)
for each in aix hpux solaris win_nt os2
do
  theDir=$shipUtilsDir/$each
  if [ ! -d $theDir ]; then
    mkdir $theDir
  fi
  if [ ! -d $theDir ]; then
    echo "$comid[Error]:    cannot create directory for $theDir"
    exit 1
  fi
done
echo "Setting permissions on directories..."
chmod ugo+rwx `dirname $releaseFolder`

echo "Checking out scripts..."
cd $shipBase
cvs checkout gemfire/release/ship
mv gemfire/release/ship scripts
rm -rf gemfire

echo "Creating links to shell scripts ..."
for each in archiverelease checkfloppy makefloppy moverel newfloppy \
	packrel restorerelease
do
  cat >$each <<END
#! /bin/sh
exec scripts/${each}.sh \$*
END
  chmod ugo+x $each
done

# Link to perl scripts
echo "Creating links to perl scripts ..."
for each in cdromcmp mailkey makecdromdirs makejobs makekey makemedia maketape tapecmp makecdrom
do
  cat >$each <<END
#! /bin/sh
exec scripts/${each}.pl \$*
END
  chmod ugo+x $each
done

echo "Copying zip and unzip executables ..."
# Make copies of the zip and unzip binaries that we will use
# when creating and shipping products.
for each in RISC6000.AIX hppa.hpux sparc.Solaris sparc.SunOS4 \
            x86.Windows_NT x86.os2
do
  ext=""
  if [ "$each" = "x86.Windows_NT" ]; then
    ext=".exe"
  fi
  if [ "$each" = "x86.os2" ]; then
    ext=".exe"
  fi
  theDir=$shipBinDir/$each
  if [ ! -e $theDir/zip$ext ]; then
    cd $theDir
    cp /gcm/where/zip21/$each/zip$ext zip$ext
  fi
  if [ ! -e $theDir/zip$ext ]; then
    echo "$comid[Error]:    cannot create link to zip$ext for $theDir"
    exit 1
  fi
  if [ ! -e $theDir/unzip$ext ]; then
    cd $theDir
    cp /gcm/where/unzip531/$each/unzip$ext unzip$ext
  fi
  if [ ! -e $theDir/unzip$ext ]; then
    echo "$comid[Error]:    cannot create link to unzip$ext for $theDir"
    exit 1
  fi
done

# Make links to the unzip binaries that we will ship.
for each in RISC6000.AIX hppa.hpux sparc.Solaris x86.Windows_NT x86.os2
do
  eachShort=""
  ext=""
  if [ "$each" = "RISC6000.AIX" ]; then
    eachShort="aix"
  fi
  if [ "$each" = "hppa.hpux" ]; then
    eachShort="hpux"
  fi
  if [ "$each" = "sparc.Solaris" ]; then
    eachShort="solaris"
  fi
  if [ "$each" = "x86.Windows_NT" ]; then
    ext=".exe"
    eachShort="win_nt"
  fi
  if [ "$each" = "x86.os2" ]; then
    ext=".exe"
    eachShort="os2"
  fi
  theDir=$shipUtilsDir/$eachShort
  if [ ! -e $theDir/unzip$ext ]; then
    cd $theDir
    ln -s ../../bin/$each/unzip$ext unzip$ext
  fi
  if [ ! -e $theDir/unzip$ext ]; then
    echo "$comid[Error]:    cannot create link to unzip$ext for $theDir"
    exit 1
  fi
done

cd $ORIGDIR

