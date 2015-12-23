#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - misc.pl
#
# Purpose - support for maketape, makekey
#
#=========================================================================

%hostToSuntype = (
  "sparc.SunOS4", 4,
  "sparc.Solaris", 10,
  "hppa.hpux", 7,
  "hppa.hpux_8", 7,
  "hppa.hpux_9", 7,
  "Symmetry.Dynix", 8,
  "RISC6000.AIX", 9,
  "i386.NCR", 5,
  "MIPSEB.sinix", 3,
  "x86.Windows_NT", 11,
  "i686.Linux", 50,
  "x86.os2", 30);

# Products always sent with GemFire product editions
# No longer applicable as all docs are in product
#@default_partnums = ("205-110-2.0-0-0-0",
#                     "206-110-2.0-0-0-0",
#                    );

# List of GemFire products
@GemFire30_PJ = ("9-111-3.0-0-0-0", @default_partnums);
@GemFire_Solaris  = ("13-10-5.0.1-0-0-0", @default_partnums);
@GemFire_WinNT    = ("13-11-5.0.1-0-0-0", @default_partnums);
@GemFire_Linux    = ("13-50-5.0.1-0-0-0", @default_partnums);

@GemFireRTE_Solaris  = ("14-10-1.3-0-0-0", @default_partnums);
@GemFireRTE_WinNT    = ("14-11-1.3-0-0-0", @default_partnums);
@GemFireRTE_Linux    = ("14-50-1.3-0-0-0", @default_partnums);

@GemFireCPP_WinNT    = ("16-11-1.1-0-0-0", @default_partnums);
@GemFireCPP_Linux    = ("16-50-1.1-0-0-0", @default_partnums);

@GemFireNC_WinNT    = ("29-11-1.2-0-0-0", @default_partnums);
@GemFireNC_Linux    = ("29-50-1.2-0-0-0", @default_partnums);

@GemFireDBA_WinNT    = ("17-11-1.0Beta1-0-0-0", @default_partnums);
@GemFireDBA_Unix     = ("17-100-1.0Beta1-0-0-0", @default_partnums);

@packages_menu = (
  "Solaris GemFire v5.0.1",
     "add_product_package(*GemFire_Solaris, *product_names,*product_list)",
  "Windows GemFire v5.0.1",
     "add_product_package(*GemFire_WinNT, *product_names,*product_list)",
  "Linux GemFire v5.0.1",
     "add_product_package(*GemFire_Linux, *product_names,*product_list)",
  "Solaris GemFireRTE v1.3",
     "add_product_package(*GemFireRTE_Solaris, *product_names,*product_list)",
  "Windows GemFireRTE v1.3",
     "add_product_package(*GemFireRTE_WinNT, *product_names,*product_list)",
  "Linux GemFireRTE v1.3",
     "add_product_package(*GemFireRTE_Linux, *product_names,*product_list)",
  "Windows GemFireC++ v1.1",
     "add_product_package(*GemFireCPP_WinNT, *product_names,*product_list)",
  "Linux GemFireC++ v1.1",
     "add_product_package(*GemFireCPP_Linux, *product_names,*product_list)",
  "Windows GemFireNativeClient v1.2",
     "add_product_package(*GemFireNC_WinNT, *product_names,*product_list)",
  "Linux GemFireNativeClient v1.2",
     "add_product_package(*GemFireNC_Linux, *product_names,*product_list)",
  "Unix GemFireDBA v1.0Beta1",
     "add_product_package(*GemFireDBA_Unix, *product_names,*product_list)",
  "Windows GemFireDBA v1.0Beta1",
     "add_product_package(*GemFireDBA_WinNT, *product_names,*product_list)",
  "No package","exit",
  );

#require "ctime.pl";
# I didn't like ctime.pl, so I've fixed it :-)

@ctime_DoW = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
@ctime_MoY = ('Jan','Feb','Mar','Apr','May','Jun',
	    'Jul','Aug','Sep','Oct','Nov','Dec');

sub my_ctime {
    local($time) = @_;
    local($[) = 0;
    local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

    # Determine what time zone is in effect.
    # Use GMT if TZ is defined as null, local time if TZ undefined.
    # There's no portable way to find the system default timezone.

    $TZ = defined($ENV{'TZ'}) ? ( $ENV{'TZ'} ? $ENV{'TZ'} : 'GMT' ) : '';
    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        ($TZ eq 'GMT') ? gmtime($time) : localtime($time);

    # Hack to deal with 'PST8PDT' format of TZ
    # Note that this can't deal with all the esoteric forms, but it
    # does recognize the most common: [:]STDoff[DST[off][,rule]]

    if($TZ=~/^([^:\d+\-,]{3,})([+-]?\d{1,2}(:\d{1,2}){0,2})([^\d+\-,]{3,})?/){
        $TZ = $isdst ? $4 : $1;
    }
    $TZ .= ' ' unless $TZ eq '';

    # $year += ($year < 70) ? 2000 : 1900;
    $year += 1900; 	# Jason's change #1.  Make it work in the year 2000.

#    sprintf("%s %s %2d %2d:%02d:%02d %s%4d\n",
#      $ctime_DoW[$wday], $ctime_MoY[$mon], $mday, $hour, $min, $sec, $TZ,
#	$year);

#    Jason's change #2:  emit more standard text
    sprintf("%s %d %s %4d %02d:%02d:%02d %s\n",
      $ctime_DoW[$wday], $mday, $ctime_MoY[$mon],
      $year, $hour, $min, $sec, $TZ);
}

# RFC822 mail user agents are picky about date format :-(
sub mailDate {
    local($time) = @_;
    local($[) = 0;
    local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        localtime($time);
    # $year += ($year < 70) ? 2000 : 1900;
    $year += 1900; 	# Jason's change #1.  Make it work in the year 2000.

    sprintf("%s %s %d %02d:%02d:%02d %4d\n",
      $ctime_DoW[$wday], $ctime_MoY[$mon], $mday, $hour, $min, $sec, $year);
}


sub removeLock {
  rmdir $lockdir_to_remove
      || print "\n$0:  unable to remove $lockdir_to_remove\n";
  &error_exit(1);
  }

# Add an entry to customers.dat
# Arguments:  1.  The text to add.
#             2.  The folder to add it to.
#	      3.  Subject of the mail message
sub add_entry {
  local ($text, $folder, $subject) = @_;
  local ($lockName, $me, $now);
  local (%oldSigs);

  # Trap likely failures
  $oldSigs{'INT'} = $SIG{'INT'};
  $oldSigs{'QUIT'} = $SIG{'QUIT'};
  $oldSigs{'TERM'} = $SIG{'TERM'};
  $SIG{'HUP'} = 'IGNORE';
  $SIG{'INT'} = 'removeLock';
  $SIG{'QUIT'} = 'removeLock';
  $SIG{'TERM'} = 'removeLock';

  $lockdir_to_remove = $lockName = &lock_folder($folder);

  if (-f $folder) {
    (&basic_copy("$folder", "$folder.BAK", $ARCH, 1) != 0) ||
	(rmdir $lockName, die "error backing up $folder: $!");
    open(FOLDER, ">>" . $folder) ||
      (rmdir $lockName, die "error appending to $folder: $!");
    }
  else {
    open(FOLDER, ">" . $folder) ||
      (rmdir $lockName, die "error creating $folder: $!");
    }

  # On non-Unix systems (like NT) we want \n to be \n, not \r\n. So use binmode
  binmode(FOLDER);

  $me = &username;
  $now = &mailDate(time);
  chop($now);

  # Now write mailfolder format stuff...
  print FOLDER "From $me $now\n";
  print FOLDER "From: $me\n";
  print FOLDER "To: $me\n";
  print FOLDER "Date: $now\n";
  print FOLDER "Subject: $subject\n";
  print FOLDER "\n";

  $text =~ s/^From/~From/g;  # disgusting Unix convention
  print FOLDER $text;

  print FOLDER "\n"; # empty line needed at end
  close FOLDER || die "error closing $folder: $!";

  rmdir($lockName) || die "$0: cannot rmdir $lockName!";

  # Restore signals
  $SIG{'INT'} = $oldSigs{'INT'};
  $SIG{'QUIT'} = $oldSigs{'QUIT'};
  $SIG{'TERM'} = $oldSigs{'TERM'};
  }

# Lock a folder to avoid write-write conflict.
# Arguments:  1. the name of the file to lock
# returns:  name of file to rmdir
sub lock_folder {
  local($thefile) = @_;
  local($lockName, $now);
  local ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
      $atime, $mtime, $ctime);


  $lockName = $thefile . ".LCK";
  for (;;) {
    return $lockName if mkdir($lockName, 777);

    # print diagnostic
    (($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime)
        = stat($lockName)) || (
	print "$0:  Can't stat $lockName: $!\n", sleep 10, next);
    $ctime = &my_ctime($ctime);
    chop($ctime);
    $now = &my_ctime(time);
    chop($now);
    print "$now:  Waiting on lockfile $lockName created $ctime\n";
    sleep 10;
    }
  return $lockName;
  }

# Return username of the current user
sub username {
  return $ENV{"USER"};
  }

# rm -rf
sub remove_dir {
  local ($theDir) = @_;
  local (@dirsToKill, @filesToKill);
  local ($thisFile);

  # print "Removing directory $theDir...\n";

  if ( ! -e "$theDir" ) {
    print "$0: directory $theDir does not exist\n";
    print "  error = $!\n";
    return 0;
    }
  # Collect list of files and directories
  if (chmod(0777, $theDir) != 1) {
    print "$0: Warning: error chmod'ing $theDir\n";
    print "  error = $!\n";
    print "  Attempting to continue.\n";
    }
  if (!opendir(THISDIR, $theDir)) {
    print "Unable to open directory $theDir, error = $!\n";
    return 1;
    }
  for (;;) {
    $thisFile = readdir THISDIR;
    if (!defined($thisFile)) {
      last;
      }
    if ($thisFile eq "." || $thisFile eq "..") {
      next;
      }
    $thisFile = "$theDir/$thisFile";
    if ( -l $thisFile) {
      push(@filesToKill, $thisFile);
      }
    elsif ( -d $thisFile) {
      push(@dirsToKill, $thisFile);
      }
    else {
      push(@filesToKill, $thisFile);
      }
    }
  closedir(THISDIR);

  foreach $thisFile (@dirsToKill) {
    if (&remove_dir($thisFile)) {
      return 1;
      }
    }
  foreach $thisFile (@filesToKill) {
    if ((!-l $thisFile) && (chmod(0777, $thisFile) != 1)) {
      print "$0: , error chmod'ing $thisFile\n";
      print "  error = $!\n";
      print "  Attempting to continue.\n";
      }
    if (!unlink($thisFile)) {
      print "Error unlinking $thisFile, error = $!\n";
      return 1;
      }
    }

  if (rmdir($theDir) != 1) {
    print "Error doing rmdir $theDir, error = $!\n";
    return 1;
    }
  return 0;
  }

# Given a directory and a name, squish them together (OS-specific)
sub delimited_dir {
  local ($givenName, $myArch) = @_;
  local ($archType);

  $archType = $ArchExtensions{$myArch};
  if ($givenName eq '') {
    return '';
    }
  elsif ( $archType eq "unix") {
    return $givenName . "/";
    }
  elsif ( $archType eq "dos" ) {
    return $givenName . "\\";
    }
  elsif ( $archType eq "mac" ) {
    return $givenName . ":";
    }
  else {
    die "internal error, unknown arch $myArch";
    }
  }

# Call the chmod() intrinsic
sub basic_chmod {
  local($name, $mode, $archType) = @_;

  if ($ArchExtensions{$archType} ne "unix") {
    return 1;
    }

  if (chmod($mode, $name) != 1) {
    print "$0: Warning: error chmod'ing $name.\n";
    print "  error = $!\n";
    return 0;
    }
  return 1;
  }

# basic_copy:  implement a cp command in perl
sub basic_copy {
  local($srcName, $destName, $archType, $okIfExists) = @_;
  local ($numThisTime, $numDone, $totalCount, $buffer);
  local ($readCount, $writeCount);

#  if ( -f $srcName && -f $destName) { # Efficiency check
#    if (-M $srcName < -M $destName) {
#      print "Skipping copy of older $srcName to newer $destName\n";
#      return;
#      }
#    }
  # It's not OK to overwrite an existing file.
  if ( ! $okIfExists && -f $destName) {
    print "$0: file $destName already exists.\n";
    return 0;
    }
  # Open the files.
  if (!open(SRCFILE, "<" . $srcName)) {
    print "$0: unable to open $srcName.\n";
    print "error = $!\n";
    return 0;
    }
  if (!open(DESTFILE, ">" . $destName)) {
    print "$0: unable to open $destName.\n";
    print "error = $!\n";
    return 0;
    }
  binmode SRCFILE;
  binmode DESTFILE;
 
  # The actual copy.
  $totalCount = -s $srcName;
  $numDone = 0;
  for (;;) {
    last if ($numDone == $totalCount);
    $readCount = sysread(SRCFILE, $buffer, 16384); # 16K transfer size
    if (!defined($readCount)) {
      print "$0: read error on $srcName.\n";
      print "  near position $numDone, error = $!\n";
      close(SRCFILE);
      close(DESTFILE);
      return 0;
      }
    $writeCount = syswrite(DESTFILE, $buffer, $readCount);
    if (!defined($writeCount)) {
      print "$0: write error on $destName.\n";
      print "  near position $numDone, error = $!\n";
      close(SRCFILE);
      close(DESTFILE);
      return 0;
      }
    if ($readCount != $writeCount) {
      print "$0: short write on $destName.\n";
      print "  near position $numDone, error = $!\n";
      close(SRCFILE);
      close(DESTFILE);
      return 0;
      }
    $numDone += $readCount;
    }

  # clean up.
  if (!close(SRCFILE)) {
    print "$0: error closing $srcName.\n";
    print "  error = $!\n";
    return 0;
    }
  if (!close(DESTFILE)) {
    print "$0: error closing $destName.\n";
    print "  error = $!\n";
    return 0;
    }

  # copy protection from sourcefile
  {
    local ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
        $atime, $mtime);

    (($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime)
        = stat($srcName)) || (print "$0:  Can't stat $srcName: $!\n", return 0);
    if (!&basic_chmod($destName, $mode, $archType)) {
      print "$0: Warning:  error chmod'ing $destName\n";
#      return 0;
      }
    if (utime($atime, $mtime, $destName) != 1) {
      print "$0: Warning: error utime'ing $destName: $!\n";
#      return 0;
    }
  }
  return 1;
  }

# Copy all files and directories in a directory tree, preserving links.
# If $okIfExists is 1 then it is OK if $newDir already exists.
# We keep $okIfExists set to 0 for subdirs.
sub basiccopy_tree {
  local($newDir, $srcDir, $archType, $okIfExists) = @_;
  local(@dirsToCopy, @filesToCopy, @linksToCopy);
  local($thisFile, $srcName, $destName, $linkvalue);

  # Collect list of files and directories in $srcDir
  if (!opendir(THISDIR, $srcDir)) {
    print "Unable to open directory $srcDir, error = $!\n";
    return 0;
    }
  for (;;) {
    $thisFile = readdir THISDIR;
    if (!defined($thisFile)) {
      last;
      }
    if ($thisFile eq "." || $thisFile eq "..") {
      next;
      }

    $srcName = &delimited_dir($srcDir, $archType) . $thisFile;

    if ( -l $srcName) {
      push(@linksToCopy, $thisFile);
      }
    elsif ( -d $srcName) {
      push(@dirsToCopy, $thisFile);
      }
    else {
      push(@filesToCopy, $thisFile);
      }
    }
  closedir(THISDIR);

  if ((-d "$newDir") && ($okIfExists == 1)) {
    print "using existing directory $newDir\n";
    }
  elsif (!mkdir($newDir, 0755)) {
    print "Unable to create directory $newDir, error = $!\n";
    return 0;
    }

  foreach $thisFile (@dirsToCopy) {
    $srcName = &delimited_dir($srcDir, $archType) . $thisFile;
    $destName = &delimited_dir($newDir, $archType) . $thisFile;

    if (!&basiccopy_tree($destName, $srcName, $archType, 0)) {
      return 0;
      }
    }

  # print "   Copying files in $srcDir...\n";
  foreach $thisFile (@filesToCopy) {
    $srcName = &delimited_dir($srcDir, $archType) . $thisFile;
    $destName = &delimited_dir($newDir, $archType) . $thisFile;
    if (!&basic_copy($srcName, $destName, $archType, 0)) {
      print "$0:  copy of source file failed\n";
      return 0;
      }
    }

  # print "   Copying links in $srcDir...\n";
  foreach $thisFile (@linksToCopy) {
    $srcName = &delimited_dir($srcDir, $archType) . $thisFile;
    $destName = &delimited_dir($newDir, $archType) . $thisFile;
    $linkvalue = readlink($srcName);
    if (!symlink($linkvalue, $destName)) {
      print "$0:  link of source file failed, linkvalue = $linkvalue\n";
      print "     destName = $destName\n";
      return 0;
      }
    }
  return 1;
  }


# Make links to files and directories in a directory tree
# If $okIfExists is 1 then it is OK if $newDir already exists.
# We keep $okIfExists set to 0 for subdirs.
sub basiclink_tree {
  local($newDir, $srcDir, $archType, $okIfExists) = @_;
  local($thisFile, $srcName, $destName, @linksToMake);

  # Collect list of files and directories in $srcDir
  if (!opendir(THISDIR, $srcDir)) {
    print "Unable to open directory $srcDir, error = $!\n";
    return 0;
    }
  for (;;) {
    $thisFile = readdir THISDIR;
    if (!defined($thisFile)) {
      last;
      }
    if ($thisFile eq "." || $thisFile eq "..") {
      next;
      }

    push(@linksToMake, $thisFile);
    }
  closedir(THISDIR);

  if ((-d "$newDir") && ($okIfExists == 1)) {
    print "using existing directory $newDir\n";
    }
  elsif (!mkdir($newDir, 0755)) {
    print "Unable to create directory $newDir, error = $!\n";
    return 0;
    }

  foreach $thisFile (@linksToMake) {
    $srcName = &delimited_dir($srcDir, $archType) . $thisFile;
    $destName = &delimited_dir($newDir, $archType) . $thisFile;

    if (!symlink($srcName, $destName)) {
      print "ERROR: Unable to create link \"$destName\"\n";
      print "  pointing to \"$srcName\"\n,   error = $!\n";
      return 0;
      }
    }

  return 1;
  }



# Copy all files and directories in a directory tree, preserving links,
# truncating directory names to 8 chars and file names to 8.3.
# The first arg ($newDir) is assumed to be truncated to 8 chars already.
# If $okIfExists is 1 then it is OK if $newDir already exists.
# We keep $okIfExists set to 0 for subdirs.
sub trunccopy_tree {
  local($newDir, $srcDir, $archType, $okIfExists) = @_;
  local(@dirsToCopy, @filesToCopy, @linksToCopy);
  local($thisFile, $srcName, $destName, $destFile, $destDir, $linkvalue);

  # Collect list of files and directories in $srcDir
  if (!opendir(THISDIR, $srcDir)) {
    print "Unable to open directory $srcDir, error = $!\n";
    return 0;
    }
  for (;;) {
    $thisFile = readdir THISDIR;
    if (!defined($thisFile)) {
      last;
      }
    if ($thisFile eq "." || $thisFile eq "..") {
      next;
      }

    $srcName = &delimited_dir($srcDir, $archType) . $thisFile;

    if ( -l $srcName) {
      push(@linksToCopy, $thisFile);
      }
    elsif ( -d $srcName) {
      push(@dirsToCopy, $thisFile);
      }
    else {
      push(@filesToCopy, $thisFile);
      }
    }
  closedir(THISDIR);

  if ((-d "$newDir") && ($okIfExists == 1)) {
    # print "using existing directory $newDir\n";
    }
  elsif (!mkdir($newDir, 0755)) {
    print "Unable to create directory/directory already exists, error = $!\n";
    print "  dirname is $newDir\n";
    return 0;
    }

  foreach $thisFile (@dirsToCopy) {
    $srcName = &delimited_dir($srcDir, $archType) . $thisFile;
    $destDir = &trunc_dirname($thisFile);
    if ($destDir eq "") {
      print "ERROR: unable to map $thisFile to a short directory string\n";
      return 0;
      }
    $destName = &delimited_dir($newDir, $archType) . $destDir;

    if (!&trunccopy_tree($destName, $srcName, $archType, 0)) {
      return 0;
      }
    }

  # print "   Copying files in $srcDir...\n";
  foreach $thisFile (@filesToCopy) {
    $srcName = &delimited_dir($srcDir, $archType) . $thisFile;
    $destFile = &trunc_filename($thisFile);
    if ($destFile eq ".") {
      print "ERROR: unable to map $thisFile to a short file string\n";
      return 0;
      }
    $destName = &delimited_dir($newDir, $archType) . $destFile;
    if (!&basic_copy($srcName, $destName, $archType, 0)) {
      print "$0:  copy of source file failed\n";
      return 0;
      }
    }

  # print "   Copying links in $srcDir...\n";
  foreach $thisFile (@linksToCopy) {
    $srcName = &delimited_dir($srcDir, $archType) . $thisFile;
    $destFile = &trunc_filename($thisFile);
    if ($destFile eq ".") {
      print "ERROR: unable to map $thisFile to a short file string\n";
      return 0;
      }
    $destName = &delimited_dir($newDir, $archType) . $destFile;
    $linkvalue = readlink($srcName);
    if (!symlink($linkvalue, $destName)) {
      print "$0:  link of source file failed, linkvalue = $linkvalue\n";
      print "     destName = $destName\n";
      return 0;
      }
    }
  return 1;
  }


# ----------------------------------------------------
# Start of routines for maketape.pl and makecdimage.pl

sub do_quit {
  local ($answer);

  print "Really quit? (press y) to confirm:  ";
  $answer = <STDIN>;
  chop($answer);
  # remove leading and trailing whitespace if any
  $answer =~ s/\s*([^\s]*)\s*/$1/;
  if ($answer eq "Y" || $answer eq "y") {
    print "OK, sorry I couldn't help you.\n";
    &error_exit(0);
    }
  print "Quit was not confirmed.\n";
  }

# Prompt for a serial number
sub get_serial {
  print "Serial number (for masters, use 'release'):  ";
  $serial = <STDIN>;
  chop($serial);
  # remove leading and trailing whitespace if any
  $serial =~ s/\s*([^\s]*)\s*/$1/;

  # No validation currently done
  }

# We generally need at least one default product put onto the media
# like docs or a took kit so present some defaults and ask if we want
# to use them or not.
# User may enter part num later on if they mistakenly refuse a default.
sub get_default_partnum {
  local($default) = @_;
  local($name);

  if (! -d "$partsDir/$default") {
    print "Could not find default part number \"$default\"\n";
    return "";
    }
  $name = &name_for_product($default);
  if ("$name" eq "") {
    print "Could not find name for default part number \"$default\"\n";
    return "";
    }

  print "Include part number $default\n";
  print "          ($name) ?  [y] ";
  $answer = <STDIN>;
  chop($answer);
  # remove leading and trailing whitespace if any
  $answer =~ s/\s*([^\s]*)\s*/$1/;
  if ($answer eq "Y" || $answer eq "y" || $answer eq "") {
    return "$default";
    }
  return "";
  }

# Add a package of products to the list
sub add_product_package {
  local(*package,*prod_names,*prod_list) = @_;
  local($partnum);
  foreach $partnum (@package) {
    if (! -d $partsDir . $DIRSEP . $partnum) {
      print "\nSorry, there is no such part $partnum\n";
      return;
      }
    &add_product_list($partnum,*prod_names,*prod_list);
    }
}

# Add a product or a list of products to the list
sub add_product {
  local(*prod_names,*prod_list) = @_;
  local($answer, @answ_array, $answ);

  print "Product part numbers to add (or \"?\" for menu):  ";
  $answer = <STDIN>;
  chop($answer);
  # Let the "split" done below
  # remove leading and trailing whitespace if any
  #$answer =~ s/\s*([^\s]*)\s*/$1/;
  $answer =~ s/(.*)\r$/$1/;

  if ($answer eq "") {
    # They bailed
    return;
    }
  if ($answer eq "?") { # do the menu
    $answer = &menu_add_product;
    if ($answer eq "") {
      # They bailed
      return;
      }
    &add_product_list($answer,*prod_names,*prod_list);
    }
  else { # Explicit product number or list of product numbers given; check it
    @answ_array = split(' ', $answer);
    foreach $answ (@answ_array) {
      if (! -d $partsDir . $DIRSEP . $answ) {
        print "\nSorry, there is no such part $answ\n";
        return;
        }
      &add_product_list($answ,*prod_names,*prod_list);
      }
    }
  }

# Add the given product number to the list.  Return 0 if a problem.
sub add_product_list {
  local($prodName,*prod_names,*prod_list) = @_;
  local($thisFile,$prod,$tempResults,$answer,$tempProdLine);

  if (! -d $partsDir . $DIRSEP . $prodName) {
    print "\nSorry, there is no such part $prodName\n";
    return 0;
    }

  # Check to see if prodName already in list.  If so, don't add it again.
  foreach $prod (@prod_list) {
    if ("$prod" eq "$prodName") {
      print "Part number $prodName is already in the list.  Continuing.\n";
      return 1;
      }
    }

  # Check for export controlled products
  $tempProdLine = $prodName;
  $tempProdLine =~ s/([^-]+)-[^-]+-[^-]+-[^-]+-[^-]+-.*/$1/;
  if (&isProductExportable($tempProdLine) == 0) {
    $tempResults = &name_for_product($prodName);
    print "\nWARNING: product $prodName, $tempResults\n";
    print "is NOT exportable except to Canada!\n";
    print "    Do you wish to continue? (press y to confirm): ";
    $answer = <STDIN>;
    chop($answer);
    # remove leading and trailing whitespace if any
    $answer =~ s/\s*([^\s]*)\s*/$1/;
    if ($answer eq "Y" || $answer eq "y") {
      print "OK, continuing.\n\n";
      }
    else {
      print "\nNot putting export controlled product $prodName on media!\n";
      return 0;
      }
    }

  $thisFile = &name_for_product($prodName);
  return 0 if $thisFile eq ""; # problem?

  $prod_names{$prodName} = $thisFile;
  push(@prod_list, $prodName); # Add the part to the list.
  return 1;
  }

# Nicety:  get _name_ of product.  It's the only file in that directory,
# so grab the name and show it.  If there's more than one name, this will
# get the first one only.  Not a big deal in practice, hopefully.
#
# Return empty string in case of trouble.
sub name_for_product {
  local ($prodName) = @_;
  local ($theDir, $thisFile);

  $theDir = $partsDir . $DIRSEP . $prodName;
  if (!opendir(THISDIR, $theDir)) {
    print "Unable to open directory $theDir, error = $!\n";
    return "";
    }
  for (;;) {
    $thisFile = readdir THISDIR;
    last if !defined($thisFile);
    next if ($thisFile eq "." || $thisFile eq ".." ||
             $thisFile eq "hidden" || $thisFile eq "special");
    last; # quit with first real entry
    }
  closedir(THISDIR);
  return $thisFile;
  }


# Walk her through a list of what's available
# Return the product string, or an empty string in case of trouble.
sub menu_add_product {
  local ($prodKind, $desiredArch);
  local ($verString);
  local ($match);
  local ($thisFile);
  local (@choices, $alias, @junk);

  # Just what _kind_ of product?
  $prodKind = &menu("Please choose the type of product:", @prodKinds);
  return "" if $prodKind eq ""; # They bailed.

  # And the architecture?
  $desiredArch = &menu("Please choose the target architecture:",
        @desiredArches);
  return "" if $desiredArch eq ""; # They bailed.

  # And they'd better know the version
  print "What version do you want (empty if you're fishing)?  ";
  $verString = <STDIN>;
  chop($verString);
  # remove leading and trailing whitespace if any
  $verString =~ s/\s*([^\s]*)\s*/$1/;
  $match = "$prodKind-$desiredArch";
  if ($verString ne "") {
    $match = "$match-$verString";
    }

  # Let's see what's available with that name...
  if (!opendir(PARTSDIR, $partsDir)) {
    print "Unable to open directory $partsDir, error = $!\n";
    return "";
    }
  @choices = ();
  for (;;) {
    $thisFile = readdir PARTSDIR;
    last if !defined($thisFile);
    next if ($thisFile eq "." || $thisFile eq "..");
    next if (!($thisFile =~ /^$match.*/));

    $alias = &name_for_product($thisFile);
    next if ($alias eq ""); # problems
    push(@choices, $alias); # key
    push(@choices, $thisFile); # value
    }
  closedir(PARTSDIR);

  if (&empty_array(@choices)) {
    print "\nSorry, no parts match $match\n";
    return "";
    }
  return &menu("Please choose one of the following products:", @choices);
  }

# Remove a product from the list
sub remove_product {
  local(*prod_names,*prod_list) = @_;
  local($to_remove, $i);
  local(@list, $each);

  # Build list, in user's order
  foreach $each (@prod_list) {
    push(@list, $prod_names{$each}); # key
    push(@list, $each); # value
    }

  # Get the choice
  $to_remove = &menu("Pick the product to remove:", @list);
  return if ($to_remove eq "");

  # Find the index in the list
  for ($i = 0; $i <= $#prod_list; $i ++) {
    last if ($prod_list[$i] eq $to_remove);
    }
  if ($i > $#prod_list) {
    print "Internal error in remove_product\n";
    return;
    }

  # Edit the lists
  delete($prod_names{$to_remove});
  splice(@prod_list, $i, 1);
  }

# Give a list of choices.  Return the value of the associative array for
# the choice made, or an empty string in case of a problem.
# Inputs:  1. a descriptive title; 2.an array with key/value pairs
sub menu {
  local ($title, @choices) = @_;
  local (@keys, @values);
  local ($each, $i, $j, $k, $nlines, $answer, @possibles);

  # consistency check
  die "empty list in menu" if &empty_array(@choices);

  # Make an ordered list
  for (;;) {
    last if &empty_array(@choices);
    $each = shift(@choices);
    push(@keys, $each);
    $each = shift(@choices);
    push(@values, $each);
    }

  show_menu:  for (;;) { # show the menu
    print "\n$title\n";
    $nlines = int(($#keys + 1) / 2) + (($#keys + 1) % 2);
    for ($i = 0; $i < $nlines; $i ++) {
      $j = $i + 1 - $[;  # one-base
      printf("%2d.  %s", $j, $keys[$i]);
      if (($i + $nlines) <= $#keys) {
        for ($k = 1; $k < (34 - length($keys[$i])); $k ++) {
          print " ";
          }
        $j = $i + $nlines + 1 - $[;  # one-base
        printf("%2d.  %s\n", $j, $keys[$i + $nlines]);
        }
      }
    if (($#keys % 2) == 0) {
      print "\n";
      }
    print "->  ";
    $answer = <STDIN>;
    chop($answer);
    # remove leading and trailing whitespace if any
    $answer =~ s/\s*([^\s]*)\s*/$1/;

    if ($answer eq "") {
      # They're bailing
      return "";
      }
    # Plan one:  they returned a numeral?
    if (!($answer =~ /[^0-9]/)) {
      $answer = $answer - 1 + $[; # zero-base
      if ($answer < $[ || $answer > $#keys) {
        print "Sorry, your answer is out of range.\n";
        next show_menu;
        }
      return $values[$answer];
      }

    # Plan two:  they gave us a unique portion of the string?

    # Mangle out any special characters in the answer (sigh)
    # This magic is in the section on regular expressions in the perl manual:
    $answer =~ s/(\W)/\\$1/g;

    @possibles = ();
    for ($i = $[; $i <= $#keys; $i ++) {
      if ($keys[$i] =~ /$answer/i) {
        push(@possibles, $i);
        }
      }
    return $values[$possibles[$[]] if $#possibles == $[;
    if ($#possibles == $[ -1) {
      print "Sorry, no matches on \"$answer\"; please try again.\n";
      next show_menu;
      }

    # Otherwise, not unique
    print "Sorry, that choice is not unique:\n\n";
    for ($i = $[; $i <= $#possibles; $i ++) {
      print "  $keys[$possibles[$i]]\n";
      }
    # and try again
    } # show the menu
  }

# Build the tar command, save the results

sub do_the_tar {
  local ($remHost,$devOrFile,*prod_list,$readmeDir) = @_;
  local ($results,$tar_cmd,$status);
  local ($theDir, $thisFile, $tempResults);
  local ($startTime, $endTime);
  local ($startTimeStr, $endTimeStr);
  local ($tarDirSpec);

  # Put the products listed in @prod_list into the file or
  # tape device $devOrFile.  If $remHost is empty, do the
  # tar on the local host.  If $remHost is not empty, use rsh
  # to do the tar on the host named $remHost.
  # $readmeDir is not a full path but rather is the name of
  # a temporary directory under shipbase/test/ where readme.txt
  # is to be.
  $results = "";
  # build the command
  if ("$remHost" eq "") {
    $tar_cmd = "";
    }
  else {
    # Most likely we are on NT
    $tar_cmd = "rsh $remHost ";
    }
  # Use -h flag on tar to follow links so we really get
  # the unzip utils files.
  $tar_cmd .= "tar -chf $devOrFile -C $shipBase utils";
  if ("$readmeDir" ne "") {
    if (-f "$shipBase/test/$readmeDir/readme.txt") {
      if ("$remHost" eq "") {
        $tarDirSpec = " -C " . $shipBase . $DIRSEP . "test" . $DIRSEP;
        $tarDirSpec .= $readmeDir . " readme.txt";
        }
      else {
        # Most likely we are on NT
        $tarDirSpec = " -C $unixShipBase/test/$readmeDir readme.txt";
        }
      $tar_cmd = $tar_cmd . $tarDirSpec;
      }
    else {
      print "Unable to find $shipBase/$readmeDir/readme.txt\n";
      &error_exit(1);
      }
    }

  foreach $each (@prod_list) { # add tarpoints
    $theDir = $partsDir . $DIRSEP . $each;
    if ("$remHost" eq "") {
      $tarDirSpec = " -C " . $partsDir . $DIRSEP . $each;
      }
    else {
      # Most likely we are on NT
      $tarDirSpec = " -C $unixShipBase/inventory/$each";
      }

    # naively, we would just add $prod_names{$each}.  However, let's
    # go the extra 9 yards and allow multiple subdirs under that directory...

    if (!opendir(CURDIR, $theDir)) {
      print "Unable to open directory $theDir, error = $!\n";
      &error_exit(1);
      }
    for (;;) {
      $thisFile = readdir CURDIR;
      last if !defined($thisFile);
      next if ($thisFile eq "." || $thisFile eq "..");
      $tar_cmd = $tar_cmd . $tarDirSpec . " $thisFile";
      }
    closedir(CURDIR);
    } # add tarpoints

  # do the tar!
  $startTime = time;
  $startTimeStr = &my_ctime($startTime);
  chop($startTimeStr);
  $tempResults = "Doing tar with\n  $tar_cmd\nplease wait...  $startTimeStr\n";
  print $tempResults;
  $results = $results . $tempResults;
  $tempResults = `$tar_cmd 2>&1`;
  $status = ($? >> 8);
  print $tempResults;
  $results = $results . $tempResults;
  if ($tempResults =~ / too long/i) {
    # tar had a problem with a long path name.  Bail out!
    print "ERROR: tar found a path name that was too long!\n";
    print $tempResults;
    &error_exit(1);
    }
  if ($tempResults =~ /no such /i) {
    # tar could not find something we asked it to archive.  Bail out!
    print "ERROR: tar could not find a file or directory!\n";
    print $tempResults;
    &error_exit(1);
    }
  $endTime = time;
  $endTimeStr = &my_ctime($endTime);
  chop($endTimeStr);
  print "...done  $endTimeStr\n";
  if ($status != 0) {
    print "$0:  tar returned error:\n\n";
    print $tempResults;
    &error_exit(1);
    }
  $tempResults = "Time elapsed = " . int($endTime - $startTime + 0.5)
        . " sec\n";
  print $tempResults;
  $results = $results . $tempResults;
  return($results);
  }

# Make a log entry describing the shippables we just made
# Arguments: 1. program name (makecdromdirs.pl, maketape.pl, ...)
#            2. product type (tape, cd dirs, floppy)
#            3. device name
#            4. the text of the tar command's output
#            5. list of product names
#            6. list of product part numbers
sub add_to_log {
  local ($progName,$prodType,$device,$cmd_results,*prod_names,*prod_list) = @_;
  local ($entry, $now);
  local ($each, $rawLogName);

  print "Now updating logs...\n";
  # Compose the log entry.
  $now = &my_ctime(time);
  chop($now);
  $entry = "$progName made a $prodType at $now on host $HOSTNAME.\n\n";
  if ($prodType eq "tape") {
    $entry = $entry . "The device was $device\n";
    }
  if ("$prodType" ne "floppy") {
    # floppy already puts this in info in $cmd_results
    $entry = $entry . "The serial number was $serial\n";
    $entry = $entry . "The products are:\n";
    foreach $each (@prod_list) {
      $entry = $entry .  "$prod_names{$each}   ($each)\n";
      }
    $entry = $entry . "\n";
    }
  $entry = $entry . "The output of the command:\n";
  $entry = $entry . $cmd_results;
  $subject = "host $HOSTNAME, ";
  if ($prodType eq "tape") {
    $subject .= "device $device, ";
    }
  $subject .= "serial $serial";
  if ($serial eq "release") {
    &add_entry($entry, $releaseFolder, $subject);
    }
  else {
    &add_entry($entry, $custFolder, $subject);
    }

  # Put a copy of the results in rawlogs
  $rawLogName = $messyDir . $DIRSEP . $serial . ".log";
  if (-f $rawLogName) {
    open(RAWLOG, ">>" . $rawLogName) || die "Cannot append $rawLogName: $!";
    }
  else {
    open(RAWLOG, ">" . $rawLogName) || die "Cannot write $rawLogName: $!";
    }
  # On non-Unix systems (like NT) we want \n to be \n, not \r\n. So use binmode
  binmode(RAWLOG);
  print RAWLOG "\n----------------------------------------\n";
  print RAWLOG $entry;
  close RAWLOG || die "error closing $rawLogName: $!";
  print "Done updating logs.\n";
  }

sub empty_array {
  local (@arr) = @_;

  return 1 if ($#arr == $[ - 1);
  }


# Check if CDRom would truncate a file name to
# 8 characters, a period, 3 characters.
# Name must start with a letter or digit.
# Allow only the chars that are in this set:
#   a-z A-Z 0-9 ! # $ % & ' ( ) - @ ^ _ ` { } ~
# Return "." if name is bad.
sub trunc_filename {
  local($fileName) = @_;
  local($tempFile,$tempExt,$res);
  $tempFile = $fileName;
  $tempExt = $fileName;
  # get the first up to 8 chars in the approved set.
  $tempFile =~ s/([a-zA-Z0-9\!\#\$\%\&\'\(\)\-\@\^\_\`\{\}\~]{0,8}).*/$1/;
  # get the first up to 3 chars after a "."
  $tempExt =~ s/.*\.([a-zA-Z0-9\!\#\$\%\&\'\(\)\-\@\^\_\`\{\}\~]{0,3}).*/$1/;
  if ("$tempExt" eq "$fileName") {
    # no extention
    $res = $tempFile;
    }
  else {
    $res = "$tempFile.$tempExt";
    }
  if ("$res" ne "$fileName") {
    print "  ERROR: truncating name $fileName to $res not allowed!\n";
    return(".");
    }
  if (length($tempFile) > 0) {
    if ($tempFile =~ /^[^a-zA-Z0-9_~]/) {
      # first char is not a letter or a digit or an underscore or a ~
      print "\nERROR: changing name $fileName to $res gave file name\n";
      print "  that did not start with a letter or a digit or an underscore.\n";
      &error_exit(1);
      }
    }
  return("$res");
  }

# Check if CDRom would truncate a directory name to
# 8 characters.
# Name must start with a letter or digit.
# Allow only the chars that are in this set:
#   a-z A-Z 0-9 ! # $ % & ' ( ) - @ ^ _ ` { } ~
# Return "" if name is bad.
sub trunc_dirname {
  local($dirName) = @_;
  local($tempdir);
  $tempdir = $dirName;
  # get the first up to 8 chars in the approved set.
  $tempdir =~ s/([a-zA-Z0-9\!\#\$\%\&\'\(\)\-\@\^\_\`\{\}\~]{0,8}).*/$1/;
  if ("$tempdir" ne "$dirName") {
    print "  ERROR: truncating name $dirName to $res not allowed!\n";
    return("");
    }
  if (length($tempdir) > 0) {
    if ($tempdir =~ /^[^a-zA-Z0-9_]/) {
      # first char is not a letter or a digit or an underscore
      print "\nERROR: changing name $dirName to $tempdir gave file name\n";
      print "  that did not start with a letter or a digit or an underscore.\n";
      &error_exit(1);
      }
    }
  return("$tempdir");
  }


sub check_file_names {
  local($srcDir) = @_;
  local(@dirsToCheck, @filesToCheck);
  local($thisFile, $srcName, $destName);
  local($tempFile, $tempExt, $tempDir, $res);

  # CDRom requires that files be in 8.3 and directories
  # be upto 8 characters.  Longer names are truncated
  # and this messes up installers in PC platforms.
  # So we check all the file and dir names...
  # Return values:
  #        0   Some error happened during processing.
  #        1   Some file or dir name is too long (path is printed).
  #        2   OK, paths are all good.

  # Collect list of files and directories in $srcDir
  if (!opendir(THISDIR, $srcDir)) {
    print "Unable to open directory $srcDir, error = $!\n";
    return 0;
    }
  for (;;) {
    $thisFile = readdir THISDIR;
    if (!defined($thisFile)) {
      last;
      }
    if ($thisFile eq "." || $thisFile eq "..") {
      next;
      }

    $srcName = "$srcDir/$thisFile";

    if ( -d $srcName) {
      push(@dirsToCheck, $thisFile);
      }
    else {
      push(@filesToCheck, $thisFile);
      }
    }
  closedir(THISDIR);

  foreach $thisFile (@dirsToCheck) {
    $srcName = "$srcDir/$thisFile";
    $tempdir = $thisFile;
    # get the first up to 8 chars in the approved set.
    $tempdir =~ s/([a-zA-Z0-9\!\#\$\%\&\'\(\)\-\@\^\_\`\{\}\~]{0,8}).*/$1/;
    if ("$tempdir" ne "$thisFile") {
      print "$SCRIPTNAME:  dir name would be truncated on CDRom, path is:\n";
      print "  $srcName\n";
      return(1);
    }
    $res = &check_file_names($srcName);
    if ($res != 2) {
      return($res);
      }
    }

  foreach $thisFile (@filesToCheck) {
    $srcName = "$srcDir/$thisFile";
    $tempFile = $thisFile;
    $tempExt = $thisFile;
    # get the first up to 8 chars in the approved set.
    $tempFile =~ s/([a-zA-Z0-9\!\#\$\%\&\'\(\)\-\@\^\_\`\{\}\~]{0,8}).*/$1/;
    # get the first up to 3 chars after a "."
    $tempExt =~ s/.*\.([a-zA-Z0-9\!\#\$\%\&\'\(\)\-\@\^\_\`\{\}\~]{0,3}).*/$1/;
    if ("$tempExt" eq "$thisFile") {
      # no extention
      $res = $tempFile;
      }
    else {
      $res = "$tempFile.$tempExt";
      }
    if ("$res" ne "$thisFile") {
      print "$SCRIPTNAME:  file name would be truncated on CDRom, path is:\n";
      print "  $srcName\n";
      return(1);
      }
    }
  return(2);
  }


# Translate a version string into a directory name.
# Remove '.' chars and trim to 8 chars
sub translate_verstring {
  local($str) = @_;
  local($res);
  $res = $str;
  # Remove "."s
  $res =~ s/\.//g;
  # get the first up to 8 chars in the approved set.
  $res =~ s/([a-zA-Z0-9\!\#\$\%\&\'\(\)\-\@\^\_\`\{\}\~]{0,8}).*/$1/;
  return("$res");
  }

sub construct_dir_path_name {
  local($mediaType, *tempDirRelative, $productLine, *prodStr,
        $targetArch, *archStr, $prodVersion, *verStr,
        $vendorCompat, *vendorStr, $beCompat, *beCompatStr,
        $patchNum, *patchStr) = @_;

  if (&translateNumToDirStr($productLine,*prodStrMapping,$prodStrMapWidth,
                                                      $mediaType,*prodStr)) {
    print "$0 error: don't know how to pick prodStr for\n";
    print "    product line: \"$productLine\"\n";
    print "    product number: \"$productNumber\"\n";
    &error_exit($cdromFilesDir);
    }
  $prodStr = &trunc_filename($prodStr);
  $prodStr =~ tr/A-Z/a-z/;

  if (&translateNumToDirStr($targetArch,*archStrMapping,$archStrMapWidth,
                                                     $mediaType, *archStr)) {
    print "$0 error: don't know how to pick archStr for\n";
    print "    target arch: \"$targetArch\"\n";
    print "    product number: \"$productNumber\"\n";
    &error_exit($cdromFilesDir);
    }
  $archStr = &trunc_filename($archStr);
  $archStr =~ tr/A-Z/a-z/;

  $verStr = &translate_verstring($prodVersion);
  $verStr =~ tr/A-Z/a-z/;

  if (&translateNumToDirStr($vendorCompat,*vendorStrMapping,
                               $vendorStrMapWidth, $mediaType, *vendorStr)) {
    print "$0 error: don't know how to pick vendorStr for\n";
    print "    vendorCompat: \"$vendorCompat\"\n";
    print "    product number: \"$productNumber\"\n";
    exit 1
    }
  $vendorStr =~ tr/A-Z/a-z/;

  $beCompatStr = "";
  if ("$beCompat" ne "0") {
    $beCompatStr = &translate_verstring($beCompat);
    $beCompatStr =~ tr/A-Z/a-z/;
    }

  $patchStr = "";
  if ($patchNum ne "0") {
    # patchNum is in the form of Pxxx where "xxx" can be "001" through "999"
    $patchStr = $patchNum;
    $patchStr =~ s/P/PATCH/;
    $patchStr =~ tr/A-Z/a-z/;
    $patchStr = &trunc_filename($patchStr);
    if ($patchStr eq "") {
      die "ERROR: unable to map $patchNum to a directory string\n";
      }
    }

  #No longer put Architecture or Version levels on CDRom
  #$tempDirRelative = "$prodStr/$verStr/$archStr";
  $tempDirRelative = "$prodStr";

  # For GemFire installers add platform type to let multiple 
  # installers reside on a single CD. 
  if ("$productLine" eq "10") {
    $tempDirRelative = "$prodStr/$archStr"; 
    } 

  if ("$vendorStr" ne "") {
    $tempDirRelative .= "/$vendorStr";
    }

  if ("$beCompatStr" ne "") {
    if (("$productLine" ne "12") && ("$productLine" ne "14") &&
        ("$productLine" ne "112") && ("$productLine" ne "114")) {
      $tempDirRelative .= "/$beCompatStr";
      }
    }

  if ("$patchStr" ne "") {
    $tempDirRelative .= "/$patchStr";
    }

  # The $tempDirRelative now has the path of the directories
  # for this product.
  }

# error exit routine.  Can be redefined to do cleanup before exit.
sub error_exit {
  print "basic exit\n";
  exit(@_);
  }

# End of routines for maketape.pl and makecdimage.pl
# --------------------------------------------------


sub tarandcomp {
  local($theInDir, $theOutDir, $theFileBase) = @_;
  local($tar_cmd, $tarName, $zipName, $compName, $gzipName);
  local($tar_regular, $tar_compressed, $tar_gzip, $zip_cmd);
  local($status);

  # Create tar files, compressed files, and compressed tar files
  # from files and directories under $theInDir.
  # For instance: If "theInDir" is /gcm/where/ship50/inventory/1-9-5.0-0-0-P001"
  # and "theOutDir" is /home/build/Scratch" and "theFileBase" is "p001gs50_AIX"
  # (which means patch001 of GemStone version 5.0)  we will get
  # this structure:
  # /home/build/Scratch/
  #             p001gs50_AIX_tar.Z    (compressed tar file)
  #             p001gs50_AIX_tar.gz   (gzipped tar file)
  #             p001gs50_AIX.zip      (compressed file)
  # These would each extract to GemStone5.0-RISC6000.AIX-PatchLevel001.
  # It is possible that the compressed tar file will be larger than a plain
  # tar file.  If this happens we would have the file p001gs50_AIX.tar
  # instead of p001gs50_AIX_tar.Z.  We will always get the .gz file.

  # WARNING! The "theInDir" and "theOutDir" must be full paths!

  # Check that $theOutDir starts with a "/"
  if (substr("$theOutDir",0,1) ne "/") {
    print "Sorry, path $theOutDir must be a full path.\n";
    return(1);
    }
  # Check that $theInDir starts with a "/"
  if (substr("$theInDir",0,1) ne "/") {
    print "Sorry, path $theInDir must be a full path.\n";
    return(1);
    }
  # Check that $theOutDir exists:
  if (! -d "$theOutDir" ) {
    print "Sorry, there is no such dir $theOutDir\n";
    return(1);
    }
  # Check that $theInDir exists:
  if (! -d $theInDir) {
    print "Sorry, there is no such dir $theInDir\n";
    return(1);
    }

  # Do all files and subdirs under the $theInDir directory...
  # build the command
  $tar_cmd = "cd $theInDir;tar -cf - *";
  
  # construct the file names
  $tarName  = "$theOutDir/$theFileBase.tar";
  $zipName  = "$theOutDir/$theFileBase.zip";
  $compName = "$theOutDir/$theFileBase" . "_tar.Z";
  $gzipName = "$theOutDir/$theFileBase" . "_tar.gz";
  
  # construct the complete tar/compress commands
  $tar_regular = $tar_cmd . " > $tarName";
  $tar_compressed = $tar_cmd . "| compress -f > $compName";
  $tar_gzip = $tar_cmd . "| gzip > $gzipName";
  $zip_cmd = "cd $theInDir;zip -r $zipName *";
  
  # do not overwrite existing files!
  if (-e "$tarName" ) {
    print "Error: file $tarName already exists\n";
    return(1);
    }
  
  # do not overwrite existing files!
  if (-e "$compName" ) {
    print "Error: file $compName already exists\n";
    return(1);
    }
  
  # do not overwrite existing files!
  if (-e "$gzipName" ) {
    print "Error: file $gzipName already exists\n";
    return(1);
    }
  
  # do not overwrite existing files!
  if (-e "$zipName" ) {
    print "Error: file $zipName already exists\n";
    return(1);
    }
  
  print "   Creating compressed tar file of $theInDir\n";
  $status = system("$tar_compressed");
  $status = $status >> 8;
  if ($status == 1) {
    print "Error: status = $status creating compressed file with this command:\n";
    print "   $tar_compressed\n";
    return(1);
    }
  if ($status == 2) {
    print "   Compressed tar file is larger than a regular tar file.\n";
    print "   Using regular tar file instead.\n";
    print "   Creating regular tar file of $theInDir\n";
    unlink("$compName");
    $status = system("$tar_regular");
    $status = $status >> 8;
    if ($status != 0) {
      print "Error: status = $status creating tar file with this command:\n";
      print "   $tar_regular\n";
      return(1);
      }
    }

  print "   Creating gzipped tar file of $theInDir\n";
  $status = system("$tar_gzip");
  $status = $status >> 8;
  if ($status != 0) {
    print "Error: status = $status creating gzip file with this command:\n";
    print "   $tar_gzip\n";
    return(1);
    }

  print "   Creating zipped file of $theInDir\n";
  $status = system("$zip_cmd");
  $status = $status >> 8;
  if ($status != 0) {
    print "Error: status = $status creating zip file with this command:\n";
    print "   $zip_cmd\n";
    return(1);
    }

  return(0); # success
  } # sub tarandcomp

