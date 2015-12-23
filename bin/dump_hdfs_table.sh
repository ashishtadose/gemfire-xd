#!/bin/bash
# Script to dump out the contents of a hdfs table for analysis
#
#This script connects to a running HDFS instance to dump out
# the data in a given table in CSV format. The CSV will contain
# the raw contents of the files, ie the event view.
#
# Example: 
# bin/dump_hdfs_table.sh hdfs://localhost:9000 /users/gfxd/gemfire /APP/MYTABLE
# This will dump the contents of all hoplogs for the table /APP/MYTABLE to a csv called
# MYTABLE.csv in the current directory.

DIR=`dirname $0`
if [ -e $DIR/../buildlinux.properties ]
then
  BUILD_DIR=`perl -lane 'if(/build.dir=(.*)/) {print $1}' $DIR/../buildlinux.properties`
fi

if [ "$BUILD_DIR" == "" ]
then
  BUILD_DIR=$DIR/../build-artifacts
fi

CLASSPATH=`$DIR/../build.sh -q echo-test-classpath | perl -lne '/CLASSPATH:(.*)$/ && print $1'`;


#echo java -cp $BUILD_DIR/linux/product-gfxd/lib/*:$CLASSPATH com.pivotal.gemfirexd.internal.engine.hadoop.mapreduce.DumpHDFSData $*
java -cp $BUILD_DIR/linux/product-gfxd/lib/*:$CLASSPATH com.pivotal.gemfirexd.internal.engine.hadoop.mapreduce.DumpHDFSData $*
