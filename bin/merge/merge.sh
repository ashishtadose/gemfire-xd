# ----------------
# Many magic tricks I use to do merging...
# ----------------

#startrev=16834	# last downmerge from trunk

startrev=17025
endrev=17035
path=https://svn.gemstone.com/repos/gemfire/trunk

# ----------------
# To do the downmerge...
# ----------------

svn merge -r$startrev:$endrev $path
exit 0

# ----------------
# Various functions used to resolve conflicts.
# Using the name "C" is no coincidence :-)
# ----------------

# Hand edit:
#C() { vi $1 ; }
# Mark as resolved:
#C() { svn resolved $1 ; }
# Display differences:
#C() { svn diff $1 ; }

# To overcome EOL issues:
#C() {
#  rm -rf scratch
#  mkdir -p scratch
#  svn revert $1
#  svn cat -r$startrev $path/$1 > scratch/before.txt
#  svn cat -r$endrev $path/$1 > scratch/after.txt
#  dos2unix scratch/before.txt
#  dos2unix scratch/after.txt
#  dos2unix $1
#  merge $1 scratch/before.txt scratch/after.txt
#  if [ $? -ne 0 ]; then
#    echo "C $1"
#  fi
#  }

# To override with trunk:
C() {
  svn cat -r$endrev $path/$1 > $1
  }

#exit 0


# ----------------
# Put your files here...
# ----------------
C   tests/com/gemstone/gemfire/internal/cache/FaultingInJUnitTest.java

exit 0

