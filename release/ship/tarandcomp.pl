#! /usr/bin/perl5
#=========================================================================
# (c) Copyright 1996-2007, GemStone Systems, Inc. All Rights Reserved.
#=========================================================================
# Name - tarandcomp.pl
#
# Purpose - make a tar file and compressed files of a directory.
#  tarandcomp.pl <inDir> <outDir> <fileBase>
#        inDir    - Directory path to be tarred and compressed.
#                    We will chdir to this path and tar and compress
#                    all files and directories in this directory.
#        outDir   - Directory path for resulting files.  MUST BE FULL PATH!
#        fileBase - First part of file name for resulting files.
#
# Example) If "inDir" is /gcm/where/ship50/inventory/1-9-5.0-0-0-P001"
#   and "outDir" is /home/build/Scratch" and "fileBase" is "p001gs50_AIX"
#   (which means patch001 of GemStone version 5.0)  we will get
#   this structure:
#   /home/build/Scratch/
#               p001gs50_AIX_tar.Z    (compressed tar file)
#               p001gs50_AIX_tar.gz   (gzipped tar file)
#               p001gs50_AIX.zip      (compressed file)
#   These would each extract to GemStone5.0-RISC6000.AIX-PatchLevel001.
#   It is possible that the compressed tar file will be larger than a plain
#   tar file.  If this happens we would have the file p001gs50_AIX.tar
#   instead of p001gs50_AIX_tar.Z.  We will always get the .gz file.
#
# $Id$
#
#=========================================================================

if (-e "/bin/bash") {
    $PWDCMD = "pwd";
    $ARCH = `/bin/bash -norc -noprofile -c 'echo \$HOSTTYPE.\$OSTYPE'`;
    chop($ARCH);
    if ($ARCH =~ /hppa\.hpux/) {
      $ARCH = "hppa.hpux";
      }
    if ($ARCH =~ /sparc\.Solaris/) {
      $ARCH = "sparc.Solaris";
      }
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

$inDir = "";
$outDir = "";
$fileBase = "";
sub usage {
print "Usage: $0 ...\n";
print "tarandcomp.pl <inDir> <outDir> <fileBase>\n";
print "      inDir    - Directory path to be tarred and compressed.\n";
print "                  We will chdir to this path and tar and compress\n";
print "                  all files and directories in this directory.\n";
print "      outDir   - Directory path for resulting files.\n";
print "      fileBase - First part of file name for resulting files.\n";
}

if ( $ARGV[0] eq "" || $ARGV[1] eq "" || $ARGV[2] eq "" ||  $#ARGV != 2) {
  &usage;
  exit(1);
  }

$fileBase = "";
@tarProdList = ();
@copyProdList = ();
$copyDirName = "";


$inDir = "$ARGV[0]";
shift;
$outDir = "$ARGV[0]";
shift;
$fileBase = "$ARGV[0]";
shift;

# Check that $inDir exists:
if (! -d $inDir) {
  print "Sorry, there is no such dir $inDir.\n";
  return(1);
  }

# Create the outDir directory if it does not already exist.
if (! -e "$outDir" ) {
  mkdir($outDir, 0755);
  }
else {
  print "Using existing directory $outDir.\n";
  }

if (&tarandcomp($inDir, $outDir, $fileBase)) {
  exit(1);
  }
print "$0: Finished\n";
exit 0;
