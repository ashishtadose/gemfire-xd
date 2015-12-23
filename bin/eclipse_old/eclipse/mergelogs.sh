#! /bin/bash
# -------------------------------
# Run MergeLogFiles, with Kirk's recommended optiotns
#
# Usage:
# 1.  Make sure you have run redirect.pl
# 2.  chdir to your test directory.
# 3.  bash $top/mergelogs.sh <outname>
#
# Creates a merged2.txt in the current directory if no arg given.
# -------------------------------

# ----
# Following values are customized by redirect.pl
JDK=/export/java/users/java_share/jdk/1.4.2.12/x86.linux
OBJ_BASE=/frodo2/users/$USER/gemfire_obj/prFeb07
# ----

if [ "$1" = "" ]; then
  out="merged2.txt"
else
  out="$1"
fi

f=
#f=`/bin/ls -1 *.log 2>/dev/null`
#c=`echo "$f" | wc -l`
#if [ $c -eq 1 ]; then
#  f=
#fi
#echo "f=$f"

ff=`find $PWD -type d`
#ff=`/bin/ls -1 */*.log 2>/dev/null`
#c=`echo "$ff" | wc -l`
# Ignore the locator log
#if [ $c -eq 1 ]; then
#  ff=
#fi
#echo "ff=$ff"

#mem=-Xmx512m
mem=-Xmx1024m

$JDK/bin/java $mem \
  -cp $OBJ_BASE/classes \
  com.gemstone.gemfire.internal.MergeLogFiles \
  -dirCount 1 \
  -mergeFile $out \
  $f $ff

