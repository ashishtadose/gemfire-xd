#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - define-ship.pl
#
# Purpose - Define the environment for shipping
#   NOTE:  These names are also in define-ship.sh!
#  
# $Id$
#=========================================================================

# TODO:  use OS-specific directory delimiters
sub define_ship {
  if ($ARCH eq "x86.Windows_NT") {
    $whereDoc="//samba/where";
    }
  else {
    $whereDoc="/gcm/where";
    }
  $unixWhereDoc="/gcm/where";
  $shipVerStr = "10";
  $shipBase = $ENV{"SHIPBASE"};
  if ($shipBase) {
    print "WARNING:  overriding shipBase with $shipBase\n";
    }
  else {
    $shipBase="$whereDoc/shipgfv$shipVerStr";
    }
  $unixShipBase = $ENV{"UNIXSHIPBASE"};
  if ($unixShipBase) {
    print "WARNING:  overriding unixShipBase with $unixShipBase\n";
    }
  else {
    $unixShipBase="$unixWhereDoc/shipgfv$shipVerStr";
    }
  $releaseFolder="$shipBase/logs/releases.dat";	# log all releases

  $goodLogDir="$shipBase/goodlogs";		# logs to diff against
  $custFolder="$shipBase/logs/customers.dat";	# customer ship logs
  $archFolder="$shipBase/logs/archives.dat";	# archive tapes
  $partsDir="$shipBase/inventory";		# where the parts are kept
  $newKeyDir="$shipBase/newkeys";		# dir of keyfiles to fax
  $keyFileName="gemstone.key";                  # name of keyfile in $newKeyDir
  $keyLog="$shipBase/logs/keys-";		# keys organized by product
  $keyFileMeister="steve.shervey\@gemstone.com";   # keyfile maker person
  $messyDir="$shipBase/rawlogs";		# maketape output, Terri's
						# dir with 1000's of files
  $floppyDir="$shipBase/floppies";

  $archiveDir="$shipBase/old-releases";
  $shipTestDir="$shipBase/test";

  # The CDRomTempDir is where we put files and directories we will use
  # as sources for the cdrom we will make on a PC.  This directory
  # can become very large, up to about 700 meg.
  # Can be changed to a link on Unix.
  # If we are on an NT box, use the C: local disk.
  if ($ARCH eq "x86.Windows_NT") {
    $CDRomTempDir="C:/CDRomTempDir";
    }
  else {
    $CDRomTempDir="$shipBase/CDRomTempDir";
    }
  $unixCDRomTempDir="$unixShipBase/CDRomTempDir";

  # The CDRomISODir is where we put the CD image we will make from
  # the files in $CDRomTempDir.  This file can become very large,
  # up to about 700 meg.
  # Can be changed to a link on Unix.
  # If we are on an NT box, use the C: local disk.
  if ($ARCH eq "x86.Windows_NT") {
    $CDRomISODir="C:\\CDRomISODir";
    }
  else {
    $CDRomISODir="$shipBase/CDRomISODir";
    }
  $unixCDRomISODir="$unixShipBase/CDRomISODir";

  # Utils that we actually ship, like unzip.  Usually links to $shipBase/bin.
  $shipUtilsDir="$shipBase/utils";
  # Utils that we use in manufacturing, like zip and unzip.
  $shipBinDir="$shipBase/bin";
  }

  &define_ship;
  1;
