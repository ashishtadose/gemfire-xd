#! /bin/perl5
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - tapecmp.pl
#
# Purpose - See if a tape matches the release
# 		argument 1: the device where the tape is
# 		argument 2: the product number
#
# $Id$
#
#=========================================================================

#require "getcwd.pl";

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


require "$SCRIPTDIR/define-ship.pl";

# Some basic environment
#$scratch=&getcwd;
$scratch="$shipBase/test";
$testDir="$scratch/tapecmp$$";
$tapeDir="$testDir/tape";
$distDir="$testDir/dist";
$tapeList="$testDir/tapefiles";
$distList="$testDir/distfiles";

#=========================================================================
# Grab arguments
if ( $ARGV[0] eq "" || $ARGV[1] eq "" || $#ARGV < 1) {
  print "Usage: $0 <device> <prodNum> {<prodNum>}\n";
  &cleanup(1);
  }

$device=$ARGV[0];
shift;

$prodList = "";
foreach $arg (@ARGV) {
  $prodList = "$prodList $arg";
  die "$0:  No such part $partsDir/$arg" if ( ! -d "$partsDir/$arg");
  }


#=========================================================================
# Set up the test environment (isolate us from the basic environment)
if (!chdir($scratch)) {
  die "cannot chdir to $scratch: $!\n";
  }
if (!mkdir($testDir, 0755)) {
  print "unable to mkdir $testDir.\n";
  print "  error = $!\n";
  &cleanup(1);
  }
print "Test directory is $testDir\n";

if (!mkdir($tapeDir, 0755)) {
  print "unable to mkdir $tapeDir.\n";
  print "  error = $!\n";
  &cleanup(1);
  }

if (!mkdir($distDir, 0755)) {
  print "unable to mkdir $distDir.\n";
  print "  error = $!\n";
  &cleanup(1);
  }

#=========================================================================
# Extract the tape

if (!chdir($tapeDir)) {
  die "cannot chdir to $tapeDir: $!\n";
  }
print "Unpacking the tape...\n";
$status = system("tar -xf $device") >> 8;
if ( $status != 0) {
  print "tar unpack of tape failed\n";
  &cleanup(1);
  }

#=========================================================================
# create the release file
print "creating the distribution...\n";
if (!chdir($shipBase)) {
  die "cannot chdir to $shipBase: $!\n";
  }
$status = system(
    "maketape -t$testDir/fromship.tar -stest $prodList >$testDir/maketape.log")
    >> 8;
if ( $status != 0 ) {
  system("cat $testDir/maketape.log");
  unlink("$testDir/maketape.log");
  print "maketape error\n";
  &cleanup(1);
  }
unlink("$testDir/maketape.log");

#=========================================================================
# Extract the distribution
print "Unpacking the distribution...\n";
if (!chdir($distDir)) {
  die "cannot chdir to $distDir: $!\n";
  }
$status = system("tar -xf $testDir/fromship.tar") >> 8;
if ( $status != 0) {
  print "tar unpack of distribution failed\n";
  &cleanup(1);
  }
unlink("$testDir/fromship.tar");

#=========================================================================
# Do the compare

&compare_dirs($distDir, $tapeDir);
print("compare success\n");
&cleanup(0);

sub compare_dirs {
  local($distDir, $tapeDir) = @_;
  local(@distNames, @tapeNames);
  local($distFile, $tapeFile);
  local($thisName, $i);

  local ($dist_dev, $dist_ino, $dist_mode, $dist_nlink, $dist_uid, $dist_gid,
      $dist_rdev, $dist_size, $dist_atime, $dist_mtime, $dist_ctime);
  local ($tape_dev, $tape_ino, $tape_mode, $tape_nlink, $tape_uid, $tape_gid,
      $tape_rdev, $tape_size, $tape_atime, $tape_mtime, $tape_ctime);

  # Look at directory entries first.
  (($dist_dev,$dist_ino,$dist_mode,$dist_nlink,$dist_uid,$dist_gid,
      $dist_rdev,$dist_size,$dist_atime,$dist_mtime, $dist_ctime)
      = stat($distDir))
      || (print "Can't stat $distDir: $!\n", &cleanup(1));

  (($tape_dev,$tape_ino,$tape_mode,$tape_nlink,$tape_uid,$tape_gid,
      $tape_rdev,$tape_size,$tape_atime,$tape_mtime, $tape_ctime)
      = stat($tapeDir))
      || (print "Can't stat $tapeDir: $!\n", &cleanup(1));

  # Examine cogent fields, make sure they are the same:
  # dev and ino are to be ignored
  if ($dist_mode != $tape_mode) {
    print "mode $dist_mode for file $distDir\n";
    print "mode $tape_mode for file $tapeDir\n";
    print "File protections disagree.\n";
    &cleanup(1);
    }

  # Get list of names in distDir
  if (!opendir(THISDIR, $distDir)) {
    print "opendir failure on $distDir, error = $!\n";
    &cleanup(1);
    }
  for (;;) {
    $thisName = readdir(THISDIR);
    last if !defined($thisName);
    next if $thisName eq "." || $thisName eq "..";
    push(@distNames, $thisName);
    }
  closedir(THISDIR);

  # and of course the names in tapeDir
  if (!opendir(THISDIR, $tapeDir)) {
    print "opendir failure on $tapeDir, error = $!\n";
    &cleanup(1);
    }
  for (;;) {
    $thisName = readdir(THISDIR);
    last if !defined($thisName);
    next if $thisName eq "." || $thisName eq "..";
    push(@tapeNames, $thisName);
    }
  closedir(THISDIR);

  # Now, the lists _themselves_ should be the same
  if ($#distNames != $#tapeNames) {
    print "dist directory $distDir has $#distNames elements\n";
    print "tape directory $tapeDir has $#tapeNames elements\n";
    &cleanup(1);
    }
    
  # Canonicalize the lists for comparison
  @distNames = sort(@distNames);
  @tapeNames = sort(@tapeNames);

  for ($i = 0; $i <= $#distNames; $i++) { # loop through files
    $distFile = $distNames[$i];
    $tapeFile = $tapeNames[$i];

    # The list of names should be identical.
    if ($distFile ne $tapeFile) {
      print "dist directory $distDir\n";
      print "tape directory $tapeDir\n";
      print "At position $i in filename list:\n";
      print "  distribution has: $distFile\n";
      print "  tape has:       : $tapeFile\n";
      &cleanup(1);
      }

    # fully qualify the name
    $distFile = $distDir . "/" . $distFile;
    $tapeFile = $tapeDir . "/" . $tapeFile;

    if (-f $distFile) {
      if (! -f $tapeFile) {
	print "File $distFile is a regular file, but not $tapeFile\n";
	&cleanup(1);
	}
      &compare_files($distFile, $tapeFile);
      }
    elsif (-d $distFile) {
      if (! -d $tapeFile) {
	print "File $distFile is a directory, but not $tapeFile\n";
	&cleanup(1);
	}
      &compare_dirs($distFile, $tapeFile);
      }
    else {
      print "File $distFile is neither a regular file or directory\n";
      &cleanup(1);
      }

    } # loop through files

  }

sub compare_files {
  local($distFile, $tapeFile) = @_;

  local ($dist_dev, $dist_ino, $dist_mode, $dist_nlink, $dist_uid, $dist_gid,
      $dist_rdev, $dist_size, $dist_atime, $dist_mtime, $dist_ctime);
  local ($tape_dev, $tape_ino, $tape_mode, $tape_nlink, $tape_uid, $tape_gid,
      $tape_rdev, $tape_size, $tape_atime, $tape_mtime, $tape_ctime);

  # Examine the stats
  (($dist_dev,$dist_ino,$dist_mode,$dist_nlink,$dist_uid,$dist_gid,
      $dist_rdev,$dist_size,$dist_atime,$dist_mtime, $dist_ctime)
      = stat($distFile))
      || (print "Can't stat $distFile: $!\n", &cleanup(1));

  (($tape_dev,$tape_ino,$tape_mode,$tape_nlink,$tape_uid,$tape_gid,
      $tape_rdev,$tape_size,$tape_atime,$tape_mtime, $tape_ctime)
      = stat($tapeFile))
      || (print "Can't stat $tapeFile: $!\n", &cleanup(1));

  # Examine cogent fields, make sure they are the same:
  # dev and ino are to be ignored
  if ($dist_mode != $tape_mode) {
    print "mode $dist_mode for file $distFile\n";
    print "mode $tape_mode for file $tapeFile\n";
    print "File protections disagree.\n";
    &cleanup(1);
    }
  # nlink, uid, gid, rdev not interesting
  if ($dist_size != $tape_size) {
    print "size $dist_size for file $distFile\n";
    print "size $tape_size for file $tapeFile\n";
    print "File sizes disagree.\n";
    &cleanup(1);
    }
  # atime, mtime, ctime not interesting
  # So much for the file header.  What about the contents?
  &compare_contents($distFile, $tapeFile);
  }

sub compare_contents {
  local($distFile, $tapeFile) = @_;
  local($totalCount, $numDone);
  local($distCount, $tapeCount);
  local($distBuf, $tapeBuf);

  if (!open(DISTFILE, "<" . $distFile)) {
    print "$0: unable to open $distFile.\n";
    print "error = $!\n";
    return 0;
    }
  if (!open(TAPEFILE, "<" . $tapeFile)) {
    print "$0: unable to open $tapeFile.\n";
    print "error = $!\n";
    return 0;
    }
  binmode DISTFILE;
  binmode TAPEFILE;

  # The actual copy.
  $totalCount = -s $distFile;  # We've already confirmed they're the same size.
  $numDone = 0;
  for (;;) {
    last if ($numDone == $totalCount);
    $distCount = sysread(DISTFILE, $distBuf, 16384); # 16K transfer size
    if (!defined($distCount)) {
      print "$0: read error on $distFile.\n";
      print "  near position $numDone, error = $!\n";
      close(DISTFILE);
      close(TAPEFILE);
      &cleanup(1);
      }
    $tapeCount = sysread(TAPEFILE, $tapeBuf, 16384); # 16K transfer size
    if (!defined($tapeCount)) {
      print "$0: read error on $tapeFile.\n";
      print "  near position $numDone, error = $!\n";
      close(DISTFILE);
      close(TAPEFILE);
      &cleanup(1);
      }
    if ($distCount != $tapeCount) {
      print "$0: inconsistent read lengths\n";
      print "  files $distFile and $tapeFile\n";
      close(DISTFILE);
      close(TAPEFILE);
      &cleanup(1);
      }
    if ($distBuf ne $tapeBuf) {
      print "$0: near position $numDone, files are unequal\n";
      print "  files $distFile and $tapeFile\n";
      close(DISTFILE);
      close(TAPEFILE);
      &cleanup(1);
      }
    $numDone += $distCount;
    }

  # clean up.
  if (!close(DISTFILE)) {
    print "$0: error closing $distFile.\n";
    print "  error = $!\n";
    &cleanup(1);
    }
  if (!close(TAPEFILE)) {
    print "$0: error closing $tapeFile.\n";
    print "  error = $!\n";
    &cleanup(1);
    }
  }

sub cleanup {
  local($exitCode) = @_;
  local($status);

  exit($exitCode) if (! -d $scratch);

  chdir($scratch);
  # TODO: check status
  $status = system("chmod -R u+w $testDir") >> 8;
  # TODO: check status
  $status = system("rm -rf $testDir") >> 8;
  # TODO: check status

  if ($exitCode != 0) {
    print "compare failure\n";
    }

  exit($exitCode);
  }
