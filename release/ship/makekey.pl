#!/bin/perl
#
# lu Usages:
#   lu daysToDate <numDays>
#     Prints out a license expiration date string that will cause a
#     license generated right now to be good for at least <numDays>.
#     The date returned will always be 10 AM PST.
#     The date returned will never fall on a Friday, Saturday, or Sunday.
# 
#   lu signLicense <propFile1> <propFile2> ... <propFileN>
#     Signs each of the specified license property files and outputs them
#     to a single file named "gemfireLicense.zip" that it creates in
#     the current directory. If a "gemfireLicense.zip" already exists
#     it will be deleted.
# 
# Required License Properties:
# Each license property file must contain these required properties:
#   product, platform, license-type, license-version,
#   customer-id, customer-name, group-id
# 
# Each license property file may contain these optional properties:
#   date, node, native-node, cpus, and purchased-cpus
# 
# The following defines each property:
# 
# product: The name of the licensed product. Currently the only
#   legal value is "GemFire".
# 
# platform: The name of the operating system platform the license is
#   for. Legal values are: "Solaris", "Linux", "Windows", and "ANY".
# 
# license-type: The type of the license.
#   Legal values are: "evaluation", "development", and "production".
# 
# license-version: The license version supported by the product to be
#   licensed. This must be equal to the value of the ant
#   "license.version" in build.xml. I product's license-version can
#   be determined by running its "gemfire license" command.
#  
# customer-id: A unique id, assigned by GemStone, that can be any string.
#   We should try to not change this, for a given customer, because
#   licenses with different customer-id's will refuse to talk to each other.
# 
# customer-name: A symbolic name that describes who the customer is.
#   Can be any string. Can be changed if the customer requests without
#   license compatibility issues.
# 
# group-id: Must be a number. It should start at "1" and be incremented
#   anytime the customer wants to change an existing license or delete
#   a license. For example they may have a node locked license to host
#   FOO and want to change it so it will license host BAR. Or they may
#   want to reduce the CPU limit. Or they may want to no longer buy a
#   license for FOO but still get licenses for their other hosts.
# 
# Each member of a distributed gemfire system must have a license before
# it can join. All the members of a given distributed gemfire system
# must have the same value for the following license properties:
#   customer-id, group-id, and license-type.
#
# CHANGES TO LICENSING FOR v6.5
#
# The main reason we are adding the client-limit is that that it can be set
# to zero allowing our evaluation license to not allow any clients.
#
# client-limit: Must be a number or not set. The new client-limit will 
#   limit how many clients can connect to a GemFire cache server. If 
#   it is set to zero then no clients will be allowed. If it is not set 
#   at all (old licenses) then an unlimited number of clients will be allowed.
#
# member-limit: Must be a number or not set. The old member-limit will now 
#   only limit the number of peers/servers that can exist in a distributed 
#   system. It will no longer limit clients. It is still true that a 
#   member-limit of zero means unlimited. It is also still true that a 
#   member-limit of -1 means that no peers are allowed (and thus should 
#   be used for client only licenses).
#
# If an older license is found by 6.5 it will not have the new client-limit
# and will thus allow any number of clients to connect. Since we never
# issued a pre 6.5 license that used the member-limit to limit clients this
# should be ok.
#
# Optional License Properties:
# 
# date: If specified it is the date on which the license will no longer be
#   valid. If not specified the license never runs out.
#   The value must be in the format "YYYY/MM/DD H oclock a, z"
#   where YYYY are digits representing the year,
#   MM are digits representing the month,
#   DD are digits representing the day of the month,
#   H is a digit or digits in the range 1-12 representing the hour of
#   the day, 
#   a is either AM or PM,
#   and z is the timezone (for example PST).
# 
# node: Locks the license to one or more nodes based on IP address or
#   host name. Care must be taken to not use an IP address if the
#   customer is using DHCP and thus does not have a static IP address.
#   Legal values are obtained by running "gemfire license" on
#   the machine to which the license will be locked.
#   This property can be a list of ip addresses or host names in which
#   case the license is valid on any of those nodes. Its also possible
#   for an ip address or host name to contain "*" characters in which
#   case any ip address or host name that matches the pattern will
#   accept the license. For example "10.80.10.*".
# 
# native-node: Locks the license to a single node. Native code is used
#   so this property will only work for code that is not running in pure
#   java mode.
#   Legal values are obtained by running "gemfire license" on
#   the machine to which the license will be locked.
# 
# cpus: If specified causes the license to only work
#   on machines whose cpu could is less than or equal to this value.
#   If unspecified then no cpu limit.
#   Legal values must be a whole number greater than zero.
# 
# purchased-cpus: If specified indicates the number of cpus actually
#   purchased. If unspecified then its the same as "cpus".
# 
#-------------------------------------------------------------
#
# todo: bullet proof prompts to repeat question if response is bad
# todo: reissue of development licenses with new sunset
# todo: reissue of licenses with new license version
# todo: for numeric answers confirm they are numbers 

use File::Basename;
use File::Find();
use Config;

# Make stderr and stdout unbuffered.
select(STDERR); $| = 1;
select(STDOUT); $| = 1;

#-------------------------------------------------------------
# make perl -w quiet
$path = $first; 
$license_version = $path;
$IP = "foo";
$zipout = "foo";
$stat = "foo"; 
$fulldir = "foo";

#-------------------------------------------------------------
# Define TopDir for base for generation of property file and licenses

local($okIfExists, $TopDir, $CustDir, $TempDir);                      

# For future use 
$okIfExists=1;
 
# TopDir is whether this script is being run from
$TopDir = `pwd`; 
chomp($TopDir);

# ArchDir is typically a directory named archive but it can be named anything
$ArchDir = "archive"; 
$FullArchDir = "$TopDir/$ArchDir"; 

if ((-d "$ArchDir") && ($okIfExists == 1)) {
  #print "Found directory $ArchDir\n";
  }

elsif (!mkdir($ArchDir, 0755)) {
   die "Unable to create directory $ArchDir, error = $!\n";
}

#-------------------------------------------------------------
# set GEMFIRE so that messages get generated correctly
$GEMFIRE = "$TopDir/product";
$ENV{'GEMFIRE'} = $GEMFIRE;
my $baseJDK = "/export/gcm/where/jdk/1.6.0_12";
if( $Config{'osname'} =~ /linux/ ) {
  $ENV{'GF_JAVA'} = "$baseJDK/x86.linux/bin/java";
} elsif ( $Config{'osname'} =~ /solaris/ ) {
  $ENV{'GF_JAVA'} = "$baseJDK/sparc.Solaris/bin/java";
} else {
  die "Unknown platform " . $Config{'osname'};
}

$lucmd = "$GEMFIRE/../hidden/bin/lu";
if (! -x "$lucmd") {
  print "Error:  No executable $lucmd\n";
  die ;
  }

$gemfirecmd = "$GEMFIRE/bin/gemfire";
if (! -x "$gemfirecmd") {
  print "Error:  No executable $gemfirecmd\n";
  die ;
  }

#-------------------------------------------------------------
# Define license variables and default values 

local ($license_version, $platform, $custID, $custName, $node); 
local ($sunsetDate, $nNode, $licType);
local ($numCpus, $purch_cpus, $product, $group_id);
local ($client_limit, $member_limit);

$product = "GemFire";

$custID = "";
$custName = "";

$node = "";
$nNode= ""; 
$platform = ""; 

$licType = "";
$sunsetDate = "";

$purch_cpus = "";
$numCpus = "";

$client_limit = "";
$member_limit = "";

$group_id = "1";

#-------------------------------------------------------------
# Initial default values for some variables
$license_version = "3.0";
local ( $gid, $hid); 
$rdytosign=0;
$status=0; 
$rollgid=0;
$syncgid=0;
$chkgidstatus=0;
$findflag=0;


#-------------------------------------------------------------
#todo need to ask what license version and use this in the archive subdirectory
#todo need license version to control what trees we run the gemfire and lu commands from

#%lic_vers = (  
#  "1", "3.0Beta",
#   );
#$license_version = "$lic_vers{$prompt}";
#
#%gemfire_path = (  
#  "3.0Beta", "/ship5/users/ship/shipgfv10/test/product",
#   );
#
#$GEMFIRE = "$gemfire_path{$prompt}";

#-------------------------------------------------------------
# Start with customer number as every archive requires it for naming
#

# Or hit return to list existing customers and license names.

while ( $findone == "0") {
  print "\nEnter the GemStone customer license number or hit return";
  print "\nto see a list of existing customers numbers and names.\n ";
  print "\nCustomer ID: ";
  $prompt = <STDIN>;
  chop($prompt);
  $prompt =~ s/"/\\"/g;

  if ($prompt eq "") {
    @custlist=&find_ids( "$ArchDir") ;
    @sorted=sort bynumber @custlist;
    print "\nCustomer ID: Customer Name \n";
    print "---------------------------\n"; 
    print @sorted;

  } else {

  $findone = "1";
  $custID = $prompt; 
  }

}

#-------------------------------------------------------------
# Try and find an existing archive for this customer
#

eval( "\$status = 1 if &find_license" );
&message("top", "find_license status was $status");

# If the status is 1 there wasn't an existing archive and collect customer
# id information to allow the archive to get created. 
if ($status == 1) {
  
  $TempDir = "$CustDir/tmp"; 
  if ((-d "$TempDir") && ($okIfExists == 1)) {
    #print "Found existing TempDir $TempDir\n";
  } elsif (!mkdir($TempDir, 0755)) {
     die "Unable to create directory $TempDir, error = $!\n";
  }

  # -------------------------------------------------
  # License wasn't found so go do new license stuff
  # Prompt for base answers to determine where to put log and 
  # property files based on customer license number
  
  &startRedirect( "$FullArchDir/$custID/makekey.log" );
  print "# =============================================\n";
  print "# STARTING UP for Customer ID: $custID\n";
  print "# Time: " . &pretty_time(time) . "\n";
  &endRedirect;
  
  print "\nWhat is the official customer name? ";
  $prompt = <STDIN>;
  chop($prompt);
  $prompt =~ s/"/\\"/g;
  $custName = $prompt;
  &message( "top", "Customer name entered: $custName" );
  
  # -------------------------------------------------
  # We now have started a makekey log under the customer number.
  #
  
  local($another);
  $another = "0";
  
  while ( $another == "0") {

    &start_new_license; 

    print "\nDo you want to generate another license property file? [y/n] ";
    $prompt = <STDIN>;
    chomp($prompt);
      if (($prompt eq "y") || ($prompt eq "Y")) {
        &message( "top", "Starting generation of another license." );
      } else {
        $another="1";
      } 
  
  }

  $rdytosign=1;
  
} else {

  $TempDir = "$CustDir/tmp"; 

  $another="0";
  while ( $another == "0") { 
    print "\nWhat do you want to do with this customer's license(s)? ";
    print "\n[m]odify, [a]dd, [d]elete, [l]ist all properties or [q]uit? [m,a,d,l,q] ";
    $prompt = <STDIN>;
    chop($prompt);
    $action=$prompt;

    &list_licenses; 

    if ("$action" eq "q") {
      # Clean up TempDir
      chdir $TopDir;
      &removeTree("$TempDir");
      exit 0; 

    } elsif ("$action" eq "l") {
      &dump_license("$CustDir/gemfireLicense.zip");

    } else { 
      if ("$action" eq "m") { 
        $action = "modify";
        &modify_license;

        # Force roll of group-id on changes of this type
        $rollgid=1;

      } elsif ("$action" eq "a") {
        $action = "add";
        &add_license;
        # Sync the group-id but don't roll
        $syncgid=1;

      } elsif ("$action" eq "d") {
        $action = "delete";
        &delete_license;
        # Force roll of group-id on changes of this type
        $rollgid=1;

      } else {
          print "\nERROR, unknown answer $action. Try again...\n\n";
      }

      print "\nDo you want to make more changes before signing? [y/n] ";
      $prompt = <STDIN>;
      chomp($prompt);
      if (($prompt eq "y") || ($prompt eq "Y")) {
        &message( "top", "Starting generation of another license." );
      } else {
        $another="1"; 
      }
    }
  }

  $rdytosign=1;

} 

#-------------------------------------------------------------
# All changes have been made so prepare to sign the license

local( $sstatus, $list ); 

if ($rdytosign == 1) {

  # Make a the list of license property files for this customer 
  local( @filenames ) = &findLicFiles( "$TempDir" );

  # All pre-sign checks should be called here
  # Check group-ids; if inconsistant then force a sync to make them match
  #
  eval( "\$chkgidstatus = 1 if &check_gid" );
  if ($chkgidstatus == 1) {
    $syncgid = 1;
  }

  # sync_gid checks the group-ids for consistancy. If there is an inconsistancy
  # then it rolls the highest group-id by one and resets all the licenses to
  # use that new group-id number.
  #if (($rollgid == 1) && ($hid != 1)) {
  if ($rollgid == 1) {
    $hid++;
    print "\nInfo: Preparing to roll group-id to $hid...\n";
  }

  if ($hid != 1) {
    print "\nRolling the group-id adds security for revoking licenses.";
    print "\n\nBy default the group-id should always increment but for some ";
    print "\ncustomers (Bear) we want the group-id to remain unchanged. ";
    print "\nChoose yes unless you know this license's group-id must not change.";
    print "\n ";
    print "\nDo you want to roll and sync the group-id? [y/n] ";
    $prompt = <STDIN>;
    chomp($prompt);

    if (($prompt eq "y") || ($prompt eq "Y")) {
      # If the highest group-id is still one then there is no need to sync as
      # new license group-ids are one by default.
      if ($hid != 1) {
        # sync_gid needs newValue defined to know what to set the group-ids to
        $newValue=$hid;
        &sync_gid;
      }
    }
  }

  chdir $TempDir;

  $list = `ls *.license`;

  print "\nThe following property files will be signed into a single zipfile. ";
  print "\n\n$list\n";
  print "Check that the above list is correct.";
  print "\nAre you ready to sign the license? [y/n] ";
  $prompt = <STDIN>;
  chomp($prompt);
  if (($prompt eq "y") || ($prompt eq "Y")) { 
    &startRedirect( "$FullArchDir/$custID/makekey.log" );
    print "# -----------\n";
    print "# Subroutine: sign_license\n";
    print "# Time: " . &pretty_time(time) . "\n";
    print "# Confirmed list to sign:\n";
    print $list;
    &endRedirect;

  } else {

    chdir $TopDir;
    &removeTree("$TempDir");
    &message( "sign_license", "Bailed out of ready to sign license question. Exiting..." );
    print "\nBailing out!!";
    print "\nCleaning up tmpdir and exiting.";
    print "\nYou'll need to restart the script and try again.\n\n";
    exit 1;
  }

  print "\n";
  &message( "sign_license", "Attempting to sign License..." );

  #Strip out cr on the end to create a single line
  $list =~ s#\n# #g;

  $sstatus = "0";
  $sstatus = system("$GEMFIRE/../hidden/bin/lu signLicense $list");

  if ( $sstatus != 0) {
    &message( "sign_license", "signLicense returned FAILURE status of $sstatus" );
    print "\nlu signLicense returned FAILURE status of $sstatus\n";
    print "\nCheck log results at: $FullArchDir/$custID/makekey.log\n";
    print "\nNot cleaning tmp location: $FullArchDir/$custID/tmp\n";
    exit 1;

  } else {
    &message( "sign_license", "signLicense returned a PASS status of zero" );

    # Get out of TempDir so that we can clean it up if needed
    chdir $TopDir;

    # The signing takes place in the tmp directory so we can still 
    # save the original gemfireLicense.zip, if exists, to new name appending
    # the current date and time 

    &save_licenses; 

    print "\nSigning was successful! Dumping license...\n";
    &dump_license("$CustDir/gemfireLicense.zip"); 

    print "\nNew gemfireLicense.zip file created at:\n";
    print "   $TopDir/$CustDir/gemfireLicense.zip\n\n\n";

    if ( $cleanup == "yes" ) { 
      # Clean up TempDir
      chdir $TopDir;
      &removeTree("$TempDir");
    }

    exit 0;  
  }
}

#-------------------------------------------------------------
# Subroutines in no particular order
#-------------------------------------------------------------

sub bynumber { 
  $a <=> $b; 
}

sub save_licenses {

  $status=0;
  if (-f "$CustDir/gemfireLicense.zip") {

    # Name to archive old zip
    $OldCustZip = &dateAsExtension(time) . ".zip";
  
    &message( "save_licenses", "Found existing gemfireLicense.zip. Renaming it to $OldCustZip" );

    $status=&copyfile( "$CustDir/gemfireLicense.zip", "$CustDir/$OldCustZip" );
    if ($status != 0) {

    &message( "save_licenses", "Problem copying $CustDir/gemfireLicense.zip to $CustDir/$OldCustZip");

    die "\nFailure: copying $CustDir/gemfireLicense.zip to $CustDir/$OldCustZip\n";
    }
  }
  
  # Save new gemfireLicense.zip from tmp to archive
  &message( "save_licenses", "Copying $TempDir/gemfireLicense.zip to $CustDir/gemfireLicense.zip" );
  $status=&copyfile( "$TempDir/gemfireLicense.zip", "$CustDir/gemfireLicense.zip" );
  if ($status != 0) {
    &message( "sign_license", "Problem copying $TempDir/gemfireLicense.zip to $CustDir/gemfireLicense.zip." );
    print "\nFailure: copying $TempDir/gemfireLicense.zip to $CustDir/gemfireLicense.zip\n";
    $cleanup="no";
  }

}

sub sync_gid {

  foreach $file ( @filenames ) {

#todo: should also sync... 
#todo: product=GemFire
#todo: customer-name=
#todo: customer-id=

    undef @origProps;
    undef @newRollProps;
    @origProps=&loadProps( "$file" );

    &startRedirect( "$FullArchDir/$custID/makekey.log" );
    print "# -----------\n";
    print "# Subroutine: sync_gid\n";
    print "# Time: " . &pretty_time(time) . "\n";
    print "# File: $file \n";
    print "# sync'ing group-ids to $hid \n";
    &endRedirect;

    @newRollProps=&chgProp( "group-id=$newValue" );

    print "Listing new properties for $file:\n";
    print "\n";
    print @newRollProps;  
    print "\n";

    open(CHG, ">$file")
      || die "unable to write $PropFileName";
 
      foreach $item (@newRollProps) {
        print CHG "$item";
      }
    
    close(CHG);

  }

} 

sub check_gid {

  print "Checking license group-id for consistancy...";
  $hid=0; 
  foreach $file ( @filenames ) {
    @Props=&loadProps( "$file" );
    if( $file =~ m/^(((.*)(\/|\\))*.*)(\/|\\)(.*)$/ ) {
        $fulldir = $1;
        $propFile = $6;
    }
    foreach $item ( @Props ) {
      if ( $item =~ m/group-id\=/ ) {
        ( $prop, $value ) = split ('=', $item );
        chomp($value);
        if ( $hid lt $value ) { 
          while ( $value ne "$hid") { 
            $hid++;
          }
          #print "hid is $hid\n\n";
        } 
        push( @gidList, "${value}-${propFile}\n" );
      }
    }
  }

  foreach $item ( @gidList ) {
    ( $gid, $fn ) = split ('-', $item );
    if ( $gid ne $hid ) {
      print "\nFound inconsistancy in license $fn";
      print "\nForcing sync of group_ids...\n";
      return 1; 
    }
  }
  print "ok\n";
  return 0; 
}

sub getLicFiles {
    if ( $_ =~ m/^.*\.(license)$/ ) {
      push(@files, $File::Find::name);
    }
}

sub findLicFiles {
    local ( @files );
    local ( $file );
    &File::Find::find(\&getLicFiles, @_);
    return @files;
}

sub list_licenses {

  undef @licshortname; 
  undef @licfullpath; 
  local( @licfullpath ) = &findLicFiles( "$TempDir" ); 

  foreach $file ( @licfullpath ) {
    if( $file =~ m/^(((.*)(\/|\\))*.*)(\/|\\)(.*)$/ ) {
        $temp=$6;
        $temp =~ s#$#\n#;
        push( @licshortname, "$temp" ); 
    }
  }

}

sub add_license {
  &start_new_license;
}

sub modify_license {

  local ( @origProps, @modProps ); 
  local ( $chgdone ) = "0";  
  &list_licenses;

  print "\nWhich license do you want to modify? [y/n] ";   
  print "\nChoose from:\n ";
  print "@licshortname";
  print "\nLicense to modify: ";
  $prompt = <STDIN>;
  chomp($prompt);
  $mod_license="$prompt";

  if (-f "$TempDir/$mod_license") {

    &message( "modify_license", "Starting modification of $mod_license" );

    @origProps=&loadProps( "$TempDir/$mod_license" );
    &message( "modify_license", "Loaded properties" );

    &startRedirect( "$FullArchDir/$custID/makekey.log" );
    print "# -----------\n";
    print "# Subroutine: modify_license\n";
    print "# Time: " . &pretty_time(time) . "\n";
    print "# origProps array dump:\n";
    print @origProps;
    &endRedirect;

    print "\nListing properties for this license...\n\n";   
    print @origProps;
    print "\nValid properties that may not shown include:";
    print "\nmember-limit=<number>";
    print "\nValid properties post v6.5 include:";
    print "\nclient-limit=<number>";
    print "\nEnter property name and it's new value. (ie. platform=Solaris)";
    $prompt = <STDIN>;
    chomp($prompt);

    $newPropStr=$prompt; 
    $stat=( $pNameToChg, $newValue ) = split ('=', $newPropStr );

    if ( "$pNameToChg" ne "group-id" ) {
      &message( "modify_license", "Changing property $pNameToChg to $newValue" );
      @newProps=&chgProp( "$newPropStr" );

      if ( $chgdone == "1" ) {
        print "Listing new properties for $mod_license:\n";
        print "\n";
        print @newProps;
        print "\n";

        &startRedirect( "$FullArchDir/$custID/makekey.log" );
        print "# -----------\n";
        print "# Subroutine: modify_license\n";
        print "# Time: " . &pretty_time(time) . "\n";
        print "# modProps array dump:\n";
        print @modProps;
        &endRedirect;

        open(CHG, ">$TempDir/$mod_license") 
          || die "unable to write $PropFileName";
  
          foreach $item (@newProps) {
            print CHG "$item";
          }

        close(CHG);

        #Force roll of group-id before license is signed
        $rollgid=1;

      } else { 
        print "\nNo property change occurred for property named $pNameToChg\n";
        print "You must enter a valid and existing property name.\n";
        print "Check that the property name was correct and try again.\n";
      }

    } else { 
      print "\nProperty group-id is protected.";   
      print "\nThis script controls when to roll it.\n";   
      
    }

  }
#todo: Need an else here. What do we do if we can't find the license due to a typo? 
}


sub chgProp {

 local( $fullprop ) = @_;
 ( $pNameToChg, $newValue ) = split ('=', $fullprop );

#todo: Need to error if the property isn't existing.
#todo: how do we to confirm they provided a valid property?
  undef @modProps;
  foreach $item ( @origProps ) {
    if ( $item =~ m/(\=)/ ) {

      ( $prop, $value ) = split ('=', $item );

      # Try and protect group-id from being changed
      if (("$prop" ne "group-id") || ($rollgid == 1) || ($syncgid == 1)){
        if ( "$prop" eq "$pNameToChg" ) {
          $item = "$prop" . "\=$newValue\n";
          chomp($value);
          print "Changing property $prop from $value to $newValue \n\n";
          $chgdone = "1";
        # clear the signature since we're changing the property file
        } elsif ("$prop" eq "signed.properties.signature") {
          $item = "$prop" . "\=\n";
        }
      }
      push( @modProps, "$item" );
    } else {
      push( @modProps, "$item" );
    }
  }
  if("$pNameToChg" == "client-limit") {
    print "\nWarning: Found client-limit property. Make sure this license is to be used with GFE v6.5 or later.\n";
  }
  return @modProps;
}

sub delete_license {

  $delflag="0";
  while ( $delflag == "0") {
    &list_licenses;

    print "\nListing licenses...\n ";
    print "@licshortname";
    print "\nChoose license to delete: ";
    $prompt = <STDIN>;
    chomp($prompt);
    $license2delete="$prompt";
  
    if (-f "$TempDir/$license2delete") {
      print "\nFound $license2delete.";
      print "\nAre you sure you want to delete this license? [y/n] ";
      $prompt = <STDIN>;
      chomp($prompt);
      if (($prompt eq "y") || ($prompt eq "Y")) {
        print "\nDeleting $license2delete";
        unlink("$TempDir/$license2delete");
      } 

    } else {
      print "Unable to locate $license2delete. Try again...";
    }

    print "\nDo you want to delete another license property file? [y/n] ";
    $prompt = <STDIN>;
    chomp($prompt);
    if (($prompt eq "n") || ($prompt eq "N")) {
      $delflag = "1";
    }
  }

}

sub find_ids {

  local( $dir ) = @_;
  $Name = "XXX";
  $Numbr = "XXX";

  undef @allout;
  undef @CustNameList;
  open( FIND, "find $dir -name makekey.log -exec grep \"Customer name entered\" {} \\; -print |" );
  while( $line = <FIND> ) {
    push( @allout, $line );
  } 
  close( FIND );

  foreach $line ( @allout ) {
    if ( $line =~ m/# Customer name entered: (\w*.*)$/ ) { 
      $Name = $1;
    } elsif ( $line =~ m#/([^/]+)/makekey.log$# ) {
        $Numbr = $1;
    }
    if (( $Name ne "XXX" ) && ( $Numbr ne "XXX" )) {
      push( @CustNameList, "${Numbr} : ${Name}\n" );
      $cname = "$Name";
      $Name = "XXX";
      $Numbr = "XXX";
    } 
  }

  if ( $dir eq "$ArchDir" ) {
    return @CustNameList;
  } else { 
    return $cname;
  }
}

sub find_license {

  chdir $TopDir;

  while ( $findflag == "0") {

    open( FIND, "find $ArchDir -name $custID -print|" );
    while( $line = <FIND> ) {
      $CustDir = $line;
      chomp($CustDir);
    }
    close( FIND );

    if (-d "$CustDir") {
      print "\nFound existing Customer archive at: $CustDir";
      &unzip_license; 

      $custName=&find_ids( "$CustDir") ;

      print "\n\nOfficial customer name appears to be: $custName \n";
      print "\nIs this the correct customer? [y/n] ";
      $prompt = <STDIN>;
      chomp($prompt);

      if (($prompt eq "n") || ($prompt eq "N")) {
        print "\nDo you want to list all the customer IDs and their names? [y/n] ";
        $prompt = <STDIN>;
        chomp($prompt);
        if (($prompt eq "y") || ($prompt eq "Y")) {
          @custlist=&find_ids( "$ArchDir") ;
          print "\nCustomer ID: Customer Name \n";
          print "---------------------------\n";
          print @custlist;
        }

        print "\nEnter the GemStone customer license number or hit return to"; 
        print "\nuse the current customer ID and continue into modification.";
        print "\nCustomer ID: ";
        $prompt = <STDIN>;
        if (($prompt eq "\n") || ($prompt eq " \n")) {

          print "\nUsing existing Customer ID $custID"; 
          print "\nThis customer ID already exists. Dumping license...\n"; 
          &dump_license("$CustDir/gemfireLicense.zip");

          # We didn't find an existing archive 
          return 0; 

        } else {

          chop($prompt);
          $prompt =~ s/"/\\"/g;
          $custID = $prompt;
          $CustDir = "$ArchDir/$custID";
        }

      } elsif (($prompt eq "y") || ($prompt eq "Y")) {
        $findflag=1;
        return 0; 

      } else {
        print "\nCouldn't determine whether answer was yes or no.";
        print "\nRestart the script and try again.\n\n";
        exit 1; 

      }

    } else {

      print "\nUnable to locate an archive for $custID."; 
      print "\nAssuming $custID to be a new customer ID."; 

      print "\nIs this the correct? [y/n] ";
      $prompt = <STDIN>;
      chomp($prompt);

      if (($prompt eq "n") || ($prompt eq "N")) {
        print "You're using a customer number that yet doesn't exist.\n"; 
        print "You'll need to restart this script and start license \n"; 
        print "for a new customer we've hit a deadend.\n"; 
        exit 1; 
      }

      print "\nStarting new customer license generation...\n\n\n"; 
      # -------------------------------------------------
      # Define temp location for generation of property file and license

      $CustDir = "$ArchDir/$custID";
      if ((-d "$CustDir") && ($okIfExists == 1)) {
        print "Created Customer archive directory $CustDir\n"; 
        }

      elsif (!mkdir($CustDir, 0755)) {
        die "Unable to create directory $CustDir, error = $!\n";
      }

      $TempDir = "$CustDir/tmp";
      if ((-d "$TempDir") && ($okIfExists == 1)) {
        #&message("find_license", "TempDir is $TempDir");
        #print "TempDir is $TempDir\n";
        }

      elsif (!mkdir($TempDir, 0755)) {
        #&message("find_license", "Die:unable to create directory $TempDir");
        die "Unable to create directory $TempDir, error = $!\n";
      }

      # We didn't find an existing archive but we've now created one along
      # with a tmp directory. Set findflag to exit the loop and return a
      # one to indicate the archive was newly created and not found.    
      $findflag=1; 
      return 1; 

    }
  }

  print "\nDo you want to the license properties? [y/n] ";
  $prompt = <STDIN>;
  chomp($prompt);
  if (($prompt eq "y") || ($prompt eq "Y")) {
    &dump_license("$CustDir/gemfireLicense.zip"); 
  } 
}

sub unzip_license {

  $TempDir = "$CustDir/tmp"; 

  if ((-d "$TempDir") && ($okIfExists == 1)) {
    print "\n\nFound existing $TempDir";
    print "\nCleaning it to prepare for unzip...\n";
    &removeTree("$TempDir"); 
  }

  if (!mkdir($TempDir, 0755)) {
    die "Unable to create directory $TempDir, error = $!\n";
  }   

  print "\nUnzipping license file to: $TempDir";
  $zipout=`unzip $CustDir/gemfireLicense.zip -d $TempDir`;

}

sub get_custName {

  # open the property files and extract the customer name

  if( $line =~ m/# Customer name entered: (\w*)$/ ) {
    $test1 = $1;
  } elsif ( $line =~ m#/([^/]+)/makekey.log$# ) {
    $test2 = $1;
  } 
  push( @CustNameList, "${test2}: ${test1}\n" );
  print "Customer ID: Name \n";
  print @CustNameList;  

}
sub dump_license {

  local($filename) = @_;
  undef @licout;
  undef @goodstuff;
  local ($all_text);
  $all_text=`$GEMFIRE/bin/gemfire license -file=$filename`;
  $savetag = 0;
  @licout=`$GEMFIRE/bin/gemfire license -file=$filename`;
  
  foreach $line ( @licout ) { 
    if (( $line =~ m/^\s*$/ ) || ( $savetag == 1)) {
      $savetag = 1;
      push( @goodstuff, $line );
    }
  }  

  print @goodstuff;

  &startRedirect( "$FullArchDir/$custID/makekey.log" );
  print "# -----------\n";
  print "# Subroutine: dump_license\n";
  print "# Time: " . &pretty_time(time) . "\n";
  print "# License info for $filename\n";
  print @goodstuff;
  &endRedirect;

}

sub get_platform {

  %hosttypes = (
    "a", "ANY",
    "s", "Solaris",
    "w", "Windows",
    "l", "Linux"
    );

  $gpflag="0";

  if ( "$licType" ne "evaluation" ) {
    while ( $gpflag == "0") {
      print "\nWhat is the target system type?\n";
      print "Enter either [s]olaris, [l]inux, [w]indows, [a]ny: [s|l|w|a] ";
      $prompt = <STDIN>;
      chop($prompt);
      if ( ("$prompt" eq "s") || ("$prompt" eq "l") || ("$prompt" eq "w") || ("$prompt" eq "a")) {

        $platform = "$hosttypes{$prompt}";
        &message( "get_platform", "Setting platform type to $platform." );
        $gpflag="1";
      } else {
        &message( "get_platform", "ERROR, unknown system type $prompt. Try again..." );
        print "\nERROR, unknown system type $prompt. Try again...\n\n";
      }   

    }

  } else {
    # evaluations work on ANY platform
    $platform = "$hosttypes{a}";
  }
}

sub calc_eval_days {

  local($luout, $calcflag );
  $calcflag="0";

  while ( $calcflag == "0") {
    print "\nHow many days from now until expiration? [#]\n";
    $prompt = <STDIN>;
    chomp($prompt);
  
    $luout=`hidden/bin/lu daysToDate $prompt`;
    chomp($luout);
    print "\nThat sets the sunset date to $luout ";
    print "\nIs this date acceptable? [y/n] ";
    $prompt = <STDIN>;
    chomp($prompt);
    if (($prompt eq "y") || ($prompt eq "Y")) {
      $calcflag="1";
      $sunsetDate = $luout; 
      &message( "calc_eval_days", "Setting sunset date to $sunsetDate." );
    }
  }
}

sub make_prop_file { 

  if ( -f "$TempDir/$PropFileName") {
    print "\nFound a license property file of the same name already existing.";
    print "\nDo you want to continue and overwrite it? [y/n] ";
    $prompt = <STDIN>;
    chomp($prompt);
    if (($prompt eq "y") || ($prompt eq "Y")) {
      &message( "", "Found existing license property file named $TempDir/$PropFileName. Overwritting and continuing..." );
    } else {
      print "\nLicense property creation cancelled. To change an existing license try using modify.";
      print "\nTo change an existing license property file try using modify.\n ";
      return 1;
    }
  }

  &message( "make_prop_file", "writing property file named $PropFileName" );
  open(KEY, ">$TempDir/$PropFileName")
    || die "unable to write $PropFileName";

  print KEY "license-version=$license_version\n";
  print KEY "platform=$platform\n";
  print KEY "customer-id=$custID\n";
  print KEY "customer-name=$custName\n";
  print KEY "node=$node\n";
  print KEY "date=$sunsetDate\n";
  print KEY "native-node=$nNode\n";
  print KEY "license-type=$licType\n";
  print KEY "cpus=$numCpus\n";
  print KEY "purchased-cpus=$purch_cpus\n";
  print KEY "product=$product\n";
  print KEY "group-id=$group_id\n";
  close(KEY);
 
} 

sub get_node_info { 

  #
  # native-node: Locks the license to a single node. Native code is used
  #   so this property will only work for code that is not running in pure
  #   java mode.
  #   Legal values are obtained by running "gemfire license" on
  #   the machine to which the license will be locked.
  #
  # Example:
  # native-node=80e683c8 Sun_Microsystems-2162590664 08-00-20-e6-83-c8
  # native-node=pureJavaMode

  # Collect Native node info
  $natflag="0"; 
  while ( $natflag == "0") {
    print "\nWhat is the Native node data? ";
    $prompt = <STDIN>;
    chop($prompt);
    $prompt =~ s/"/\\"/g;
    $nNode = $prompt;

    print "\nFor Native node info you entered: $nNode";
    print "\nIs this correct? [y/n] ";
    $prompt = <STDIN>;
    chomp($prompt);
    if (($prompt eq "y") || ($prompt eq "Y")) {
      &message( "get_node_info", "setting nNode to $nNode" );
      $natflag="1";
    }
  } 

  # node: Locks the license to one or more nodes based on IP address or
  #   host name. Care must be taken to not use an IP address if the
  #   customer is using DHCP and thus does not have a static IP address.
  #   Legal values are obtained by running "gemfire license" on
  #   the machine to which the license will be locked.
  #   This property can be a list of ip addresses or host names in which
  #   case the license is valid on any of those nodes. Its also possible
  #   for an ip address or host name to contain "*" characters in which
  #   case any ip address or host name that matches the pattern will
  #   accept the license. For example "10.80.10.*".
  #
  # Example:
  # node=happy 10.80.10.74

#todo: if nNode is set to pureJavaMode then we must require an entry to node. 
#
# If nNode is set to something other then pureJavaMode then it's not
# neccesary to have an entry in node.  

  # Collect node info
  $nodeflag="0"; 
  while ( $nodeflag == "0") {
    print "\nPlease enter the node data: [nodename IP.Address] ";
    $prompt = <STDIN>;
    chop($prompt);
    $prompt =~ s/"/\\"/g;
    $node = $prompt;

    print "\nFor node info you entered: $node";
    print "\nIs this correct? [y/n] ";
    $prompt = <STDIN>;
    chomp($prompt);
    if (($prompt eq "y") || ($prompt eq "Y")) {
      &message( "get_node_info", "setting node to $node" );
      ( $hostname, $IP ) = split (' ', $node );

    $nodeflag="1";

    }
  }
}

sub get_cpu_info { 

  print "\nHow many CPUs does this node have? [#] ";
  $prompt = <STDIN>;
  chop($prompt);
  $numCpus = $prompt;
  &message( "get_cpu_info", "setting numCpus to $numCpus" );

  print "\nHow many CPUs did this customer purchase for this node? [#] ";
  $prompt = <STDIN>;
  chop($prompt);
  $purch_cpus = $prompt;
  &message( "get_cpu_info", "setting purch_cpus to $purch_cpus" );

}

sub start_new_license {

  print "\nIs this an [e]valuation, [n]odelocked, or [u]nlimited license? [e|n|u] ";
  $prompt = <STDIN>;
  chop($prompt);
  if (("$prompt" eq "e")) {
    &message( "start_new_license", "evaluation license choice" );
  
    $licType="evaluation";
    &get_platform; 

    # Leave off platform name if it's any
    if ("$platform" eq "Any") {
      $PropFileName = "${licType}.license";
    } else {
      $PropFileName = ${platform} . ".${licType}.license";
    }
  
    if ( -f "$TempDir/$PropFileName") {
  
      print "A ${platform} evaluation property file already exists.\n";
      print "Delete it and continue? [y/n] ";
      $prompt = <STDIN>;
      chomp($prompt);
      if (($prompt eq "y") || ($prompt eq "Y")) {
        &message( "start_new_license", "Found existing evaluation license. Deleting and continuing..." );
        unlink("$TempDir/$PropFileName");
        &calc_eval_days; 
        &make_prop_file;
      }

    } else {
      &calc_eval_days; 
      &make_prop_file;

    } 
  
  } elsif ("$prompt" eq "n") {
  
    #-------------------------------------------------------------
    # NODELOCK TYPE LICENSES
    #-------------------------------------------------------------
    # DO PRODUCTION HERE
    #
    print "\nIs this a [d]evelopment or [p]roduction License? [d|p] ";
    $prompt = <STDIN>;
    chop($prompt);
    if (("$prompt" eq "p")) {
      &message( "start_new_license", "production license choice" );
      $licType="production";
  
      &get_platform;
  
    #-------------------------------------------------------------
    # DO DEVELOPMENT HERE

    } elsif ("$prompt" eq "d") {
  
      &message( "start_new_license", "development license choice" );
      $licType="development";
  
      &get_platform;
  
      #For BearStearns order, no sunset date on development licenses
      #print "\nDevelopment licenses are sunset licenses.\n";
      #&calc_eval_days; 
  
    } else {
      print "\nUnknown value $prompt. Restart the script.\n";
      exit 1;
    }
  
    #-------------------------------------------------------------
    # DO COMMON NODELOCK LICENSE HERE
    
    &get_node_info;
    &get_cpu_info;

    $PropFileName = ${hostname} . ".${licType}.license";
  
    &make_prop_file;
  
  } elsif ("$prompt" eq "u") {

    print "\nIs this an unlimited [d]evelopment or [p]roduction License? [d|p] ";
    $prompt = <STDIN>;
    chop($prompt);
    if (("$prompt" eq "p")) {
      &message( "start_new_license", "unlimited production license choice" );
      $licType="production";
  
    } elsif ("$prompt" eq "d") {
  
      &message( "start_new_license", "unlimited development license choice" );
      $licType="development";

    } else {
      print "\nUnknown value $prompt. Restart the script.\n";
      exit 1;
    }

    &get_platform;
    $PropFileName = "unlimited" . "${platform}" . ".${licType}.license";
    &make_prop_file;

  } else {
    print "\nUnknown license type of $prompt\n";
    exit 1;
  
  }
}

sub loadProps { 
  local( $licpropfile ) = @_;  
  local( $line, @proplist );

  open( PROPS, "<$licpropfile" );
  while( !eof( PROPS ) ) { 
    $line = <PROPS>;
    push( @proplist, "$line" );
  }

  close( PROPS );
  return @proplist;

}     

sub pretty_time {
  local($time) = @_;
  local($[) = 0;
  local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
  local( $result );

  #- Some display translation arrays -#
  @ctime_DoW = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
  @ctime_MoY = ('Jan','Feb','Mar','Apr','May','Jun', 'Jul','Aug','Sep','Oct','Nov','Dec');

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
  $year += 1900;

  $result = sprintf("%s %d %s %4d %02d:%02d:%02d %s", $ctime_DoW[$wday], $mday, $ctime_MoY[$mon], $year, $hour, $min, $sec, $TZ);
  return $result;
}   


sub dateAsExtension {
  local($time) = @_;
  local($[) = 0;
  local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
  local( $result );

  # Determine what time zone is in effect.
  # Use GMT if TZ is defined as null, local time if TZ undefined.
  # There's no portable way to find the system default timezone.

  $TZ = defined($ENV{'TZ'}) ? ( $ENV{'TZ'} ? $ENV{'TZ'} : 'GMT' ) : '';
  ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
      ($TZ eq 'GMT') ? gmtime($time) : localtime($time);

  # fix month so it doesn't start with jan = 0
  $mon += 1;
  # $year += ($year < 70) ? 2000 : 1900; 
  $year += 1900;      # change #1.  Make it work in the year 2000.
  
  # change #2:  emit more standard text
   $result = sprintf("%4d%2.2d%2.2d_%02d:%02d", $year, $mon, $mday, $hour, $min );

  return $result;
} 

sub copyfile {
  local( $from, $to ) = @_;
  local( $buff );
  
  unless( open( FROM, "<$from" ) ) {
      print "Copy Failure: cannot open $from: $!";
      return 1;
  }
  unless( open( TO, ">$to" ) ) {
      print "Copy Failure: cannot create $to: $!";
      return 1;
  }
  
  binmode FROM;
  binmode TO;
  
  for (;;) {
    $junk = read(FROM, $buff, 16384);
    if (!defined($junk)) {
      &message("copyfile", "read failure: $!");
      return 1;
      }
    last if $junk == 0;
    print TO $buff;
    }
  close( TO );
  close( FROM );
  return 0;
}   

sub removeTree {
  local( $dir ) = @_;
  local( @files );
  if ( ! -d "$dir" ) {
    warn( "Directory not found: $dir\n" );
    return 0;
    }
  if (!opendir( DIR, "$dir" )) {
    warn( "opendir($dir) failure: $!\n" );
    return 0; 
    }
  @files = readdir(DIR);
  closedir( DIR );
  
  chmod(0777, "$dir") || warn "chmod failed on $dir: $!";
  while ( $#files != -1 ) {
    $item = shift( @files );
    next if $item eq "." || $item eq "..";

    if ( -l "$dir/$item" ) {
      unlink( "$dir/$item" ) || warn "unlink failed on $dir/$item";
      }
    elsif ( -d "$dir/$item" ) {
      chmod(0777, "$dir/$item") || warn "chmod failed on $dir/$item: $!";
      &removeTree( "$dir/$item" );
      }
    elsif ( -f "$dir/$item" ) {
      chmod(0777, "$dir/$item") || warn "chmod failed on $dir/$item: $!";
      unlink( "$dir/$item" ) || warn "unlink failed on $dir/$item";
      }
    }

  if ( -l $dir) {
    print "Retaining symbolic link $dir\n";
    }
  else {
    rmdir( "$dir" ) || warn "rmdir failed on $dir\n"; 
    }
  #return 0;
}   

#-----------------------------------------------------------------
# Redirect STDOUT and STDERR to the given file. Use endRedirect
# to restore output. This puts the logfile on a stack. endRedirect
# restores to the previous log file, or STDOUT if none.
#-----------------------------------------------------------------
sub startRedirect {
  local( $logfile ) = @_;
  if ( $#outputStack == -1 ) {
    # Duplicate STDOUT and STDERR so they can be restored.
    open( SAVEOUT, ">>&STDOUT" ) || &critical("Duplicating STDOUT");
    open( SAVEERR, ">>&STDERR" ) || &critical("Duplicating STDERR");
  select( SAVEOUT ); $| = 1;
  select( SAVEERR ); $| = 1;
  }
  push( @outputStack, $logfile );
  # Redirect STDOUT and STDERR to given logfile name.
  open( STDOUT, ">>$logfile" ) || &critical("Redirecting STDOUT to $logfile");
  open( STDERR, ">>&STDOUT" ) || &critical("Redirecting STDERR to STDOUT");
  # unbuffer these file handles for immediate flushing.
  select( STDERR ); $| = 1;
  select( STDOUT ); $| = 1;  
}       
      
#-----------------------------------------------------------------
# See startRedirect. restores to the previous log file, or STDOUT
# if none.
#-----------------------------------------------------------------
sub endRedirect {
  close( STDOUT );
  close( STDERR );
  pop( @outputStack );
  if ( $#outputStack == -1 ) {
    open( STDOUT, ">>&SAVEOUT" ) || &critical("Restoring STDOUT");
    open( STDERR, ">>&SAVEERR" ) || &critical("Restoring STDERR");
  } else {
    $outfile = $outputStack[$#outputStack];
    open( STDOUT, ">>$outfile" )
        || &critical("Redirecting STDOUT to $outfile");
    open( STDERR, ">>&STDOUT" )
        || &critical("Redirecting STDERR to STDOUT");
    select( STDERR ); $| = 1;
    select( STDOUT ); $| = 1;
  }
}   

sub message {
  local( $subrtn, $text ) = @_;
  &startRedirect( "$FullArchDir/$custID/makekey.log" );
  print "# -----------\n";
  print "# Subroutine: $subrtn\n";
  print "# Time: " . &pretty_time(time) . "\n";
  print "# $text\n";
  &endRedirect; 
  } 

