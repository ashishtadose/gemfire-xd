#!/usr/bin/perl -w
# Author: Dan Smith
# This script performs a git bisect to locate the commit that caused
# a unit test to start failing

use strict;
use Getopt::Long;
use File::Basename;
use Cwd 'abs_path';

my $scriptdir = dirname(abs_path($0));

sub bisectGit {
  (my $class, my $num, my $good, my $bad) = @_;

  my $goodHash = `git svn find-rev r$good`;
  chomp $goodHash;
  my $badHash = `git svn find-rev r$bad`;
  chomp $badHash;

  if(!$goodHash) {
    die "Could not find good revision $good in history";
  }

  if(!$badHash) {
    die "Could not find bad revision $bad in history";
  }

  print ("Running git  bisect $badHash $goodHash\n");
  system('git', 'bisect', 'start', $badHash, $goodHash) == 0 || die "Could not run git bisect $!";
  system('git', 'bisect', 'run', "$scriptdir/run_unit_test.pl", '-class', $class, '-compile', '-num', $num) == 0 || die "Bisect failed $!";
}

sub bisectSVN {
  (my $class, my $num, my $good, my $bad) = @_;

#Clear any previous state
  system('svn-bisect', 'reset');

#Do the bisect
  print ("Running svn-bisect $good $bad\n");
  system('svn-bisect', 'start', $good, $bad) == 0 || die "Could not run git bisect $!";
  system('svn-bisect', 'run', "$scriptdir/run_unit_test.pl -class $class -compile -num $num") == 0 || die "Bisect failed $!";
}


my $num = 1;
my $class;
my $good = '';
my $bad = '';
my $success = GetOptions ("num=i" => \$num,    
            "class=s"   => \$class,      
            "good=i"   => \$good,      
            "bad=i"   => \$bad);
if(!$success || !$class || !$good || !$bad) {
  print("Usage: bisect.pl -class classname -good goodrev -bad badrev [-num N]\n");
  print("    classname  the name of the class you want to run, eg BugsTest\n");
  print("    N          the number of times to run the test\n");
  print("    goodrev    the svn revision where the test was previously passing \n\n");
  print("    badrev     the svn revision where the test started failing \n");
  print("\nRun this script in the root directory of either a svn or git checkout.\n");
  print("\nFor svn users you must have svn-bisect installed. Eg on ubuntu install \nsubversion-tools\n");
  print("\nFor git users your current git checkout should have both goodrev\n");
  print("and badrev in its revision history.\n");
  print("You may want to run run git svn fetch, git checkout remotes/[svn-branch-name]\n");
  print("before gooding the bisect\n");
  exit 1;
}

my $isGit = system('git rev-parse --is-inside-work-tree')==0;

if($isGit) {
  bisectGit($class, $num, $good, $bad);
} else {
  bisectSVN($class, $num, $good, $bad);
}


