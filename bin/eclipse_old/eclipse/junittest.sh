#! /bin/bash
# -------------------
# Script for running a single junit test
#
# Usage:
# 1.  Make sure you have run redirect.pl
# 2.  Cd to the top directory of your checkout.
# 3.  Add or uncomment your test case below.
# 4.  bash ./junittest.sh
# -------------------

# ----
# Following values are customized by redirect.pl
SRC=/export/shared_build/users/$USER/prFeb07
# ----

# -------------------------
# Common test cases
#
# Note: you can grab a range in vi and
# pipe thus:
#    :'a,'m ! sort | uniq
# in order to add/refresh/clean up this list.
# -------------------------
#testcase=com/gemstone/gemfire/internal/PageFileTest.class
testcase=com/gemstone/gemfire/internal/LicenseTest.class

if [ "$testcase" != "" ]; then
  testcase=`echo $testcase | sed -e 's/\.txt//' | sed -e 's#\.#/#g'`
  testcase=-Djunit.testcase=${testcase}.class
fi

echo "testcase is $testcase"

bash build.sh run-java-tests $testcase -Dlocal.conf=$SRC/dunit.conf
