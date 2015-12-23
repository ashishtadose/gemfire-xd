#!/usr/bin/perl -w
# Author: Dan Smith
# This script allows you to run any gemfire or gemfirexd junit and dunit test 
# by passing just the classname.
#
# This script optionally recompiles gemfire and gemfirexd and runs a unit test a
# specified number of times and exits with status 0 if the test succeeds every
# time
#
# This script is suitable for use with git bisect or svn-bisect, because it
# returns exit code 125 to indicate that a compile failed, allowing the bisect
# to skip over compilation errors.

use strict;
use Getopt::Long;
my $compile = '';
my $num = 1;
my $class = '';
my $filename = '';
my $use64bit = '';
my $success = GetOptions ("num=i" => \$num,    
            "class=s"   => \$class,      
            "filename=s"   => \$filename,      
            "compile"  => \$compile,
            "64" => \$use64bit);
if(!$success || !($class || $filename)) {
  print("Usage: run_unit_test.pl -class classname [-num N] [-compile]\n");
  print("Usage: run_unit_test.pl -filename path/to/myfile.java [-num N] [-compile]\n");
  print("  classname - the name of the class you want to run, eg BugsTest\n");
  print("  filename - optionally specify the full path to the java file. Only necessary if two classes have the same name \n");
  print("  N the number of times to run the test\n");
  print("  compile recompile before running the test\n");
#Exit with a status that will tell git bisect to abort
  exit 128;
}

if($class && $filename) {
  print("Please specify either -filename or -class but not both\n");
  exit 128;
}

if($class) {
#Be nice to people and clean up a .class or .java if they accidently append it.
  $class =~ s/\.class$//;
  $class =~ s/\.java$//;

#Locate the test class and test type
  $filename=`find tests gemfirexd/GemFireXDTests/ -name $class.java`;
  chomp $filename;

  if($filename =~ /\n/) {
    print "\nMore than one test with the same name found. You will need to specify one of these fullpaths with the -filename argument \n";
    print "$filename\n";
    exit 128;
  }

  if(!$filename) {
    print ("Unable to locate the test class $class\n");
#Exit with a status that will tell git bisect to abort
    exit 128;
  }
}

#Convert the filename to a classname
my $classname=$filename;
$classname =~ s/^tests\///; 
$classname =~ s/^gemfirexd\/GemFireXDTests\/(junit|dunit)\///; 
$classname =~ s/java$/class/;

#Determine the build target (junit, dunit gfxd junit, gfxd-dunit)
my $isGfxd = $filename =~ /^gemfirexd/;
my $dunit = $classname =~ /DUnit/;
my $quickstart = $classname =~ /^quickstart/;
my $wanDunit = $dunit && 
                  ($classname =~ /com\/gemstone\/gemfire\/internal\/cache\/wan/
                  || $classname =~ /com\/pivotal\/gemfirexd\/wan/);

my $target;
my $testname;
if($isGfxd) {
  if($wanDunit) {
    $target='gfxd-run-wan-dunit-tests';
    $testname="-Dgfxd.wan.dunit.testcase=$classname";
  } elsif($dunit) {
    $target='gfxd-run-dunit-tests';
    $testname="-Dgfxd.dunit.testcase=$classname";
  }  else {
    $target='gfxd-run-junit-tests';
    $testname="-Dgfxd.junit.testcase=$classname";
  }
} else {
  if($wanDunit) {
    $target='run-wan-dunit-tests';
    $testname="-Dwan.dunit.testcase=$classname";
  } elsif($dunit) {
    $target='run-dunit-tests';
    $testname="-Ddunit.testcase=$classname";
  } elsif($quickstart) {
    $target='run-quickstart-tests';
    $testname="-Dquickstart.testcase=$classname";
  } else {
    $target='run-java-tests';
    $testname="-Djunit.testcase=$classname";
  }
}

if($use64bit) {
  $target=$target . "64";
}


#Do a build.
if($compile) {
  if($isGfxd) {
  system('./build.sh', 'clean', 'gfxd-clean', 'gfxd-build-java-product', 'compile-tests', 'gfxd-compile-all-tests')==0 || exit 125;
  } else {
    system('./build.sh', 'clean', 'build-product-nodocs', 'compile-tests')==0 || exit 125;
  }
}

#gfxd build leaves files around that then cause conflicts
#system('rm gemfirexd/java/engine/com/pivotal/gemfirexd/internal/iapi/services/cache/ClassSizeCatalog.java') || die 'Couldnt cleanup gemfirexd files $!';

#Run the test the given number of times.
my $i;
for ($i = 0; $i < $num; $i++) {
  print("./build.sh -DlogLevel=fine -DdmVerbose=true $testname $target \n");
  system('./build.sh', '-DlogLevel=fine', '-DdmVerbose=true', $testname, $target)==0 || die ("$class failed on iteration $i\n");
}
print("$i iterations of $class succeeded\n\n");
