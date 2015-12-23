#! /usr/bin/perl5
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - mkcderror.pl
#
# Purpose - error exit routine for making directories to put on cdrom
#           This file redefines the error_exit() routine from misc.pl
#           Do a "require" of this file after the require for misc.pl
#           in order to redefine "error_exit()".
#
# $Id$
#
#=========================================================================

# cleanup and exit.  We are redefining here the subroutine from misc.pl
sub error_exit {
  local($dirName) = @_;
  print "Exiting\n";
  close(CONTENTS);
  &cleanup_cdrom_dirs($dirName);
  exit(1);
  }

1;
