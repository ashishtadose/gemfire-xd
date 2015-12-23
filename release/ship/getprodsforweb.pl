#! /usr/bin/perl5
#=========================================================================
# (c) Copyright 1996-2007, GemStone Systems, Inc. All Rights Reserved.
#=========================================================================
# Name - getprodsforweb.pl
#
# Purpose - get some products into a directory for later web distribution.
#  getprodsforweb.pl <shortName> [-t <prodList>] [-c <prodList>]
#     shortName   - A short name used for result directory and part
#                      of the tar file names.
#     -t prodList - Tars files of the space separated list of product
#                      numbers from ship and compresses them.
#     -c prodList - Copies files of the space separated list of product
#                      numbers from ship as is.
#                      Does NOT tar and compresses them.
#
# Creates directory <shortName> in the current directory if it does not exist.
#
# With the "-t prodList" option it places into directory <shortName>
# three files: the compressed tar file, a gzipped tar file, and a zip file
# of the requested product <prodNum>.  In these files you get what you would
# have on a tape; a partname directory and its subdirs.  Use this when
# there are a lot of files or a large amount of data in the product.
#
# With the "-c prodList" option it places into directory <shortName>
# all the files and directories of each product in the list.
# You get the files from inside each ...../inventory/partnum/partname
# directory, NOT the "partname" directory level itself.
# Use this when there are only a few small files in the product
# (for instance: a filein patch).
#
# Example 1) If "shortName" is "p001gs50" (which means patch001 of
#   GemStone version 5.0) and we have "-t 1-9-5.0-0-0-P001" we will get
#   this structure:
#      p001gs50/
#               p001gs50_AIX.tar.Z    (compressed tar file)
#               p001gs50_AIX.tar.gz   (gzipped tar file)
#               p001gs50_AIX.zip      (compressed file)
#   These would extract to GemStone5.0-RISC6000.AIX-PatchLevel001.
#   It is possible that the compressed tar file will be larger than a plain
#   tar file.  If this happens we would have the file p001gs50_AIX.tar
#   instead of p001gs50_AIX.tar.Z.  We will always get the .gz file.
#
# Example 2) If "shortName" is "p002gbs50" (which means patch002 of
#   GemBuilder version 5.0) and we have "-c 2-110-5.0-22-0-P002" we will get
#   this structure:
#      p002gbs50/
#                p00250.a30
#                p00250.aix
#                p00250.t30
#                p00250.txt
#   Note that the directory level "GemBuilder5.0+va3.0a-all-PatchLevel002"
#   is NOT present.
#
# Use readme2html.pl to take a first stab at converting a patch's readme
# file to html and after cleanup put the html file into the <shortName> dir.
#
# Use sendtowebhost.pl to tar up the whole lot and send the results
# to www.gemstone.com via ftp to a private directory for extraction
# and final testing.
# A webmaster will then need to put these files in a public place on
# the web after making suitable changes to the text of the proper web page.
#
# $Id$
#
#=========================================================================

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
require "$SCRIPTDIR/define-ship.pl";
require "$SCRIPTDIR/partnummapping.pl";

#=========================================================================
# Grab arguments

$tarProdNum = "";
$copyProdNum = "";
$shortName = "";
sub usage {
print "Usage: $0 ...\n";
print "getprodsforweb.pl <shortName> [-t <prodList>] [-c <prodList>]\n";
print "  shortName   - A short name used for result directory and part\n";
print "                   of the tar file names.\n";
print "  -t prodList - Tars files of the space separated list of product\n";
print "                   numbers from ship and compresses them.\n";
print "  -c prodList - Copies files of the space separated list of product\n";
print "                   numbers from ship as is.\n";
print "                   Does NOT tar and compresses them.\n";
}

if ( $ARGV[0] eq "" || $ARGV[1] eq "" || $ARGV[2] eq "" || $#ARGV < 2) {
  &usage;
  exit 1;
  }

@tarProdList = ();
@copyProdList = ();


$shortName = "$ARGV[0]";
shift;

$addToTarlist = 0;
$addToCopylist = 0;
foreach $arg (@ARGV) {
  if ($arg =~ /^-t$/i) {
    $addToTarlist = 1;
    $addToCopylist = 0;
    }
  elsif ($arg =~ /^-c$/i) {
    $addToCopylist = 1;
    $addToTarlist = 0;
    }
  elsif ($arg =~ /^-d$/i) {
    $addToCopylist = 0;
    $addToTarlist = 0;
    }
  else {
    if ($addToTarlist) {
      push(@tarProdList, "$arg");
      }
    elsif ($addToCopylist) {
      push(@copyProdList, "$arg");
      }
    else {
      print "ERROR: do not know what to do with arg $arg\n";
      print "  bailing out\n";
      &usage;
      exit 1;
      }
    }
  }

# create a scratch directory if it does not already exist
# in the current working directory
$testDir="$ORIGDIR/$shortName";
if (! -e "$testDir" ) {
  mkdir($testDir, 0755);
  }
else {
  print "Using existing directory $testDir.\n";
  }

if (!chdir("$testDir")) {
  print "ERROR: unable to cd $testDir.\n";
  print "  error = $!\n";
  exit 1;
  }

foreach $tarProdNum (@tarProdList) {
  # Create tar files, compressed files, and compressed tar files
  # from files and directories from product copyProdNum
  # Check that the partnumber exists
  $theDir = $partsDir . $DIRSEP . $tarProdNum;
  if (! -d $theDir) {
    print "Sorry, there is no such part $tarProdNum.\n";
    exit 1;
    }

  # get the OSTYPE of the specified partnumber
  $targOSTYPE = $tarProdNum;
  $targOSTYPE =~ s/[^-]+-([^-]+)-[^-]+-[^-]+-[^-]+-.*/$1/;
  $OSstr = "";
  if (&translateNumToDirStr($targOSTYPE,*archStrMapping,$archStrMapWidth,
                                                            $webMedia,*OSstr)) {
    print "$0 error: don't know how to pick OSstr for\n";
    print "    target arch: \"$targOSTYPE\"\n";
    print "    product number: \"$tarProdNum\"\n";
    exit 1;
    }

  if (&tarandcomp($theDir, $testDir, $shortName . "-" . $OSstr)) {
    exit 1;
    }
  } # "$tarProdNum" ne ""

foreach $copyProdNum (@copyProdList) {
  # Copy files and directories from product copyProdNum
  # Check that the partnumber exists
  $theDir = $partsDir . $DIRSEP . $copyProdNum;
  if (! -d $theDir) {
    print "Sorry, there is no such part $copyProdNum.\n";
    exit 1;
    }

  # naively, we would just add the product name directory.  However, let's go
  # the extra 9 yards and allow multiple subdirs under the partnum directory...
  
  if (!opendir(CURDIR, $theDir)) {
    print "Unable to open directory $theDir, error = $!\n";
    exit 1;
    }
  for (;;) {
    $thisFile = readdir CURDIR;
    last if !defined($thisFile);
    next if (($thisFile eq ".") || ($thisFile eq ".."));
    if (!&basiccopy_tree("$testDir", "$theDir/$thisFile", "$ARCH", 1)) {
      print "ERROR:  can not copy files\n";
      print "   from $theDir/$thisFile\n";
      print "   to   $testDir\n";
      exit 1;
      }
    }
  closedir(CURDIR);
  } # "$copyProdNum" ne ""

print "$0: Finished\n";
exit 0;

