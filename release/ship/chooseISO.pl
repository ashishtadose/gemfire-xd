#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - chooseISO.pl
#
# Purpose - support for makecdrom
#
# $Id$
#
#=========================================================================


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
  "add iso image", "add_product(*product_names,*product_list)",
  "remove iso image", "remove_product(*product_names,*product_list)",
  "place holder", "show_choices(*product_names,*product_list)",
  "show status", "show_choices(*product_names,*product_list)",
  "make the CDRom dirs!", "exit",
  "quit (no creation)", "do_quit",
  );


# initialization
$cdromFilesDir = "";
@product_list = ();  # list of products
%product_names = (); # list of names for the above products

# Top-level control for acquiring user input
sub input_arguments {
  local($verified_arguments, $tmp_def_partnum);

  &add_product(*product_names,*product_list);

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
  print "CDRom dir path: $cdromFilesDir\n";
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
  if ($choice eq "exit") { # all done!!!!
    return 1;
    }
  if ($choice eq "") { # no valid choice
    return 0;
    }

  # Do the command, keep reading
  print "\n";
  eval "&" . $choice;
  return 0;
  }

sub chooseISO {
  local($isoPath, $tmpDir, $found, $thisFile);
  &input_arguments;
  &show_choices(*product_names, *product_list);

  if (scalar(@product_list) == 0) {
    print "No iso image selected.\n";
    return "";
    }

  if (scalar(@product_list) > 1) {
    print "Too many iso images selected.  Must choose only one.\n";
    return "";
    }

  # find the .iso file name
  $isoPath = "";
  $tmpDir  = "$partsDir/" . $product_list[0] . "/";
  $tmpDir .= "$product_names{$product_list[0]}";
  if (!opendir(THISDIR, $tmpDir)) {
    print "Unable to open directory $tmpDir, error = $!\n";
    return "";
    }
  $found = 0;
  for (;;) {
    $thisFile = readdir THISDIR;
    if (!defined($thisFile)) {
      last;
      }
    if (("$thisFile" eq ".") || ("$thisFile" eq "..")) {
      next;
      }
    if ("$thisFile" =~ /.iso$/i) {
      $found = 1;
      last;
      }
    }
  if ($found == 1) {
    $isoPath = "$tmpDir/$thisFile";
    return "$isoPath";
    }
  else {
    return "";
    }
  }

1;
