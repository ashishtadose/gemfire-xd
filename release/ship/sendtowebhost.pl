#! /usr/bin/perl5
#=========================================================================
# (c) Copyright 1996-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - sendtowebhost.pl
#
# Purpose - Send a directory's files to the web host's private patch directory.
#      sendtowebhost.pl <shortName> <srcDir>
#         shortName - A short directory name.
#         srcDir    - Source directory of files to send.
#
# Creates directory <shortName> in the web host's private patch directory
# and uses ftp to put a tar file of the files from directory <srcDir>
# into <shortName>.
#
# $Id$
#
#=========================================================================


if ( $ARGV[0] eq "" || $ARGV[1] eq "" || $#ARGV != 1) {
  print "Usage: $0 <shortName> <srcDir>\n";
  exit 1;
  }

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

require "$SCRIPTDIR/misc.pl";

#=========================================================================
# Grab arguments

$shortName=$ARGV[0];
shift;

$srcDir=$ARGV[0];
shift;

if (!chdir("$srcDir")) {
  print "ERROR: unable to cd $srcDir.\n";
  print "  error = $!\n";
  exit 1;
  }

# This is the private place where we will put the new directory
$webRootDir="/www1/users/webadmin/W3/Private/PatchTest";
$webUser="webuser";
$webHost="www.gemstone.com";

# Ask for the password for the web account we will use.
system("stty -echo");
print "Enter the password for \"$webUser\"\n   on the web host \"$webHost\": ";
$webPasswd = <STDIN>;
chop($webPasswd);
system("stty echo");
print "\n";

# The <srcDir> has the files and maybe subdirs that we want transfered to
# $webHost.  Since ftp does not do recursive puts for a directory
# tree, we make a tar file called $shortName.tmp.tar, transfer this
# tar file to $webHost, extract the files with tar on $webHost,
# and remove $shortName.tmp.tar.

$bigTarFile = "$shortName.tmp.tar";
$tarBig="tar -cvf $bigTarFile *";
$status = system("$tarBig");
$status = $status >> 8;
if ($status != 0) {
  print "Error: status = $status creating tar file with this command:\n";
  print "   $tarBig\n";
  exit 1;
  }


# put the files onto the web host
print "   Attempting ftp to $webHost\n";
open(FTP, "|ftp -in $webHost");
print FTP "user $webUser $webPasswd\n";
print FTP "mkdir $webRootDir/$shortName\n";
print FTP "cd $webRootDir/$shortName\n";
print FTP "binary\n";
print FTP "verbose\n";
print FTP "put $bigTarFile\n";
print FTP "bye\n";
close(FTP);
unlink($bigTarFile);
print "$0: Finished\n";
exit 0;

