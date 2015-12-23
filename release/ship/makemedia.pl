#! /usr/bin/perl5
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - makemedia.pl
#
# Purpose - From a set of files in $shipBase/incoming which each contain
#           part numbers, call maketape or makefloppy or makecdromdirs
#           with the appropriate args.  If successful, move the file
#           from "incoming" to "finished".
#           The goal is to keep from retyping part numbers which wastes
#           time and is error prone.
#           The files in "incoming" are created by makejobs.pl.
#
# $Id$
#
#=========================================================================

print "$0: Initializing, please wait...\n";

if ( -e "/export/localnew/scripts/suntype" ) {
  $HOSTTYPE = `/export/localnew/scripts/suntype -hosttype`;
  chomp( $HOSTTYPE );
  $OSTYPE = `/export/localnew/scripts/suntype -ostype`;
  chomp($OSTYPE);
  $HOSTTYPE_OSTYPE = "$HOSTTYPE.$OSTYPE";
  $ARCH = $HOSTTYPE_OSTYPE;
  $PWDCMD = "pwd";
} elsif ($ENV{"OS2_SHELL"} ne "") {
    $PWDCMD = "cd";
    $ARCH = "x86.os2";
} elsif ($ENV{"OS"} eq "Windows_NT") {
  $ARCH = "x86.Windows_NT";
  # print STDERR "WARNING: assuming that MKS toolkit is _not_ installed.\n";
  delete $ENV{"SHELL"}; # for safety
  delete $ENV{"PATH"}; # for safety
  $PWDCMD = "cd";
  }
else {
  die "cannot determine architecture";
  }

sub getcwd {
    local($result) = `$PWDCMD`;
    $result =~ s@^/tmp_mnt@@;
    chop($result);
    $result;
}


sub get_my_name {
    local($myName, $myPath);

    $ORIGDIR = &getcwd;
    # $myName = $^X;
    $myName = $0;
    if ($myName =~ m@.*/.*@) {    # invoked with explicit directory path
	$SCRIPTNAME = $myName;
	$SCRIPTNAME =~ s@.*/([^/]+)@$1@;
	$SCRIPTDIR = $myName;
	$SCRIPTDIR =~ s@(.*)/[^/]+@$1@;
    } else { # invoked from current directory
	$SCRIPTNAME = $myName;
	$SCRIPTDIR = $ORIGDIR;
    }

    if (!chdir($SCRIPTDIR)) {
	die "cannot chdir to perl directory $SCRIPTDIR: $!\n";
    }
    $SCRIPTDIR = &getcwd;
    if (!chdir($ORIGDIR)) {
	die "cannot chdir to original directory $ORIGDIR: $!\n";
    }
}
&get_my_name;

if ($ARCH eq "x86.os2") {
  $HOSTNAME = $ENV{"HOSTNAME"};
  }
elsif ($ARCH eq "x86.Windows_NT") {
  $HOSTNAME = $ENV{"COMPUTERNAME"};
} else {
  $HOSTNAME = `uname -n`;
  chop($HOSTNAME);
  }

# Make stderr and stdout unbuffered.
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

if (-e "/bin/bash") {
  $DIRSEP = "/";
  }
else {
  $DIRSEP = "\\";
  }

require "$SCRIPTDIR/define-ship.pl";

if (!chdir($shipBase)) {
  die "cannot chdir to perl directory $shipBase: $!\n";
  }

sub do_menu {
  local ($menu_type, $columns) = @_;
  local (@choices);
  local ($thisFile, $answer);
  local ($i, $j, $k, $nlines, $item);

  # Get list of files of proper type
  if (!opendir(INCOMINGDIR, "incoming")) {
    print "Unable to open directory \"incoming\", error = $!\n";
    return "";
    }
  @choices = ();
  for (;;) {
    $thisFile = readdir INCOMINGDIR;
    last if !defined($thisFile);
    # Ignore files/directories ".", "..", and those that start with "working_"
    next if (($thisFile eq ".") || ($thisFile eq "..") ||
             ($thisFile =~ /^working_/));
    if (("$menu_type" eq "tape") &&
        (($thisFile =~ /_4mm_/) || ($thisFile =~ /_8mm_/) ||
                                    ($thisFile =~ /_qic_/))){
      push(@choices, $thisFile);
      }
    if (("$menu_type" eq "4mm") && ($thisFile =~ /_4mm_/)) {
      push(@choices, $thisFile);
      }
    if (("$menu_type" eq "8mm") && ($thisFile =~ /_8mm_/)) {
      push(@choices, $thisFile);
      }
    if (("$menu_type" eq "qic") && ($thisFile =~ /_qic_/)) {
      push(@choices, $thisFile);
      }
    if (("$menu_type" eq "flp") && ($thisFile =~ /_flp_/)) {
      push(@choices, $thisFile);
      }
    if (("$menu_type" eq "cdr") && ($thisFile =~ /_cdr_/)) {
      push(@choices, $thisFile);
      }
    if ("$menu_type" eq "all") {
      push(@choices, $thisFile);
      }
    }
  closedir(INCOMINGDIR);

  if ($#choices == $[ - 1) {
    print "Sorry, no orders of type $menu_type.\n";
    return "";
    }

  @choices = sort(@choices);

  # Display the list
  print "\n";
  $nlines = int(($#choices + 1) / $columns);
  if ((($#choices + 1) % $columns) > 0) {
    $nlines = $nlines + 1;
    }
  for ($i = 0; $i < $nlines; $i ++) {
    for ($j = 0; $j < $columns; $j ++) {
      $item = ($i * $columns) + $j;
      if ($item <= $#choices) {
        printf("%2d. %s", $item + 1, $choices[$item]);
        for ($k = 1;
             $k < (int(80 / $columns) - length($choices[$item]) - 3); $k++){
          print " ";
          }
        }
      }
    print "\n";
    }
  print "\n";
  print "Enter choice number (just to return to exit)  ";
  $answer = <STDIN>;
  chop($answer);
  # remove leading and trailing whitespace if any
  $answer =~ s/\s*([^\s]*)\s*/$1/;

  if ($answer eq "") {
    # They're bailing
    return "";
    }
  if (($answer < 1) || ($answer > ($#choices + 1))) {
    # They're bailing
    return "";
    }
  $answer = $answer - 1 + $[; # zero-base
  return ($choices[$answer]);
}

#-------------------------------------------------------
# Miscellaneous tables...

sub numerically { $a <=> $b };

#-------------------------------------------------------
# End of boiler plate, begin of real work
sub usage {
  print "Usage:   drive <media-type>\n";
  print "  <media-type> may be one of the following:\n";
  print "  tape 4mm 8mm qic flp cdr all\n";
  print "If <media-type> is omitted the user is prompted for it.\n";
}

sub media_type_ok {
  local ($type) = @_;
  foreach $tmp (@mediaList) {
    if ("$type" eq "$tmp") {
      return(1);
      }
  }
  return(0);
}

# Keep in this order! We depend on it if no arg given!
@mediaList = ("all", "tape", "cdr", "8mm", "4mm", "qic", "flp");

# initialization
if ($ARGV[0] ne "") {
  if (&media_type_ok($ARGV[0]) == 1) {
    $type = $ARGV[0];
    }
  else {
    &usage;
    exit 1;
    }
  }
else {
  # Prompt the user
  print "Select a media type you wish to work with:\n";
  print "  1. All media\n";
  print "  2. All tape types\n";
  print "  3. CDR\n";
  print "  4. 8mm tape\n";
  print "  5. 4mm tape\n";
  print "  6. QIC-150 tape\n";
  print "  7. Floppies\n";
  print "Enter your choice number: ";
  $prompt = <STDIN>;
  chop($prompt);
  # remove leading and trailing whitespace if any
  $prompt =~ s/\s*([^\s]*)\s*/$1/;

  if (($prompt >= 1) && ($prompt <= 7)) {
    $type = $mediaList[($prompt - 1)];
    }
  else {
    print "Choice out of range.  Exiting.\n";
    exit 1;
    }
  }

$prnVersion = "$shipVerStr";
$prnVersion =~ s/(.+)(.{1})/$1.$2.x/;

print "\nWelcome to makemedia for GemStone/J version $prnVersion\n";
print "You have chosen to work with $type media for this session\n\n";

for (;;) {
  $choice = &do_menu($type, 3);
     # $choice now has a file name of the form "sssss_ddd_n.txt"
     # The "sssss" is a serial/order "number" which may be any set of
     #   chars and may be any length.
     # The "ddd" must be from this list: 4mm 8mm qic cdr flp
     # The "n" will be some integer made up of 1 or more digits.
     # The file may be multi line and will have all the part numbers to be
     # written to a particular piece of media.
     # For floppies, there must be only one part number in the file.

  $device = "";  # tape device to write to.
  $serial = "";  # serial/order number
  $cmd    = "";
  $parts  = "";
  if ("$choice" ne "") {
    # Rename job file to "working_" prefix to let others know we are
    # running this job now.
    if (-e "incoming/working_$choice") {
      # Someone else has already grabbed this job while we were waiting
      # for the user to make their selection.
      print "This job is already being run by another user.\n";
      print "Continuing.  Try again.\n";
      next;
      }      
    if (!rename("incoming/$choice", "incoming/working_$choice")) {
      print "ERROR, could not rename\n";
      print "   incoming/$choice\n";
      print "to incoming/working_$choice\n";
      print "Continuing.  Try again.\n";
      next;
      }      
    $serial = $choice;
    $serial =~ s/(.*)_.*_.*/$1/;
    # Now read the part numbers out of file name $choice
    if (!open(INFILE, "< incoming/working_$choice")) {
      print "$0: unable to open input file incoming/$choice.\n";
      print "error = $!\n";
      exit 1;
      }
    while (<INFILE>) {
      $tmpinput = $_;
      # remove newlines
      chop($tmpinput);
      # make one long space separated string
      $parts .= "$tmpinput ";
      }
    if (!close(INFILE)) {
      print "$0: error closing $inFile.\n";
      print "  error = $!\n";
      }
    if ("$parts" eq "") {
      print "ERROR: file named \"working_$choice\" seems to be empty.\n";
      print "Continuing.  Try again.\n";
      next;
      }

    if (($choice =~ /_4mm_/) || ($choice =~ /_8mm_/) || ($choice =~ /_qic_/)) {
      # Prompt for tape device
      print "Enter tape device to use (for example  /dev/rst3): ";
      $device = <STDIN>;
      chop($device);
      $device =~ s/"/\\"/g;
      $cmd = "./maketape -s $serial -t $device $parts";
      }
    elsif ($choice =~ /_flp_/) {
      if ($parts =~ /\s*\S+\s+\S+/) {
        # Found two or more part numbers in $parts.
        # zero or more white space then
        # one or more non-whitespace then
        # one or more whitespace then
        # one or more non-whitespace again
        # (Two or more part numbers).
        print "ERROR: makefloppy can only have a single part number.\n";
        print "  file name $choice\n";
        print "  parts = \"$parts\"\n";
        print "Continuing.  Try again.\n";
        next;
        }
      else {
        $cmd = "./makefloppy -s $serial $parts";
        }
      }
    elsif ($choice =~ /_cdr_/) {
      $cmd = "perl ./scripts/makecdromdirs.pl -s $serial $parts";
      }
    else {
      print "ERROR: do not know how do deal with file named \"$choice\"\n";
      print "Continuing.  Try again.\n";
      next;
      }

    # Now run the command
    print "\nAbout to run:\n\n$cmd\n\nTry to run this job? [y] ";
    $answer = <STDIN>;
    chop($answer);
    $answer =~ s/"/\\"/g;
    if (("$answer" eq "Y") || ("$answer" eq "y") || ("$answer" eq "")) {
      print "Running job.\n\n";
      $ret = system("$cmd 2>&1") >> 8;
      if ($ret == 0) {
        # move job file to "finished"
        if(!rename("incoming/working_$choice", "finished/$choice")) {
          print "ERROR, could not rename\n";
          print "   incoming/working_$choice\n";
          print "to finished/$choice";
          print "Continuing.  Try again.\n";
          next;
          }      
        }
      else {
        # error in job, print message
        print "ERROR, problem with running job file\n";
        print "  incoming/$choice\n";
        print "Return value was $ret\n";
        }
      }
    else {
      print "Not running job.\n";
      }
    }
  else {
    print "Nothing selected.\n";
    }
  print "Do another? [y] ";
  $prompt = <STDIN>;
  chop($prompt);
  $prompt =~ s/"/\\"/g;
  if ($prompt eq "n" || $prompt eq "N") {
    last;
    }
  }

exit 0;
