#! /bin/bash
typeset -i testCount
#testCount=`grep -c .conf batterytest.bt`
testCount=`grep "Running a total of" batterytest.log | \
      perl -ne 'BEGIN{$sum=0;} /.*Running a total of (\d+) .*$/; $sum+=$1; END{print "$sum\n"}'`

typeset -i numfailures
typeset -i numhangs
typeset -i numpass
typeset -i numrun

#function grantorHangs {
#  typeset -i numG
#  typeset -i count
#  numG=0
#  count=0
#  for x in `grep " H " oneliner.txt`; do
#    if [ $count -eq 3 ]; then
#      found=`grep -l ElderRecovery $x/bg*.log`
#      if [ x"$found" != x ]; then
#        numG=$((numG + 1))
#      fi
#      count=0
#    else
#      count=$((count + 1))
#    fi
#  done
#  echo "grantor hangs=$numG"
#}

if [ `uname` = "SunOS" ]; then
  cls() { clear; }
  upt() { uptime; }
  me=`whoami`
elif [ `uname` = "Darwin" ]; then
  cls() { clear; }
  upt() { uptime; }
  me=`whoami`
elif [ `uname` = "Linux" ]; then
  cls() { clear; }
  upt() { uptime; }
  me=`whoami`
elif [ `uname` = "AIX" ]; then
  cls() { clear; }
  upt() { uptime; }
  me=`whoami`
else
  # echo "Defaulting to Windows build"
  # cls() { cmd /c cls ; }
  cls() { echo "" ; echo "" ; echo ""; }
  upt() { echo "" ; }
  me=$USERNAME
fi

while [ 0 ]
do
  cls

  date
  upt
  echo ""
  numpass=`grep -c " P " oneliner.txt`
  numhangs=`grep -c " H " oneliner.txt`
  numfailures=`grep -c " F " oneliner.txt`
  numrun=`grep -c "RESULT: Test " batterytest.log`

  echo "total=$testCount  tests run=$numrun  passed=$numpass  failed=$numfailures  hung=$numhangs"
#  grantorHangs
  echo ""
  echo "current test:"
  grep "DIR=" batterytest.log | tail -1
  echo ""
  echo "oneliner.txt:"
  tail -4 oneliner.txt

  if [ $testCount -eq $numrun ]; then
    exit 0
  fi
  sleep 30
done
