#!/usr/bin/perl

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

# $Id$
#
# This program has the following functions:
#  copy <manifest-name> <arch> <DestRootDir> <packing-list> {definitions}
#    Process the manifest, making copies in the destination directory
#  link <manifest-name> <arch> <DestRootDir> {definitions}
#    like the above, but files are symlinked.  Unix only.
#
#  <manifest-name> is a program describing the target product, of course.
#
#  <arch> is one of the following:
#	  sparc.SunOS4
#	  sparc.Solaris
#	  hppa.hpux
#	  hppa.hpux_8
#	  hppa.hpux_9
#         x86.Windows_NT
#         x86.Windows_95
#         x86.NTWindows_95
#	  Symmetry.Dynix
#	  i386.NCR
#	  MIPSEB.sinix
#	  RISC6000.AIX
#	  x86.os2
#	  x86.win31
#         x86.win32s
#         x86.NTwin32s
#         mac
#         powermac
#
#  In all cases, <DestRootDir> is created.  It is an error if <DestRootDir>
#  already exists.  makeprod.pl will create <DestRootDir>/product for the
#  product files and directories customers will see and <DestRootDir>/hidden
#  for files with the "hide" attribute in the packing-list.
#  makeprod.pl will also create <DestRootDir>/sources when the makeprod
#  function is "copy".
#
#  <packing-list> is a pretty list of files, with comments, to include in the
#  release.
#
#  {definitions} are zero or more definitions of the form,
#    identifier=value
#
#  Commands in a manifest:
#  The following commands are supported in a manifest file:
#  1.  Blank lines are not significant.
#  2.  All text following an unescaped "#" on a line is ignored.
#  3.  User-level comments:  All text following an unescaped "!" is ignored
#      and the comment is copied to the packing list.
#  4.  Control structures:
#       if <perl-expr>
#       endif
#
#	if <perl-expr>
#	else
#	endif
#
#	if <perl-expr>
#	elsif <perl-expr>
#	elsif <perl-expr>
#	...
#	[else]
#	endif
#
#  5.  File Creation
#  mkdir <newDir>
#       create a directory
#  copy  <destName> <srcName> <fileType>
#	creates a file from the given source (with the copy and link commands)
#	and propogates the file from the source to the destination with the
#	release command.  <fileType> is used to add a file extension to the
#	name, if appropriate on this system.  Supported file types:
#
#	type	unix	nt
#	obj	.o	.obj
#	exe	""	.exe
#	lib	.a	.lib
#	dll	.so	.dll
#	text	""	""	(no filename modification is performed)
#	bin	""	""	(ditto, but binary data)
#	dir	""	""	(directory, esp. in chmod command)
#
#	<srcName> is evaluated as a perl expression, so that $foo/bar is
#	expressly allowed.
#
#  6.  Help commands
#      help <text>
#      require {names}
#
#	The "help" command appends text to a help message.
#	The "require" command requires that the given names refer to existing
#	directories.  If one is missing, a message is printed and the
#	accumulated help text is dumped.
#
#  7.	Messages
#	say <text>
#	  Print a message
#	die <text>
#	  Print a message and die
#
# ---------------------------------------------------------------------

require "find.pl";

if (-e "/export/localnew/scripts/suntype") {
    $HOSTTYPE = `/export/localnew/scripts/suntype -hosttype`;
    chomp( $HOSTTYPE );
    $OSTYPE = `/export/localnew/scripts/suntype -ostype`;
    chomp( $OSTYPE );
    $ARCH = "$HOSTTYPE.$OSTYPE";
} else {
    $ARCH = "x86.Windows_NT";
}

$is_cygwin = 0;
if ($ARCH eq "x86.Windows_NT") {
  # print STDERR "WARNING: assuming that MKS toolkit is _not_ installed.\n";
  delete $ENV{"SHELL"}; # for safety
  # delete $ENV{"PATH"}; # for safety
  $UNAME = `uname`;
  chomp($UNAME);
  if ( $UNAME =~ /CYGWIN_NT/ ) {
    $is_cygwin = 1;
    $DIRSEP = "/";
  } else {
    $DIRSEP = "\\";
  }
} else {
  $DIRSEP = "/";
}


use Cwd;

sub get_my_name {
    local($myName);

    $ORIGDIR = &cwd();
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
    $SCRIPTDIR = &cwd();
    if (!chdir($ORIGDIR)) {
	die "cannot chdir to original directory $ORIGDIR: $!\n";
    }
}
&get_my_name;

#require "$SCRIPTDIR/../ship/partnummapping.pl";
unshift (@INC, "$SCRIPTDIR/../ship");
require "partnummapping.pl";

#require "$SCRIPTDIR/misc.pl";
unshift (@INC, $SCRIPTDIR);
require "misc.pl";
require "miscpack.pl";

$RUNNINGARCH = $ARCH;  # $ARCH is overwritten later

# Make stderr and stdout unbuffered.
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

# Constant Dictionaries

# Generic handlers
$SIG{'HUP'} = 'IGNORE';
$SIG{'INT'} = 'signalHandler';
$SIG{'QUIT'} = 'signalHandler';
$SIG{'TERM'} = 'signalHandler';

$doingReinstall = 0;

# The following magic is from the perl man page!
$symlink_exists = (eval 'symlink("","");', $@ eq '');

# Get the execution mode
if ( $ARGV[0] eq "copy" ) {
  $RequestedCopyMode = "copy";
  }
elsif ( $ARGV[0] eq "link" ) {
  $RequestedCopyMode = "link";
  if (! $symlink_exists) {
    print "This system does not support symlinks; will use copy instead.\n";
    print "Only newer or non-existant files will be copied.\n";
    $doingReinstall = 1;
    }
  }
elsif ( $ARGV[0] eq "noremove" ) {
  $doingReinstall = 1;
  print "Doing a reinstall.\n";
  $RequestedCopyMode = "link";
  if (! $symlink_exists) {
    print "This system does not support symlinks; will use copy instead.\n";
    print "Only newer or non-existant files will be copied.\n";
    }
  }
elsif ( $ARGV[0] eq "update" ) {
  $doingUpdate = 1;
  print "Doing an update.\n";
  $RequestedCopyMode = "copy";
  print "Only newer or non-existant files will be copied.\n";
  }
else {
  &generalUsage;
  }
shift;
$CopyMode = $RequestedCopyMode;

# manifest
$TheManifest = $ARGV[0];
if (! &mustBeOldFile($TheManifest, "manifest")) {
  &generalUsage;
  }
shift;

# arch
$ARCH = $ARGV[0];
$ArchType = $ArchExtensions{$ARCH};
if ( ! $ArchType) {
  printf("Unknown architecture \"$ARCH\"\n");
  &error_exit;
  }
shift;

if ($ARCH eq "hppa.hpux") {
    $UnixExtensions{"dll"} = ".sl";
} elsif ($ARCH eq "RISC6000.AIX") {
    $UnixExtensions{"dll"} = ".o";
}

# DestDir
$DestRootDir = $ARGV[0];
shift;
$DestDir = "$DestRootDir/product";
if ($RUNNINGARCH eq "x86.os2" || $RUNNINGARCH eq "x86.Windows_NT") {
  $DestRootDir =~ s%\\%/%g;    # don't allow backslashes for OS/2
  $DestDir =~ s%\\%/%g;    # don't allow backslashes for OS/2
  }
if (! &mustBeNewDir($DestRootDir, "DestRootDir")) {
  &generalUsage;
  }
if (! &mustBeNewDir($DestDir, "DestDir")) {
  &generalUsage;
  }

# PackingList
$PackingList = $ARGV[0];
if ( ! &mustBeNewFile($PackingList, "PackingList")) {
  &copyUsage;
  }
shift;
if ($RUNNINGARCH eq "x86.os2" || $RUNNINGARCH eq "x86.Windows_NT") {
  $PackingList =~ s%\\%/%g;    # don't allow backslashes for OS/2
  }

# Copy sources?
$shouldCopySources = $ARGV[0];
  if ( $shouldCopySources eq "nosources" ) {
    $shouldCopySources = 0;
  } elsif ($shouldCopySources eq "sources" ) {
    $shouldCopySources = 1;
  } else {
    print "Unknown arg: $shouldCopySources\n";
    &copyUsage;
  }
  shift;

# Read the rest of the command line arguments.
if (( $CopyMode eq "copy") || ( $CopyMode eq "link")) {
  if ( $CopyMode eq "link") {
    if (! $symlink_exists) {
	$CopyMode = "copy";
    }
  }
  $HiddenDir = "$DestRootDir/hidden";
  if ($RUNNINGARCH eq "x86.os2" || $RUNNINGARCH eq "x86.Windows_NT") {
    $HiddenDir =~ s%\\%/%g;    # don't allow backslashes for OS/2
    }
  if (! &mustBeNewDir($HiddenDir, "HiddenDir")) {
    &copyUsage;
    }
} else {
  die "Internal error, CopyMode is $CopyMode";
  }

print "CopyMode    = $CopyMode\n";
print "TheManifest = $TheManifest\n";
print "DestRootDir = $DestRootDir\n";
print "DestDir     = $DestDir\n";
print "PackingList = $PackingList\n";
if ($HiddenDir ne "") {
  print "HiddenDir   = $HiddenDir\n";
  }

# Load up the definitions on the command line
while ( defined $ARGV[0]) {
  $this = $ARGV[0];
  shift;
  if (! ($this =~ /^\S+=\S+$/ )) {
    print "$0:  illegal definition (must be of the form 'a=b'): $this\n";
    &clean_and_die;
    }
  $junk = $this;
  $junk =~ s/^(\S+)=(\S+)$/\$$1=\"$2\";/;

  if ($RUNNINGARCH eq "x86.os2" || $RUNNINGARCH eq "x86.Windows_NT") {
    $junk =~ s%\\%/%g;	# Don't allow backslash
    }
  
  eval $junk;
  if ($@ ne '') {
    print "$0:  eval of \"$junk\" failed: $@\n";
    &clean_and_die;
    }
  print "    $this\n";	# debug
  }

%SourceList = ();

if ( $PackingList ne "") {

  # Build a list of line in existing packing file so we don't print
  # duplicates.
  if (-e "$PackingList" ) {
    if (!open( DUPS, "<$PackingList") ) {
      print "$0: unable to read $PackingList.\n";
      print "error = $!\n";
    } else {
      for (;;) {
	$line_mds1 = <DUPS>;
	last if !defined($line_mds1);
        $duplicate_line{"$line_mds1"} = 1;
	}
      close( DUPS );
    }
  }

  if (!open(PACKINGLIST, ">>" . $PackingList)) {
    print "$0: unable to open packing list $PackingList.\n";
    print "error = $!\n";
    &error_exit;
    }
  #make each write to the packing list flush to disk
  select((select(PACKINGLIST), $| = 1) [ $[ ]);
  }
if (!open(MANIFEST, "<" . $TheManifest)) {
  print "$0: unable to open manifest $TheManifest.\n";
  print "error = $!\n";
  &clean_and_die;
  }
binmode MANIFEST;

# for include processing
@stacked_input_files = ($TheManifest);
@stacked_input_positions = (tell MANIFEST);
@stacked_input_lineNums = (0);
$get_line_eof = 0;
$found_error = 0;
$HelpText = "";

ANOTHER_LINE: for (;;) {
  $newLine = &get_line;
  last if $newLine eq "eof";
  @newParsed = &parse_packing_line($newLine);
  &do_line(@newParsed);
  }

if ( $PackingList ne "") {
  if (!close(PACKINGLIST)) {
    print "$0: error closing $PackingList.\n";
    print "  error = $!\n";
    &clean_and_die;
    }
  }

# if ($ARCH eq "x86.os2") {
# } elsif ($ARCH eq "x86.Windows_NT") {
# } elsif ("$CopyMode" eq "copy") {
#   print "  Building product checksums now...\n";
# 
#   # The following command checksums the source directory, placing the
#   # result in the new directory
# 
#   # this manifest language doesn't have line continuation yet.  Sorry.
#   system("chmod u+w $DestDir/install");
#   $chksumcmd="here=`pwd`;cd $DestDir;DestDir=`pwd`;GEMSTONE=$DestDir;export GEMSTONE;rm -f install/checksums.good;cd install;./checksum \$DestDir \$DestDir/PACKING \$DestDir/install/checksums.good install/checksums.good originate";
#   if (system($chksumcmd) != 0) {
#     print "$0: error creating checksums.good with this command:\n";
#     print "  $chksumcmd\n";
#     print "  error: $!\n";
#     &clean_and_die;
#     }
#   system("chmod u-w $DestDir/install");
# }

# Note we do not test CopyMode because 'link' becomes 'copy' on NT.
if ( $RequestedCopyMode eq "copy") {
  (($dev,$ino,$mode,$nlink) = stat($DestDir))
	  || (print "$0:  Can't stat $DestDir: $!\n", &clean_and_die);
  if (!&basic_chmod($DestDir, 0755)) {
    print "$0:  error making $DestDir writable\n";
    &clean_and_die;
    }
  $SourcesDir = "$DestRootDir/sources";
  if ($RUNNINGARCH eq "x86.os2" || $RUNNINGARCH eq "x86.Windows_NT") {
    $SourcesDir =~ s%\\%/%g;    # don't allow backslashes for OS/2
    }
  &make_sources("$SourcesDir") if ($shouldCopySources);
  if (!&basic_chmod($DestRootDir, $mode)) {
    print "$0:  error making $DestRootDir readonly\n";
    &clean_and_die;
    }
  }

&clean_and_die if $found_error;
print "$0:  Successful completion\n";

# --------------------------------------------------------------------
# Usage and general support 


# Usage messages
sub copyUsage {
  print "Usage: $0 copy <manifest> <arch> <DestDir> <packingList> <sources?> {definitions}\n";
  &error_exit;
  }
sub generalUsage {
  print "Usage: $0 (\"copy\" | \"link\" | \"update\")\n";
  print "    <manifest> <arch> <destdir> <packingList> <sources?> ...\n";
  &error_exit;
  }

# --------------------------------------------------------------------
# Parsing and input routines


# Read a line of input.  Returns the line and its line number.
sub get_line {
  local ($result);

  if ($get_line_eof) {
    return "eof";		# if called repeatedly at eof, return eof.
    }
  for (;;) {
    $result = <MANIFEST>;
    last if defined($result);

    # eof processing
    if (!close(MANIFEST)) {
      print "$0: error closing $stacked_input_files[0].\n";
      print "  error = $!\n";
      &clean_and_die;
      }
    shift(@stacked_input_files);
    shift(@stacked_input_positions);
    shift(@stacked_input_lineNums);
    if ($#stacked_input_files == $[ - 1) {
      $get_line_eof = 1;
      return "eof";
      }

    # pop the input stack
    if (!open(MANIFEST, "<" . $stacked_input_files[0])) {
      print "$0: unable to open manifest(2) $stacked_input_files[0].\n";
      print "error = $!\n";
      &clean_and_die;
      }
    binmode MANIFEST;
    if (!seek(MANIFEST, $stacked_input_positions[0], 0)) {
      print "$0: unable to open to seek within $stacked_input_files[0].\n";
      print "error = $!\n";
      &clean_and_die;
      }
    next; # restart line processing
    }
  chop($result);
  if (length($result) > 0) {
      if (ord(substr($result, length($result) - 1, 1)) eq 13) {
	  # reading a DOS-style file 
	  chop($result);
      }
  }
  $stacked_input_lineNums[0] ++;
  return $result;
  }

# --------------------------------------------------------------------
# Semantic Productions and support routines

sub padded_print {
  local ($text, $len) = @_;
  local ($i, $wordlen, $line);
  $line = "";

  return if ($text eq "");
  $line .= $text;
  $wordlen = length($text);
  if ($wordlen >= $len) {
    $line .= " ";
    return $line;
    }
  for ($i = $wordlen; $i < $len; $i ++) {
    $line .= " ";
    }
    return $line;
  }

# Add a line to a packing list.
# inputs: $op, $name, $comment
sub add_packing_list {
  local ($op, $name, $type, $comment) = @_;
  local ($i, $wordlen, $line);
  $line = "";

  $op = $op;  # reserved for future use?
  if ($PackingList eq "") {
    return;
    }

  if ($type eq "dir") {
    return;
    }

  # TODO: better formatting
  if ( $name ne "") {
    # print PACKINGLIST "$name\t$type\t";
    $line .= &padded_print($name, 40);
    $line .= &padded_print($type, 10);
    $line .= "\n";
    if (! $duplicate_line{"$line"} ) {
      print PACKINGLIST "$line";
      }
    $duplicate_line{"$line"} = 1;
    }
  if ($comment ne "") {
    print PACKINGLIST "!$comment\n";
    return;
    }
  }

# Given a parsed line, dispatch execution.  Will recurse
# on "if", for instance.
# inputs: $lineText
# outputs: a parsed line that was not executed.
sub do_line {
  local (@parsed) = @_;
  local ($type, $enlarged);

  $type = &eval_string($parsed[0]);
  if ($type eq "#") {
    return;			# comment, no processing necessary
    }
  if ($type eq "!") {
    &add_packing_list('!', '', '', $parsed[1]); # put text into packing list.
    return;
    }
  if ($type eq "help") {
    $HelpText = $HelpText . &eval_string($parsed[2]) . "\n";
    return;
    }
  if ($type eq "say") {
    print &eval_string($parsed[2]) . "\n";
    return;
    }
  if ($type eq "die") {
    print &eval_string($parsed[2]) . "\n";
    &tell_position;
    # print "$0:  dieing at manifest request...\n";
    # &clean_and_die;
    print "$0:  ERROR signalled by manifest.\n";
    $found_error = 1;
    return;
    }
  if ($type eq "include") {
    $stacked_input_positions[0] = tell MANIFEST;
    if (!close(MANIFEST)) {
      &tell_position;
      print "$0:  error closing $stacked_input_files[0].\n";
      print "  error = $!\n";
      &clean_and_die;
      }

    # do the push
    $enlarged = &eval_string($parsed[2]);
    if (!open(MANIFEST, "<" . $enlarged)) {
      &tell_position;
      print "$0:  unable to open manifest(3) '$enlarged'.\n";
      print "error = $!\n";
      &clean_and_die;
      }
    binmode MANIFEST;
    unshift(@stacked_input_files, $enlarged);
    unshift(@stacked_input_positions, tell MANIFEST);
    unshift(@stacked_input_lineNums, 0);
    return;
    }
  if ($type eq "packing") {
    $enlarged = &eval_string($parsed[2]);
    if ($ArchType eq "dos") {
      # Replace forward slashes with backslashes
      $enlarged =~ s#/#\\#g;
      }
    if ($ArchType eq "mac") {
      # Replace forward slashes with colon
      $enlarged =~ s#/#:#g;
      }
    &add_packing_list("packing", $enlarged, "text", "");
    return;
    }
  if ($type eq "dummy") {
    # create zero-length file
    $enlarged = &eval_string($parsed[2]);
    if ($ArchType eq "dos") {
      # Replace forward slashes with backslashes
      $enlarged =~ s#/#\\#g;
      }
    if ($ArchType eq "mac") {
      # Replace forward slashes with colon
      $enlarged =~ s#/#:#g;
      }
    &add_packing_list("dummy", $enlarged, $parsed[3], "");
    $enlarged = &delimited_dir($DestDir, $RUNNINGARCH) . $enlarged;
    if ($doingReinstall && -e $enlarged) {
	# don't wipe out an existing file
	return;
    }
    if ($doingUpdate && -e $enlarged) {
    # zero bytes, already exists, must be up to date.
    return;
    }
    if (!open(DESTFILE, ">" . $enlarged)) {
      &tell_position;
      print "$0:  unable to open destfile $enlarged.\n";
      print "error = $!\n";
      # &clean_and_die;
      $found_error = 1;
      return;
      }
    close(DESTFILE);
    return;
    }
  if ($type eq "define") {
    $enlarged = "\$" . $parsed[2] . "=" . $parsed[3];
    eval $enlarged;
    if ($@ ne '') {
      &tell_position;
      print "$0:  eval of \"$enlarged\" failed: $@\n";
      # &clean_and_die;
      $found_error = 1;
      }
    # print "    $enlarged\n";	# debug
    return;
    }
  if ($type eq "exec") {
    $enlarged = &eval_string($parsed[2]);
    if (system($enlarged) != 0) {
      &tell_position;
      print "$0:  evaluation of \"$enlarged\" failed\n";
      print "  error: $!\n";
      &clean_and_die;
      $found_error = 1;
      }
    return;
    }
  if ($type eq "require") {
    &do_require(@parsed);
    return;
    }
  if ($type eq "copy" || $type eq "hide" || $type eq "data" || $type eq "copyifpresent" || $type eq "hideifpresent" ) {
    &do_copy(@parsed);
    return;
    }
  if ($type eq "slink") {
    &do_slink(@parsed);
    return;
    }
  if ($type eq "chmod") {
    &do_chmod(@parsed);
    return;
    }
  if ($type eq "mkdir") {
    &do_mkdir(@parsed);
    return;
    }
  if ($type eq "if") {
    &do_if(@parsed);  # can recurse
    return;
    }
  if ($type eq "else" || $type eq "elsif" || $type eq "endif") {
    &tell_position;
    print "$0:  $type with no matching if\n";
    # &clean_and_die;
    $found_error = 1;
    return;
    }
  # endif, else should not be seen here!
  print "internal error in do_line, type is \"$type\"\n";
  &clean_and_die;
  }

# Set the protection of a copied file based on its type
sub set_protection {
  local($name, $fileType) = @_;
  local($mode);

  return if ($ArchType ne "unix");
  $mode = $AllModes{$fileType};
  if (! $mode) {
    &tell_position;
    print "set_protection: Unknown fileType $fileType for file $name\n";
    # &clean_and_die;
    $found_error = 1;
    return;
    }
  elsif (!&basic_chmod($name, oct($mode))) {
    &tell_position;
    print "set_protection:  chmod error\n";
    # &clean_and_die;
    $found_error = 1;
    return;
    }
  }

# do_chmod:  destName filetype protection
sub do_chmod {
  local (@parsed) = @_;
  local ($type, $comment, $destName, $fileType, $protection) = @parsed;
  local ($expandedDest, $fullDest);

  $expandedDest = &eval_string($destName);
  $fullDest = &delimited_dir($DestDir, $RUNNINGARCH)
	. &base_name($expandedDest, $fileType, $ARCH);
  if ($RUNNINGARCH eq "x86.os2" || $RUNNINGARCH eq "x86.Windows_NT") {
    # Replace backslashes with forward slashes
    $fullDest =~ s#\\#/#g;
    }
  if (!&basic_chmod($fullDest, oct($protection))) {
    &tell_position;
    print "$0:  error in chmod\n";
    # &clean_and_die;
    $found_error = 1;
    return;
    }
  }

# Implement the "require" command
sub do_require {
  local (@parsed) = @_;
  local ($type, $list) = @parsed;
  local (@fields, $ok, $this, $expanded);

  $list = $list;	# noise?
  @fields = split(/\s+/, $parsed[2]);
  $ok = 1;
  foreach $this (@fields) {
    $expanded = &eval_string( "\$" . $this);
    if ($expanded eq '') {
      &tell_position;
      print "$0:  require:  no definition for $this\n";
      $ok = 0;
      }
    if ($ok && !&mustBeOldDir($expanded, "expansion of \$$this")) {
      &tell_position;
      print "$0:  require:  directory check failed for $this\n";
      $ok = 0;
      }
    if (!$ok) {
      print $HelpText;
      print "\n";
      # &clean_and_die;
      $found_error = 1;
      return;
      }
    $SourceList{$this} = $expanded;
    }
  }


# Support for text_copy
# get_char:  fetch a single character, or a multi-character error message
sub get_char {
  local ($readCount, $buffer);

  $readCount = read(SRCFILE, $buffer, 1); # Single-character read
  return "read failure = $!" if (!defined($readCount));
  return "unexpected eof" if ($readCount == 0);
  return $buffer;
  }

# put_line:  write a line.  Returns 0 on success.
sub put_line {
  local ($theLine) = @_;

  if (printf(DESTFILE "%s", $theLine) == 0) {
    return "printf error = $!";
    }
  return 0;
  }

# put_eol:  write a line and and eol.  Returns 0 on success.
sub put_eol {
  local ($line, $archType) = @_;
  local ($ok);

  if ($archType eq "unix") {
    $line = $line . pack("C", 10);
    }
  elsif ($archType eq "dos") {
    $line = $line . pack("C", 13);
    $line = $line . pack("C", 10);
    }
  elsif ($archType eq "mac") {
    $line = $line . pack("C", 13);
    }
  else {
    die "put_eol:  unknown archtype $archType";
    }

  return &put_line($line);
  }

# text_copy:  does unix2dos noise
# Returns 1 on success

$warned_slow_conversion = 0;

sub text_copy {
  local($srcName, $destName, $archType) = @_;
  local ($has_textcvt) = 0;
  local ($numRead, $totalCount, $thisChar, $failure);
  local ($readCount, $line);

  $has_textcvt = 1 if ($RUNNINGARCH eq "sparc.Solaris");
  $has_textcvt = 1 if ($RUNNINGARCH eq "sparc.SunOS4");
  $has_textcvt = 1 if ($RUNNINGARCH eq "hppa.hpux");
  $has_textcvt = 1 if ($RUNNINGARCH eq "hppa.hpux_8");
  $has_textcvt = 1 if ($RUNNINGARCH eq "hppa.hpux_9");
  $has_textcvt = 1 if ($RUNNINGARCH eq "Symmetry.Dynix");
  $has_textcvt = 1 if ($RUNNINGARCH eq "i386.NCR");
  $has_textcvt = 1 if ($RUNNINGARCH eq "MIPSEB.sinix");
  $has_textcvt = 1 if ($RUNNINGARCH eq "RISC6000.AIX");
  $has_textcvt = 1 if ($RUNNINGARCH eq "x86.os2");

  # textcvt does not handle mac text conversions, do it the hard way.
  $has_textcvt = 0 if ("$archType" eq "mac");

  if ($has_textcvt) {
    return (0 == system("textcvt $archType $srcName $destName"));
    }

  # do it the hard way
  if (!$warned_slow_conversion) {
    $warned_slow_conversion = 1;
    print "WARNING:  no fast text conversion for this system\n";
    }

  # Open the files.
  if (!open(SRCFILE, "<" . $srcName)) {
    print "$0: unable to open srcfile $srcName.\n";
    print "error = $!\n";
    return 0;
    }
  if (!open(DESTFILE, ">" . $destName)) {
    print "$0: unable to open destfile(2) $destName.\n";
    print "error = $!\n";
    return 0;
    }

  binmode SRCFILE;
  binmode DESTFILE;
  
  # The actual copy.
  $totalCount = -s $srcName;
  $numRead = 0;
  $line = "";
  for (;;) { # for all input characters
    last if ($numRead == $totalCount);
    $thisChar = &get_char;
    if (length($thisChar) != 1) {
      print "$0: read error on $srcName.\n";
      print "  near position $numRead, error = $thisChar\n";
      close(SRCFILE);
      close(DESTFILE);
      return 0;
      }
    $numRead ++;
    if (ord($thisChar) != 13 && ord($thisChar) != 10) {
      $line = $line . $thisChar;
      next;
      }

    # OK, we've read some sort of lineend
    if (ord($thisChar) == 13) { # ^M found
      if ($numRead == $totalCount) { # ^M at eof???
	$failure = &put_eol($line, $archType);
	if ($failure != 0) {
	  print "$0: write error on $destName.\n";
	  print "  near position $numRead, error = $failure\n";
	  close(SRCFILE);
	  close(DESTFILE);
	  return 0;
	  }
        last;
        } # ^M at eof???

      # Look at next character.
      $thisChar = &get_char;
      if (length($thisChar) != 1) {
	print "$0: read error on $srcName.\n";
	print "  near position $numRead, error = $thisChar\n";
	close(SRCFILE);
	close(DESTFILE);
	return 0;
	}
      $numRead ++;

      if (ord($thisChar) == 10) { # ^M followed by ^J
	$failure = &put_eol($line, $archType);
	if ($failure != 0) {
	  print "$0: write error on $destName.\n";
	  print "  near position $numRead, error = $failure\n";
	  close(SRCFILE);
	  close(DESTFILE);
	  return 0;
	  }
	$line = "";
	next;
	} # ^M followed by ^J

      # Illicit control-character in input file
      print "$0: dangling control-M in $srcName.\n";
      print "  near position $numRead\n";
      # so make an eol :-(
      $failure = &put_eol($line, $archType);
      if ($failure != 0) {
	print "$0: write error on $destName.\n";
	print "  near position $numRead, error = $failure\n";
	close(SRCFILE);
	close(DESTFILE);
	return 0;
	}
      # and keep the strange character after it
      $line = $thisChar;
      } # ^M found
    else { # ^J found
      $failure = &put_eol($line, $archType);
      if ($failure != 0) {
	print "$0: write error on $destName.\n";
	print "  near position $numRead, error = $failure\n";
	close(SRCFILE);
	close(DESTFILE);
	return 0;
	}
      $line = "";
      } # ^J found
    } # for all input characters

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
    local ($dev, $ino, $mode, $nlink);

    (($dev,$ino,$mode,$nlink) = stat($srcName))
	  || (print "$0:  Can't stat $srcName: $!\n", return 0);
    if (!&basic_chmod($destName, $mode)) {
      print "$0:  error chmod'ing $destName\n";
      return 0;
      }
  }
  return 1;
  }



# Cover for basic_copy and text_copy, decides whether to do eol conversions
# returns 1 on success
sub actual_copy {
  local ($src, $dest, $fileType) = @_;

  # Do a literal byte to byte copy if doing a 'copy'
  # or if the file is not 'text' or a 'script'.
  local($literalCopy) = ($fileType ne "text" && $fileType ne "script");

  local($updatingFile) = 0;

  if ($doingReinstall) {
      if (-f $src && -f $dest) {
	  if (-M $src >= -M $dest) {
	      return 1;
	  }
      }
      $updatingFile = 1;
      if ($RUNNINGARCH eq "x86.Windows_NT" && $ArchType eq "dos") {
	  # the 'u2d' command used below prints a message.
      } else {
	  print "updating $dest\n";
      }
  }
  if ($doingUpdate) {
    if (-f $src && -f $dest) {
      if (-M $src >= -M $dest) {
        return 1;
      } else {
	$updatingFile = 1;
        print "updating $dest\n";
        unlink( $dest );
      }
    }
  }

  if ($RUNNINGARCH eq "x86.Windows_NT" && $ArchType eq "dos") {
      # We use u2d on NT because it is faster and because it does a better
      # job of updating out of date existing files.

      # Note that u2d checks the dates of the files and decides
      # if a update is needed.
      # It is a supported tool whose source code is checked in to
      # tools/u2d/, but it only compiles on Windows NT.

      # If you want you can comment out this section but I've had trouble
      # with the basic_copy and text_copy on NT. The text_copy in particular
      # was very slow
      local($u2dOptions) = "";
      
      if ($literalCopy) {
	  # The -b switch puts u2d in binary mode. Without it the copy
	  # will be done in a mode that converts Unix text to DOS text.
	  $u2dOptions .= " -b";
      }
      if ($doingReinstall) {
	  # The -u option causes u2d to only do the copy if the src is
	  # newer than the destination. It also will print out any copy
	  # it does.
	  $u2dOptions .= " -u";
      }
      if ($is_cygwin) {
	$src = `cygpath -w "$src"`;
	chomp($src);
	$src = "\'$src\'";
	$dest = `cygpath -w "$dest"`;
	chomp($dest);
	$dest = "\'$dest\'";
      }
      $u2d = "${DIRSEP}${DIRSEP}n080-fil01${DIRSEP}localnew${DIRSEP}$RUNNINGARCH${DIRSEP}u2d.exe";
      return (0 == system("$u2d $u2dOptions $src $dest"));
  } else {
      if (!$updatingFile && ! -f $dest) {
        print "creating $dest\n";
      }
      if ($literalCopy) {
	  return &basic_copy($src, $dest, $ArchType, $doingReinstall);
      } else {
	  # Last ditch, check the lineends!
	  return &text_copy($src, $dest, $ArchType);
      }
  }
}

#  slink:  destName srcName filetyep
# Creates a softlink named 'destName'. The link is to 'srcName'.
# 
sub do_slink {
    local (@parsed) = @_;
    local ($type, $destName, $srcName, $fileType, $comment);
    local ($fullDest, $expandedDest, $expandedSrc);

    ($type, $comment, $destName, $srcName, $fileType) = @parsed;

    $expandedDest = &eval_string($destName);
    $expandedDest = &base_name($expandedDest, $fileType, $ARCH);
    $fullDest = &delimited_dir($DestDir, $RUNNINGARCH) . $expandedDest;

    $expandedSrc = &eval_string($srcName);

    if (! $symlink_exists) {
	&tell_position;
	print "$0: symbolic links do not exist on this platform\n";
	# &clean_and_die;
	$found_error = 1;
	return;
    }
    if ($doingUpdate) {
      # should read link and check that it matches expandedSrc.
      if (-e "$fullDest") {
        return;
	  }
    }
    if (!symlink($expandedSrc, $fullDest)) {
	&tell_position;
	print "$0: symlink failed:\n";
	print "  link of $expandedSrc to $fullDest\n";
	print "  error = $!\n";
        # &clean_and_die;
	$found_error = 1;
	return;
    }
    if ($type ne "hide") {
	&add_packing_list("slink", $expandedDest, $fileType, $comment);
    }
}

#  copy:  destName srcName fileType
# also: "data" and "hide" commands.
sub do_copy {
  local (@parsed) = @_;
  local ($type, $destName, $srcName, $fileType, $comment);
  local ($fullDest, $fullSrc, $expandedDest, $expandedSrc);
  local ($fullDest_pdb, $fullSrc_pdb);

  ($type, $comment, $destName, $srcName, $fileType) = @parsed;

  $expandedDest = &eval_string($destName);
  $expandedDest = &base_name($expandedDest, $fileType, $ARCH);
  $fullDest = &delimited_dir($DestDir, $RUNNINGARCH) . $expandedDest;

  # Expand the source name.
  # expand environment variables
  $expandedSrc = &eval_string($srcName);
  # and then attach an extension
  $expandedSrc = &base_name($expandedSrc, $fileType, $ARCH);
  $fullSrc = $expandedSrc;

  if (! -f $fullSrc) {
    &tell_position;
    if ($type eq "copyifpresent" || $type eq "hideifpresent" ) {
      print("$0: WARNING: file $fullSrc does not exist.\n");
      } 
    else {
      print("$0: file $fullSrc does not exist.\n");
      # &clean_and_die;
      $found_error = 1;
      }
    return;
    }

  if ($type eq "hide" || $type eq "hideifpresent") {
    # copy the file to HiddenDir
    # Add the extension and directory.
    $fullDest = &delimited_dir($HiddenDir, $RUNNINGARCH) . $expandedDest;
    # pdb , if any, goes in same directory
    $pdbDest = $fullDest;
    }
  else {
    # Add the extension and directory.
    $fullDest = &delimited_dir($DestDir, $RUNNINGARCH) . $expandedDest;
    # construct a hidden destination for the .pdb , case we neede it
    # pdb, if any, goes in same directory on slow, hidden directory on fast.
    if ( $kind eq "" ) { $kind = " "; }  # dummy line in case kind not defined.
    if ($kind eq "slow") {    # kind may not be defined here
      $pdbDest = $fullDest;  
      }
    else {
      $pdbDest = &delimited_dir($HiddenDir, $RUNNINGARCH) . $expandedDest;
      }
    }

  if ($RUNNINGARCH eq "x86.Windows_NT") {
    # Replace backslashes with forward slashes
    $fullDest =~ s#\\#/#g;
    $fullSrc =~ s#\\#/#g;
    $pdbDest =~ s#\\#/#g;
    # for .exe and .dll , put the .pdb file in the same place as the .exe or .dll in a slow
    if ($fileType eq "exe") {
      $fullDest_pdb = $pdbDest;
      $fullDest_pdb =~ s#\.exe$#.pdb#;

      $fullSrc_pdb = $fullSrc ;
      $fullSrc_pdb =~ s#\.exe$#.pdb#;
      }
    if ($fileType eq "dll") {
      $fullDest_pdb = $pdbDest;
      $fullDest_pdb =~ s#\.dll$#.pdb#;

      $fullSrc_pdb = $fullSrc ;
      $fullSrc_pdb =~ s#\.dll$#.pdb#;
      }
    }

  if ($CopyMode eq "copy") {
    if (!&actual_copy($fullSrc, $fullDest, $fileType)) {
      &tell_position;
      print "$0:  copy failed\n";
      # &clean_and_die;
      $found_error = 1;
      return;
      }
    &set_protection($fullDest, $fileType);
    if (defined($fullDest_pdb)) {
      if (! -f $fullSrc_pdb) {
#        &tell_position;
#        print("$0: WARNING: file $fullSrc_pdb does not exist.\n");
        }
      else {
        if (!&actual_copy($fullSrc_pdb, $fullDest_pdb, $fileType)) {
          &tell_position;
          print "$0:  copy failed\n";
          # &clean_and_die;
          $found_error = 1;
          return;
          }
        &set_protection($fullDest_pdb, $fileType);
        }
      }
    }
  elsif ($CopyMode eq "link") {
    if ($type eq "data") {
      if (!&actual_copy($fullSrc, $fullDest, $fileType)) {
	&tell_position;
        print "$0:  copy failed\n";
        # &clean_and_die;
	$found_error = 1;
	return;
        }
      &set_protection($fullDest, $fileType);
      }
    else {
      if (substr($fullSrc, 0, 1) ne "/") {
	$fullSrc = $ORIGDIR . "/" . $fullSrc;
 	}
      if (! -f $fullSrc) {
	&tell_position;
	print "$0: WARNING:  symlink target\n";
        print "    $fullSrc does not exist.\n";
	}
      if (!symlink($fullSrc, $fullDest)) {
	&tell_position;
	print "$0: symlink failed:\n";
	print "  link of $fullSrc to $fullDest\n";
	print "  error = $!\n";
        # &clean_and_die;
	$found_error = 1;
	return;
	}
      }
    }
  else {
    die "illegal CopyMode in do_copy";
    }

  if ($type ne "hide") {
    if ($ArchExtensions{$ARCH} eq "dos") {
      # Replace forward slashes with backslashes
      $fullDest =~ s#/#\\#g;
      }
    if ($ArchExtensions{$ARCH} eq "mac") {
      # Replace forward slashes with colon
      $fullDest =~ s#/#:#g;
      }
    &add_packing_list("copy", $expandedDest, $fileType, $comment);
    }
  }

# Execute the mkdir.
sub do_mkdir {
  local (@parsed) = @_;
  local ($fullName);

  $fullName = &delimited_dir($DestDir, $RUNNINGARCH) . $parsed[1];
  $fullName = &eval_string($fullName);
  if ($HiddenDir ne "") {
    $hiddenFullName = &delimited_dir($HiddenDir, $RUNNINGARCH) . $parsed[1];
    $hiddenFullName = &eval_string($hiddenFullName);
  } else {
    $hiddenFullName = "junk";
  }

  if (($doingReinstall || $RequestedCopyMode eq "link")) {
    if (-d $fullName && ($HiddenDir eq "" || -d $hiddenFullName) ) {
       return; # Permit re-install
    }
  }
  if ($doingUpdate) {
    if (-d $fullName) {
      chmod( 0755, $fullName);
    }
    if ($HiddenDir ne "" && -d $hiddenFullName) {
      chmod( 0755, $fullName);
    }
    if (-d $fullName && ($HiddenDir eq "" || -d $hiddenFullName) ) {
      return;
    }
  }
  if (! -d $fullName) {
    if (! &basic_mkdir($fullName, 0755)) {
      &tell_position;
      print "$0: unable to mkdir $fullName.\n";
      # &clean_and_die;
      $found_error = 1;
      return;
    }
  }
  if ($HiddenDir ne "") {
    if (! -d $hiddenFullName) {
      if (! &basic_mkdir($hiddenFullName, 0755)) {
	  &tell_position;
	  print "$0: unable to mkdir hidden $hiddenFullName.\n";
	  # &clean_and_die;
	  $found_error = 1;
	  return;
      }
    }
  }

  # &add_packing_list("mkdir", $parsed[1], "dir", $parsed[2]);
  }

sub do_if {
  local (@parsed) = @_;
  local ($bool, $did_a_block, $block_is_live, $found_else);
  local ($newLine);
  local ($nested_ifs) = 0;
  local ($startLineNum, $startFile);

  $did_a_block = 0;
  $block_is_live = 0;
  $found_else = 0;
  $startLineNum = $stacked_input_lineNums[0];
  $startFile = $stacked_input_files[0];
  NEW_CONDITIONAL: for (;;) { # process conditional, possibly cascaded
    shift(@parsed);	# don't need the type any more

    # Evaluate the expression, using Lisp-like trick
    $bool = eval($parsed[0]);
    if ($@ ne "") {
      &tell_position;
      print("$0: if statement failed.\n");
      print("  expression: $parsed[0]\n");
      print("  error text: $@\n");
      # &clean_and_die;
      $found_error = 1;
      return;
      }
    if ($did_a_block) {
      $block_is_live = 0;
      }
    elsif ($bool) {
      $did_a_block = 1;
      $block_is_live = 1;
      }
    else {
      $block_is_live = 0;
      }

    # Read lines until endif, else, or elsif.  Execute if appropriate
    ANOTHER_LINE: for (;;) {
      $newLine = &get_line;
      if ($newLine eq "eof") {
	print ("from near line $startLineNum in $startFile\n");
	print ("if-statement has no matching endif\n");
	# &clean_and_die;
	$found_error = 1;
	return;
	}
      @parsed = &parse_packing_line($newLine);
      $type = $parsed[0];

      if (!$block_is_live) { # deal with nested dead blocks
	if ($type eq "if") {
	  # keep a nest count, keep reading lines
	  $nested_ifs ++;
	  next ANOTHER_LINE;
	  }
	elsif ($type eq "endif") {
	  # if this is a nested block, just keep count and keep reading
	  if ($nested_ifs > 0) {
	    $nested_ifs --;
	    next ANOTHER_LINE;
	    }
	  }
	elsif ($type eq "elsif" || $type eq "else") {
	  # if this is a nested block, just keep reading
	  if ($nested_ifs > 0) {
	    next ANOTHER_LINE;
	    }
	  # otherwise, we need to process it.
	  }
        else {
	  next ANOTHER_LINE;
	  }
	} # dealing with nested dead blocks

      # OK, block is live.

      if ($type eq "endif") {
	return;
	}
      elsif ($type eq "elsif") {
	next NEW_CONDITIONAL;
	}
      elsif ($type eq "else") { # handle "else"
	if ($found_else) {
	  &tell_position;
	  print "$0: too many elses\n";
	  print "(matching if near line $startLineNum in $startFile)\n";
	  # &clean_and_die;
	  $found_error = 1;
	  return;
	  }
	$found_else = 1;
	if ($did_a_block) {
	  $block_is_live = 0;
	  }
	else {
	  $did_a_block = 1;
	  $block_is_live = 1;
	  }
	next ANOTHER_LINE;
	} # handle "else"

      # Survived all of above, we need to evaluate the line
      &do_line(@parsed);
      }
    } # process conditional, possibly cascaded
  }

# --------------------------------------------------------------------
# Trap handling, cleanup

sub error_exit {
  print "$0:  error exit\n";
  exit 1;
  }

sub clean_and_die {
  if ($doingReinstall) {
    print "Failed but no cleanup done since doing a reinstall.\n";
    &error_exit;
  }

  &error_exit;
  print "Removing the failed product!...\n";
  chdir($ORIGDIR);
  &remove_dir($DestDir);

  if ( $PackingList ne "") {
    if (close(PACKINGLIST)) {
      unlink($PackingList);
      }
    }
  if ($HiddenDir ne "") {
    &remove_dir($HiddenDir);
    }
  if (-d $SourcesDir) {
    &remove_dir($SourcesDir);
    }
  &error_exit;
  }

sub signalHandler {
  print "Trapped your signal!\n";
  $SIG{'HUP'} = 'IGNORE';
  $SIG{'INT'} = 'signalHandler';
  $SIG{'QUIT'} = 'signalHandler';
  $SIG{'TERM'} = 'signalHandler';
  &clean_and_die;
  }

# --------------------------------------------------------------------
# source product management

# Build the SOURCE directory tree based on the SourceList
sub make_sources {
  local($newDir) = @_;
#  local($dirCount) = 1;
  local($destName);

  print "Writing source tree $newDir...\n";
  chmod( 0755, $DestRootDir );
  if (! &basic_mkdir($newDir, 0755)) {
    print "$0: unable to mkdir source directory $newDir.\n";
    &clean_and_die;
    }
  foreach $this (keys(%SourceList)) {
#    $destName = &delimited_dir($newDir, $RUNNINGARCH) . "dir" . $dirCount;
    $destName = &delimited_dir($newDir, $RUNNINGARCH) . $this;
    print "   Copying files from $SourceList{$this} to $this...\n";
    if (!&copy_tree($destName, $SourceList{$this}, $RUNNINGARCH)) {
      print "copy_tree failed!\n";
      &clean_and_die;
      }
#    $dirCount ++;
    }
  }

sub make_perl_dash_w_silent {
  %AllModes = %AllModes;
  $Is_Called = $Is_Called;
  &make_perl_dash_w_silent;
  &signalHandler;
  }

# --------------------------------------------------------------------
# for inclusion

if ($Is_Called) {
  1;
  }
else {
  exit 0;
  }
