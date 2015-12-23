#! /bin/perl -w
# -------------------------------------
# Magic script for redirecting Eclipse and the support infrastructure
# for your current environment.
#
# Usage:
# 1.  cd to the top of your checkout.
# 2.  perl bin/eclipse/redirect.pl
#   (then follow the prompts)
# -------------------------------------


use Cwd;
use Config;
use Switch;

#constants for the replacement mode in &mangle
use constant KEY_VALUE => 1;
use constant SED       => 2;


my($SRC) = &mygetcwd();

# ----------------------------------------------------------------

# Basic sanity checks
if (! -d ".metadata" ) {
  print "ERROR: Please invoke this script from the top level of your checkout\n";
  exit 1;
  }

$settings = ".metadata/.plugins/org.eclipse.core.runtime/.settings";
if (! -d $settings ) {
  print "ERROR: How odd, no directory $settings\n";
  exit 1;
  }

my($resource_prefs) = "$settings/org.eclipse.core.resources.prefs";
if (! -f $resource_prefs) {
  print "ERROR: How odd, no file $resource_prefs\n";
  exit 1;
  }

my($jdt_prefs) = "$settings/org.eclipse.jdt.core.prefs";
if (! -f $jdt_prefs) {
  print "ERROR: How odd, no file $jdt_prefs\n";
  exit 1;
  }

print "\n";
print "If you have a standalone /gcm, specify it here.\n";
my($GCM) = $SRC;
#$GCM =~ s#^(.*)[/\\][^/\\]+#$1#;
#$GCM .= "/gemfire_jars";
#$GCM = "/export/frodo2/users/$USER/standalone";
$GCM = $ENV{'GCMDIR'} || "/gcm";
$GCM = &getDir("GCM", "$GCM", 0);

# Try to make a guess at OBJ_BASE, JDK
my($OBJ_BASE) = "";
my ($JDK);
my ($ECLIPSEJDK);
#my($kind) = $ENV{"HOSTTYPE"} . "." . $ENV{"OSTYPE"};
my($kind) = `bash -c "echo \$HOSTTYPE.\$OSTYPE"`;
$kind = lc($kind);
chomp($kind);
my($props) = "";
if ($kind eq "i686.cygwin") {
  $props = "buildwin.properties";
  }
elsif ($kind eq "i386.linux" || $kind eq "x86_64.linux" 
    || $kind eq "i386.linux-gnu"
    || $kind eq "i486.linux-gnu"
    || $kind eq "x86_64.linux-gnu"
    ) {
  $props = "buildlinux.properties";
  $JDK = "$GCM/where/jdk/1.5.0_17/x86.linux";
  $ECLIPSEJDK = "$GCM/where/jdk/1.6.0_7/x86.linux";
  }
elsif ($kind =~ /^sparc\.solaris.*/) {
  $props = "buildsol.properties";
  $JDK = "$GCM/where/jdk/1.5.0_17/sparc.Solaris";
  $ECLIPSEJDK = "$GCM/where/jdk/1.6.0_7/sparc.Solaris";
  }
elsif ($Config{'osname'} =~ /^darwin/) {
  $props = "buildmac.properties";
  $JDK = "/System/Library/Frameworks/JavaVM.framework/Versions/1.4.2/Home";
  $ECLIPSEJDK = "/System/Library/Frameworks/JavaVM.framework/Versions/1.5.0/Home";
  }
else {
  print "kind = $kind\n";
  $JDK = "$GCM/where/jdk/1.5.0_17/$kind";	# wild guess
  $ECLIPSEJDK = "$GCM/where/jdk/1.6.0_7/$kind";
  $props = "";
  }
if (-f $props) {
  if (open(IN, $props)) {
    my($line);
    for (;;) {
      $line = <IN>;
      last unless defined($line);
      chomp($line);
      next unless $line =~ /osbuild.dir=(.*)/;
      $OBJ_BASE = $1;
      last;
      }
    close IN;
    }
  }

for (;;) {
  print "\n";
  print "At this point you should have already done a build.sh.\n";
  print "Your results were placed in a build artifacts directory.\n";
  print "Please give us the name of that directory (OBJ_BASE)\n";
  $OBJ_BASE = &getDir("OBJ_BASE", $OBJ_BASE, 0);

  my($ok) = 1;
  $ok = $ok && -d $OBJ_BASE;
  $ok = $ok && -d "$OBJ_BASE/classes";
  $ok = $ok && -d "$OBJ_BASE/hidden";
  $ok = $ok && -d "$OBJ_BASE/product";
  if (!$ok) {
    print "Sorry, this does not seem to be the result of a build.\n";
    print "Please try again.\n";
    next;
    }
  last;
  }

for (;;) {
  print "\n";
  print "Now, we need to location of 1.5 JDK, for your tools.jar|classes.jar\n";
  $JDK = &getDir("JDK", $JDK, 0);

  my($ok) = 1;
  $ok = $ok && -d $JDK;
  $ok = $ok && (-d "$JDK/jre" || $Config{'osname'} =~ /^darwin/);
  $ok = $ok && -d "$JDK/lib";
  $ok = $ok && (-f "$JDK/lib/tools.jar" || -f "$JDK/../Classes/classes.jar");
  if (!$ok) {
    print "Sorry, this does not seem to be a Sun SDK.\n";
    print "Please try again.\n";
    next;
    }
  last;
  }

print "\n";
print "Finally, we need the location of an empty directory for your\n";
print "Eclipse build artifacts (ECLIPSE_BASE).  It should not be located\n";
print "underneath your source tree, nor may it be the same as your OBJ_BASE.\n";
# Encourage user to make ECLIPSE_BASE parallel to OBJ_BASE
my($ECLIPSE_BASE) = "${OBJ_BASE}_eclipse";
#$ECLIPSE_BASE =~ s#^(.*)[/\\][^/\\]+#$1#;
$ECLIPSE_BASE = &getDir("ECLIPSE_BASE", $ECLIPSE_BASE, 1);

&mangle($jdt_prefs, "JDK", $JDK, KEY_VALUE);
&mangle($jdt_prefs, "OBJ_BASE", $OBJ_BASE, KEY_VALUE);
&mangle($jdt_prefs, "GEMFIRE_JARS", $GCM, KEY_VALUE);
&mangle($jdt_prefs, "SRC", $SRC, KEY_VALUE);
print " ...successfully modified $jdt_prefs\n";

&mangle($resource_prefs, "OBJ_BASE", $OBJ_BASE, KEY_VALUE);
&mangle($resource_prefs, "ECLIPSE_BASE", $ECLIPSE_BASE, KEY_VALUE);
print " ...successfully modified $resource_prefs\n";

if ( $Config{'osname'} =~ /^darwin/ ) {
  &adjustClasspathForDarwin($SRC);
  print " ...modified classpath for darwin\n";
}

&copy("bin/eclipse/makeglimpse", "makeglimpse");
&copy("bin/eclipse/jgrep", "jgrep");
print " ...created glimpse scripts\n";

&copy("bin/eclipse/dunit.conf", "dunit.conf");

&copy("bin/eclipse/dunittest.sh", "dunittest.sh");
&mangle("dunittest.sh", "SRC", $SRC, KEY_VALUE);
chmod(0755, "dunittest.sh");
print " ...successfully modified dunittest.sh\n";

&copy("bin/eclipse/junittest.sh", "junittest.sh");
&mangle("junittest.sh", "SRC", $SRC, KEY_VALUE);
chmod(0755, "junittest.sh");
print " ...successfully modified junittest.sh\n";

&copy("bin/eclipse/mergelogs.sh", "mergelogs.sh");
&mangle("mergelogs.sh", "JDK", $JDK, KEY_VALUE);
&mangle("mergelogs.sh", "OBJ_BASE", $OBJ_BASE, KEY_VALUE);
chmod(0755, "mergelogs.sh");
print " ...successfully modified mergelogs.sh\n";

exit 0;


# ----------------------------------------------------------------

sub copy {
  my($src, $dest) = @_;

  open(IN, "<$src") || die "Cannot read $src: $!";
  open(OUT, ">$dest") || die "Cannot write $dest: $!";

  my($line);
  for (;;) {
    $line = <IN>;
    last unless defined($line);

    print OUT $line;
    }
  close IN;
  close OUT;
  }

# Return canonicalized hostname (remove /cygdrive nonsense)
sub mygetcwd {
  my($result) = &getcwd();

  if ($result =~ m#/cygdrive/(.)$#) {
    return "$1:";
    }
  $result =~ s#^/cygdrive/(.)/(.*)#$1:/$2#;
  return $result;
  }

# Canonicalize a filename.  Returns undef if error occurred
sub canonicalize {
  my($in) = @_;
  my($result);
  
  my($isWindows) = 0;
  if (-d "c:/") {
    $isWindows = 1;
    }

  if ($isWindows) {
    $in =~ s#\\#/#g;
    }
  my($dirName) = $in;
  my($baseName) = $in;

  $dirName =~ s#^(.+)[/][^/]+$#$1#;
  $baseName =~ s#^.+[/]([^/]+)$#$1#;
  if ($baseName eq $dirName) {
    $baseName = "";
    }

  if (!chdir($dirName)) {
    print "Parent directory $dirName does not exist: $!\n";
    chdir($SRC) || die "Could not return to home directory $SRC: $!";
    return undef;
    }
  $dirName = &mygetcwd();

  if ($isWindows) {
    $dirName =~ s#\\#/#g; # render into forward-slashes

    $dirName =~ s#/cygdrive/(\w)/(.*)#$1:/$2#; # /cygdrive/x/y --> x:/y
    $dirName =~ s#/cygdrive/(\w)$#$1:#;        # /cygdrive/x --> x:

    # Following comes from the legacy cygwin mounts on certain older
    # machines.  Yucch!
    $dirName =~ s#^/(\w)/(.*)#$1:/$2#; # /c/foo/bar --> c:/foo/bar
    $dirName =~ s#^/(\w)$#$1:#; # /c --> c:
    }

  $result = "$dirName/$baseName";
  chdir($SRC) || die "Could not return to home directory $SRC: $!";
  return $result;
  }


# Perform a string substitution on given file
sub mangle {
  my($file, $key, $newVal, $mode) = @_;
  my($tmp) = "${file}.tmp";

  open(IN, "<$file") || die "Cannot read input file $file: $!";
  open(OUT, ">$tmp") || die "Cannot write output file $tmp: $!";

  my($line);
  for (;;) {
    $line = <IN>;
    last if !defined($line);

    chomp($line);
    switch ($mode) {
      case KEY_VALUE { $line =~ s#\b$key\b=(.*)#$key=$newVal#; }
      case SED { $line =~ s#$key#$newVal#; }
      else { die "Unknown mode $mode"; }
    }
    print OUT "$line\n";
    }
  close IN;
  close OUT;

  rename($file, "${file}.bak") || die "Could not back up $file: $!";
  rename($tmp, $file) || die "Could not rename $tmp to $file: $!";
  (unlink("${file}.bak") == 1) || die "Could not delete $(file}.bak: $!";
  }

# The classpath settings are a little different for the mac
sub adjustClasspathForDarwin($) {
  my $SRC = shift;
  for my $dir (qw(src examples templates quickstart tests)) {
    my $classpathFile = "$SRC/$dir/.classpath";
    die "$classpathFile is missing" unless( -f "$classpathFile" );
    &mangle($classpathFile, "JDK/jre/lib", "JDK/lib", SED);
    &mangle($classpathFile, "JDK/lib/tools.jar", "JDK/../Classes/classes.jar", SED);
  }
  

}


sub getDir {
  my($prompt, $default, $mustBeNew) = @_;
  my($result);

  $default = "" unless defined($default);
  for (;;) {
    print "$prompt [$default]: ";
    $result = <STDIN>;
    chomp($result);

    if ($result eq "") {
      $result = $default;
      }
    if ($result eq "") {
      print "Sorry, an empty string will not suffice.\n";
      next;
      }


    $result = &canonicalize($result);
    next unless defined($result);
    print "Canonicalized name is \"$result\"\n";
    print "OK? [y] ";
    my($ans);
    $ans = <STDIN>;
    chomp($ans);
    if ($ans ne "" && $ans !~ /^y/i) {
      print "OK, let's try again\n";
      next;
      }

    # Jump through some hoops to canonicalize
    if ($mustBeNew) { # must not exist
      if (-d $result) {
        print "Directory \"$result\" exists; OK to delete?\n";
        print "[Enter a 'y' to force a delete ] ";
        $ans = <STDIN>;
        chomp($ans);
        if ($ans !~ /^y/i) { # don't allow empty response
          print "All right, let's try again...\n";
          next;
          }

        system "rm -rf $result";
        if (-d $result) {
          print "Unable to delete directory $result (sorry)\n";
          next;
          }
        }
      } # must not exist
    else { # must exist
      my ($found) = -d $result;
      if (!$found) {
        print "Directory \"$result\" not found: $!\n";
        next;
        }
      } # must exist

    return $result;
    } # for

  }

