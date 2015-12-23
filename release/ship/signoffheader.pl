#! /usr/bin/perl5
#=========================================================================
# (c) Copyright 1996-2007, GemStone Systems, Inc. All Rights Reserved.
#=========================================================================
# Name - signoffheader.pl
#
# Purpose - Given a partnumber create the header text for
#           the signoff sheets for the product and the source product.
#
#    signoffheader.pl <partnum>
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
require "$SCRIPTDIR/partnummapping.pl";

#=========================================================================
# Grab arguments

sub usage {
print "Usage: $0 ...\n";
print "signoffheader.pl <partnum>\n";
}
if ( $ARGV[0] eq "" || $#ARGV != 0) {
  &usage;
  exit 1;
  }

$startTime = time;
$startTimeStr = &my_ctime($startTime);
chop($startTimeStr);
($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
$year += 1900;

$dateStr = $ctime_MoY[$mon] . " $mday, $year";
$prodLine="";
$targArch="";
$prodVersion="";
$vendCompat="";
$servCompat="";
$patch="";
$LicPartNum="0";
$dirName="";

$productNum = "$ARGV[0]";

&parse_part_num($productNum,*prodLine,*targArch,*prodVersion,*vendCompat,
                *servCompat,*patch);
# Routine partnum_to_dirname() sends some stuff to STDOUT which we don't
# want to see here so save and redirect STDOUT, call partnum_to_dirname(),
# and then restore STDOUT.
open(SAVEOUT, ">&STDOUT");
open(STDOUT, "> /dev/null");
$dirName = &partnum_to_dirname($productNum);
close(STDOUT);
open(STDOUT, ">&SAVEOUT");


if ($LicPartNum ne 0) {
print "============================================================================\n";
&print_header($productNum,$prodLine,$targArch,$prodVersion,$vendCompat,
                $servCompat,$patch,$dirName,$dateStr);
exit 1;

} 

print "============================================================================\n";
&print_header($productNum,$prodLine,$targArch,$prodVersion,$vendCompat,
                $servCompat,$patch,$dirName,$dateStr);

$srcProdNum = $productNum;
$srcProdNum     =~ s/([^-]+)-.*/$1/;
if ((($srcProdNum >= 1) && ($srcProdNum <= 99)) ||
    (($srcProdNum >= 500) && ($srcProdNum <= 599))) {
  # There is a source code product
  }
else {
  print "============================================================================\n";
  print "No Source product for product number $srcProdNum\n";
  exit 1;
  }

$srcProdNum += 100;
$srcProduct = $productNum;
$srcProduct =~ s/[^-]+(.*)/$srcProdNum$1/;

$prodLine="";
$targArch="";
$prodVersion="";
$vendCompat="";
$servCompat="";
$patch="";
$dirName="";

$productNum = $srcProduct;

&parse_part_num($productNum,*prodLine,*targArch,*prodVersion,*vendCompat,
                *servCompat,*patch);

# Routine partnum_to_dirname() sends some stuff to STDOUT which we don't
# want to see here so save and redirect STDOUT, call partnum_to_dirname(),
# and then restore STDOUT.
open(SAVEOUT, ">&STDOUT");
open(STDOUT, "> /dev/null");
$dirName = &partnum_to_dirname($productNum);
close(STDOUT);
open(STDOUT, ">&SAVEOUT");

print "============================================================================\n";
&print_header($productNum,$prodLine,$targArch,$prodVersion,$vendCompat,
                $servCompat,$patch,$dirName,$dateStr);
print "============================================================================\n";


sub print_header {
  local($prodNum,$prodLine,$targArch,$prodVersion, $vendCompat,$servCompat,
        $patch,$dirName,$dateStr) = @_;
  local($tmpStr, $fixedPath);
  local($tempDirRelative, $prodStr, $archStr, $verStr);
  local($vendorStr, $beCompatStr, $patchStr);

  if ($LicPartNum ne 0) {
    print "PRODUCT:        GemFire Suite Layer License\n";
    }
  else {
    print "PRODUCT:        ";
    &translateNumToDirStr($prodLine,*prodStrMapping,$prodStrMapWidth,
                        $signoffMedia,*tmpStr);
    print "$tmpStr ";
    } 

  if ("$patch" ne "0") {
    print "LICENSE TYPE:   ";
    if ("$patch" eq "1") {
       print "Nodelock for GemFire SMP/Distributed\n";
    } 
    elsif ("$patch" eq "2") {
       print "Floating for GemFire SMP/Distributed\n";
    }
    elsif ("$patch" eq "3") {
       print "Nodelock for XML Integration Module\n";
    }
    elsif ("$patch" eq "4") {
       print "Floating for XML Integration Module\n";
    }
    else {
       print "ERROR: Unknown license type $patch\n";
       exit(1);
    }

  print "PLATFORM:       ";
  }

  &translateNumToDirStr($targArch,*archStrMapping,$archStrMapWidth,
                        $signoffMedia,*tmpStr);


  if ("$servCompat" ne "0") {
    print "with $servCompat\n                ";
    }
  print "on $tmpStr\n";
  print "VERSION NO:     $prodVersion\n";
  print "PART NO:        $prodNum\n";

  if ($LicPartNum eq 0) {
    print "DATE:           $dateStr\n";
    print "INVENTORY DIRECTORY NAME: $dirName\n";
    &construct_dir_path_name($cdromMedia, *tempDirRelative,
              $prodLine, *prodStr, $targArch, *archStr,
              $prodVersion, *verStr, $vendCompat, *vendorStr,
              $servCompat, *beCompatStr, $patch, *patchStr);
    if ($prodLine != 700) {
      if ( &is_source_product($prodLine) ) {
        print "CDROM DIRECTORY PATH:     $tempDirRelative/$archStr.zip\n";
        }
      else {
        $fixedPath = $tempDirRelative;
        $fixedPath =~ s/\//\\/g;
        print "CDROM DIRECTORY PATH:     $fixedPath\\*.*\n";
        }
    }

  } else {
    print "============================================================================\n";
  }

}
  
