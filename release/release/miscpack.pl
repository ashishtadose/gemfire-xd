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

#----------------------------------------------------------------------------
# $Id$
#----------------------------------------------------------------------------

# Some packing list routines used in makeprod.pl and patch-it.pl

# Maps from filetypes to extensions
%UnixExtensions = ("obj", ".o", "exe", "", "lib", ".a", "dll", ".so",
    "text", "", "bin", "", "dir", "", "script", "");

%DosExtensions = ("obj", ".obj", "exe", ".exe", "lib", ".lib", "dll", ".dll",
    "text", "", "bin", "", "dir", "", "script", ".bat");

%MacExtensions = ("obj", "", "exe", "", "lib", "", "dll", "",
    "text", "", "bin", "", "dir", "", "script", "");

# File protection modes, maps from filetypes to Unix protection
%AllModes = ("obj", "444", "exe", "555", "lib", "444", "dll", "555",
        "text", "444", "bin", "444", "dir", "555", "script", "555");

# Give an include traceback (error handling)
sub tell_position {
  local ($i);

  print 
      "\n$0, near line $stacked_input_lineNums[0] in $stacked_input_files[0]\n";
  for ($i = 1; $i <= $#stacked_input_lineNums; $i ++) {
    print "  from line $stacked_input_lineNums[$i] in $stacked_input_files[$i]\n";
    }
  }

# Strip a word off the input.
# inputs: $text, $reason
# outputs: next word, remainder of text
sub loadWord {
  local ($theText, $reason) = @_;
  local ($newWord, $remainingText, $test);

  $newWord = $theText;
  $newWord =~ s/^\s*(\S+).*/$1/;
  $remainingText = $theText;
  $remainingText =~ s/^\s*\S+(.*)/$1/;
  if ($remainingText eq $theText) {
    $remainingText = "";
    }
  $test = $newWord;
  $test =~ s/(.).*/$1/;
  if (! $test) {
    &tell_position;
    print "$0:  empty word found when expected $reason\n";
    #&clean_and_die;
    return ("bogus", "");
    }
  return ($newWord, $remainingText);
  }

# parse an packing list line.
# input:  $inputLine
# returns: ($type, $comment, ...)
#   
# For each of the following $type's, the optional information is:
#  #:
#  mkdir: newdir
#  copy:  destName srcName fileType
#  if: perl-expr
#  endif:
#  else:
#  elsif: <perl-expr>
sub parse_packing_line {
  local ($theLine) = @_;
  local ($type, $comment);
  local ($field1, $field2, $field3, $field4);

  # is it a comment?
  if ( $theLine =~ /^\s*#.*/) {
    $theLine =~ s/^[^!]*!(.*)$/$1/; # Strip down to the text
    if ($theLine eq "") { # Kludge to allow blank lines
      $theLine = " ";
      }
    return ("#", $theLine);
    }

  # is it a visible comment?
  if ( $theLine =~ /^\s*!.*/) {
    $theLine =~ s/^[^!]*!(.*)$/$1/; # Strip down to the text
    if ($theLine eq "") { # Kludge to allow blank lines
      $theLine = " ";
      }
    return ("!", $theLine);
    }

  # How about a blank line?
  if ( $theLine =~ /^\s*$/) {
    return ("#", "");
    }
  
  # Crack the type off of the line.
  $type = $theLine;
  $type =~ s/^\s*(\S+)\s*.*$/$1/;
  $theLine =~ s/^\s*\S+\s*(.*)$/$1/;

  $type = &eval_string("$type");
  # Need to eval type, but if evals to nothing, treat as a comment
  if (!defined($type) || $type eq "") {
    return ("#", "");
    }

  if ( $type eq "mkdir" ) {
    # only field is name of directory.
    # permit a user comment on this line.
    ($field1, $field2) = &loadWord($theLine, "mkdir directory name");
    $comment = $theLine;
    $comment =~ s/^[^!]*!(.*)$/$1/;
    return ($type, $comment, $field1);
    }
  elsif ( $type eq "chmod") {
    # chmod file filetype protection
    # no comments
    ($field1, $field2) = &loadWord($theLine, "chmod file name");
    ($field2, $field3) = &loadWord($field2, "chmod file type");
    ($field3, $field4) = &loadWord($field3, "chmod file protection");
    return ($type, "", $field1, $field2, $field3);
    }
  elsif ( $type eq "help" || $type eq "say" || $type eq "die" ||
	$type eq "exec") {
    $field1 = $theLine;
    $field1 =~ s/^\s*$type\s(.*)$/$1/; # Just retain the text, incl. whitespace.
    return ($type, "", $field1);
    }
  elsif ( $type eq "dummy") {
    $field1 = $theLine;
    ($field1, $field2) = &loadWord($theLine, "file name");
    ($field2, $junk) = &loadWord($field2, "file type");
    return ($type, "", $field1, $field2);
    }
  elsif ( $type eq "define") {
    $field1 = $theLine;
    ($field1, $field2) = &loadWord($theLine, "define name");
#    ($field2, $junk) = &loadWord($field2, "define value");
    return ($type, "", $field1, $field2);
    }
  elsif ( $type eq "packing") {
    $field1 = $theLine;
    ($field1, $field2) = &loadWord($theLine, "packing name");
    return ($type, "", $field1);
    }
  elsif ( $type eq "include") {
    $field1 = $theLine;
    ($field1, $field2) = &loadWord($theLine, "include name");
    return ($type, "", $field1);
    }
  elsif ( $type eq "require") {
    $field1 = $theLine;
    $field1 =~ s/^\s*require\s+(.*)$/$1/; # Just retain the text.
    return ($type, "", $field1);
    }
  elsif ( $type eq "copy" || $type eq "hide" || $type eq "data" || $type eq "slink" || $type eq "copyifpresent" || $type eq "hideifpresent" ) {
    #  copy:  destName srcName fileType
    # permit a user comment on this line.
    ($field1, $field2) = &loadWord($theLine, "file destination name");
    ($field2, $field3) = &loadWord($field2, "file source name");
    ($field3, $junk) = &loadWord($field3, "file type");

    $comment = $theLine;
    $comment =~ s/^[^!]*!(.*)$/$1/;
    if ($comment eq $theLine) {
      $comment = "";
      }
    return ($type, $comment, $field1, $field2, $field3, $field4);
    }
  elsif ( ($type eq "if") || ($type eq "elsif") ) {
    # No user comments permitted, only field is an expression to evaluate
    return ($type, $theLine);
    }
  elsif ( ($type eq "endif") || ($type eq "else") ) {
    # no user comments permitted, no arguments returned.
    return ($type, "");
    }
  else {
    &tell_position;
    print "$0: unknown line type \"$type\"\n";
    #&clean_and_die;
    return ("eof");	# to kill it
    }
  }


# Conjure up a name (without preceding system directory info)
# inputs: ($name, $fileType, $forArch)
sub base_name {
  local ($name, $fileType, $forArch) = @_;
  local ($myExtension, $theArchType);

  $theArchType = $ArchExtensions{$forArch};

  # Get the extension.
  if ( $theArchType eq "unix") {
    $myExtension = $UnixExtensions{$fileType};
    }
  elsif ( $theArchType eq "dos") {
    $myExtension = $DosExtensions{$fileType};
    }
  elsif ( $theArchType eq "mac") {
    $myExtension = $MacExtensions{$fileType};
    }
  else {
    die "internal error in base_name, arch $theArchType\n";
    }
  if (!defined($myExtension)) {
    &tell_position;
    printf "$0:  unknown file type $fileType\n";
    # &clean_and_die;
    return "nosuch.fil";
    }

#  if ($forArch eq "dos") {
#    # Replace forward slashes with backslashes
#    $name =~ s#/#\\#g;
#    }
  return $name . $myExtension;
}


# Expand the name by using "eval".
sub eval_string {
  local ($in) = @_;
  local ($out, $quoted);

  if ($RUNNINGARCH eq "x86.os2" || $RUNNINGARCH eq "x86.Windows_NT") {
    $in =~ s%\\%/%g;    # don't allow backslashes for OS/2
    }
  $quoted = "\"" . $in . "\"";  # surround with quotation marks
  $out = eval $quoted;
  if ($@ ne "") {
    &tell_position;
    print("$0: expansion of \"$in\" failed.\n");
    print("  error text: $@\n");
    # &clean_and_die;
    return "";
    }
  return $out;
  }

# Die if the directory exists or cannot be created
sub mustBeNewDir {
  local($theName, $theType) = @_;

  if ( $theName eq "" ) {
    print "$0:  new directory name not given.\n";
    return 0;
    }
  if ( -d $theName) {
    if ($doingReinstall || $doingUpdate) {
      return 1;
    }
    print "$0:  $theType directory $theName already exists.\n";
    &error_exit; # NOT cleanup; it would delete the directory!
    }
  if (! &basic_mkdir($theName,0755)) {
    print "$0:  unable to create $theType directory $theName\n";
    &error_exit;
    }
  return 1;
  }

# Die if the directory does not exist
sub mustBeOldDir {
  local($theName, $theType) = @_;

  if ( $theName eq "" ) {
    return 0;
    }
  if (! -d $theName) {
    print "$0:  $theType directory $theName does not exist.\n";
    &error_exit;
    }
  return 1;
  }

# Die if the given file exists
sub mustBeNewFile {
  local($theName, $theType) = @_;

  if ($doingReinstall || $doingUpdate) {
    return 1;
  }
  if (-f $theName) {
    print "$0: $theType file $theName already exists.\n";
    &error_exit;
    }
  return 1;
  }

# Die if the given file does not exist
sub mustBeOldFile {
  local($theName, $theType) = @_;

  if ( $theName eq "" ) {
    return 0;
    }
  if (! -f $theName) {
    print "$0:  $theType file $theName does not exist.\n";
    &error_exit;
    }
  return 1;
  }

1;
