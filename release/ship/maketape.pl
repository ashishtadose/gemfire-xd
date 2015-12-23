#! /usr/bin/perl5
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - maketape.pl
#
# Purpose - To build product tapes
#
# $Id$
#
#=========================================================================

print "$0: Initializing, please wait...\n";

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


#-------------------------------------------------------
# Sanctioned Devices...
# Place an array with the name $HOSTNAME_devices here, and
# get_device will find it.  This array will be converted into an associative
# array in its use, so it should be key/value pairs, of course!

# ship
@ship_devices = ("QIC-150 (rst0)", "/dev/rst0",
  "QIC-150 (rst1)", "/dev/rst1",
  "4mm DAT, 800bpi (sun)", "/dev/rst2",
  "4mm DAT, 800bpi (Andataco)", "/dev/rst3",
  "4mm DAT 1600bpi (sun)", "/dev/rst10",
  "4mm DAT 1600bpi (Andataco)", "/dev/rst11",
  "8mm (2Gb sun)", "/dev/rst4",
  "8mm (2Gb Andataco)", "/dev/rst5",
  "8mm (5Gb sun)", "/dev/rst12",
  "8mm (5Gb Andataco)", "/dev/rst13");

# See if we have a list of devices...
eval "@" . "known_devices = @" . $HOSTNAME . "_devices";
if (&empty_array(@known_devices)) {
  $has_devices = 0;
  }
else {
  $has_devices = 1;
  }

#-------------------------------------------------------
# Miscellaneous tables...

sub numerically { $a <=> $b };

# The menu of kinds of products we know about:
@prodKinds = ();
$tableRows = @prodStrMapping / $prodStrMapWidth;
for ($row = 0; $row < $tableRows; $row++) {
  push(@prodKinds, @prodStrMapping[($row * $prodStrMapWidth) + $tarMedia]);
  push(@prodKinds, @prodStrMapping[($row * $prodStrMapWidth)]);
  }


# Architectures
@desiredArches = ();
$tableRows = @archStrMapping / $archStrMapWidth;
for ($row = 0; $row < $tableRows; $row++) {
  push(@desiredArches, @archStrMapping[($row * $archStrMapWidth) + $tarMedia]);
  push(@desiredArches, @archStrMapping[($row * $archStrMapWidth)]);
  }

@edit_menu = (
  "add a product", "add_product(*product_names,*product_list)",
  "remove a product", "remove_product(*product_names,*product_list)",
  "change device", "get_device",
  "change serial", "get_serial",
  "show status", "show_choices(*product_names,*product_list)",
  "make the tape!", "exit",
  "quit (no creation)", "do_quit",
  );


#-------------------------------------------------------
# End of boiler plate, begin of real work

# initialization
$device = "";  # device to write to.
$serial = "";  # "serial number" to write to logs
               # use a value of "release" for masters
@product_list = ();  # list of products
%product_names = (); # list of names for the above products
$lockdir_to_remove = "";

# Look for batch invocation
if ($ARGV[0] ne "") { # batch?
  require "$SCRIPTDIR/getopts.pl";

  &Getopts("s:t:hm");
  exit 1 if ($opt_err);
  $serial = $opt_s if ($opt_s ne "");
  $serial = "release" if ($opt_m ne "");
  if ($opt_t ne "") {
    if (!($opt_t =~ /\/.*/)) {
      $device = "/dev/" . $opt_t;
      }
    else {
      $device = $opt_t;
      }
    }
  if ($opt_h ne "") {
    print "Usage: $0 -t<device> -m|-s<serial> <product> {<product>}\n";
    exit 0;
    }
  for (;;) {
    last if $ARGV[0] eq "";
    exit 1 if !&add_product_list($ARGV[0],*product_names,*product_list);
    shift;
    }
  if (&empty_array(@product_list)) {
    print "$0:  error; at least one product must be specified.\n";
    exit 1;
    }
  if ($serial eq "" || $device eq "") {
    print "$0:  error; both serial and device must be set.\n";
    exit 1;
    }
  } # batch?
else {
  # Interactive execution
  &input_arguments;
  }

&make_the_tape;
exit 0;

# Top-level control for acquiring user input
sub input_arguments {
  local($verified_arguments, $tmp_def_partnum);

  # some mandatory data we won't leave empty...
  for (;;) {
    last if ($device ne "");
    &get_device;
    }
  for (;;) {
    last if ($serial ne "");
    &get_serial;
    }

  # some products we generally put on the media
  foreach $each (@default_partnums) {
    $tmp_def_partnum = &get_default_partnum($each);
    if ("$tmp_def_partnum" ne "") {
      &add_product_list($tmp_def_partnum,*product_names,*product_list);
      }
    }

  &add_product(*product_names,*product_list);

  $verified_arguments = 0;
  for (;;) {
    # General editing
    $verified_arguments = &edit_arguments;
    last if $verified_arguments;
    }
  }


# Prompt for a device
sub get_device {
  local(@junk);

  print "Device or file (or \"?\" for menu):  ";
  $answer = <STDIN>;
  chop($answer);
  if ($answer eq "?") { # do the menu
    if ($has_devices) {
      $answer = &menu("Choose one of the known devices:", @known_devices);
      if ($answer ne "") {
	$device = $answer;
	}
      }
    else {
      print "Sorry, I don't know about devices on $HOSTNAME.\n";
      }
    } # do the menu
  else {
    $device = $answer;
    }
  }

# Show what's been chosen.
sub show_choices {
  local(*prod_names,*prod_list) = @_;
  local($prod);

  print "---------------------------------\n";
  print "Device: $device\n";
  print "Serial: $serial\n";
  print "\n";
  print "Products currently chosen:\n";
  foreach $prod (@prod_list) {
    printf "%-50s %s\n", $prod_names{$prod}, $prod;
    }
  print "---------------------------------\n";
  }

# Control loop for modifying the product choices
sub edit_arguments {
  local ($choice);

  $choice = &menu("Please choose an action", @edit_menu);
  return 1 if ($choice eq "exit"); # all done!!!!
  return 0 if ($choice eq ""); # no valid choice

  # Do the command, keep reading
  print "\n";
  eval "&" . $choice;
  return 0;
  }

sub append_special_readme_file {
  local ($OutFile, $InFile) = @_;
  # Append the contents of $InFile onto $OutFile
  # and indenting the text.
  if (!open(IN, "<$InFile")) {
    die "ERROR: could not open $InFile $!\n";
    }
  if (!open(OUT, ">>$OutFile")) {
    die "ERROR: could not open $OutFile $!\n";
    }
  while(<IN>) {
    chop;
    print OUT "  $_\n";
    }
  print OUT "\n";
  close(IN);
  close(OUT);
  }

sub append_prod_description_to_readme {
  local ($ReadmeOut, $partnum, $productLine, $targetArch, $prodVersion,
         $vendorCompat, $beCompat, $patchNum) = @_;
  local ($prodName, $prettyProdName, $prettyArchType, $prettyVendorStr);
  if (!open(READMEOUT, ">>$ReadmeOut")) {
    die "ERROR: could not open $ReadmeOut $!\n";
    }
  # Get the product name.  Don't use partnum_to_dirname() because
  # that mapping may have been overridden when the product was created.
  $prodName = &name_for_product($partnum);
  if ("$prodName" eq "") {
    print "Unable to find product name for part num $partnum\n";
    exit 1;
    }
  if (&translateNumToDirStr($productLine,*prodStrMapping,$prodStrMapWidth,
                                             $signoffMedia,*prettyProdName)) {
    print "$0 error: don't know how to pick prodStr for\n";
    print "    product line: \"$productLine\"\n";
    exit 1;
    }
  # Use tarMedia so we don't get OS version numbers.  They may be out of sync.
  if (&translateNumToDirStr($targetArch,*archStrMapping,$archStrMapWidth,
                                                 $tarMedia,*prettyArchType)) {
    print "$0 error: don't know how to pick archStr for\n";
    print "    target arch: \"$targetArch\"\n";
    exit 1;
    }
  $prettyArchType =~ tr/\./ /;
  if (&translateNumToDirStr($vendorCompat,*vendorStrMapping,$vendorStrMapWidth,
                                           $signoffMedia, *prettyVendorStr)) {
    print "$0 error: don't know how to pick vendorStr for\n";
    print "    vendorCompat: \"$vendorCompat\"\n";
    print "    product number: \"$productNumber\"\n";
    exit 1;
    }

  print "Appending to $ReadmeOut\n";
  print READMEOUT "---------------------------------\n";
  print READMEOUT "$prodName\n";
  print READMEOUT "  This product is ";
  if ("$patchNum" ne "0") {
    $patchStr = $patchNum;
    $patchStr =~ s/P([^-]*)/\1/;
    print READMEOUT "Patch$patchStr for ";
    }
  print READMEOUT "the $prettyProdName\n";
  print READMEOUT "  version $prodVersion for $prettyArchType platforms.\n";
  print READMEOUT "\n";

  close(READMEOUT);
  }


sub make_the_readme {
  local ($readmeDir, *prod_list) = @_;
  local ($partnum,$productLine,$targetArch,$prodVersion,$vendorCompat);
  local ($beCompat,$patchNum,$sourcesPartNum,$specialProdLine);
  local ($specialReadme, $prodName, $readme_path, $dateStr);

  $dateStr = &my_ctime(time);
  chop($dateStr); # clip off the newline at the end

  # Add generic instructions on where to find product files
  if (!open(READMEIN, "<$SCRIPTDIR/tapeTopReadme.txt")) {
    die "ERROR: could not open $SCRIPTDIR/tapeTopReadme.txt $!\n";
    }
  $readme_path = "$shipTestDir/$readmeDir/readme.txt";
  if (!open(READMEOUT, ">>$readme_path")) {
    die "ERROR: could not open $readme_path $!\n";
    }
  print "Creating $readme_path\n";
  # Use binary mode and explicitly put <CR><LF> at line ends
  # so the readme looks good on Unix or NT.
  binmode(READMEOUT);
  print READMEOUT "This tape was mastered on $dateStr\n\n";
  while(<READMEIN>) {
    chop;
    print READMEOUT "$_\n";
    }
  close(READMEIN);
  close(READMEOUT);

  foreach $partnum (@product_list) {
    if (&parse_part_num($partnum,*productLine,*targetArch,*prodVersion,
                                     *vendorCompat,*beCompat,*patchNum)) {
      # partnumber is badly formed, error string already printed
      die "ERROR: could not parse part number\n";
      }
    &append_prod_description_to_readme($readme_path,$partnum, $productLine,
         $targetArch,$prodVersion,$vendorCompat,$beCompat, $patchNum);

    $prodName = &name_for_product($partnum);
    if ("$prodName" eq "") {
      die "ERROR: Unable to find product name for part num $partnum\n";
      }
    # This product may have a "special/readme.txt" in the coresponding
    # source product.  Append it to the tape readme.txt if it exists.
    if (($productLine <= 100) ||
        (($productLine >= 500) && ($productLine < 600))) {
      $specialProdLine = $productLine + 100;
      }
    else {
      $specialProdLine = $productLine + 50;
      }
    $sourcesPartNum  = "$specialProdLine". "-" . "$targetArch" . "-";
    $sourcesPartNum .= "$prodVersion" . "-" ."$vendorCompat" . "-";
    $sourcesPartNum .= "$beCompat". "-" . "$patchNum";
    $specialReadme = "$partsDir/$sourcesPartNum/special/readmeAddendum.txt";
    if (-f "$specialReadme") {
      &append_special_readme_file($readme_path, $specialReadme, $prodName);
      }
    }
  }


sub make_the_tape {
  local ($tar_results, $temp_readme_dir);

  &show_choices(*product_names, *product_list);
  $temp_readme_dir = "maketapetmp$$";
  mkdir("$shipTestDir/$temp_readme_dir", 0755);
  &make_the_readme($temp_readme_dir, *product_list);
  $tar_results = &do_the_tar("",$device,*product_list,$temp_readme_dir);
  $tar_results = $tar_results . "\n";
  &add_to_log("maketape.pl","tape",$device, $tar_results,
        *product_names,*product_list);
  unlink("$shipTestDir/$temp_readme_dir/readme.txt");
  rmdir("$shipTestDir/$temp_readme_dir");
  }

