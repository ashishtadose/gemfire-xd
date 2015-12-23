#! /bin/bash
#
#  A script to monitor a dunit test run.  This is similar to watch.sh,
#  but gives a little different information
#  
#  To use it, chdir to the dunit output directory (the one containing
#  dunit-progress-host0.txt, and execute the script.
#

if [ `uname` = "SunOS" ]; then
  cls() { clear; }
  me=`whoami`
elif [ `uname` = "Darwin" ]; then
  cls() { clear; }
  me=`whoami`
elif [ `uname` = "Linux" ]; then
  cls() { clear; }
  me=`whoami`
elif [ `uname` = "AIX" ]; then
  cls() { clear; }
  me=`whoami`
else
  # echo "Defaulting to Windows build"
  # cls() { cmd /c cls ; }
  cls() { echo "" ; echo "" ; echo ""; }
  me=$USERNAME
fi

#me=`whoami | sed -e 's/\\\\//'`
watchfile=/tmp/watchdunit${me}.tmp
rm -f $watchfile
grep "testClass = " ../dunit-tests.conf >$watchfile
#numtests=`wc -l $watchfile | cut -d " " -f 1`
numtests=`wc -l <$watchfile`
numtests=`echo $numtests`
typeset -i numfailures
typeset -i num
while [ 0 ]
do
  # --------------
  cls
  if [ x"$startedat" = x -a x"$dunitfile" != x ]; then
    startedat=`head -2 $dunitfile | tail -1 | cut -c 18-22`
  fi
  echo "folder: `basename $PWD`"
#  date
  echo -n "uptime: "
  uptime
  date
  echo ""

  # How many done?
  # --------------
  done=`grep -w "TEST" dunit-passed*.txt | wc -l`

  # --------------
  # Count up and display failures
  #ls -lrt failures 2>/dev/null | tail -5
  numfailures=`egrep -c -e "(FAILURE|ERROR)" dunit-progress*.txt | \
      perl -ne 'BEGIN{$sum=0;} /\D*(\d+)$/; $sum+=$1; END{print "$sum\n"}'`
  egrep -e "(FAILURE|ERROR)" dunit-progress*.txt | tail -5
  if [ $numfailures -ne 0 ]; then
    echo ""
  fi

  # --------------
  # Display progress
  for file in `ls dunit-progress*.txt`
  do
    test=`grep -w START $file | tail -1 | cut -d '(' -f 2 | cut -d ')' -f 1`
    #echo "test=($test)"
    if [ "$test" != "" ]; then
      n=`grep -h -n "$test" $watchfile | sed -e 's/:.*;/:/' |
        perl -e '$in=<STDIN>; chop($in); print $in;'`
      echo -n "#$n"
    fi
    tail -1 $file 

  done

  # --------------
  # Overall summary...
  echo ""
  echo "failures = $numfailures tests = $numtests done = $done"

  # --------------
  # Exit conditions
  if [ ! -f in_progress.txt ]; then
    exit 0
  fi
  if [ -f errors.txt ]; then
    exit 1
  fi

  sleep 10

done
