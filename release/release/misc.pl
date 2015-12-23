# Copyright (c) 2010-2015 Pivotal Software, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License. You
# may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing
# permissions and limitations under the License. See accompanying
# LICENSE file.

#-----------------------------------------------------------------
# Determine $HOSTTYPE_OSTYPE
#-----------------------------------------------------------------
if ( -e "/export/localnew/scripts/suntype" ) {
        $HOSTTYPE = `/export/localnew/scripts/suntype -hosttype`;
        chomp( $HOSTTYPE );
        $OSTYPE = `/export/localnew/scripts/suntype -ostype`;
        chomp($OSTYPE);
        $HOSTTYPE_OSTYPE = "$HOSTTYPE.$OSTYPE";
} elsif ( $ENV{"OS"} eq "Windows_NT" ) {
    $HOSTTYPE_OSTYPE = "x86.Windows_NT";
    # delete $ENV{"PATH"}; # for safety
} else {
    $HOSTTYPE_OSTYPE = "unknown";
}

# put this rsh_commands def BEFORE "package misc".
%rsh_commands = ("hppa.hpux", "remsh",
        "hppa.hpux_8", "remsh",
        "hppa.hpux_9", "remsh",
        "i386.NCR", "remsh",
        "MIPSEB.sinix", "rsh",
        "Symmetry.Dynix", "resh",
        "sparc.SunOS4", "rsh",
        "sparc.Solaris", "rsh",
        "RISC6000.AIX", "rsh",
        "x86.Windows_NT", "rsh",
#        "x86.os2", "rsh -l $USER"	# $USER not yet defined here
	);

package misc;

$HOSTTYPE_OSTYPE = $main'HOSTTYPE_OSTYPE;


#----------------------------------------------------------------------------
# tools to support this nasty getarch implementation...
#----------------------------------------------------------------------------

# Try a command, with absolutely no interest in capturing its output.
sub try_command {
  local ($theNoise) = @_;
  local ($result);

  # Perl magic to save stdout/stderr and then redirect to NULL
  open(SAVEOUT, ">&STDOUT");
  open(SAVEERR, ">&STDERR");
  open(STDOUT, ">/dev/null");
  open(STDERR, ">&STDOUT");

  $result = system($theNoise) == 0;

  # Corresponding magic to put back
  close(STDOUT);
  close(STDERR);
  open(STDOUT, ">&SAVEOUT");
  open(STDERR, ">&SAVEERR");
  close(SAVEOUT);
  close(SAVEERR);

  return $result;
  }

sub get_uname {
  local ($theArg) = @_;
  local ($result);

  if (!open(NOISE, "/bin/uname " . $theArg . "|")) {
    die "open of '/bin/uname $theArg' failed:  $!\n";
    }
  $result = <NOISE>;
  close(NOISE);
  chop($result);
  return $result;
  }

sub main'getarch {
  local($nodeName) = @_;
  local($HostType, $OsType);
  local($osRelease, $osMjrRelNum);

  $nodeName = $nodeName;  # junk
  if (! -e "/bin/bash") { # Must be NT or OS/2
    return "x86.os2" if $ENV{"OS2_SHELL"} ne "";
    return "x86.Windows_NT" if $ENV{"OS"} eq "Windows_NT";
    die "cannot determine architecture";
    }

  if (&try_command("sparc")) {	# sparc?  (complicated)
    $HostType = "sparc";
    $osRelease = &get_uname("-r");
    $osMjrRelNum = $osRelease;
    $osMjrRelNum =~ s/^([0-9]*)\..*/$1/;
    if ("$osMjrRelNum" eq "4")  {
      $OsType = "SunOS4";
      }
    elsif ($osMjrRelNum eq "5") {
      $OsType = "Solaris";
      }
    else {
      die "This sparc is neither SunOS or Solaris?  \"$osMjrRelNum\"\n";
      }
    return $HostType . "." . $OsType;
    }

  if (&try_command("hp-pa")) {
    return "hppa.hpux";
    }

  if (&try_command("/bin/uname -p")) { # NCR?
    $osRelease = &get_uname("-p");
    if ( $osRelease eq "386/486/MC") {
      return "i386.NCR";
      }
    }

  if (&try_command("uname -s")) { # Sinix, AIX, Dynix
    $osRelease = &get_uname("-s");
    if ($osRelease =~ /SINIX.*/) {
      return "MIPSEB.sinix";
      }
    if ($osRelease =~ /AIX.*/) {
      return "RISC6000.AIX";
      }
    if ($osRelease =~ /DYNIX.*/) {
      return "Symmetry.Dynix";
      }
    }

  die "Sorry, all my attempts to determine this architecture failed.\n";
  }


# rm -rf
sub main'remove_dir {
  local ($theDir) = @_;
  local (@dirsToKill, @filesToKill);
  local ($thisFile);

  # print "Removing directory $theDir...\n";

  if ( ! -e "$theDir" ) {
    print "$0: $theDir does not exist\n";
    print "  error = $!\n";
    return 0;
    }
  # Collect list of files and directories
  if (chmod(0777, $theDir) != 1) {
    print "$0: error chmod'ing $theDir\n";
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
    if ( -l $thisFile ) {
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
    if (&main'remove_dir($thisFile)) {
      return 1;
      }
    }
  foreach $thisFile (@filesToKill) {
    # print "Removing file $thisFile...\n";
    if ((!-l $thisFile) && (chmod(0777, $thisFile) != 1)) {
      print "$0: error chmod'ing $thisFile\n";
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
sub main'delimited_dir {
  local ($givenName) = @_;
  local ($archType);

  $archType = $main'ArchExtensions{$HOSTTYPE_OSTYPE};
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
    die "internal error, unknown arch $HOSTTYPE_OSTYPE";
    }
  }

# basic_copy:  implement a cp command in perl
sub main'basic_copy {
  local($srcName, $destName, $okIfExists) = @_;
  local ($numDone, $totalCount, $buffer);
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
  $buffer = "";
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
    if (!&main'basic_chmod($destName, $mode)) {
      print "$0:  error chmod'ing $destName\n";
      return 0;
      }
    if (utime($atime, $mtime, $destName) != 1) {
      print "$0:  error utime'ing $destName: $!\n";
      return 0;
      }
  }
  return 1;
  }

# Call the chmod() intrinsic
sub main'basic_mkdir {
  local($name, $mode, $pleasedont) = @_;

  if (defined($pleasedont) && $pleasedont ne "") { 
    print "basic_mkdir: pleasedont = $pleasedont\n";
    }

  if (!mkdir($name, 0755)) {
    print "$0: unable to mkdir $name.\n";
    print "  error = $!\n";
    return 0;
    }

  if ($main'ArchExtensions{$HOSTTYPE_OSTYPE} ne "unix") {
    return 1;
    }

  if (chmod(0755, $name) != 1) {
    print "$0: error chmod'ing $name.\n";
    print "  error = $!\n";
    return 0;
    }
  return 1;
  }

# Call the chmod() intrinsic
sub main'basic_chmod {
  local($name, $mode, $pleasedont ) = @_;

  if (defined($pleasedont) && $pleasedont ne "") { 
    print "basic_chmod: pleasedont = $pleasedont\n";
    }

  if ($main'ArchExtensions{$HOSTTYPE_OSTYPE} ne "unix") {
    return 1;
    }

  if (chmod($mode, $name) != 1) {
    print "$0: error chmod'ing $mode $name.\n";
    print "  error = $!\n";
    return 0;
    }
  return 1;
  }

# Return TRUE if the subdirectory should be pruned
sub is_garbage_dir {
  local ($dirName) = @_;
  local ($delim);
  local($archType) = $main'ArchExtensions{$HOSTTYPE_OSTYPE};

  if ($archType eq "unix") {
    $delim = "/";
    }
  elsif ($archType eq "dos") {
    $delim = "[\\\\/]";
    }
  elsif ($archType eq "mac") {
    $delim = ":";
    }
  else {
    print "is_garbage_dir:  unknown archType $archType\n";
    $delim = "/";
    }

  return 1 if $dirName =~ /.*${delim}slow[0-9]+$/;
  return 1 if $dirName =~ /.*${delim}fast[0-9]+$/;
  return 1 if $dirName =~ /.*${delim}lint[0-9]+$/;
  return 1 if $dirName =~ /.*${delim}prof[0-9]+$/;
  return 1 if $dirName =~ /.*${delim}noop[0-9]+$/;
  return 1 if $dirName =~ /.*${delim}log[0-9]+$/; # get rid of this someday
  return 1 if $dirName =~ /.*${delim}slowgcc$/;
  return 1 if $dirName =~ /.*${delim}fileinlog$/;

  # For OS/2
  return 1 if $dirName =~ /.*${delim}slow$/;
  return 1 if $dirName =~ /.*${delim}fast$/;
  return 1 if $dirName =~ /.*${delim}noop$/;
  return 1 if $dirName =~ /.*${delim}prof$/;

  # for the jdk: .../jdk/build/.../obj_g, etc.
  return 1 if $dirName =~ /.*${delim}jdk${delim}build${delim}.*${delim}obj$/;
  return 1 if $dirName =~ /.*${delim}jdk${delim}build${delim}.*${delim}obj_g$/;
  return 1 if $dirName =~ /.*${delim}jdk${delim}build${delim}.*${delim}obj_n$/;
  return 1 if $dirName =~ /.*${delim}jdk${delim}build${delim}.*${delim}obj_p$/;

  return 1 if $dirName =~ /.*${delim}jdk${delim}build${delim}(solaris|win32)${delim}bin$/;
  return 1 if $dirName =~ /.*${delim}jdk${delim}build${delim}(solaris|win32)${delim}lib$/;
  return 1 if $dirName =~ /.*${delim}jdk${delim}build${delim}(solaris|win32)${delim}classes$/;
  return 1 if $dirName =~ /.*${delim}jdk${delim}build${delim}(solaris|win32)${delim}classes_g$/;
  return 1 if $dirName =~ /.*${delim}jdk${delim}build${delim}(solaris|win32)${delim}doc$/;
  return 1 if $dirName =~ /.*${delim}idlc${delim}build${delim}(solaris|win32)${delim}org${delim}omg${delim}idltojava${delim}(ast|idlgen)${delim}Templates.DB$/;
  return 1 if $dirName =~ /.*${delim}(javax|secure|server|conversion|query|orb|transport|baseapi|orbsvc|admin|ejb|client|3tc|debug|tools|web)${delim}(lib|classes|classes_g)$/;
  return 1 if $dirName =~ /.*${delim}(javax|secure|server|conversion|query|orb|transport|baseapi|orbsvc|admin|ejb|client|3tc|debug|tools|web)${delim}objects\d+(_g|_n)*$/;
  return 1 if $dirName =~ /.*${delim}(javax|secure|server|conversion|query|orb|transport|baseapi|orbsvc|admin|ejb|client|3tc|debug|tools|web)${delim}(defaults)$/;
  return 1 if $dirName =~ /.*${delim}hotspotWin${delim}build${delim}win32_i486${delim}hotspot_hp$/;
  return 1 if $dirName =~ /.*${delim}hotspot${delim}build${delim}solaris${delim}solaris_sparc_hp$/;

  return 0;
  }

# Copy a directory tree, ignoring "garbage" directories
sub main'copy_tree {
  local($newDir, $srcDir, $pleasedont) = @_;
  local(@dirsToCopy, @filesToCopy);
  local($thisFile, $srcName, $destName);

  if (defined($pleasedont) && $pleasedont ne "") { 
    print "copy_tree: pleasedont = $pleasedont\n";
    }

  if (&is_garbage_dir($srcDir)) {
    print "    (skipping directory $srcDir)\n";
    return 1;
    }
  
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

    $srcName = &main'delimited_dir($srcDir) . $thisFile;

    # following check helps on OS/2, where NFS symbolic links as garbage
    # directories give perl fits, since it can't properly stat() them.
    if ($HOSTTYPE_OSTYPE eq "x86.os2") {
      next if (&is_garbage_dir($srcName));
      }

    if ( -l $srcName) {
      print "    (skipping link $srcName)\n";
      }
    elsif ( -d $srcName) {
      push(@dirsToCopy, $thisFile);
      }
    else {
      push(@filesToCopy, $thisFile);
      }
    }
  closedir(THISDIR);

  if (!&main'basic_mkdir($newDir, 0755)) {
    return 0;
    }

  foreach $thisFile (@dirsToCopy) {
    $srcName = &main'delimited_dir($srcDir) . $thisFile;
    $destName = &main'delimited_dir($newDir) . $thisFile;

    if (!&main'copy_tree($destName, $srcName)) {
      return 0;
      }
    }

  # print "   Copying files in $srcDir...\n";
  foreach $thisFile (@filesToCopy) {
    $srcName = &main'delimited_dir($srcDir) . $thisFile;
    $destName = &main'delimited_dir($newDir) . $thisFile;
    if (!&main'basic_copy($srcName, $destName, 0)) {
      print "$0:  copy of source file failed\n";
      return 0;
      }
    }
  return 1;
  }

# Copy all files and directories in a directory tree
sub main'basiccopy_tree {
  local($newDir, $srcDir, $pleasedont) = @_;
  local(@dirsToCopy, @filesToCopy);
  local($thisFile, $srcName, $destName);

  if (defined($pleasedont) && $pleasedont ne "") { 
    print "basiccopy_tree: pleasedont = $pleasedont\n";
    }

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

    $srcName = &main'delimited_dir($srcDir) . $thisFile;

    if ( -l $srcName) {
      # assume a file
      push(@filesToCopy, $thisFile);
      }
    elsif ( -d $srcName) {
      push(@dirsToCopy, $thisFile);
      }
    else {
      push(@filesToCopy, $thisFile);
      }
    }
  closedir(THISDIR);

  if (!&main'basic_mkdir($newDir, 0755)) {
    return 0;
    }

  foreach $thisFile (@dirsToCopy) {
    $srcName = &main'delimited_dir($srcDir) . $thisFile;
    $destName = &main'delimited_dir($newDir) . $thisFile;

    if (!&main'basiccopy_tree($destName, $srcName)) {
      return 0;
      }
    }

  # print "   Copying files in $srcDir...\n";
  foreach $thisFile (@filesToCopy) {
    $srcName = &main'delimited_dir($srcDir) . $thisFile;
    $destName = &main'delimited_dir($newDir) . $thisFile;
    if (!&main'basic_copy($srcName, $destName, 0)) {
      print "$0:  copy of source file failed\n";
      return 0;
      }
    }
  return 1;
  }

# make a list of all files and directories in a directory tree
sub main'list_tree {
  local($srcDir, *fileList) = @_;
  local(@dirsToList, @filesToList);
  local($thisFile, $srcName);

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

    $srcName = &main'delimited_dir($srcDir) . $thisFile;

    # following check helps on OS/2, where NFS symbolic links as garbage
    # directories give perl fits, since it can't properly stat() them.
    if ($HOSTTYPE_OSTYPE eq "x86.os2") {
      next if (&is_garbage_dir($srcName));
      }

    if ( -l $srcName) {
      # assume a file
      push(@filesToList, $thisFile);
      }
    elsif ( -d $srcName) {
      push(@dirsToList, $thisFile);
      }
    else {
      push(@filesToList, $thisFile);
      }
    }
  closedir(THISDIR);

  foreach $thisFile (@dirsToList) {
    $srcName = &main'delimited_dir($srcDir) . $thisFile;
    if (!&main'list_tree($srcName, *fileList)) {
      return 0;
      }
    }

  # print "   Copying files in $srcDir...\n";
  foreach $thisFile (@filesToList) {
    $srcName = &main'delimited_dir($srcDir) . $thisFile;
    push(@fileList, $srcName);
    }
  return 1;
  }


# Check that all files and directories in a directory tree are accessable
# (files readable by this user, dirs read and execute by this user).
sub main'checkPermissions_tree {
  local($srcDir) = @_;
  local(@dirsToCheck, @filesToCheck);
  local($thisFile, $srcName);

  # Collect list of files and directories in $srcDir
  if ((! -x "$srcDir") || (! -r "$srcDir")) {
    print "directory $srcDir does not have rx permission for this user.\n";
    return 0;
    }
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

    $srcName = &main'delimited_dir($srcDir) . $thisFile;

    if ( -l $srcName) {
      # assume a file
      push(@filesToCheck, $thisFile);
      }
    elsif ( -d $srcName) {
      push(@dirsToCheck, $thisFile);
      }
    else {
      push(@filesToCheck, $thisFile);
      }
    }
  closedir(THISDIR);


  foreach $thisFile (@dirsToCheck) {
    $srcName = &main'delimited_dir($srcDir) . $thisFile;

    if (!&main'checkPermissions_tree($srcName)) {
      return 0;
      }
    }

  foreach $thisFile (@filesToCheck) {
    $srcName = &main'delimited_dir($srcDir) . $thisFile;
    if (! -r "$srcName") {
      print "$0:  read access check of source file \"$srcName\" failed\n";
      return 0;
      }
    }
  return 1;
  }

1;
