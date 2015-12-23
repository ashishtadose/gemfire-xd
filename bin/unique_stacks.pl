#!/usr/bin/perl -w

use strict;

my $SORT = 1;

my $currentStack;

my $DEBUG = 0;

my %stacks;
while(<>) {
  my $line = $_;
  if($line =~ /^"/) {
    $currentStack = "";
    $DEBUG && print("-----------deteted the start of a stack $line");
  }
  elsif(defined $currentStack) {
    if($line =~ /^\w*$/) {
    $DEBUG && print("----------ending stack $currentStack");
#$currentStack =~ s/0x[0-9a-fA-F]+/XxXXX/g;
#      $currentStack =~ s/(?<!jav)([0-9a-fA-F]+:+)[0-9a-fA-F]+/X:X:X:X:X/g;
#      $currentStack =~ s/(?<!java:)[0-9]+/X/g;
      $stacks{$currentStack}++;
      undef $currentStack;
    } elsif($line =~ /^\tat/ ) {
    $DEBUG && print("----------adding to stack $currentStack\n$line");
      $currentStack = "$currentStack$line";
    }
  } else {
    #do nothing
  }
}

my @keySet = keys %stacks;

if($SORT) {
  sub hashValueDescendingNum {
   $stacks{$b} <=> $stacks{$a};
  }

  @keySet = sort hashValueDescendingNum (keys %stacks);
}

foreach (@keySet) {
  print "----$stacks{$_} instances of this stack\n";
  print $_;
}
