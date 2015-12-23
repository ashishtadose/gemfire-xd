#!/usr/bin/perl5
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - ourtee.pl
#
# Purpose - execute a command sending command's stdout
#           to standard out in real time and also to a buffered outfile
#           with the return status being the command's return status.
#
# This program basicly does "command | tee -a outfile" but returns
# the exit status of "command" instead of the exit status of "tee".
#
# example usage from a shell program:
#    perl ourtee.pl "fdformat -f /dev/floppy 2>&1" logfile.txt
#    stat=$?
#
#
# $Id$
#
#=========================================================================


sub ourtee {
  local($cmd, $outfile) = @_;
  local($stat);

  if (($cmd eq "") || ($outfile eq "")) {
    print "Usage:  ourtee(command, outfile)";
    return 1;
  }
  # Make stderr and stdout unbuffered.
  select(STDERR); $| = 1;
  select(STDOUT); $| = 1;


  # Open the command as an input pipe.
  open( IN, "$cmd|" ) || die( "failed" );

  # Open what would be the destination of tee.
  open( OUT, ">>$outfile" );

  while(read(IN,$char, 1)) {
    # Output to both stdout and the logfile.
    print $char;
    print OUT $char;
  }

  close( OUT );
  close( IN );
  # Close everybody
  # Now that we closed a pipe, $? is the status word.
  # $? >> 8 is the exit value of the subprocess.
  $stat = ($? >> 8);
  return $stat;
}

if ( $ARGV[0] eq "" || $ARGV[1] eq "" || $#ARGV < 1) {
  print "Usage:  perl ourtee.pl command outfile";
  exit 1;
}

exit &ourtee($ARGV[0],$ARGV[1]);
