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

#require "getcwd.pl";
require "ctime.pl";

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
  # delete $ENV{"PATH"}; # for safety
  $PWDCMD = "cd";
  }
else {
  die "cannot determine architecture";
  }

#verStr may be overridden on command line but use this for default
$verStr = "20";

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

# General utilities
require "$SCRIPTDIR/../ship/partnummapping.pl";
require "$SCRIPTDIR/misc.pl";

# Get the location of shipping directories
require "$SCRIPTDIR/../ship/define-ship.pl";

print "$0\n";

$ext = "";
$comndSep = ";";
if ($ARCH eq "x86.Windows_NT") {
  $comndSep = "&";
  $ext = ".exe";
  }
$zip = "$shipBinDir/$ARCH/zip$ext";
if ( ! -f $zip) {
  print "$SCRIPTNAME error:  File $zip does not exist\n";
  exit 1;
  }
# zip arg of file types not to compress when including in a zip file
$noCompresSuf = "-n .Z:.z:.zip:.gif:.jpg:.jpeg:.gz";
$zip .= " $noCompresSuf";
$unzip = "$shipBinDir/$ARCH/unzip$ext";
if ( ! -f $unzip) {
  print "$SCRIPTNAME error:  File $unzip does not exist\n";
  exit 1;
  }

# Make stderr and stdout unbuffered.
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

if ( $ARGV[0] eq "help" || $ARGV[0] eq "" || $ARGV[0] eq "-h") {
  &usage;
  }

# # Get the manifest
# $TheManifest = $ARGV[0];
# if ( ! -f $TheManifest) {
#   print "$SCRIPTNAME error:  File $TheManifest does not exist\n";
#   exit 1;
#   }
# shift;

# The product number?
$ProductNumber = $ARGV[0];
if ( $ProductNumber eq "") {
  print "$SCRIPTNAME error: Product number must not be empty!\n";
  exit 1;
  }
shift;

# Originating directory:
$SourceDir = $ARGV[0];
if ( ! -d $SourceDir) {
  print "$SCRIPTNAME error:  Source directory $SourceDir does not exist.\n";
  exit 1;
  }
shift;

# Fully expand SourceDir
if (!chdir($SourceDir)) {
  print "$SCRIPTNAME:  unable to cd to $SourceDir; errno = $!\n";
  exit 1;
  }
$SourceDir=&getcwd;
if (!chdir($ORIGDIR)) {
  print "$SCRIPTNAME:  unable to cd (back) to $ORIGDIR; errno = $!\n";
  exit 1;
  }

# Delete existing product?
$DeleteExisting = $ARGV[0];
if ($DeleteExisting eq "-d") {
  shift;
  }
else {
  # The arg is likely empty or a variable definition if is not -d flag.
  # Make sure we don't shift and lose the arg and make sure we do not
  # try to do the delete.
  $DeleteExisting = "";
  }

# Long file and dir names are OK?
if ($ARGV[0] eq "-l") {
  $CheckForLongNames = 0;
  print "WARNING!! USING THE \"-l\" FLAG MAY PREVENT PRODUCTS\n";
  print "    FROM GOING ONTO STANDARD ISO9660 CDROM!!!\n";
  shift;
  }
else {
  # The arg is likely empty or a variable definition if is not -l flag.
  # Make sure we don't shift and lose the arg and make sure we do
  # the long file and dir name checking.
  $CheckForLongNames = 1;
  }

# Save the definitions on the command line
@DEFINITIONS = @ARGV;
# Load up the definitions on the command line
while ( defined $ARGV[0]) {
  $this = $ARGV[0];
  shift;
  if (! ($this =~ /^\S+=\S+$/ )) {
    print "$SCRIPTNAME: illegal definition (must be of the form 'a=b') $this\n";
    exit(1);
    }
  $junk = $this;
  $junk =~ s/^(\S+)=(\S+)$/\$\1=\"\2\";/;

  if ($ARCH eq "x86.os2" || $ARCH eq "x86.Windows_NT") {
    $junk =~ s%\\%/%g;  # Don't allow backslash
    }

  eval $junk;
  if ($@ ne '') {
    print "$SCRIPTNAME:  eval of \"$junk\" failed: $@\n";
    exit(1);
    }
  print "    $this\n";  # debug
  }

# --------------------------------------------------------------
# Simple checks and expansions:

$targArch="";
$prodFamily="";
$dummy2="";
$dummy3="";
$dummy4="";
$dummy5="";
$patchNum="";

if (&parse_part_num($ProductNumber,*prodFamily,*targArch,*dummy2,
                                     *dummy3,*dummy4,*patchNum)) {
  # partnumber is badly formed, error string already printed
  exit(1);
  }

if ( ! -w "$SourceDir") {
  print "$SCRIPTNAME\[Error\]:  Can not write in dir $SourceDir\n";
  print "  Must be able to write in dir to rename subdirs\n";
  exit 1;
  }

if (($prodFamily >= 1) && ($prodFamily <= 100)) {
  # There is a source product for this product
  if ( ! -d "$SourceDir/sources") {
    print "$SCRIPTNAME\[Error\]:  No such directory, $SourceDir/sources\n";
    exit 1;
    }
  }

if (&translateNumToDirStr($targArch,*archStrMapping,$archStrMapWidth,$tarMedia,
                                                                    *archStr)) {
  print "$SCRIPTNAME error: don't know how to pick archStr for\n";
  print "    target arch: \"$targArch\"\n";
  print "    product number: \"$productNumber\"\n";
  exit 1
  }

if (&translateNumToDirStr($targArch,*archStrMapping,$archStrMapWidth,
               $cdromMedia, *zipFileArchStr)) {
  print "$SCRIPTNAME error: don't know how to pick archStr for\n";
  print "    target arch: \"$targArch\"\n";
  print "    product number: \"$productNumber\"\n";
  exit 1
  }
$zipFileArchStr =~ tr/A-Z/a-z/;

# As of Facets 2.0 both platforms have installers
$ProdToShip = "$SourceDir/installer";

if ( ! -d "$ProdToShip") {
  print "$SCRIPTNAME\[Error\]:  No such directory, $ProdToShip\n";
  exit 1;
  }
# Check accessibility of files and dirs in prod tree.
print "Checking access permissions of $ProdToShip\n";
if (!&checkPermissions_tree("$ProdToShip")) {
  print "Error: file or dir in\n     $ProdToShip\n";
  print "   not accessable by this user. Exiting\n";
  exit 1;
  }
print "OK\n";
print "Checking access permissions of $SourceDir/sources\n";
# Check accessibility of files and dirs in sources tree.
if (-d "$SourceDir/sources") {
  if (!&checkPermissions_tree("$SourceDir/sources")) {
    print "Error: file or dir in\n     $SourceDir/sources\n";
    print "   not accessable by this user. Exiting\n";
    exit 1;
    }
  }
print "OK\n";

if (($prodFamily >= 1) && ($prodFamily <= 100)) {
  # There is a hidden product for this product
  if ( ! -d "$SourceDir/hidden") {
    print "$SCRIPTNAME\[Error\]:  No such directory, $SourceDir/hidden\n";
    exit 1;
    }
  }

# TODO:  use OS-specific directory delimiters
$createdDir="$partsDir/$ProductNumber"; 	# temporary image directory

$myArch = &getarch;

# Figure about the source product
$srcProdNum = $ProductNumber;
$srcProdNum =~ s/([^-]+)-.*/\1/;
if (($prodFamily <= 100) || (($prodFamily >= 500) && ($prodFamily < 600))) {
  $srcProdNum += 100;
  }
else {
  $srcProdNum += 50;
  }
$srcProduct = $ProductNumber;
$srcProduct =~ s/[^-]+(.*)/$srcProdNum\1/;
$srcProductRootDir = "$partsDir/$srcProduct";
$hiddenDir="$srcProductRootDir/hidden";
$specialDir="$srcProductRootDir/special";

if ((($prodFamily >= 1) && ($prodFamily <= 100)) ||
   (($prodFamily >= 400) && ($prodFamily <= 600) && (-d "$SourceDir/special"))){
  # There is a source product
  print "$SCRIPTNAME\[Info\]: source archive product number is: $srcProduct\n";
  if ( -d "$srcProductRootDir") {
    if ($DeleteExisting) {
      if ( -l "$srcProductRootDir") {
        print "$SCRIPTNAME\[Error\]: Can not remove previous source release!\n";
        print "   $srcProductRootDir is a link, probably to an\n";
        print "   overflow directory and must be removed by hand.\n";
        exit 1;
        }
      print "$SCRIPTNAME\[Info\]: removing previous source release...\n";
      &remove_dir("$srcProductRootDir");
      }
    else {
      print "$SCRIPTNAME\[Error\]: You must use the -d flag to remove";
      print " the previous release.\n";
      exit 1;
      }
    }
  if (!&main'basic_mkdir("$srcProductRootDir", 0755)) {
    exit 1;
    }
  }
$ArchiveName = &partnum_to_dirname($srcProduct);
$ArchiveDir = "$srcProductRootDir/$ArchiveName";
print "$SCRIPTNAME\[Info\]: source archive dir is: $ArchiveDir\n";

# --------------------------------------------------------------
# clean up
if ( -d "$createdDir") {
  print "$SCRIPTNAME\[Info\]: found directory $createdDir\n";
  if ($DeleteExisting) {
    if ( -l "$createdDir") {
      print "$SCRIPTNAME\[Error\]: Can not remove previous release!\n";
      print "   $createdDir is a link, probably to.\n";
      print "   an overflow directory and must be removed by hand.\n";
      exit 1;
      }
    print "$SCRIPTNAME\[Info\]: removing previous release...\n";
    &remove_dir($createdDir);
    }
  else {
    print "$SCRIPTNAME\[Error\]: You must use the -d flag to remove";
    print " the previous release.\n";
    exit 1;
    }
  }

if ( -d $hiddenDir ) {
  print "$SCRIPTNAME\[Info\]: found directory $hiddenDir\n";
  if ($DeleteExisting) {
    print "$SCRIPTNAME\[Info\]: removing previous release's hidden files..\n";
    &remove_dir($hiddenDir);
    }
  else {
    print "$SCRIPTNAME\[Error\]: You must use the -d flag to remove";
    print " the previous release.\n";
    exit 1;
    }
  }
if ( -d $specialDir ) {
  print "$SCRIPTNAME\[Info\]: found directory $specialDir\n";
  if ($DeleteExisting) {
    print "$SCRIPTNAME\[Info\]: removing previous release's special files.\n";
    &remove_dir($specialDir);
    }
  else {
    print "$SCRIPTNAME\[Error\]: You must use the -d flag to remove";
    print " the previous release.\n";
    exit 1;
    }
  }
if ( -d $ArchiveDir ) {
  print "$SCRIPTNAME\[Info\]: found directory $ArchiveDir\n";
  if ($DeleteExisting) {
    print "$SCRIPTNAME\[Info\]: removing previous release's source files..\n";
    &remove_dir($ArchiveDir);
    }
  else {
    print "$SCRIPTNAME\[Error\]: You must use the -d flag to remove";
    print " the previous release.\n";
    exit 1;
    }
  }


# --------------------------------------------------------------

if (! mkdir($createdDir,0755)) {
  print "$SCRIPTNAME:  unable to create directory $createdDir; errno = $!\n";
  exit 1;
  }

print "$SCRIPTNAME\[Info\]: ship dir is         : $createdDir\n";
print "$SCRIPTNAME\[Info\]: product dir  is     : $SourceDir\n";

$rootName = &partnum_to_dirname($ProductNumber);
$rootDir = $createdDir . "/" . $rootName;	#   target ship directory

# No longer using packing files; no longer using checksum
$packingName = "none";

# Figure out the target architecture

# We don't want to "system" this script, because memory and line length
# limitations in DOS would probably make it fail...
# @OLD_ARGV = @ARGV;
# @ARGV = ("release", $TheManifest, $TARGETARCH, $rootDir,
# 	 $packingName, $SourceDir, $hiddenDir, "verStr=$verStr", @DEFINITIONS);
# 
# $Is_Called = 1;
# require "$SCRIPTDIR/makeprod.pl";
# @ARGV = @OLD_ARGV;

if (($prodFamily eq "12") || ($prodFamily eq "14") || ($prodFamily eq "18")) {
  # It is GemStone, GemStoneJ, or GemStoneJVisiBroker
  $GEMSTONE = $ProdToShip;
} else {
  # use the GEMSTONE from the @DEFINITIONS list
}

$prodTreeStatus = 2;

# Do not make a zip file, just copy the files and then verify them
print "$SCRIPTNAME\[Info\]: Now copying installer ...\n";
if (!&basiccopy_tree($rootDir, "$ProdToShip")) {
  print "$SCRIPTNAME:  unable to copy installer files\n";
  &relcleanup;
}

# chmod the files and dirs so only ship can write them
if ($ArchExtensions{$myArch} eq "unix") {
  # don't write protect shipped product for "user" since some
  # standard tars can't untar it if you do.
  system("chmod -R go-w $createdDir");
  }
else {
  print "WARNING: did not chmod -R go-w directory\n";
  print "  $createdDir\n";
  }
# --------------------------------------------------------------
# Now for the source archive, hidden, and special files

if (($prodFamily >= 1) && ($prodFamily <= 100)) {
  print "$SCRIPTNAME\[Info\]: Now zipping source archive...\n";
  if (! mkdir($ArchiveDir,0755)) {
    print "$SCRIPTNAME:  unable to create directory $ArchiveDir; errno = $!\n";
    exit 1;
    }

  # Links are not supported on PCs.  Rename the dir instead.
  if (!rename("$SourceDir/sources","$SourceDir/$ArchiveName")) {
    print "Error: renaming dir\n     $SourceDir/sources\n";
    print "  to $SourceDir/$ArchiveName failed. Exiting\n";
    &relcleanup;
    }
  # Do the zip, do not preserve links, follow them instead
  $theTime = &ctime(time);
  print "Creating the sources zip.  This may take a while!  $theTime";
  if (!chdir($SourceDir)) {
    print "$SCRIPTNAME:  unable to cd to $SourceDir; errno = $!\n";
    exit 1;
    }
  $zipCmd  = "cd $SourceDir $comndSep ";
  # Don't use -y flag with sources
  $zipCmd .= "$zip -q -r $ArchiveDir/$zipFileArchStr.zip $ArchiveName";
  if ($ARCH eq "x86.Windows_NT") {
    # translate unix path separators "/" to "\"
    $zipCmd =~ tr/\//\\/;
    }
  $status = system("$zipCmd");
  # $status = $status >> 8;
  if (!chdir($ORIGDIR)) {
    print "$SCRIPTNAME:  unable to cd (back) to $ORIGDIR; errno = $!\n";
    exit 1;
    }
  if ($status != 0) {
    print "$SCRIPTNAME:  unable to zip product directories\n";
    # Fix the rename we did
    rename("$SourceDir/$ArchiveName","$SourceDir/sources");
    &relcleanup;
    }
  # Fix the rename we did
  rename("$SourceDir/$ArchiveName","$SourceDir/sources");

  # Check the zip file with unzip's internal test (-t option)
  $theTime = &ctime(time);
  print "Verifying the sources zip.  This may take a while!  $theTime";
  $zipCmd = "$unzip -q -t $ArchiveDir/$zipFileArchStr.zip";
  if ($ARCH eq "x86.Windows_NT") {
    # translate unix path separators "/" to "\"
    $zipCmd =~ tr/\//\\/;
    }
  $status = system("$zipCmd");
  # $status = $status >> 8;
  if ($status != 0) {
    print "$SCRIPTNAME:  verify error of $ArchiveDir/$zipFileArchStr.zip\n";
    &relcleanup;
    }

  print "$SCRIPTNAME\[Info\]: Now copying hidden files...\n";
  if (!&basiccopy_tree($hiddenDir, "$SourceDir/hidden")) {
    print "$SCRIPTNAME:  unable to copy hidden directories\n";
    &relcleanup;
    }
  if ($ArchExtensions{$myArch} eq "unix") {
    # we are running on unix and can use "diff"
    $diff_cmd = "diff -r $hiddenDir $SourceDir/hidden > /dev/null";
    print "$SCRIPTNAME\[Info\]: Now verifying hidden files with this command\n";
    print "    $diff_cmd\n";
    if (system("$diff_cmd")) {
      print "$SCRIPTNAME\[Error\]:  diff of hidden directories failed!\n";
      &relcleanup;
      } else {
      print "$SCRIPTNAME\[Info\]:  diff of hidden directories OK\n";
      }
    }
  }
if ( -d "$SourceDir/special") {
  print "$SCRIPTNAME\[Info\]: Now copying special files...\n";
  if (!&basiccopy_tree($specialDir, "$SourceDir/special")) {
    print "$SCRIPTNAME:  unable to copy special directories\n";
    &relcleanup;
    }
  if ($ArchExtensions{$myArch} eq "unix") {
    # we are running on unix and can use "diff"
    $diff_cmd = "diff -r $specialDir $SourceDir/special > /dev/null";
    print "$SCRIPTNAME\[Info\]: Now verifying special files with this command\n";
    print "    $diff_cmd\n";
    if (system("$diff_cmd")) {
      print "$SCRIPTNAME\[Error\]:  diff of special directories failed!\n";
      &relcleanup;
      }
    else {
      print "$SCRIPTNAME\[Info\]:  diff of special directories OK\n";
      }
    }
  }
if (-d "$srcProductRootDir") {
  # chmod the files and dirs so only ship can write them
  if ($ArchExtensions{$myArch} eq "unix") {
    # do fully protect the sources, special, and hidden dirs
    system("chmod -R go-w $srcProductRootDir");
    }
  else {
    print "WARNING: did not chmod -R go-w directory\n";
    print "  $srcProductRootDir\n";
    }
  }

if ($prodTreeStatus == 1) {
  print "$SCRIPTNAME\[WARNING\]:\n\n";
  print "WARNING WARNING WARNING:\n";
  print "Detected \"path too long for tar\" problem for the product, source,\n";
  print "special, or hidden directory for this product.\n";
  print "Check the output from $SCRIPTNAME for more info.\n";
  print "FIX THIS BEFORE PROCEEDING!\n";
  print "Sending mail to jimk noting the problem.\n";
  $MAILFILE = "$messyDir/errmail.txt";
  $ENV{"MAILFILE"} = $MAILFILE;
  if ( -f $MAILFILE) {
    unlink $MAILFILE || die "could not remove $MAILFILE: $!";
  }
  open(ERRMAILFILE, ">" . $MAILFILE) || die "$MAILFILE: $!";
  print ERRMAILFILE "Error doing release.pl for product number\n";
  print ERRMAILFILE " \"$ProductNumber\"\n";
  print ERRMAILFILE "path too long for some product.\n";
  print ERRMAILFILE "prodTreeStatus   is $prodTreeStatus\n";
  close ERRMAILFILE;
  $RSH = $rsh_commands{$ARCH};
  if ($RSH eq "") {
    print "$SCRIPTNAME\[Error\]:  don't know how to rsh on $ARCH\n";
    exit 1;
  }
  $junk = "$RSH servio /usr/ucb/mail -s \"'release.pl path length problem'\"" .
            " jimk <$MAILFILE";
  system $junk;
  exit 1;
  }
else {
  print "$SCRIPTNAME\[Info\]:  Successful completion\n";
  exit 0;
  }

sub usage {
  print "$SCRIPTNAME <product-number> <srcDir> [-d] [-l] [variable=value]
     product-number - shipping product number for resulting product
     srcDir  - the root of the product tree from which to copy. This directory
               must have directories named sources, product, hidden, and
               for PC products, installer.  May have directory named special
               which is used for special files like readme.txt that get
               put at the top level of the CDRom.
     -d - delete any previously released product with the given product-number.
             Without this flag, if a product already exists we will exit
             with an error.  If present this must after <srcDir> and
             before any variable=value items.
     -l - long file and dir names are allowed for the distribution files.
             Without this flag, all file and dir names are checked to see
             if they meet the DOS naming restrictions.  With this flag,
             no checking is done.  If present this must after <srcDir> and
             before any variable=value items.
             STANDARD CDROMS WILL TRUNCATE LONG NAMES.  Only Rockridge/Joliet
             cdroms preserve long file names.
     variable=value - set perl variable with name 'variable' to 'value'\n";
  print "
Create a shipping product <product-number> from files underneath <srcDir>
Example command:

   $0 1-7-5.1-0-0-0 gs\n";
  exit 1;
  }
 

sub relcleanup {
  if (!chdir($shipBase)) {
    die "cannot chdir to perl directory $shipBase: $!\n";
  }
  print "$SCRIPTNAME\[Error\]: Cleaning up the failed product release...\n";
  if ( -d "$createdDir") {
    print "  removing directory $createdDir\n";
    &remove_dir($createdDir);
  }
  if ( -d "$hiddenDir") {
    print "  removing directory $hiddenDir\n";
    &remove_dir($hiddenDir);
  }
  if ( -d "$specialDir") {
    print "  removing directory $specialDir\n";
    &remove_dir($specialDir);
  }
  if ( -d "$srcProductRootDir") {
    print "  removing directory $srcProductRootDir\n";
    &remove_dir($srcProductRootDir);
  }
  exit 1;
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

sub check_tree {
  local ($treeDir, $fromDir, $myArch, $targetArch, $prodFamily, $packingFile, $patchNum) = @_;
  local (@treeList, @packingList, $tnum, $pnum, $filePath, $isOK, $pathCheck);

  # Check a shippable product tree.
  # Return values:
  #        0   Some error happened during processing,
  #               system error, checksum failed, diff failed.
  #        1   Some file name is too long (path is printed).
  #        2   OK, paths are all good.

  if ((($ArchExtensions{$targetArch} eq "dos") ||
       ($ArchExtensions{$targetArch} eq "mac") ||
       (($prodFamily >= 400) && ($prodFamily <= 599)))
        && ($CheckForLongNames == 1)) {
    # When put on CDRom, PC products and JDKs just have their files and dirs
    # copied, not tarred or zipped into a single file.  The CDRom is limited
    # to DOS style names so check for problems now and bail out if
    # there is a problem.
    print "Checking product for DOS file and dir name compatability.\n";
    $pathCheck = &check_file_names($treeDir);
    if ($pathCheck != 2) {
      return $pathCheck;
    }
  } # if PC product

  print "This is a patch, third party or a non-unix product.";
  print "  Not verifying checksum.\n";
  if ($ArchExtensions{$myArch} eq "unix") {
    # we are running on unix and can use "diff"
    print "Doing diff of files.\n";
    $diff_cmd = "diff -r $treeDir $fromDir > /dev/null";
    print "$SCRIPTNAME\[Info\]: Now verifying files with this command:\n";
    print "    $diff_cmd\n";
    if (system("$diff_cmd")) {
      print "$SCRIPTNAME\[Error\]:  diff of directories failed!\n";
      &relcleanup;
    } else {
      print "$SCRIPTNAME\[Info\]:  diff of directories OK\n";
    }
  } else {
    print "Not running on unix.  Not doing diff of files.\n";
  }
  return 2;
}

sub check_checksum {
  local ($treeDir, $myArch, $prodFamily, $packingFile) = @_;
  local (@treeList, @packingList, $tnum, $pnum, $filePath, $isOK);

  # Check a shippable product tree.
  # Return values:
  #        0   Some error happened during processing,
  #               system error, checksum failed, diff failed.
  #        2   OK, paths are all good.
  # We assume we have a non-patch unix product with a unix checksum!

  # Make sure we don't have extra files, ones not in the checksum list.

  # Get a sorted list of the files in directory "treeDir"
  if (!chdir($treeDir)) {
    print "$SCRIPTNAME:  unable to cd to $treeDir , errno = $!\n";
    return 0;
  }
  if (&list_tree(".", *treeList)) {
    foreach $filePath (@treeList) {
      # remove the "./" from the beginning of each path
      $filePath =~ s/^\.\///;
    }
    @treeList = sort(@treeList);
  } else {
    print "Error from list_tree\n";
    if (!chdir($ORIGDIR)) {
      print "$SCRIPTNAME:  unable to cd (back) to $ORIGDIR; errno = $!\n";
    }
    return 0;
  }
  if (!chdir($ORIGDIR)) {
    print "$SCRIPTNAME:  unable to cd (back) to $ORIGDIR; errno = $!\n";
    return 0;
  }

  #get a sorted list of the lines in the packingFile, stripping comments
  if (!open(PACKINGFILE, "<" . $packingFile)) {
    print "$SCRIPTNAME: unable to open $packingFile.\n";
    print "error = $!\n";
    return 0;
  }
  # grab the first token of lines that do NOT begin
  # with "!" (ignore comment lines)
  while(<PACKINGFILE>) {
    if (!/^!/) {
      push(@packingList,(split)[0]);
    }
  }
  if (!close(PACKINGFILE)) {
    print "$SCRIPTNAME: error closing $packingFile.\n";
    print "error = $!\n";
    return 0;
  }
  foreach $filePath (@packingList) {
    # remove the "./" from the beginning of each path
    $filePath =~ s/^\.\///;
  }
  @packingList = sort(@packingList);

  # Now compare the sorted packing list with the list of
  # files actually in the directory.
  # We are making sure we did not pick up any extra files, ones not
  # in the packing list.
  if (scalar(@packingList) != scalar(@treeList)) {
    $pnum = scalar(@packingList);
    $tnum = scalar(@treeList);
    print "$SCRIPTNAME: Error, packing list $packingFile has $pnum files but\n";
    print " directory $treeDir has $tnum files.\n";
    print " packing list has:\n";
    foreach $filePath (@packingList) {
      print $filePath . "\n";
    }
    print " $treeDir list has:\n";
    foreach $filePath (@treeList) {
      print $filePath . "\n";
    }
    return 0;
  }
  $listIsOK = 1;
  $cnt = 0;
  foreach $filePath (@packingList) {
    if ($filePath ne @treeList[$cnt]) {
      print "  Error, packing list entry $filePath does not match\n";
      print "         file path @treeList[$cnt]\n";
      $listIsOK = 0;
    }
    $cnt++;
  }
  if ($listIsOK == 0) {
    return 0;
  }

  if (($prodFamily eq "12") || ($prodFamily eq "14") || ($prodFamily eq "18")) {
    # GemStone/J and GemStone/J with VisiBroker
    $checksum_cmd = "cd $treeDir/install;./checktree";
  } else {
    print "Error: do not know how to check checksums for this product.\n";
    return 0;
  }
  print "$SCRIPTNAME\[Info\]: Now verifying the checksum of files in the\n";
  print "     product directory.  GEMSTONE is $GEMSTONE\n";
  print "     Verifying checksums by doing this command:\n";
  print "     $checksum_cmd\n";
  if (system("$checksum_cmd")) {
    print "$SCRIPTNAME:  ERROR! checksum of files in\n";
    print "       $treeDir\n";
    print "    does not match checksums file\n";
    return 0;
  }
  return 2;
}



