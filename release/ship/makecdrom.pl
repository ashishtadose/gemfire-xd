#! /usr/bin/perl5 
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - makecdrom.pl
#
# Purpose - Construct files and dirs to be put onto a CDR by
#        calling collectprods.pl, make an CDRom image file of these
#        files and dirs by calling makecdromimage.pl, and burn this image
#        file onto a CDR by calling either Easy-CD Pro, Easy CD Creator,
#        or cdrecord.
#        Both collectprods.pl and makecdromimage.pl are run on the
#        local machine if it is a UNIX machine.  Otherwise if this script
#        is run from a PC those scripts are run on the UNIX machine "ship".
#        The cd writing software is run on the machine running this script.
#        Temp directories for the files and image are put under $SHIPBASE.
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
require "$SCRIPTDIR/misc.pl";
require "$SCRIPTDIR/partnummapping.pl";
require "$SCRIPTDIR/mkcderror.pl";
require "$SCRIPTDIR/chooseISO.pl";

$ext = "";
$comndSep = ";";
if ($ARCH eq "x86.Windows_NT") {
  $ext = ".exe";
  $comndSep = "&";
  }
#-------------------------------------------------------
# Miscellaneous tables...

sub numerically { $a <=> $b };

#-------------------------------------------------------
# End of boiler plate, begin of real work

#$jolietDisk = 0;
#$rockRidgeDisk = 0;
# For GSJ 4.x disks always use Joliet and Rockridge long filename extention.
$jolietDisk = 1;
$rockRidgeDisk = 1;
$preconfirmLinks = 0;

# Must use elmo or another Solaris 2.7 OS to get compatible 
# version of mkisofs that works with syntax makecdrom.pl uses.
$remHost = "lark";

if ($ARGV[0] ne "") {
  require "$SCRIPTDIR/getopts.pl";

  &Getopts("hjrRu:");
  exit 1 if ($opt_err);
  $remHost = $opt_u if ($opt_u ne "");
  $jolietDisk = 0 if ($opt_j ne "");
  if ($opt_r ne "") {
    $rockRidgeDisk = 0;
    }
  if ($opt_R ne "") {
    $rockRidgeDisk = 1;
    $preconfirmLinks = 1;
    }

  if ($opt_h ne "") {
    print "Usage: $0 [-h] [-j] [-r] [-u <hostname>]\n";
    print "This routine makes a cdrom\n";
    print "This routine calls collectprods.pl to collect product\n";
    print "directories together, then calls makecdromimage.pl to make\n";
    print "a cdrom image file (Joliet/Rockridge by default), then starts up\n";
    print "the CDR burning software.\n";
    print "   -h  Print this usage message.\n";
    print "   -j  Turn OFF Joliet format (Win95/98, NT4.0 long names).\n";
    print "   -r  Turn OFF RockRidge format (UNIX long names).\n";
#    print "         Interactively confirm links put on the disk.\n";
    print "   -R  Turn OFF RockRidge format (UNIX long names).\n";
#    print "         Interactively confirm links put on the disk.\n";
    print "  (Use -r -j together to make a standard ISO9660 disk.)\n";
    print "   -u <hostname>  If this script is running from a PC\n";
    print "         do the collectprods.pl and makecdromimage.pl\n";
    print "         on machine <hostname>.\n";
    exit 0;
    }
  }

# initialization
$procID = $$;
$cdImageFileName = "cdrom_" . "$HOSTNAME" . "_$procID" . ".iso";
$cdImageFilePath = "$unixCDRomISODir/$cdImageFileName";
$PCcdImageFilePath = "$shipBase/CDRomISODir/$cdImageFileName";
# file should not exist yet.
if (-e "$PCcdImageFilePath") {
  print "ERROR: file $PCcdImageFilePath\n";
  print "  already exists!\n";
  print "Exiting\n";
  exit 1;
  }
$cdromFilesDir = "cdrom_" . "$HOSTNAME" . "_$procID";
$cdromFilesDirPath = "$unixCDRomTempDir/$cdromFilesDir";
# dir should not exist yet.
if (-e "$shipBase/CDRomTempDir/$cdromFilesDir") {
  print "ERROR: directory $shipBase/CDRomTempDir/$cdromFilesDir\n";
  print "  already exists!\n";
  print "Exiting\n";
  exit 1;
  }

$dirscmd  = "";
$imagecmd = "";
$rmdircmd = "";
if ("$ARCH" eq "x86.Windows_NT") {
  $rmdircmd .= "rsh $remHost ";
  $dirscmd  .= "rsh $remHost ";
  $imagecmd .= "rsh $remHost ";
  $tmpshipbase = $ENV{"UNIXSHIPBASE"};
  if ("$tmpshipbase" ne "") {
    $dirscmd .= "setenv SHIPBASE $tmpshipbase; ";
    $imagecmd .= "setenv SHIPBASE $tmpshipbase; ";
    }
  }
$rmdircmd .= "rm -rf ";
$virusScan = 0;
$nortonAV = "c:\\Program Files\\Norton AntiVirus\\navw32.exe";
if(("$ARCH" eq "x86.Windows_NT") && (-f "$nortonAV")){
  # Ask if we should do a virus scan with Norton (default to yes)
  print "\nScan product files for viruses? [y] ";
  $answer = <STDIN>;
  chop($answer);
  # remove leading and trailing whitespace if any
  $answer =~ s/\s*([^\s]*)\s*/$1/;
  if ($answer eq "Y" || $answer eq "y" || $answer eq "") {
    $virusScan = 1;
    }
  }

# Create a directory with links to products in inventory, don't copy products
$dirscmd .= "cd $unixShipBase; scripts/collectprods.pl -k -c $cdromFilesDir";


# Since the -k flag for collectprods.pl creates a tree with links we MUST
# use the -f flag with makecdromimage.pl.  Otherwise the disk would get
# the links instead of the files.
# Create an ISO image file, following links
$imagecmd .= "cd $unixShipBase; scripts/makecdromimage.pl -f"
              . " -i $cdromFilesDirPath -o $cdImageFilePath";
if ($jolietDisk != 0) {
  $dirscmd .= " -l";
  $imagecmd .= " -j";
  }
if ($rockRidgeDisk != 0) {
  # Only add "-l" to $dirscmd once.
  if ($jolietDisk == 0) {
    $dirscmd .= " -l";
    }
  if ($preconfirmLinks != 0) {
    $imagecmd .= " -R -q";
    }
  else {
    $imagecmd .= " -r -q";
    }
  }
else {
  # If we are not doing a RockRidge disk, follow links instead of ignore them
# Alway follow links. See above.
#  $imagecmd .= " -f";
  }

# Create a directory structure with all the products in it.
#print "Running: $dirscmd \n";
$status = system("$dirscmd");
$status = $status >> 8;
if (! -d "$shipBase/CDRomTempDir/$cdromFilesDir") {
  # Some error in creating directory structure with all the products in it
  # or user chose to exit without creating dirs.
  # rsh may not pass command status back to us so we checked
  # for dir's existance.
  print "ERROR: did not create directory of products.\n";
  print "  command was \"$dirscmd\"\n";
  print "  status was $status\n";
  print "Exiting\n";
  exit 1;
  }
if ($status == 0) {
  # Collecting the files (or links to them) has succeeded.
  if ($virusScan == 1) {
    # Now do a virus scan
    print "\nStarting virus scan.\n";
    $startTime = time;
    $startTimeStr = &my_ctime($startTime);
    chop($startTimeStr);
    print "Start time is $startTimeStr\n";
    $nortCmd = "c: \& \"$nortonAV\"";
    $nortCmd .= " Q:\\shipgfv$shipVerStr\\CDRomTempDir\\$cdromFilesDir /S+\n";
    print "$nortCmd\n";
    $status = system("$nortCmd");
    $endTime = time;
    $endTimeStr = &my_ctime($endTime);
    chop($endTimeStr);
    print "End time is $endTimeStr\n";
    print "Finished with virus scan.\n";
    print "Check Norton Window for scan results and click Finished.\n";
    print "OK to proceed? y/n ";
    $answer = <STDIN>;
    chop($answer);
    # remove leading and trailing whitespace if any
    $answer =~ s/\s*([^\s]*)\s*/$1/;
    if ($answer ne "Y" && $answer ne "y") {
      print "ERROR: Norton AntiVirus scan returned $status.\n";
      print "  Aborting this cdrom session.\n";
      # Remove the directory structure with all the products in it.
      if (-d "$shipBase/CDRomTempDir/$cdromFilesDir") {
        $status2 = system("$rmdircmd $cdromFilesDirPath");
        $status2 = $status2 >> 8;
        if ($status != 0) {
          print "ERROR: could not remove $cdromFilesDirPath\n";
          print "  with command $rmdircmd $cdromFilesDirPath\n";
          print "  status2 = $status2\n";
          print "Exiting\n";
          exit 1;
          }
        }
      print "Exiting\n";
      exit 1;
      }
    }
  else {
    print "\nWARNING: Not doing a virus scan on the files for the CDRom!\n";
    }
  # Create a CDRom image file ready to be burned to a CDR.
  print "\n";
  $status = system("$imagecmd");
  $status = $status >> 8;
  # COMMENT OUT THIS CONDITIONAL CLEANUP TO DEBUG DIR STRUCTURE
  # Remove the directory structure with all the products in it.
  if (-d "$shipBase/CDRomTempDir/$cdromFilesDir") {
    $status2 = system("$rmdircmd $cdromFilesDirPath");
    $status2 = $status2 >> 8;
    if ($status != 0) {
      print "ERROR: could not remove $cdromFilesDirPath\n";
      print "  with command $rmdircmd $cdromFilesDirPath\n";
      print "  status2 = $status2\n";
      print "Exiting\n";
      exit 1;
      }
    }
  if(! -f "$PCcdImageFilePath") {
    # Some error in creating image file.
    # rsh may not pass command status back to us so we checked
    # for files's existance.
    print "ERROR: did not create directory of products.\n";
    print "  command was \"$imagecmd\"\n";
    print "  status was $status\n";
    print "Exiting\n";
    exit 1;
    }
  }
else {
  # Error creating a directory structure with all the products in it.
  print "ERROR: command returned non-zero status of $status\n";
  print "  command was \"$dirscmd\"\n";
  print "Exiting\n";
  exit 1;
  }

if ($status == 0) {
  # Image file found or created OK
  if ("$ARCH" eq "x86.Windows_NT") {
    if (-f "$CDRomISODir/temp.iso") {
      # clean up previous iso image file if one exists
      unlink("$CDRomISODir/temp.iso");
      }
    # Copy image file up to the PC
    print "Copying the image file up to the PC.  This will take a while...\n";
    $startTime = time;
    $startTimeStr = &my_ctime($startTime);
    chop($startTimeStr);
    print "Start time is $startTimeStr\n";

    if(! &basic_copy("$PCcdImageFilePath","$CDRomISODir/temp.iso",$ARCH,1)) {
      # Error copying a CDRom image file ready to be burned to a CDR.
      print "ERROR: could not copy\n";
      print "  from $PCcdImageFilePath\n";
      print "  to   $CDRomISODir/temp.iso\n";
      print "Exiting\n";
      if (-f "$PCcdImageFilePath") {
        unlink("$PCcdImageFilePath");
      }
      exit 1;
      }
    $endTime = time;
    $endTimeStr = &my_ctime($endTime);
    chop($endTimeStr);
    print "End time is $endTimeStr\n";
    # Remove the image file from the UNIX machine
    }
  }
else {
  # Error creating a CDRom image file ready to be burned to a CDR.
  print "ERROR: command returned non-zero status of $status\n";
  print "  command was \"$imagecmd\"\n";
  print "Exiting\n";
  exit 1;
  }

if ("$ARCH" eq "x86.Windows_NT") {
  # If we have gone this far, we have found no errors.
  # So start up the burner software with the burn-an-image config
  # file and wait for someone to press the "write" button and exit the
  # CD writing program.
  if (-f "c:\\easy-cd pro\\ecdpro.exe") {
    # This is a configuration running NT 3.51 and Easy-CD Pro 1.x
    # This is obsolete now.
    # Set the current drive to C:, cd to c:\"easy-cd pro", run ecdpro.
    $burnit = "c: \& cd c:\\\"easy-cd pro\" \& ecdpro.exe isoburn.ecd";
    print "Starting Easy CD Pro\n";
    }
  elsif (-f "c:\\Program Files\\Easy CD Creator\\Creatr32.exe") {
    # This is a configuration running NT 4.0 and Easy-CD Creator 3.5x
    # Set the current drive to C:, cd to c:\"Program Files"\"Easy CD Creator",
    # run Creatr32.exe.
    $burnit  = "c: \& cd c:\\Program Files\\Easy CD Creator \&";
    $burnit .= " Creatr32.exe c:\\CDRomIsoDir\\temp.iso";
    print "Starting Easy CD Creator\n";
    }
  elsif (-f "c:\\Program Files\\Adaptec\\Easy CD Creator 4\\Creatr32.exe") {
    # This is a configuration running NT 4.0 and Easy-CD Creator 4.0x
    # Set the current drive to C:, cd to c:\"Program Files"\"Easy CD Creator",
    # run Creatr32.exe.
    $burnit  = "c: \& cd c:\\Program Files\\Adaptec\\Easy CD Creator 4 \&";
    $burnit .= " Creatr32.exe c:\\CDRomIsoDir\\temp.iso";
    print "Starting Easy CD Creator\n";
    }
  elsif (-f "C:\\Program Files\\Roxio\\Easy CD Creator 6\\Easy CD Creator\\Creatorc.exe") {
    # This is a configuration running Win2K and Easy-CD Creator 6.0x
    # cd to C:\\Program Files\\Roxio\\Easy CD Creator 6\\Easy CD Creator,
    # run Creatorc.exe
    $burnit  = "c: \& cd C:\\Program Files\\Roxio\\Easy CD Creator 6\\Easy CD Creator \&";
    $burnit .= " Creatorc.exe c:\\CDRomIsoDir\\temp.iso";
    print "Starting Easy CD Creator 6.0\n";
    }
  else {
    # Don't know where we are!
    print "ERROR: Could not find CD burner software.  Exiting!\n";
    exit 1;
    }
  system("$burnit");
  print "Cleaning up ship iso image...\n";
  unlink("$PCcdImageFilePath");
  }
else {
  # Check for cdrecord in /usr/local/<suntyp>bin
  # and check for cdrom device.  If OK, continue, else bail out.
  #system("$burnit");
  print "\nWe will call cdrecord here\n";
  #clean up cdrom image that was made
  print "Cleaning up ship iso image...\n";
  unlink("$PCcdImageFilePath");
  }

exit 0;

sub cleanup_cdrom_dirs {
  local($dirName) = @_;
  # remove the contents of $dirName if it exists
  # $dirName should be a full path
  if ( -e $dirName) {
    print "Cleaning up $dirName\n";
    if (&remove_dir($dirName) != 0) {
      print "ERROR: could not remove dir $dirName: $!\n";
      exit(1);
      }
    }
  }

