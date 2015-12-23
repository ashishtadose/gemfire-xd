#! /bin/perl5
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - makecdromimage.pl
#
# Purpose - Construct a CD image file for burning onto a CDR.
#           Allow basic ISO 9660, RockRidge extensions, and Joliet extensions.
#           RockRidge is an extension to ISO 9660 that allows links and
#           UNIX style file names (long names and dot files).
#           RockRidge is confirmed supported on Solaris 2.5.1 and 2.6,
#           HPUX 10.10, 10.20, and 11.0, and AIX 4.1.5 and 4.2.
#           Other systems and other versions MAY support RockRidge
#           but they have not been tested here.
#           Joliet is an extension to ISO 9669 that allows long file names
#           and Unicode characters in the names (up to 64 chars).
#           Joliet is supported on NT 4.x and Win95/Win98.
#
#           When making a RockRidge image you really should be on a UNIX
#           machine.  Since PCs know nothing about symbolic links for
#           files and directories they will not be preserved as links
#           in an image made on a PC.
#
# Examples of mounting/unmounting a RockRidge CD:
#      Solaris: Can be any regular user (root access not required).
#               RockRidge extensions are automaticly detected and used.
#
#               Mounting the CDRom is done automatically under /cdrom when
#                 the cd is placed in the drive.
#
#               Umounting is done with "eject cdrom" after all processes
#                 accessing the cdrom are finished and after all shells
#                 "cd"ed to the cdrom have "cd"ed elsewhere.
#
#      AIX: Must be root.  A directory to use as a mount point must exist
#             (like /mnt or /cdrom).
#             RockRidge extensions are automaticly detected and used.
#
#           YOU HAVE TO BE ROOT FOR ALL OF THE FOLLOWING.
#             To mount CDRom at /mnt, as root do:
#               Put the CDRom in the drive.
#               mount -o ro -v cdrfs /dev/cd0 /mnt
#
#             To unmount CDRom at /mnt, as root do:
#               umount /mnt
#               Push the eject button and take the CDRom from the drive.
#
#     HPUX: Must be root.  A directory to use as a mount point must exist
#             (like /mnt or /cdrom).
#           RockRidge extensions are NOT detected and used by the
#           HPUX standard mount commands and drivers.  A special
#           set of daemons and mount commands MUST be used.
#
#           YOU HAVE TO BE ROOT FOR ALL OF THE FOLLOWING.
#             As root check for the following daemons.  Start them like
#             this if they are not running:
#                 /usr/sbin/pfs_mountd &
#                 /usr/sbin/pfsd &
#
#             Make sure the /etc/pfs_fstab has the right info.  For example
#             with a cdrom at   /dev/dsk/c1t2d0   to be mounted at /cdrom
#             use this line in /etc/pfs_fstab:
#                 /dev/dsk/c1t2d0 /cdrom pfs-rrip xlat=unix 0 0
#
#             To mount the CDRom at /cdrom do:
#                 Put the CDRom in the drive.
#                 /usr/sbin/pfs_mount /cdrom
#
#             To umount the CDROM that is at /cdrom do:
#                 /usr/sbin/pfs_umount /cdrom
#                 Push the eject button and take the CDRom from the drive.
#
#             To stop the pfs daemons, use "kill -TERM" on their processes ids
#             BUT ONLY AFTER THE CD IS UNMOUNTED.
#
#
#
# $Id$
#
#=========================================================================

print "$0: Initializing\n";

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

require "$SCRIPTDIR/getopts.pl";
require "$SCRIPTDIR/misc.pl";

#-------------------------------------------------------
# End of boiler plate, begin of real work

sub list_links {
  local ($theDir,*relPathLinks,*fullPathLinks,*excludeList) = @_;
  local (@dirsToSearch);
  local ($thisFile, $theLink, $each, $check);

  if ( ! -e "$theDir" ) {
    print "$0: directory $theDir does not exist\n";
    print "  error = $!\n";
    return 0;
    }
  # Collect list of files and directories
  if (!opendir(THISDIR, $theDir)) {
    print "Unable to open directory $theDir, error = $!\n";
    return 1;
    }
  for (;;) {
    $check = 1;
    $thisFile = readdir THISDIR;
    if (!defined($thisFile)) {
      last;
      }
    if ($thisFile eq "." || $thisFile eq "..") {
      next;
      }
    $thisFile = "$theDir/$thisFile";
    # Check exclude list, don't check or follow if found in list
    foreach $each (@excludeList) {
      if ("$each" eq "$thisFile") {
        $check = 0;
        }
      }
    if (!$check) {
      next;
      }
    if ( -l $thisFile) {
      $theLink = readlink($thisFile);
      if (($theLink =~ /^\//) || ($theLink =~ /^\\/)) { 
        push(@fullPathLinks,"$thisFile  ->  $theLink");
        }
      else {
        push(@relPathLinks,"$thisFile  ->  $theLink");
        }
      }
    elsif ( -d $thisFile) {
      push(@dirsToSearch, $thisFile);
      }
    }
  closedir(THISDIR);

  foreach $thisFile (@dirsToSearch) {
    if (&list_links($thisFile,*relPathLinks,*fullPathLinks,*excludeList)) {
      return 1;
      }
    }
  return 0;
  }

sub usage {
  print "Usage: $SCRIPTNAME [-f] [-h] [-r] -[R] [-j] [-q] -i <dir> -o <path> [-x <path_list>]
  This script uses mkisofs to construct a CD image file in ISO9660 format,
  RockRidge format, or Joliet format.  This image is suitable for burning
  onto a CDR.  RockRidge is an extension to ISO9660 for use on UNIX that
  allows links and UNIX style file names (long names and dot files).
  A RockRidge CD will not be very useful/readable on a Windows PC.
  Joliet is an extension to ISO9660 for NT 4.x and Win95/Win98 that allows
  long Unicode file names.  A Joliet CD will not be very useful/readable on
  UNIX.
   Options:
      -f        Follow symbolic links when generating the image.  The default
                  is to enter the links as links for RockRidge images
                  and IGNORE links for all other formats.
      -h        Display this usage message.
      -q        Quiet.  Tell mkisofs to not print out the gory details of
                  the long to short name mapping conflicts as they are
                  found and resolved.
      -r        Make a RockRidge image and ask for links to be verified.
      -R        Make a RockRidge image and pre-confirm all links as OK.
      -j        Make a Joliet image.
      -i <dir>  Input directory.  This is the root of the directory structure
                  that will be put into the image.  The directory \"<dir>\" will
                  become \"/\" on the cdrom.
      -o <path> Output file.  This is the file where the CDRom image will
                  written.  The file extension \".iso\" will be added if
                  its not on already.  This is the file that will be
                  used by the CDR maker to burn a CD.  DO NOT PUT THIS FILE
                  UNDER THE INPUT DIRECTORY.
      -x <path_list>  Exclude list.  A space delimited list of file and/or
                  directory paths to exclude from the CD image.  Paths are
                  relative to the \"-i <dir>\" path.  If used, this option
                  MUST be the last one on the command line since all items
                  after the -x will be treated as paths to exclude.
";
  }

$mkisoOpts = "-a -A \"GEMSTONE PRODUCTS\" -d -L -P \"GEMSTONE SYSTEMS, INC.\"";
$mkisoOpts .= " -D -p \"GEMSTONE SYSTEMS, INC.\" -V GEMSTONE_PRODUCTS";
$mkisoOpts .= " -no-split-symlink-components -no-split-symlink-fields";

$outFile = "";
$inDir = "";
@excludeList = ();
$followLinks = 0;
$quiet = 0;
$rockRidgeImage = 0;
$linksPreVerified = 0;
$jolietImage = 0;

$startTime = time;
$startTimeStr = &my_ctime($startTime);
chop($startTimeStr);
print "Start time is $startTimeStr\n";
 
# Parse the command line options.
&Getopts("fhrRji:qo:x");
exit 1 if ($opt_err);
if ($opt_f ne "") {
  # Follow links
  $mkisoOpts .= " -f";
  $followLinks = 1;
  }
if ($opt_q ne "") {
  # quiet
  $mkisoOpts .= " -q";
  $quiet = 1;
  }
if ($opt_r ne "") {
  $mkisoOpts .= " -r";
  $rockRidgeImage = 1;
  }
if ($opt_R ne "") {
  $mkisoOpts .= " -r";
  $rockRidgeImage = 1;
  $linksPreVerified = 1;
  }
if ($opt_j ne "") {
  # quiet
  $mkisoOpts .= " -J";
  $jolietImage = 1;
  }
if ($opt_h ne "") {
  &usage;
  exit 0;
  }
$inDir = $opt_i if ($opt_i ne "");
$outFile = $opt_o if ($opt_o ne "");
if ($opt_x ne "") {
  # Add paths to the exclude list
  for (;;) {
    last if $ARGV[0] eq "";
    push(@excludeList, "$inDir" . "$DIRSEP". "$ARGV[0]");
    shift;
    }
  }

# Check for required items
if (("$inDir" eq "") || ("$outFile" eq "")) {
  print "ERROR: must give \"-i <dir>\" and \"-o <path>\"\n";
  &usage;
  exit 1;
  }
if ( ! ($outFile =~ /.*\.iso/)) {
  # Add .iso to the end of the filename if it is missing
  $outFile .= ".iso";
  }
if (! -e "$inDir") {
  print "ERROR: directory $inDir\n";
  print "  does not exist!\n";
  print "Exiting\n";
  exit 1;
  }
if (-e "$outFile") {
  print "ERROR: file $outFile\n";
  print "  already exists!\n";
  print "Exiting\n";
  exit 1;
  }

if (("$ARCH" eq "x86.Windows_NT") && ($rockRidgeImage == 1)) {
  print "WARNING: you are running on a PC and asking to make a\n";
  print "  Rock Ridge image.  Be aware that PCs don't know about links\n";
  print "  and therefore links can not be preserved in this image!\n";
  print "Do you wish to continue making the image? [n|y] ";
  $answer = <STDIN>;
  chop($answer);
  # remove leading and trailing whitespace if any
  $answer =~ s/\s*([^\s]*)\s*/$1/;
  if ($answer eq "N" || $answer eq "n" || $answer eq "") {
    print "OK, sorry I couldn't help you.\n";
    exit 1;
    }
  }

$mkisoOpts .= " -o $outFile";
foreach $each (@excludeList) {
  $mkisoOpts .= " -x $each";
  }
$mkisoOpts .= " $inDir";

$mkisoCmd = "mkisofs $mkisoOpts";

@relPathLinks = ();
@fullPathLinks = ();

if ($followLinks == 0) {
  # Saving links as links in the CD image.
  &list_links($inDir,*relPathLinks,*fullPathLinks,*excludeList);
  if (@relPathLinks > 0) {
    print "\nRelative path links:\n";
    print "--------------------\n";
    foreach $line (@relPathLinks) {
      print "$line\n";
      }
    print "\n";
    }
  if (@fullPathLinks > 0) {
    print "\nFull path links:\n";
    print "--------------------\n";
    foreach $line (@fullPathLinks) {
      print "$line\n";
      }
    if ($rockRidgeImage != 0) {
      print "\nWARNING! WARNING!\n";
      print "  Links to full paths will be preserved and will point\n";
      print "  to the wrong place if they are intended to point to items\n";
      print "  on the CDRom!\n\n";
      }
    else {
      print "\nDANGER!\n";
      print "  Links will be IGNORED and will NOT be put on the CDRom!\n\n";
      }
    }
  if (@relPathLinks > 0) {
    if ($rockRidgeImage != 0) {
      print "\nCAUTION:\n";
      print "Examine the list of symbolic links carefully!  Links are being\n";
      print "preserved on this image.  If a link points to a file\n";
      print "or directory that is not being put in the image, the link\n";
      print "will likely not get resolved (will be broken) when the CDRom\n";
      print "is mounted.\n\n";
      }
    else {
      print "\nDANGER!\n";
      print "  Links will be IGNORED and will NOT be put on the CDRom!\n\n";
      }
    }
  if (((@relPathLinks > 0) || (@fullPathLinks > 0)) && ($linksPreVerified == 0)){
    print "Is this disposition of links OK? [n|y] ";
    $resp = <STDIN>;
    chop($resp);
    # remove leading and trailing whitespace if any
    $resp =~ s/\s*([^\s]*)\s*/$1/;
    if (($resp ne "y") && ($resp ne "Y")) {
      print "Exiting without making image file\n";
      exit 1;
      }
    }
  }
else {
  print "Following links instead of preserving them\n";
  }
print "Running the following command:\n";
print "  $mkisoCmd\n";
$status = system("$mkisoCmd");
$status = $status >> 8;
if ($status != 0) {
  print "command returned non-zero exit status of $status: $!\n";
  exit 1;
  }
$endTime = time;
$endTimeStr = &my_ctime($endTime);
chop($endTimeStr);
print "End time is $endTimeStr\n";
exit 0;
