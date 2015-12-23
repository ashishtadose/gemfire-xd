#! /bin/sh
#set -e
# ---------------------
# Run a specified .bt file
#
# Usage:
# 1.  Make sure you have run redirect.pl
# 2.  cd to the top directory of your checkout.
# 3.  Edit the local.conf in your top level directory;
#     start with the one in bin/eclipse if you want some ideas.
# 4.  Create the .bt file if you're not using a canned one.
# 5.  bash ./runbt.sh <bt-file>
# ---------------------

# ----
# Following values are customized by redirect.pl
ECLIPSEJDK=/gcm/where/jdk/1.6.0_2/x86.linux
#OBJ_BASE=/frodo2/users/$USER/gemfire_obj/downmerge
SRC=/export/shared_build/users/$USER/downmerge
OBJ_BASE=/frodo2/users/$USER/gemfire_obj/downmerge
# ----

# ----
# Customize to taste...

TEST_BASE=$OBJ_BASE/tests	# the tests tree
CONF=$SRC/local.conf		# your preferred configuration
TOP=$TEST_BASE/results		# base directory for hydra output

# nukeHungTest
nuke=-DnukeHungTest=true
#nuke=-DnukeHungTest=false

# numTimestoRun
iterations=-DnumTimesToRun=1
#iterations=-DnumTimesToRun=10

# -until.  Please note the date format is rather odd and finicky.
#  -until date/time
#       Executes tests until a specific date.  Dates are
#       specified according to the "MM/dd/yyyy hh:mm a"
#       SimpleDateFormat.  Example: 08/11/2008 12:21 PM
until=
#until="-until 08/11/2008 6:00 PM"
# ----

# ----
# No user serviceable parts inside
# ----
BT=$SRC/test.bt
if [ "$1" != "" ]; then
  BT="$1"
fi


case $HOSTTYPE.$OSTYPE in
  i686.cygwin)
    DS=";"
    ;;
  x86_64.linux*)
    DS=":"
    ;;
  i386.linux*)
    DS=":"
    ;;
  i486.linux*)
    DS=":"
    ;;
  sparc.solaris*)
    DS=":"
    ;;
  *)
    echo "Don't know this arch"
    exit 1
    ;;
esac

export NO_BUILD_LOG=true

export GEMFIRE=$OBJ_BASE/product
if [ ! -d "$GEMFIRE" ]; then
  echo "GEMFIRE $GEMFIRE does not exist"
fi

export JTESTSROOT=$OBJ_BASE/tests
if [ ! -d "$JTESTSROOT" ]; then
  echo "JTESTSROOT $JTESTSROOT does not exist"
fi

export JTESTS=$JTESTSROOT/classes
if [ ! -d "$JTESTS" ]; then
  echo "JTESTS $JTESTS does not exist!"
else
  echo "JTESTS     : " $JTESTS
fi

if [ ! -d "$OBJ_BASE/product" ]; then
  echo "$GEMFIRE $OBJ_BASE/product does not exist"
fi
pushd $OBJ_BASE/product
export GEMFIRE=$PWD
popd

cp=.
#cp=$cp$DS$OBJ_BASE/classes
cp=$cp${DS}$JTESTS${DS}$GEMFIRE/lib/gemfire.jar
cp=$cp${DS}$JTESTS${DS}$GEMFIRE/lib/backport-util-concurrent.jar

export CLASSPATH=$cp
echo "CLASSPATH  : $CLASSPATH"

newpath=$OBJ_BASE/product/../hidden/lib
newpath=$newpath$DS$OBJ_BASE/product/jre/bin
export PATH=$newpath$DS$PATH
#echo "PATH       : $PATH"

exec 1>&1
exec 2>&1
exec 0>&1
#set -v
#set -x
date

# Get rid of "No xauth" warning
if [ "$DISPLAY" != "" ]; then
  xauth add `echo "${DISPLAY}" | sed 's/.*\(:.*\)/\1/'` . `mcookie`
  hosts="fili"
  for each in $hosts
  do
    cmd='xauth add `echo "'${DISPLAY}'" | sed '"'"'s/.*\(:.*\)/\1/'"'"'` . `mcookie`'
    ssh $each "$cmd"
  done
fi

mkdir -p $TOP
if [ -f $CONF ]; then
  echo "Copying $CONF to $TEST_BASE"
  cp $CONF $TOP/local.conf
fi
cp $BT $TOP/test.bt

##
##

cd $TOP
echo "BT         $BT"
echo "TOP        `pwd`"
echo "nuke       $nuke"
echo "iterations $iterations"
echo "until      $until"

rm -f oneliner.txt
rm -f batterytest.log
$ECLIPSEJDK/bin/java \
  $nuke \
  -Djava.library.path=$OBJ_BASE/hidden/lib \
  -DJTESTS=$JTESTS \
  -DGEMFIRE=$OBJ_BASE/product \
  -DtestFileName=$TOP/test.bt \
  -Dtests.results.dir=$OBJ_BASE/tests/results \
  -Dbt.result.dir=$OBJ_BASE/tests/results \
  $iterations \
  batterytest.BatteryTest \
  $until
