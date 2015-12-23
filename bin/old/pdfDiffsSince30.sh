#! /bin/bash
#

#set -x

# This script uses enscript and distill to create a PDF file that
# highlights the modifications made to files under CVS revision
# control.
#
# usage: pdfCvsDiffs.sh pdfFile [files]*

function createPostScript {
  for i in $*; do
    current=.`basename ${i}`.current
    cvs update -p -r gemfire300_release $i > ${current}
    diff ${current} $i | diffpp ${current} | enscript -G2re --line-numbers --pretty-print -o - -b "$i Page \$% of \$="
    rm -f ${current}
  done
}


if [ $# -le 0 ]; then
  echo ""
  echo "** Missing pdf file"
  echo ""
  echo "usage: pdfDiffsSince30.sh pdfFile [files*]"
  echo ""
  exit 1
fi

pdfFile=${1}
shift

# look for all locally modified files under CVS control
cvsCommand="cvs -nq update -r gemfire300_release $*"
echo "Invoking ${cvsCommand}"
files=`eval ${cvsCommand} | egrep "^M |^C |^U " | cut -d " " -f2`

createPostScript ${files} | distill > ${pdfFile}

