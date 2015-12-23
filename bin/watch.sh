#! /bin/bash
while [ 0 ]
do
  date
  uptime
  if [ ! -f in_progress.txt ]; then
    exit 0
  fi
  if [ -f errors.txt ]; then
    exit 1
  fi
  if [ -f HungDUnitTest.txt ]; then
    exit 1
  fi
  # ls -l *.txt
  ls -l dunit-passed*.txt dunit-progress*.txt
  tail -1 dunit-progress*.txt
  echo "failures = `ls -1 failures 2>/dev/null | wc -l`"
  ls -lrt failures 2>/dev/null | tail -5
  echo ""
  sleep 10
done
