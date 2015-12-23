#! /usr/bin/perl5
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - mailkey.pl
#
# Purpose - To build, email, and print GemStone keyfiles
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

if (("$ARCH" ne "sparc.SunOS4") && ("$ARCH" ne "sparc.Solaris") 
    && ("$ARCH" ne "hppa.hpux")) {
  print "ERROR:  This script must be run on a sparc or an HP\n";
  exit 1;
  }

sub output_text_and_keyfile {
  # the filehandle "OUT" must already be open
  local($text, $keyFilePath) = @_;
  local($line);

  print OUT "$text";
  open(KEY, "<$keyFilePath")
        || die "unable to read $keyFilePath";
  for (;;) {
    $line = <KEY>;
    last if !defined($line);
    print OUT "$line";
    }
  close(KEY);
  print OUT "_______________________________________________________________\n";
  print OUT "Steve Shervey                  GemStone Systems, Inc.\n";
  print OUT "Technical Support              1260 NW Waterhouse, Suite 200\n";
  print OUT "steve.shervey\@gemstone.com    Beaverton, OR  97006\n";
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

#-------------------------------------------------------
# End of boiler plate, begin of real work

$givenPartNum = $ARGV[0];
if ($givenPartNum eq "") {
  print "$0\[Info\]:  Usage:  $0 <part-num>\n";
  exit 1;
  }
if (! -d "$partsDir/$givenPartNum") {
  print "$0\[Error\]:  No such part $givenPartNum\n";
  exit 1;
  }

$makekeyCmd = "$SCRIPTDIR/makekey.pl $givenPartNum";
if (0 != system($makekeyCmd)) {
  print "$0\[Error\]:  Error occurred during makekey.pl.  Exiting...\n";
  exit 1;
  }

$emailText="";
$emailAddress="";
$emailSubject="";
print "Do you want to send this keyfile via email?  [y] ";
$prompt = <STDIN>;
chop($prompt);
if ($prompt eq "y" || $prompt eq "Y" || $prompt eq "") {
  $cmd = "/usr/ucb/mail";
  if ( ! -e $cmd ) {
    $cmd = "/bin/mailx";
    if ( ! -e $cmd ) {
      $cmd = "/usr/bin/mailx";
      if ( ! -e $cmd ) {
        $cmd = "";
        }
      }
    }
  if ("$cmd" eq "") {
    print "WARNING:  can not send mail from this host.  Keyfile not sent!\n";
    }
  else {
    while ("$emailAddress" eq "") {
      print "  Send to: ";
      $prompt = <STDIN>;
      chop($prompt);
      # remove leading and trailing whitespace if any
      $prompt =~ s/\s*(.*)\s*$/$1/;
      $emailAddress=$prompt;
      }
    while ("$emailSubject" eq "") {
      print "  Subject: ";
      $prompt = <STDIN>;
      chop($prompt);
      # remove leading and trailing whitespace if any
      $prompt =~ s/\s*(.*)\s*$/$1/;
      $emailSubject=$prompt;
      }
    $done = 0;
    while (! $done) {
      $prompt="";
      $emailText = "";
      print "  Enter email message text.  ";
      print "A line with just a '.' ends the text.\n";
      while ("$prompt" ne ".") {
        print "  ? ";
        $prompt = <STDIN>;
        chop($prompt);
        if ("$prompt" ne ".") {
          $emailText .= $prompt . "\n";
          }
        }
      $emailText .= "-----------------\n";
      print "Above text is OK ?  [y] ";
      $prompt = <STDIN>;
      chop($prompt);
      if ($prompt eq "y" || $prompt eq "Y" || $prompt eq "") {
        $done = 1;
        }
      }
    print "Really send email to $emailAddress,$keyFileMeister ?  [y] ";
    $prompt = <STDIN>;
    chop($prompt);
    if ($prompt eq "y" || $prompt eq "Y" || $prompt eq "") {
      $cmd .= " -s \"$emailSubject\" $emailAddress,$keyFileMeister";
      open (OUT, "|$cmd") || die "unable to start email command $cmd";
      &output_text_and_keyfile("$emailText", "$newKeyDir/$keyFileName");
      close(OUT);
      }
    else {
      print "  Not sending email after all.\n";
      }
    }
  }
else {
  print "  Not sending email.\n";
  }

print "Do you want to print this keyfile?  [n] ";
$prompt = <STDIN>;
chop($prompt);
if ($prompt eq "y" || $prompt eq "Y") {
  open (OUT, "|lpr") || die "unable to start lpr command";
  print OUT "Keyfile sent to $emailAddress\n";
  print OUT "Subject: $emailSubject\n";
  $now = &my_ctime(time);
  print OUT "Date: $now\n";
  &output_text_and_keyfile("$emailText", "$newKeyDir/$keyFileName");
  close(OUT);
  }
else {
  print "  Not printing keyfile.\n";
  }

exit 0;
