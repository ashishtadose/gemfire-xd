#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - define-ship.sh
#
# Purpose - Set up environment variables for release scripts (private)
#   NOTE:  These names are also in define-ship.pl!
#  
# $Id$
#=========================================================================

shipVerStr="11"
if [ "$SHIPBASE" != "" ]; then
  #shipBase=/denim3/users/jason/gs35/build/ship/foo/ship
  echo "WARNING:  overriding shipBase with $SHIPBASE"
  shipBase=$SHIPBASE
else
  shipBase=/gcm/where/shipgfv$shipVerStr
fi


releaseFolder=$shipBase/logs/releases.dat	# log all releases

goodLogDir=$shipBase/goodlogs			# logs to diff against
custFolder=$shipBase/logs/customers.dat	        # customer ship logs
archFolder=$shipBase/logs/archives.dat		# archive tapes
partsDir=$shipBase/inventory			# where the parts are kept
newKeyDir=$shipBase/newkeys			# keyfiles to fax
keyLog=$shipBase/logs/keys-			# keys organized by product
messyDir=$shipBase/rawlogs			# maketape output, Terri's
						# dir with 1000's of files
floppyDir=$shipBase/floppies

archiveDir=$shipBase/old-releases
shipTestDir=$shipBase/test

# The CDRomTempDir is where we put files and directories we will use
# as sources for the cdrom we will make on a PC.  This directory
# can become very large, up to about 700 meg.
# Can be changed to a link on Unix.
# If we are on an NT box, use the C: local disk.
if [ "$ARCH" = "x86.Windows_NT" ]; then
  CDRomTempDir=C:\\CDRomTempDir
else
  CDRomTempDir=$shipBase/CDRomTempDir
fi

# The CDRomISODir is where we put the CD image we will make from
# the files in $CDRomTempDir.  This file can become very large,
# up to about 700 meg.
# Can be changed to a link on Unix.
# If we are on an NT box, use the C: local disk.
if [ "$ARCH" = "x86.Windows_NT" ]; then
  CDRomISODir=C:\\CDRomISODir
else
  CDRomISODir=$shipBase/CDRomISODir
fi

# Utils that we actually ship, like unzip.  Usually links to $shipBase/bin.
shipUtilsDir=$shipBase/utils
# Utils that we use in manufacturing, like zip and unzip.
shipBinDir=$shipBase/bin

