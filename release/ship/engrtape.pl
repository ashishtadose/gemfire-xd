#!/usr/bin/perl5
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - engrtape.pl
#
# Purpose - Allow engineers to zip and make a tape of an engineering
#   release so engineering can make and send a one-off to a customer.
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
  $ARCH = $HOSTTYPE_OSTYPE";
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

require "$SCRIPTDIR/define-ship.pl";

if ($#ARGV != 3) {
  print "Usage:  engrtape.pl super_dir zip_dir pretty_name tar_output\n";
  print "   super_dir: Directory which has a subdir named \"product\".\n";
  print "              This dir must be writable by the running user!\n";
  print "   zip_dir: Directory where we will temporarily put a\n";
  print "              file named product.zip.\n";
  print "   pretty_name: Directory name which will become the top level\n";
  print "              dir on the tape.  We will rename super_dir/product\n";
  print "              to super_dir/pretty_name and then zip and tar\n";
  print "              through this new directory name.  The directory\n";
  print "              will be renamed back to product when we are finished.\n";
  print "              Example: GemStone5.1.engr2-hppa.hpux\n";
  print "   tar_output:  The output target for the tar.  May be a\n";
  print "              tape device or a file path.\n";
  exit 1;
}

$super_dir=$ARGV[0];
$zip_dir_root=$ARGV[1];
$pretty_name=$ARGV[2];
$tar_output=$ARGV[3];

if ("$super_dir" eq "$zip_dir_root") {
  print "ERROR: super_dir and zip_dir can not be the same directory. Exiting\n";
  }

if (! -e "$super_dir/product") {
  print "Error: can not find $super_dir/product.  Exiting\n";
  exit 1;
  }

if (! -w "$super_dir") {
  print "Error: directory $super_dir not writable by you.  Exiting\n";
  exit 1;
  }

if (! -e "$zip_dir_root") {
  print "Error: can not find $zip_dir_root.  Exiting\n";
  exit 1;
  }

if (! -w "$zip_dir_root") {
  print "Error: directory $zip_dir_root not writable by you.  Exiting\n";
  exit 1;
  }

$zip_dir = "$zip_dir_root/$pretty_name";

if (-e "$zip_dir") {
  print "Error: Dir $zip_dir already exists.  Exiting\n";
  exit 1;
  }

if (!mkdir("$zip_dir",0777)) {
  print "Error: could not create $zip_dir.  Exiting\n";
  exit 1;
  }


# Use rename instead of symlink because we want zip to preserve links.
if (!rename("$super_dir/product","$super_dir/$pretty_name")) {
  print "Error: renaming $super_dir/product\n";
  print "  to $super_dir/$pretty_name failed. Exiting\n";
  exit 1;
  }

$cmd  = "cd $super_dir; ";
$cmd .= "zip -y -q -r $zip_dir/product.zip $pretty_name";
print "doing this command:\n  $cmd\n";
$status = system("$cmd");
if ( $status != 0) {
  print "Error: zip failed, returned value $status.  Exiting\n";
  # Don't really exit yet, rename dir first.
  }
else {
  # do the tar
  $cmd="tar -cvhf $tar_output -C $shipBase utils -C $zip_dir_root $pretty_name";
  print "doing this command:\n  $cmd\n";
  $status = system("$cmd");
  if ( $status != 0) {
    print "Error: tar failed, returned value $status.  Exiting\n";
    # Don't really exit yet, rename dir first.
    }
  }

if (!unlink("$zip_dir/product.zip")) {
  print "Error: could not remove $zip_dir/product.zip, continuing\n";
  }
if (!rmdir("$zip_dir")) {
  print "Error: could not remove $zip_dir, continuing\n";
  }

if (!rename("$super_dir/$pretty_name","$super_dir/product")) {
  print "Error: renaming $super_dir/$pretty_name\n";
  print "  to $super_dir/product failed. Exiting\n";
  exit 1;
  }

exit $status
