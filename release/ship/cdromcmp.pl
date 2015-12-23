#! /bin/perl5
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - cdromcmp.pl
#
# Purpose - See if a CDRom's contents matches the products expected.
# 		argument 1: the directory where the CDRom is mounted
# 		argument 2: the product number (optional)
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
	$SCRIPTNAME =~ s@.*/([^/]+)@\1@;
	$SCRIPTDIR = $myName;
	$SCRIPTDIR =~ s@(.*)/[^/]+@\1@;
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

$testDir="$CDRomTempDir";
$distDir="$testDir/cdrom";

#=========================================================================
# Grab arguments
if ( $ARGV[0] eq "" || $#ARGV < 0) {
  print "Usage: $0 <cdromdir> {<prodNum>} {<prodNum>}\n";
  &cleanup(1);
  }

$cdromDir=$ARGV[0];
shift;
# Name of file to ignore during comparison
$ignoreFileName="$cdromDir/contents.txt";

$prodList = "";
foreach $arg (@ARGV) {
  $prodList = "$prodList $arg";
  die "$0:  No such part $partsDir/$arg" if ( ! -d "$partsDir/$arg");
  }

#=========================================================================
# clean out test place
if (!chdir($distDir)) {
  die "cannot chdir to $distDir: $!\n";
  }
$status = system("chmod -R u+w .") >> 8;
if ($status != 0) {
  die "cannot chmod -R u+w $distDir\/.: $!\n";
  }
$status = system("rm -rf *") >> 8;
if ($status != 0) {
  die "cannot rm -rf $distDir\/*: $!\n";
  }

# create the release file
print "creating the distribution...\n";
if (!chdir($shipBase)) {
  die "cannot chdir to $shipBase: $!\n";
  }
if ("$prodList" eq "") {
  # create product list interactively
  system("touch $testDir/makecdromdirs.log");
  $status = system("makecdromdirs") >> 8;
  }
else {
  $status =
     system("makecdromdirs  -stest $prodList >$testDir/makecdromdirs.log") >> 8;
  }
if ( $status != 0 ) {
  system("cat $testDir/makecdromdirs.log");
  unlink("$testDir/makecdromdirs.log");
  print "makecdromdirs error\n";
  &cleanup(1);
  }
unlink("$testDir/makecdromdirs.log");


#=========================================================================
# Do the compare

$fileCompareFail = 0;
&compare_dirs($distDir, $cdromDir);
if ($fileCompareFail == 0) {
  print("compare success\n");
  }
else {
  print("compare failure\n");
  }
&cleanup(0);

sub compare_dirs {
  local($distDir, $cdromDir) = @_;
  local(@distNames, @cdromNames);
  local($distFile, $cdromFile);
  local($thisName, $i);

  local ($dist_dev, $dist_ino, $dist_mode, $dist_nlink, $dist_uid, $dist_gid,
      $dist_rdev, $dist_size, $dist_atime, $dist_mtime, $dist_ctime);
  local ($cdrom_dev, $cdrom_ino, $cdrom_mode, $cdrom_nlink, $cdrom_uid, $cdrom_gid,
      $cdrom_rdev, $cdrom_size, $cdrom_atime, $cdrom_mtime, $cdrom_ctime);

  # Look at directory entries first.
  (($dist_dev,$dist_ino,$dist_mode,$dist_nlink,$dist_uid,$dist_gid,
      $dist_rdev,$dist_size,$dist_atime,$dist_mtime, $dist_ctime)
      = stat($distDir))
      || (print "Can't stat $distDir: $!\n", &cleanup(1));

  (($cdrom_dev,$cdrom_ino,$cdrom_mode,$cdrom_nlink,$cdrom_uid,$cdrom_gid,
      $cdrom_rdev,$cdrom_size,$cdrom_atime,$cdrom_mtime, $cdrom_ctime)
      = stat($cdromDir))
      || (print "Can't stat $cdromDir: $!\n", &cleanup(1));

  # Examine cogent fields, make sure they are the same:
  # dev and ino are to be ignored
  # mode ignored too since modes on CDRom are set by the mounting system
  # if ($dist_mode != $cdrom_mode) {
  #  print "mode $dist_mode for file $distDir\n";
  #  print "mode $cdrom_mode for file $cdromDir\n";
  #  print "File protections disagree.\n";
  #  &cleanup(1);
  #  }

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

  # and of course the names in cdromDir
  if (!opendir(THISDIR, $cdromDir)) {
    print "opendir failure on $cdromDir, error = $!\n";
    &cleanup(1);
    }
  for (;;) {
    $thisName = readdir(THISDIR);
    last if !defined($thisName);
    next if $thisName eq "." || $thisName eq "..";
    push(@cdromNames, $thisName);
    }
  closedir(THISDIR);

  # Now, the lists _themselves_ should be the same
  if ($#distNames != $#cdromNames) {
    print "dist directory $distDir has $#distNames elements\n";
    print "cdrom directory $cdromDir has $#cdromNames elements\n";
    &cleanup(1);
    }
    
  # Canonicalize the lists for comparison
  @distNames = sort(@distNames);
  @cdromNames = sort(@cdromNames);

  for ($i = 0; $i <= $#distNames; $i++) { # loop through files
    $distFile = $distNames[$i];
    $cdromFile = $cdromNames[$i];

    # The list of names should be identical.
    if ($distFile ne $cdromFile) {
      print "dist directory $distDir\n";
      print "cdrom directory $cdromDir\n";
      print "At position $i in filename list:\n";
      print "  distribution has: $distFile\n";
      print "  cdrom has:       : $cdromFile\n";
      &cleanup(1);
      }

    # fully qualify the name
    $distFile = $distDir . "/" . $distFile;
    $cdromFile = $cdromDir . "/" . $cdromFile;

    if (-f $distFile) {
      if (! -f $cdromFile) {
	print "File $distFile is a regular file, but not $cdromFile\n";
	&cleanup(1);
	}
      &compare_files($distFile, $cdromFile);
      }
    elsif (-d $distFile) {
      if (! -d $cdromFile) {
	print "File $distFile is a directory, but not $cdromFile\n";
	&cleanup(1);
	}
      &compare_dirs($distFile, $cdromFile);
      }
    else {
      print "File $distFile is neither a regular file or directory\n";
      &cleanup(1);
      }

    } # loop through files

  }

sub compare_files {
  local($distFile, $cdromFile) = @_;

  local ($dist_dev, $dist_ino, $dist_mode, $dist_nlink, $dist_uid, $dist_gid,
      $dist_rdev, $dist_size, $dist_atime, $dist_mtime, $dist_ctime);
  local ($cdrom_dev, $cdrom_ino, $cdrom_mode, $cdrom_nlink, $cdrom_uid,
      $cdrom_gid, $cdrom_rdev, $cdrom_size, $cdrom_atime, $cdrom_mtime,
      $cdrom_ctime);
  local ($compStat);

  if ("$cdromFile" eq "$ignoreFileName") {
    print "\nIgnoring file $ignoreFileName\nCheck this by hand!\n\n";
    return 1;
    }

  # Examine the stats
  (($dist_dev,$dist_ino,$dist_mode,$dist_nlink,$dist_uid,$dist_gid,
      $dist_rdev,$dist_size,$dist_atime,$dist_mtime, $dist_ctime)
      = stat($distFile))
      || (print "Can't stat $distFile: $!\n", &cleanup(1));

  (($cdrom_dev,$cdrom_ino,$cdrom_mode,$cdrom_nlink,$cdrom_uid,$cdrom_gid,
      $cdrom_rdev,$cdrom_size,$cdrom_atime,$cdrom_mtime, $cdrom_ctime)
      = stat($cdromFile))
      || (print "Can't stat $cdromFile: $!\n", &cleanup(1));

  # Examine cogent fields, make sure they are the same:
  # dev and ino are to be ignored
  # mode ignored too since modes on CDRom are set by the mounting system
  # if ($dist_mode != $cdrom_mode) {
  #  print "mode $dist_mode for file $distDir\n";
  #  print "mode $cdrom_mode for file $cdromDir\n";
  #  print "File protections disagree.\n";
  #  &cleanup(1);
  #  }

  # nlink, uid, gid, rdev not interesting
  if ($dist_size != $cdrom_size) {
    print "size $dist_size for file $distFile\n";
    print "size $cdrom_size for file $cdromFile\n";
    print "File sizes disagree.\n";
    &cleanup(1);
    }
  # atime, mtime, ctime not interesting
  # So much for the file header.  What about the contents?
  $compStat = &compare_contents($distFile, $cdromFile);
  if ($compStat == 0) {
    $fileCompareFail = 1;
    }
  }

sub compare_contents {
  local($distFile, $cdromFile) = @_;
  local($totalCount, $numDone);
  local($distCount, $cdromCount);
  local($distBuf, $cdromBuf);

  if (!open(DISTFILE, "<" . $distFile)) {
    print "$0: unable to open $distFile.\n";
    print "error = $!\n";
    return 0;
    }
  if (!open(CDROMFILE, "<" . $cdromFile)) {
    print "$0: unable to open $cdromFile.\n";
    print "error = $!\n";
    return 0;
    }
  binmode DISTFILE;
  binmode CDROMFILE;

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
      close(CDROMFILE);
      &cleanup(1);
      }
    $cdromCount = sysread(CDROMFILE, $cdromBuf, 16384); # 16K transfer size
    if (!defined($cdromCount)) {
      print "$0: read error on $cdromFile.\n";
      print "  near position $numDone, error = $!\n";
      close(DISTFILE);
      close(CDROMFILE);
      &cleanup(1);
      }
    if ($distCount != $cdromCount) {
      print "$0: inconsistent read lengths\n";
      print "  files $distFile and $cdromFile\n";
      close(DISTFILE);
      close(CDROMFILE);
      &cleanup(1);
      }
    if ($distBuf ne $cdromBuf) {
      print "$0: near position $numDone, files are unequal\n";
      print "  files $distFile\n    and $cdromFile\n";
      close(DISTFILE);
      close(CDROMFILE);
      return 0;
      }
    $numDone += $distCount;
    }

  # clean up.
  if (!close(DISTFILE)) {
    print "$0: error closing $distFile.\n";
    print "  error = $!\n";
    &cleanup(1);
    }
  if (!close(CDROMFILE)) {
    print "$0: error closing $cdromFile.\n";
    print "  error = $!\n";
    &cleanup(1);
    }
  return 1;
  }

sub cleanup {
  local($exitCode) = @_;
  local($status);

  exit($exitCode) if (! -d $distDir);

  chdir($distDir);
  # TODO: check status
  $status = system("chmod -R u+w .") >> 8;
  # TODO: check status
  $status = system("rm -rf *") >> 8;
  # TODO: check status

  if ($exitCode != 0) {
    print "compare failure\n";
    }

  exit($exitCode);
  }
