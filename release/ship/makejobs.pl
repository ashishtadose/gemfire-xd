#! /usr/bin/perl5
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - makejobs.pl
#
# Purpose - From a cut an paste of a File Maker Pro record for a packing list,
#           create a set of files in $shipBase/incoming which each contain
#           part numbers, one file for each piece of media.
#           The goal is to keep from retyping part numbers which wastes
#           time and is error prone.
#           The files created are used by makemedia.pl.
#
# $Id$
#
#=========================================================================

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
#  delete $ENV{"PATH"}; # for safety
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

# Make stderr and unbuffered.
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

if (-e "/bin/bash") {
  $DIRSEP = "/";
  }
else {
  $DIRSEP = "\\";
  }

require "$SCRIPTDIR/define-ship.pl";


sub openJobFile {
  local ($fileName) = @_;
  if (-e $fileName) {
    print "Error, file \"$fileName\" already exists!\n";
    return 0;
    }
  if (!open(JOBFILE, "> $fileName")) {
    print "Error, could not open file \"$fileName\" for output!\n";
    return 0;
    }
  print "Creating job file $fileName\n";
  return 1;
}

sub closeJobFile {
  print JOBFILE "\n";
  print  "\n";
  close(JOBFILE);
}


$achar = "";
$ignore = 0;
$expectedRecords = 27;

# The array "field" will have the $expectedRecords strings that correspond
# to the $expectedRecords fields of a packing list.  Start them as empty
# strings so we can append characters to their ends as needed.
for ($i=0; $i < $expectedRecords; $i++) {
  $field[$i] = "";
  }

$prnVersion = "$shipVerStr";
$prnVersion =~ s/(.+)(.{1})/$1.$2.x/;

print "\nWelcome to makejobs for GemStone/J version $prnVersion\n";
print "Paste the FileMaker record to this window,\n";
print " then press the 'return' key.\n\n";

# Use raw input so we get all the control chars and don't have
# to deal with the shell's input buffering and line editing.
system("stty raw");

# Now, suck in all the chars...
$index = 0;
while (read(STDIN,$achar,1)) {
  if (("$achar" eq "\003") || ("$achar" eq "\004") ||
      ("$achar" eq "\012") || ("$achar" eq "\015")) {
    # cntl-C, cntl-D, cntl-J <LF>, cntl-M <CR>, Done
    last;
    }

  if ("$achar" gt "\176") {
    # special char, ignore
    }
  elsif ("$achar" eq "\011") {
    # cntl-), horizontal tab, field separator, move to next field
    $index++;
    }
  elsif ("$achar" eq "\013") {
    # cntl-K, vertical tab, originally typed in as a <CR>, convert to space
    $field[$index] .= " ";
    }
  else {
    $field[$index] .= "$achar";
    }
}
# Turn off raw mode (go back to cooked mode).
system("stty -raw");

# Check to see if we got all the fields we were expecting.
if ($index != ($expectedRecords - 1)) {
  $temp = $index + 1;
  print "Error: expected $expectedRecords records, found $temp\n";
  print "Exiting\n";
  exit 1;
  }
else {
  print "\n\nInput complete.  Thank you.\n";
  }

# OK, now that we have the fields lets put them into variables with
# meaningful names.

$licenseNum     = $field[0];
$licensee       = $field[1];
$shipAddress    = $field[2];
$maintExpire    = $field[3];
$warntExpire    = $field[4];
$evalExpire     = $field[5];
$orderNum       = $field[6];
$orderReqDate   = $field[7];
$requestedBy    = $field[8];
$methodShip     = $field[9];
$actualShipDate = $field[10];
$estDelivery    = $field[11];
$qtyOrdered     = $field[12];   # This has subfields
$qtySent        = $field[13];   # This has subfields
$billToAddress  = $field[14];
$partNum        = $field[15];   # This has subfields
$prodDescrpt    = $field[16];   # This has subfields
$mediaType      = $field[17];   # This has subfields
$comments       = $field[18];
$refPONum       = $field[19];
$mediaPrice     = $field[20];   # This has subfields
$intrnCostCntr  = $field[21];
$gemsmithExpire = $field[22];
$price          = $field[23];   # This has subfields
$extPrice       = $field[24];   # This has subfields
$subtotal       = $field[25];
$residencAddress= $field[26];

# Set the dir name where we will put the job files.
$orderDir = "$shipBase/incoming";

# Check for any existing job files that have this order's number.
# There should not be any!
if (!opendir(ORDERDIR, $orderDir)) {
  print "Unable to open directory $orderDir, error = $!\n";
  exit 1;
  }
for (;;) {
  $thisFile = readdir ORDERDIR;
  last if !defined($thisFile);
  next if (($thisFile eq ".") || ($thisFile eq ".."));
  if (($thisFile =~ /^$orderNum/) || ($thisFile =~ /^working_$orderNum/)) {
    print "Error, found existing job file for order number $orderNum.\n";
    print "  file \"$orderDir/$thisFile\"\n";
    print "Exiting.\n";
    closedir(ORDERDIR);
    exit 1;
    }
  }
closedir(ORDERDIR);

# Put all the items in the repeating subfields that we care about into
# separate slots in arrays, even the empty items at the end (that is why we
# use the "limit" functionality of split()).

@sentTable  = split(/\035/, $qtySent, 10000);
@partsTable = split(/\035/, $partNum, 10000);
@mediaTable = split(/\035/, $mediaType, 10000);

$num3inchFloppies = 0;
$num4mmTapes = 0;
$num8mmTapes = 0;
$numQICTapes = 0;
$numCDR = 0;
$addItem = 0;
$currentType = "";

print "\nProcessing items for order $orderNum\n";

$jobFile = "";
$index = -1;
foreach $mediaItem (@mediaTable) {
  $index = $index + 1;
  $mediaItem =~ tr/A-Z/a-z/;

  if (("$mediaItem" eq "4mm") || ("$mediaItem" eq "8mm") ||
      ("$mediaItem" eq "qic") || ("$mediaItem" =~ /^1\/4/) ||
      ("$mediaItem" eq "cdr") || ("$mediaItem" =~ /^3\.5/)) {
    # It was a new media we need to make and newMedia() processed it.
    if ("$mediaItem" eq "4mm") {
      $currentType = "4mm";
      $num = ++$num4mmTapes;
      }
    elsif ("$mediaItem" eq "8mm") {
      $currentType = "8mm";
      $num = ++$num8mmTapes;
      }
    elsif (("$mediaItem" eq "qic") || ("$mediaItem" =~ /^1\/4/)) {
      # Found 'qic' or '1/4' at beginning of $mediaItem
      # (should be '1/4"' but lets cope with typing errors).
      $currentType = "qic";
      $num = ++$numQICTapes;
      }
    elsif ("$mediaItem" eq "cdr") {
      $currentType = "cdr";
      $num = ++$numCDR;
      }
    elsif ("$mediaItem" =~ /^3\.5/) {
      # Found '3.5' at beginning of $mediaItem
      # (should be '3.5"' but lets cope with typing errors).
      $currentType = "flp";
      $num = ++$num3inchFloppies;
      }
    else {
      print "Unhandled logic error 1\nExiting\n";
      exit 1;
      }
  
    &closeJobFile();
    if ($sentTable[$index] > 0) {
      # not backordered
      if ("$currentType" eq "flp") {
        $checkDir = "$floppyDir/";
        }
      else {
        $checkDir = "$partsDir/";
        }
      $checkDir .= $partsTable[$index];
      if (! -d $checkDir) {
        # Problem, either the part number was typed in wrong
        # or the part number is for a different product line.
        print "Warning, could not find $partsTable[$index] in $shipBase\n";
        print "   Part number could be miss typed or the part could be\n";
        print "   for a different product line.\n";
        print "   Ignoring these items";
        $addItem = 0;
        }
      else {
        $addItem = 1;
        $jobFile  = "$orderDir/$orderNum" . "_" . "$currentType" . "_";
        $jobFile .= "$num" . ".txt";
        if (!&openJobFile($jobFile)) {
          print "Exiting\n";
          exit 1;
          }
        }
      }
    else {
      $addItem = 0; # backordered
      &closeJobFile();
      print "Ignoring backordered item";
      }
    }
  elsif ("$mediaItem" eq "rn") {
    # Release note, not an item we need to make
    $addItem = 0;
    $currentType = "rn";
    &closeJobFile();
    print "Ignoring Release Note";
    }
  elsif ("$mediaItem" eq "doc") {
    # Release note, not an item we need to make
    $addItem = 0;
    $currentType = "doc";
    &closeJobFile();
    print "Ignoring Doc";
    }
  elsif ("$mediaItem" eq "") {
    # Another part number for the previous media type, add to job file
    # or not just like we did before.
    if (("$currentType" eq "4mm") || ("$currentType" eq "8mm") ||
        ("$currentType" eq "qic") || ("$currentType" eq "cdr") ||
        ("$currentType" eq "flp")) {
      if ("$currentType" eq "flp") {
        $checkDir = "$floppyDir/";
        }
      else {
        $checkDir = "$partsDir/";
        }
      $checkDir .= $partsTable[$index];
      if (($addItem == 1) && ($partsTable[$index] ne "") && (! -d $checkDir)) {
        # Problem, either the part number was typed in wrong
        # or the part number is for a different product line.
        print "\nWarning, could not find $partsTable[$index] in $shipBase\n";
        print "   Part number could be miss typed or the part could be\n";
        print "   for a different product line.\n";
        print "CLOSING AND REMOVING JOB FILE $jobFile\n";
        print "   Ignoring these items";
        $addItem = 0;
        &closeJobFile();
        unlink("$jobFile");
        }
      }
    }
  else {
    # Unknown media type!
    print "Warning, do not know how to handle\n";
    print "    media type of \"$mediaItem\".\n";
    print "Ignoring this item!\n";
    $addItem = 0;
    $currentType = "unk";
    &closeJobFile();
    }

  if (($addItem == 1) && ("$partsTable[$index]" ne "")) {
    # We have an open job file of the proper name
    print JOBFILE "   $partsTable[$index]";
    print  "   $partsTable[$index]";
    }
  if (($addItem == 0) && ("$partsTable[$index]" ne "")) {
    # backordered or error or ignored items
    print  "   $partsTable[$index]";
    }


  } # foreach

&closeJobFile();
print "Done\n";
exit 0;
