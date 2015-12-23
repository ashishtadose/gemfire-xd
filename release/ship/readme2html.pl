#! /usr/bin/perl5
#=========================================================================
# (c) Copyright 1996-2007, GemStone Systems, Inc. All Rights Reserved.
#=========================================================================
# Name - readme2html.pl
#
# Purpose - Makes a first cut at converting a GemStone readme for a patch
#           or release to an html file.
#
#    readme2html.pl <infile> <outfile> "<title string>"
#
# Reads <infile> and writes results to <outfile>, performing these
# actions along the way:
# 1) Puts the GemStone graphic at the top.
# 2) Puts "<title string>" into the title and header.
# 3) Lines that start with '!' or '#' characters are treated as comments
#     and are included in the html file as comments.
# 4) Uses bold text for each line that ends with a colon (":");
# 5) Indents all other lines, stripping leading spaces.
# 6) For lines that start with a 5 digit number, attempts to create
#     a link to a bugnote for a bug with that number.
# 7) Add a section with generic names, titles, and links for
#     files to download (to be changed/moved later by the user);
# 8) Add a dated footer with an email link to "support@gemstone.com".
#
# $Id$
#
#=========================================================================

print "$0: Initializing\n";
 
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
require "find.pl";

#=========================================================================
# Grab arguments

$inFile = "";
$outFile = "";
$titleStr = "";
sub usage {
print "Usage: $0 ...\n";
print "readme2html.pl <infile> <outfile> \"<title string>\"\n";
print "  Reads text file <infile> and converts it to html in\n";
print "  file <outfile>, putting \"<title string>\" in the title and header.\n";
}
if ( $ARGV[0] eq "" || $ARGV[1] eq "" || $ARGV[2] eq "" || $#ARGV != 2) {
  &usage;
  exit 1;
  }

$inFile = "$ARGV[0]";
shift;
$outFile = "$ARGV[0]";
shift;
$titleStr = "$ARGV[0]";
shift;

$get_line_eof = 0;       # used by sub get_line()
$finish_paragraph = 0;   # used by process_line()
$bugNotesDir = "/gcm/where/bugnotes";

if (!open(OUTFILE, ">" . $outFile)) {
  print "$0: unable to open output file $outFile.\n";
  print "error = $!\n";
  exit 1;
  }
if (!open(INFILE, "<" . $inFile)) {
  print "$0: unable to open input file $inFile.\n";
  print "error = $!\n";
  exit 1;
  }

# Define the header for the html file with the GemStone graphic,
# the title for the patch logger, and the title text.
$headerStr =
"<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML//EN//2.0\">\n" .
"<html><head>\n" .
"<!-- entire title including at least opening tag must be on one line -->\n" .
"<!-- for patch logger to figure out the title by grepping this file-->\n" .
"<title>" . $titleStr . "</title>\n" .
"<LINK REV=\"made\" HREF=\"mailto:webmaster\@gemstone.com\">\n" .
"</head><body bgcolor=\"#FFFFFF\">\n" .
"\n" .
"<IMG SRC =\"/Graphics/GemStone/gs256smal.gif\" " .
"ALT=\"GemStone Systems, Inc.\">\n" .
"\n" .
"<P><hr>\n" .
"\n" .
"<H1>" . $titleStr . "</H1>\n" .
"\n" .
"<DL>\n" .
"\n";

print OUTFILE $headerStr;

# process each line in the text file
for (;;) {
  ($newLine, $newLineNum) = &get_line;
  if ($newLine eq "eof") {
    last;
    }
  &process_line($newLine, $newLineNum);
  }

# Define a section for downloadable files
$downloadStr =
"<P>\n" .
"<DT>\n" .
"<b>Files to download:</b>\n" .
"<DD>\n" .
"download these files<BR>\n" .
"<P>\n" .
"<BLOCKQUOTE>\n" .
"<A HREF=\"file1.bbb\"><code>file1.bbb</code></A>\n" .
"        text describing file1<BR>\n" .
"<A HREF=\"file2.bbb\"><code>file2.bbb</code></A>\n" .
"        text describing file2<BR>\n" .
"<A HREF=\"file3.bbb\"><code>file3.bbb</code></A>\n" .
"        text describing file3<BR>\n" .
"</BLOCKQUOTE>\n";

print OUTFILE $downloadStr;

# Define the footer
$footerStr =
"</DL>\n" .
"\n" .
"\n" .
"<hr><P>\n" .
"\n" .
"<I> Last updated 04-Dec-96 by \n" .
"<A HREF=\"mailto:support\@gemstone.com\">support\@gemstone.com</A><BR>\n" .
"</I>\n" .
"\n" .
"</body>\n" .
"</html>\n";

print OUTFILE $footerStr;

if (!close(OUTFILE)) {
  print "$0: error closing $outFile.\n";
  print "  error = $!\n";
  }
if (!close(INFILE)) {
  print "$0: error closing $inFile.\n";
  print "  error = $!\n";
  }
print "$0:  Done\n";
exit 0;


sub get_line {
  local ($result);

  if ($get_line_eof) {
    return ("eof", -1);         # if called repeatedly at eof, return eof.
    }
  $result = <INFILE>;
  if (!defined($result)) {      # eof processing
    $get_line_eof = 1;
    return ("eof", -1);
    }
  chop($result);
  if (ord(substr($result, length($result) - 1, 1)) eq 13) {
    # reading a DOS-style file on Unix.
    chop($result);
    }
  return ($result,$.);
  }


sub process_line {
  local ($theLine, $lineNum) = @_;
  local ($bugNum, $bugNoteFile);

  $theLine =~ s/^\s*(.*)$/$1/;  # Strip leading white spaces
  $theLine =~ s/\</\&lt;/g;   # Change "<" chars to "&lt;" to keep html happy
  $theLine =~ s/\>/\&gt;/g;   # Change ">" chars to "&gt;" to keep html happy

  # If the line starts with a "#" or "!"
  # it is a comment line.  Make it an html comment.
  if (($theLine =~ /^#.*/) || ($theLine =~ /^!.*/)) {
    print OUTFILE "<!-- $theLine -->\n";
    return;
    }

  # If the line ends with a ":"
  # it is a paragraph header line.  Make it bold.
  if ($theLine =~ /^.*:$/) {
    if ($finish_paragraph) {
      print OUTFILE "<P>\n";
      }
    print OUTFILE "<DT>\n<b>$theLine</b>\n<DD>\n";
    $finish_paragraph = 1;
    return;
    }

  # If the line begins with a 5 digit number
  # it is a bug reference line.  See if we can link to a bugnote.
  if ($theLine =~ /^[0-9]{5} .*$/) {
    $bugNum = $theLine;
    $bugNum =~ s/^([0-9]{5}) .*$/$1/;
    $theLine =~ s/^[0-9]{5}( .*$)/$1/;
    $bugNoteFile = &findBugNoteFile($bugNum);
    if ("$bugNoteFile" eq "") {
      # no bugnote found, just use normal text
      print OUTFILE "$bugNum$theLine<BR>\n";
      }
    else {
      print OUTFILE "<A HREF=\"/Customers/Bugnotes/$bugNoteFile#$bugNum\">\n";
      print OUTFILE "$bugNum</A>$theLine<BR>\n";
      }
    return;
    }

  # Its just a normal text line.
  print OUTFILE "$theLine\n";
  return;
  }

sub findBugNoteFile {
  local ($bugNum) = @_;
  local (@fileList, $thisFile, $line);

  # Look in all the files in $bugNotesDir to find a line with
  # the string 'HREF="#xxxxx"' where xxxxx is the bug number.
  # If found, return the filename. Otherwise return "".

  # Get a list of the files we will search.
  if ( ! -e "$bugNotesDir" ) {
    print "ERROR: findBugNoteFile, directory $bugNotesDir does not exist\n";
    print "  error = $!\n";
    return "ERROR_ERROR_ERROR";
    }
  if (!opendir(THISDIR, $bugNotesDir)) {
    print "ERROR: findBugNoteFile, unable to open directory $bugNotesDir, error = $!\n";
    return "ERROR_ERROR_ERROR";
    }
  for (;;) {
    $thisFile = readdir THISDIR;
    if (!defined($thisFile)) {
      last;
      }
    if ($thisFile eq "." || $thisFile eq "..") {
      next;
      }
    if ($thisFile =~ /.*\.html$/) {
      # found a ".html" file, add it to the list
      if ( -l "$bugNotesDir/$thisFile") {
        push(@fileList, $thisFile);
        }
      elsif ( -f "$bugNotesDir/$thisFile") {
        push(@fileList, $thisFile);
        }
      }
    }
  closedir(THISDIR);


  foreach $thisFile (@fileList) {
    # Look in each file for the HREF line
    if (!open(TMPFILE, "<$bugNotesDir/$thisFile")) {
      print "ERROR: findBugNoteFile, cannot open $file: $!\n";
      return "ERROR_ERROR_ERROR";
      }
    for (;;) { # do a line
      $line = <TMPFILE>;
      last if !defined($line);
      if ($line =~ /.*HREF=\"\#$bugNum\".*/) {
        # found a match, return the filename where we found it
        close(TMPFILE);
        return "$thisFile";
        }
      }
    }

  # No match found.
  return "";
  }

