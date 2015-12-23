#! /usr/bin/perl5 
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - collectprods.pl
#
# Purpose - Collect product files and dirs for burning onto a CDR.
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
#  delete $ENV{"PATH"}; # for safety
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

require "$SCRIPTDIR/define-ship.pl";
require "$SCRIPTDIR/misc.pl";
require "$SCRIPTDIR/partnummapping.pl";
require "$SCRIPTDIR/mkcderror.pl";

$ext = "";
$comndSep = ";";
if ($ARCH eq "x86.Windows_NT") {
  $ext = ".exe";
  $comndSep = "&";
  }
$zip = "$shipBinDir/$ARCH/zip$ext";
if ( ! -f $zip) {
  print "$0 error:  File $zip does not exist\n";
  exit 1;
  }
# zip arg of file types not to compress when including in a zip file
$noCompresSuf = "-n .Z:.z:.zip:.gif:.jpg:.jpeg:.gz";
$zip .= " $noCompresSuf";
$unzip = "$shipBinDir/$ARCH/unzip$ext";
if ( ! -f $unzip) {
  print "$0 error:  File $unzip does not exist\n";
  exit 1;
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
  "add products", "add_product(*product_names,*product_list)",
  "remove a product", "remove_product(*product_names,*product_list)",
  "change serial", "get_serial",
  "show status", "show_choices(*product_names,*product_list)",
  "make the CDRom dirs!", "exit",
  "quit (no creation)", "do_quit",
  );


#-------------------------------------------------------
# End of boiler plate, begin of real work

# initialization
$serial = "";  # "serial number" to write to logs
               # use a value of "release" for masters
$cdromDirName = "";
$cdromFilesDir = "";
@product_list = ();  # list of products
%product_names = (); # list of names for the above products
$lockdir_to_remove = "";
$longNamesOK = 0;
$makeLinks = 0;

# Look for batch invocation
if ($ARGV[0] ne "") { # batch?
  require "$SCRIPTDIR/getopts.pl";

  &Getopts("c:hklms:");
  exit 1 if ($opt_err);
  $serial = $opt_s if ($opt_s ne "");
  $serial = "release" if ($opt_m ne "");
  $longNamesOK = 1 if ($opt_l ne "");
  $makeLinks = 1 if ($opt_k ne "");
  if ($opt_c ne "") {
    $cdromDirName = $opt_c;
    $cdromFilesDir = "$CDRomTempDir/$cdromDirName";
    }
  if ($opt_h ne "") {
    print "Usage: $0 -c <cdimagefile> -m|-s<serial> <product> {<product>}\n";
    print " This routine collects a set of products under a single directory\n";
    print " which will then be processed by other scripts and placed onto\n";
    print " a CDRom\n";
    print " -c <CDRomDir>  Name of directory where we will collect files\n";
    print "                  and directories we want on a CDRom.\n";
    print "                  For PCs this is put under C:\CDRomTempDir\n";
    print "                  For UNIX this is put under \$shipBase/CDRomTempDir\n";
    print " -h    Display this usage message.\n";
    print " -k    Create links to product files instead of copying them.\n";
    print " -l    Allow long file and directory names.\n";
    print " -m    Use serial value for release masters.  Same as \"-s release\"\n";
    print " -s <serial>  Serial number for this order, found on packaging list\n";
    print "  <product>   List of partnumbers of products to include.\n";
    exit 0;
    }
  for (;;) {
    last if $ARGV[0] eq "";
    exit 1 if !&add_product_list($ARGV[0],*product_names,*product_list);
    shift;
    }
  if ("$cdromFilesDir" eq "") {
    print "$0:  error; must give \"-c <CDRomDir>\" value.\n";
    exit 1;
    }
  if (&empty_array(@product_list)) {
    # Interactive execution
    &input_arguments;
    }
  if ($serial eq "") {
    print "$0:  error; serial number must be set.\n";
    exit 1;
    }
  } # batch?
else {
  print "$0:  error; must at least give \"-c <CDRomDir>\" value.\n";
  exit 1;
  }

&make_the_cdrom_dirs;

exit 0;

# Top-level control for acquiring user input
sub input_arguments {
  local($verified_arguments, $tmp_def_partnum);

  # some mandatory data we won't leave empty...
  for (;;) {
    last if ($serial ne "");
    &get_serial;
    }

#  # some products we generally put on the media
#  foreach $each (@default_partnums) {
#    $tmp_def_partnum = &get_default_partnum($each);
#    if ("$tmp_def_partnum" ne "") {
#      &add_product_list($tmp_def_partnum,*product_names,*product_list);
#      }
#    }

  if (&select_package == 0) {
    &add_product(*product_names,*product_list);
    }

  $verified_arguments = 0;
  for (;;) {
    # General editing
    $verified_arguments = &edit_arguments;
    last if $verified_arguments;
    }
  }


# Show what's been chosen.
sub show_choices {
  local(*prod_names,*prod_list) = @_;
  local($prod);

  print "---------------------------------\n";
  print "Serial: $serial\n";
  print "CDRom dir path: $cdromFilesDir\n";
  print "\n";
  print "Products currently chosen:\n";
  foreach $prod (@prod_list) {
    printf "%-50s %s\n", $prod_names{$prod}, $prod;
    }
  print "---------------------------------\n";
  }

# Control loop for selecting packages of products
sub select_package {
  local ($choice);

  $choice = &menu("Please choose a package or action", @packages_menu);
  return 0 if ($choice eq "exit"); # all done!!!!
  return 0 if ($choice eq ""); # no valid choice

  # Do the command, keep reading
  print "\n";
  eval "&" . $choice;
  &show_choices(*product_names,*product_list);
  return 1;
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

sub cleanup_cdrom_dirs {
  local($dirName) = @_;
  # remove the contents of $dirName if it exists
  # $dirName should be a full path
  if ( -e $dirName) {
    print "Cleaning up $dirName\n";
    if (&remove_dir($dirName) != 0) {
      print "ERROR: could not remove dir $dirName: $!\n";
      exit(1);
      }
    }
  }

sub create_base_readme_file {
  local($readme_path, $dateStr) = @_;
  # Add generic instructions on where to find product files and
  # how to pull them off the CD.
    
print "#### running create_base_readme_file\n";
    
  if (!open(READMEOUT, ">$readme_path")) {
    die "ERROR: could not open $readme_path $!\n";
    } 
  # Use binary mode and explicitly put <CR><LF> at line ends
  # so the readme looks good on Unix or NT.
  binmode(READMEOUT);
  print READMEOUT "GemStone CD-ROM Readme.txt\r\n";
  print READMEOUT "\r\n";
  print READMEOUT "This CD was mastered on $dateStr\r\n";
  print READMEOUT "\r\n";
  print READMEOUT "---------------------------------\r\n";
  print READMEOUT "List of the Products on this CD  \r\n";
  close(READMEOUT);
  } 

sub append_to_readme_file {
  local($readme_path, $dateStr) = @_;
  # Add generic instructions on where to find product files and
  # how to pull them off the CD.

  if (!open(READMEIN, "<$SCRIPTDIR/cdromTopReadme.txt")) {
    die "ERROR: could not open $SCRIPTDIR/cdromtopreadme.txt $!\n";
    }
  if (!open(READMEOUT, ">>$readme_path")) {
    die "ERROR: could not open $readme_path $!\n";
    }
  # Use binary mode and explicitly put <CR><LF> at line ends
  # so the readme looks good on Unix or NT.
  binmode(READMEOUT);
  while(<READMEIN>) {
    chop;
    print READMEOUT "$_\r\n";
    }
  close(READMEIN);
  close(READMEOUT);
  }

sub append_special_readme_file {
  local ($OutFile, $InFile) = @_;
  # Append the contents of $InFile onto $OutFile adding DOS line endings
  # and indenting the text.
  if (!open(IN, "<$InFile")) {
    die "ERROR: could not open $InFile $!\n";
    }
  if (!open(OUT, ">>$OutFile")) {
    die "ERROR: could not open $OutFile $!\n";
    }
  binmode(OUT);
  while(<IN>) {
    chop;
    print OUT "  $_\r\n";
    }
  print OUT "\r\n";
  close(IN);
  close(OUT);
  }

sub append_prod_description_to_readme {
  local ($ReadmeOut, $partnum, $productLine, $targetArch, $prodVersion,
         $vendorCompat, $beCompat, $patchNum, $cdDirPath) = @_;
  local ($prodName, $prettyProdName, $prettyArchType, $cdArchType);
  local ($prettyVendorStr, $fixedPath);

  if (!open(READMEOUT, ">>$ReadmeOut")) {
    die "ERROR: could not open $ReadmeOut $!\n";
    }
  # Get the product name.  Don't use partnum_to_dirname() because
  # that mapping may have been overridden when the product was created.
  $prodName = &name_for_product($partnum);
  if ("$prodName" eq "") {
    print "Unable to find product name for part num $partnum\n";
    &error_exit($cdromFilesDir);
    }
  #Special treatment for GSJ editions names in readme.txt.
  if (("$productLine" eq "6") || ("$productLine" eq "7") ||
      ("$productLine" eq "8") || ("$productLine" eq "9")) {
    $productLine = 12;
    }
  if (&translateNumToDirStr($productLine,*prodStrMapping,$prodStrMapWidth,
                                             $signoffMedia,*prettyProdName)) {
    print "$0 error: don't know how to pick prodStr for\n";
    print "    product line: \"$productLine\"\n";
    exit 1
    }
  # Use tarMedia so we don't get OS version numbers.  They may be out of sync.
  if (&translateNumToDirStr($targetArch,*archStrMapping,$archStrMapWidth,
                                                 $tarMedia,*prettyArchType)) {
    print "$0 error: don't know how to pick archStr for\n";
    print "    target arch: \"$targetArch\"\n";
    exit 1
    }
  $prettyArchType =~ tr/\./ /;
  # Get arch string for use with .zip filename.
  if (&translateNumToDirStr($targetArch,*archStrMapping,$archStrMapWidth,
                                                 $cdromMedia,*cdArchType)) {
    print "$0 error: don't know how to pick archStr for\n";
    print "    target arch: \"$targetArch\"\n";
    exit 1
    }
  $cdArchType =~ tr/A-Z/a-z/;
  if (&translateNumToDirStr($vendorCompat,*vendorStrMapping,$vendorStrMapWidth,
                                           $signoffMedia, *prettyVendorStr)) {
    print "$0 error: don't know how to pick vendorStr for\n";
    print "    vendorCompat: \"$vendorCompat\"\n";
    print "    product number: \"$productNumber\"\n";
    exit 1
    }

  print "Appending to $ReadmeOut\n";
  # Use binary mode and explicitly put <CR><LF> at line ends
  # so the readme looks good on Unix or NT.
  binmode(READMEOUT);
  print READMEOUT "---------------------------------\r\n";
  print READMEOUT "$prodName\r\n";
  print READMEOUT "  This product is ";
  if ("$patchNum" ne "0") {
    $patchStr = $patchNum;
    $patchStr =~ s/P([^-]*)/\1/;
    print READMEOUT "Patch$patchStr for ";
    }
  print READMEOUT "the $prettyProdName\r\n";
  print READMEOUT "  version $prodVersion for $prettyArchType platforms.\r\n";
  local ($fixcdDirPath);
  if (&is_unix_product($targetArch)) {
    #print READMEOUT "    $cdDirPath/";
    $fixcdDirPath="$cdDirPath";
    }
  else {
    # Change forward slashes "/" to backslashes "\" for PC products
    $fixedPath = $cdDirPath;
    $fixedPath =~ s/\//\\/g;
    #print READMEOUT "    $fixedPath\\"
    $fixcdDirPath="$fixedPath";
    } 
  if (-e "$partsDir/$partnum/$prodName/$cdArchType.zip") {
    print READMEOUT "$cdArchType.zip\r\n";
    }
  elsif (-e "$partsDir/$partnum/$prodName/setupWin32_gf30.exe") {
    if ( $prettyArchType eq "x86 Windows_NT") {
      $prettyArchType = "x86 Windows 2000 or later"
    }
    print READMEOUT "\r\n";
    print READMEOUT "  To install on $prettyArchType run this installer:\r\n";
    print READMEOUT "  $fixcdDirPath\\setupWin32_gf30.exe\r\n";
    }
  elsif (-e "$partsDir/$partnum/$prodName/setupSparcSol_gf30.bin") {
    print READMEOUT "\r\n";
    print READMEOUT "  To install on $prettyArchType run this installer:\r\n";
    print READMEOUT "  $fixcdDirPath/setupSparcSol_gf30.bin\r\n";
    }
  elsif (-e "$partsDir/$partnum/$prodName/setupLinux_gf30.bin") {
    print READMEOUT "\r\n";
    print READMEOUT "  To install on $prettyArchType run this installer:\r\n";
    print READMEOUT "  $fixcdDirPath/setupLinux_gf30.bin\r\n";
    }
  elsif (-e "$partsDir/$partnum/$prodName/setupGemFirePJ_gf30.bin") {
    print READMEOUT "\r\n";
    print READMEOUT "  To install on $prettyArchType run this installer:\r\n";
    print READMEOUT "  $fixcdDirPath/setupGemFirePJ_gf30.bin\r\n";
    }
  else {
    #print READMEOUT "*.*\r\n";
    print READMEOUT "  This product may be obtained from:\r\n";

    # Try and print the $prodName contents
    local( @contentfiles, $dir ); 
    $dir="$partsDir/$partnum/$prodName";
    if ( ! -d "$dir" ) {
      warn( "Directory not found: $dir\n" );
      return 0;  
      }
    if (!opendir( DIR, "$dir" )) {
      warn( "opendir($dir) failure: $!\n" ); 
      return 0;
      }
    @contentfiles = readdir(DIR);
    closedir( DIR );
   
    #chmod(0777, "$dir") || warn "chmod failed on $dir: $!";
    while ( $#contentfiles != -1 ) {
      $item = shift( @contentfiles );
      next if $item eq "." || $item eq "..";
      print READMEOUT "    $fixcdDirPath/$item\r\n"
      #print READMEOUT "$item\n";
      } 
    }
  print READMEOUT "\r\n";

  close(READMEOUT);

  }

# Build the files and directories for a CDRom
# and log the results like maketape does.
sub make_the_cdrom_dirs {
  local ($results, $tempResults, $doneWork);
  local ($theDir, $thisFile, $status, $srcFile, $destFile);
  local ($startTime, $endTime);
  local ($startTimeStr, $endTimeStr);
  local (@tempList, $tempDir, $tempDirRelative, $prodDir, $tempFile, $zipFile);
  local ($productLine, $targetArch, $prodVersion);
  local ($vendorCompat, $beCompat, $patchNum);
  local ($prodStr, $archStr, $verStr, $vendorStr, $beCompatStr, $patchStr);
  local ($found, $prod);
  &show_choices(*product_names, *product_list);

  $startTime = time;
  $startTimeStr = &my_ctime($startTime);
  chop($startTimeStr);
  $results = "";
  $tempResults = "Making the tree from which we will make the CDRom.\n";
  print $tempResults;
  $results = $results . $tempResults;
  $tempResults = "Start time is $startTimeStr\n";
  print $tempResults;
  $results = $results . $tempResults;
  $cdromFilesContents = "$cdromFilesDir/contents.txt";
  $cdromFilesReadme = "$cdromFilesDir/readme.txt";
  # Don't clean up any previous directory structures under $CDRomTempDir
  # since we could be colliding with another process!
  if (-e "$cdromFilesDir") {
    print "ERROR: directory $cdromFilesDir\n";
    print "  already exists!\n";
    print "Exiting\n";
    exit 1;
    }

  # Create a tree with the products
  if (!mkdir($cdromFilesDir, 0755)) {
    die "ERROR: could not mkdir $cdromFilesDir: $!\n";
    }

  $theDir = $cdromFilesDir;

  $dateStr = &my_ctime(time);
  chop($dateStr); # clip off the newline at the end
  &create_base_readme_file($cdromFilesReadme, $dateStr);

  if (!open(CONTENTS, ">$cdromFilesContents")) {
    die "ERROR: could not open $cdromFilesContents $!\n";
    }
  # Use binary mode and explicitly put <CR><LF> at line ends
  # so the readme looks the same whether created on Unix or NT.
  binmode(CONTENTS);

  print CONTENTS "This CD was mastered on $dateStr\r\n";
  print CONTENTS "Here is a guide for finding products on this CD.\r\n\r\n";

  foreach $each (@product_list) {
    # Look at each product in the product_list and for each one
    # create the appropriate directory names and levels.
    # For PC products, make a copy of the product directory.
    # For Unix products, get a zip file.

    #=========================================================================
    # Parse the part number
    #=========================================================================
    if (&parse_part_num($each,*productLine,*targetArch,*prodVersion,
                                     *vendorCompat,*beCompat,*patchNum)) {
      # partnumber is badly formed, error string already printed
      &error_exit($cdromFilesDir);
      }

    # create the directory path for the product
    $tempDir = $theDir;   # used for full path on machine that makes CDRom
    $tempDirRelative = "";   # used for relative path in CONTENTS.TXT on CDRom

    &construct_dir_path_name($cdromMedia, *tempDirRelative,
              $productLine, *prodStr, $targetArch, *archStr,
              $prodVersion, *verStr, $vendorCompat, *vendorStr,
              $beCompat, *beCompatStr, $patchNum, *patchStr);

    @levels = split('/',$tempDirRelative);
    foreach $dirLevel (@levels) {
      $tempDir .= "/$dirLevel";
      if (! -e $tempDir ) {
        if (! mkdir($tempDir, 0755)) {
          die "unable to create directory $tempDir; errno = $!\n";
          }
        }
      }

    # The $tempDir now has the path of the last level of directories
    # for this product.
    # We will create a directory and copy all product files and directories.
    # It is an error if files already exist since that means some other
    # product's files are already in place and there is some conflict
    # with two products' directory mappings...

    # Add a basic product description to the CDRom readme.txt
    &append_prod_description_to_readme($cdromFilesReadme,$each,
         $productLine,$targetArch,$prodVersion,$vendorCompat,$beCompat,
         $patchNum,$tempDirRelative);

    # This product may have a "special/readmeAddendum.txt" in the coresponding
    # source product.  Append it to the CDRom readme.txt if it exists.
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
      $tempResults = &name_for_product($each);
      $specialComment = "Special readme.txt for $tempResults:";
      &append_special_readme_file("$cdromFilesReadme", "$specialReadme");
      }

    $doneWork = 0;
    if (&is_source_product($productLine)) {
      # There is a "hidden" dir and maybe a "special" dir along side
      # the sources product.  These are always trees and need to be
      # zipped since we likely have long file names there.
      #
      # Zip up the "hidden" dir and grab it
      # Use the first 5 chars of the archStr and append "hid.zip"
      # to get the name of the zip file for the "hidden" directory.
      $hiddenZipFile = "$archStr";
      $hiddenZipFile =~ s/(^.....).*/$1/;
      $hiddenZipFile .= "hid.zip";
      $tempFile  = "$partsDir/$each";
      $tempResults = "Zip $tempFile/hidden to\n     $tempDir/$hiddenZipFile\n\n";
      $results = $results . $tempResults;
      if (-e "$tempDir/$hiddenZipFile" ) {
        # file exists! Error!
        print "ERROR: file, $tempDir/$hiddenZipFile already exists!\n";
        print "   This means part number $each\n";
        print "   conflicts with another in this list:\n";
        foreach $prod (@product_list) {
          print "     $prod\n";
          }
        &error_exit($cdromFilesDir);
        }
      print $tempResults;
      chdir("$tempFile");
      $zipCmd = "$zip -q -r $tempDir/$hiddenZipFile hidden";
      if ($ARCH eq "x86.Windows_NT") {
        # translate unix path separators "/" to "\"
        $zipCmd =~ tr/\//\\/;
        }
      $status = system("$zipCmd");
      chdir("$ORIGDIR");
      $status = $status >> 8;
      if ($status != 0) {
        print "ERROR: status = $status. Error doing zip\n$zipCmd\n";
        &error_exit($cdromFilesDir);
        }
      # Zip up the "special" dir and grab it too
      # Use the first 5 chars of the archStr and append "spc.zip"
      # to get the name of the zip file for the "special" directory.
      $specialZipFile = "$archStr";
      $specialZipFile =~ s/(^.....).*/$1/;
      $specialZipFile .= "spc.zip";
      $tempFile  = "$partsDir/$each";
      if (-d "$tempFile/special") {
        $tempResults = "Zip $tempFile/special to\n     $tempDir/$specialZipFile\n\n";
        $results = $results . $tempResults;
        if (-e "$tempDir/$specialZipFile" ) {
          # file exists! Error!
          print "ERROR: file, $tempDir/$specialZipFile already exists!\n";
          print "   This means part number $each\n";
          print "   conflicts with another in this list:\n";
          foreach $prod (@product_list) {
            print "     $prod\n";
            }
          &error_exit($cdromFilesDir);
          }
        print $tempResults;
        chdir("$tempFile");
        $zipCmd = "$zip -q -r $tempDir/$specialZipFile special";
        if ($ARCH eq "x86.Windows_NT") {
          # translate unix path separators "/" to "\"
          $zipCmd =~ tr/\//\\/;
          }
        $status = system("$zipCmd");
        chdir("$ORIGDIR");
        $status = $status >> 8;
        if ($status != 0) {
          print "ERROR: status = $status. Error doing zip\n$zipCmd\n";
          &error_exit($cdromFilesDir);
          }
        }
      }

    # Do not make trees with directory names of "hidden" or "special"
    # since the # names of files there are generally too long, like
    # the sources tree.  We made zip files of these dirs above.

    # Get the product directory path
    $prodDir = "$partsDir/$each";
    if (!opendir(CURDIR, $prodDir)) {
      print "Unable to open directory $prodDir, error = $!\n";
      &error_exit($cdromFilesDir);
      }
    $found = 0;
    for (;;) {
      $thisFile = readdir CURDIR;
      last if !defined($thisFile);
      next if (($thisFile eq ".") || ($thisFile eq "..") ||
               ($thisFile eq "hidden") || ($thisFile eq "special"));
      if (! $found) {
        $tempFile = $thisFile;
        $found = 1;
        }
      else {
        print "ERROR:  Found more than one dir in\n";
        print "   $prodDir\n";
        print "  found $tempFile and $thisFile\n";
        &error_exit($cdromFilesDir);
        }
      }
    if (! $found) {
      print "ERROR: no files or directories for part $each\n";
      print "  in directory $prodDir\n";
      &error_exit($cdromFilesDir);
      }
    closedir(CURDIR);

    $prodDir = "$prodDir/$tempFile";
    # copy or link each item in the product directory
    if ($longNamesOK != 0) {
      # Long names are just fine
      if ($makeLinks != 0) {
        $tempResults = "Linking files and directories\n" .
                   "   from $prodDir\n" .
                   "   to   $tempDir\n";
        print $tempResults;
        $results = $results . $tempResults;
        if (! &basiclink_tree("$tempDir", "$prodDir", $ARCH, 1)) {
          print "ERROR: unable to copy tree\n";
          print "      $prodDir\n";
          print "   to $tempDir\n";
          &error_exit($cdromFilesDir);
          }
        }
      else {
        $tempResults = "Copying files and directories\n" .
                   "   from $prodDir\n" .
                   "   to   $tempDir\n";
        print $tempResults;
        $results = $results . $tempResults;
        if (! &basiccopy_tree("$tempDir", "$prodDir", $ARCH, 1)) {
          print "ERROR: unable to copy tree\n";
          print "      $prodDir\n";
          print "   to $tempDir\n";
          &error_exit($cdromFilesDir);
          }
        }
      }
    else {
      # No long names allowed
      if ($makeLinks != 0) {
        $tempResults = "Linking files and directories\n" .
                   "   from $prodDir\n" .
                   "   to   $tempDir\n";
        print $tempResults;
        $results = $results . $tempResults;
        if (! &basiclink_tree("$tempDir", "$prodDir", $ARCH, 1)) {
          print "ERROR: unable to copy tree\n";
          print "      $prodDir\n";
          print "   to $tempDir\n";
          &error_exit($cdromFilesDir);
          }
        if( &check_file_names("$tempDir") != 2) {
          print "ERROR: not allowed to copy tree\n";
          print "      $prodDir\n";
          print "   to $tempDir\n";
          print " Some file or directory name(s) not in DOS format.\n";
          &error_exit($cdromFilesDir);
          }
        }
      else {
        $tempResults = "Copying files and directories\n" .
                   "   from $prodDir\n" .
                   "   to   $tempDir\n";
        print $tempResults;
        $results = $results . $tempResults;
        if (! &trunccopy_tree("$tempDir", "$prodDir", $ARCH, 1)) {
          print "ERROR: unable to copy tree\n";
          print "      $prodDir\n";
          print "   to $tempDir\n";
          &error_exit($cdromFilesDir);
          }
        }
      }
    print "\n";
    $tempResults = &name_for_product($each);
    print CONTENTS "product:  $tempResults";
    if ("$beCompat" ne "0") {
      print CONTENTS " with $beCompat";
      }
    print CONTENTS "\r\n";
    if (&is_unix_product($targetArch)) {
      print CONTENTS "path:     $tempDirRelative/";
      }
    else {
      # Change forward slashes "/" to backslashes "\" for PC products
      $fixedPath = $tempDirRelative;
      $fixedPath =~ s/\//\\/g;
      print CONTENTS "path:     $fixedPath\\";
      }
    if (-e "$tempDir/$archStr.zip") {
      print CONTENTS "$archStr.zip";
      }
    else {
      print CONTENTS "*.*";
      }
    print CONTENTS "\r\n\r\n";
    $doneWork = 1;

    if ($doneWork == 0) {
      # Did not put this product in the tree! Error!
      print "ERROR: did not put product $each in the tree.\n";
      print "   Something is very wrong\n";
      &error_exit($cdromFilesDir);
      }
    } # foreach $each (@product_list)

  close(CONTENTS);

  &append_to_readme_file($cdromFilesReadme, $dateStr);

#  # Copy the unzip executables.
#  $tempResults = "Copying the unzip executables\n";
#  print $tempResults;
#  $results = $results . $tempResults;
#  $tempDir = "$cdromFilesDir/utils";
#  if (! mkdir("$tempDir", 0755)) {
#    print "ERROR: unable to create directory $tempDir; errno = $!\n";
#    &error_exit($cdromFilesDir);
#    }
#  # Just do Solaris and NT for now.  Add HPUX and AIX later, when needed.
#  foreach $each (10,11) {
#    if (&translateNumToDirStr($each,*archStrMapping,$archStrMapWidth,
#                                                     $cdromMedia, *archStr)) {
#      print "$0 error: don't know how to pick archStr for\n";
#      print "    target arch: \"$each\"\n";
#      &error_exit($cdromFilesDir);
#      }
#    $ext = "";
#    if ($each == 11) {
#      $ext = ".exe";
#      }
#    $archStr = &trunc_filename($archStr);
#    $archStr =~ tr/A-Z/a-z/;
#    if (! mkdir("$tempDir/$archStr", 0755)) {
#      &error_exit($cdromFilesDir);
#      }
#    $destFile = "$tempDir/$archStr/unzip$ext";
#    $srcFile="$shipUtilsDir/$archStr/unzip$ext";
#    if (! &basic_copy("$srcFile", "$destFile", $ARCH, 0)) {
#      print "ERROR: unable to copy file\n";
#      print "      $srcFile\n";
#      print "   to $destFile\n";
#      &error_exit($cdromFilesDir);
#      }
#    }

  $endTime = time;
  $endTimeStr = &my_ctime($endTime);
  chop($endTimeStr);
  $tempResults = "End time is $endTimeStr\n";
  print $tempResults;
  $results = $results . $tempResults;
  $tempResults = "Time elapsed = " . int($endTime - $startTime + 0.5)
                   . " sec\n";
  print $tempResults;
  $results = $results . $tempResults;
  &add_to_log("collectprods.pl", "cd dirs", $cdromDirName, $results,
               *product_names, *product_list);
  return(0);
  }

