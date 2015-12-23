#! /bin/bash
set -e
# ----------------------------
# Script to run a single dunit test
#
# Usage:
# 1.  Make sure you have run redirect.pl
# 2.  Cd to the top directory of your checkout.
# 3.  Edit (uncomment or add) your single test case.
#     Many common occurrences are commented below.
# 4.  bash ./dunittest.sh
# ----------------------------

# ----
# Following values are customized by redirect.pl
SRC=/export/shared_build/users/jpenney/bugfix2
# ----

# -------------------------
# Common test cases
#
# Note: you can grab a range in vi and
# pipe thus:
#    :'a,'m ! sort | uniq
# in order to add/refresh/clean up this list.
# -------------------------

testcase=com.gemstone.sqlfabric.internal.engine.distributed.PreparedStatementDUnit.txt




if [ "$testcase" != "" ]; then
  testcase=`echo $testcase | sed -e 's/\.txt//' | sed -e 's#\.#/#g'`
  testcase=-Dsqlf.dunit.testcase=${testcase}.class
fi
echo "testcase is \"$testcase\""

bash build.sh sqlf-run-dunit-tests $testcase -Dlocal.conf=$SRC/dunit.conf
#bash build.sh sqlf-run-dunit-tests $testcase -Dlocal.conf=$SRC/local.conf
