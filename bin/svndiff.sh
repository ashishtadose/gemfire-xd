#! /bin/bash
# 
# Utility to have svn diff use our own diff, with our own options.
#
# Usage:
#  svn diff . --diff-cmd bin/sdiff.sh >diff.log

myFlags="-b"	# Ignore blanks
u=$1		# -u
L1=$2		# -L
f1="$3"		# label 1
L2=$4		# -L
f2="$5"		# label 2
n1=$6		# first file
n2=$7		# second file

diff $myFlags $u $L1 "$f1" $L2 "$f2" "$n1" "$n2"
