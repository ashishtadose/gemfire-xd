#! /bin/bash
# ---------------------------
# Script for creating a new metadata.zip
#
# Usage:
# 1.  cd to the top directory of your checkout
# 2.  bash bin/eclipse/saveall.sh
#
# Note: Occasionally eclipse gets confused about its indexes.
# If this should happen, uncomment out the exit (marked below), then
# run this script.  This will run the cleaning portion of the script.
# Don't forget to comment the exit out again afterwards.
# ---------------------------
set -e

# Don't save the *.properties files, includes real directory names!
#*.properties

files="
*/.classpath
*/.project
*/.settings
.metadata
"

if [ ! -d .metadata ]; then
  echo "Hunh?  No .metadata folder!"
  exit 1
fi

# Bogus index files, large, not necessary, and can confuse a restore
echo "Removing non-transportable metadata..."
rm -rf .metadata/.plugins/org.eclipse.core.resources/.projects/*/.indexes
rm -rf .metadata/.plugins/org.eclipse.jdt.core/*.index

rm -f .metadata/.log
rm -f .metadata/.lock
rm -f .metadata/.*.log
rm -f .metadata/.plugins/org.eclipse.core.resources/.snap
rm -rf .metadata/.plugins/org.eclipse.core.resources/.history
rm -f .metadata/.plugins/org.eclipse.core.resources/.projects/*/.syncinfo
rm -f .metadata/.plugins/org.eclipse.core.resources/.projects/*/.syncinfo.snap
rm -f .metadata/.plugins/org.eclipse.core.resources/.projects/*/.markers
rm -f .metadata/.plugins/org.eclipse.core.resources/.projects/*/org.eclipse.jdt.core/state.dat
rm -rf .metadata/.plugins/org.eclipse.epp.usagedata.recording/*
rm -rf .metadata/.plugins/org.eclipse.ltk.core.refactoring/.refactorings/*
rm -rf .metadata/.plugins/org.eclipse.m2e.core/nexus/*
rm -f .metadata/.plugins/org.eclipse.jdt.core/*


# No longer necessary?
rm -rf .metadata/.plugins/org.eclipse.wst.xml.core
#rm -rf .metadata/.plugins/org.tigris.subversion.subclipse.core

rm -rf .metadata/.plugins/org.eclipse.core.resources/.root/.indexes
rm -rf .metadata/.plugins/org.eclipse.pde.core/.cache

# Don't do this, I've wired in the XML into this file
#rm -rf .metadata/.plugins/edu.umd.cs.findbugs.plugin.eclipse

# Bad Idea:
#rm -rf .metadata/.plugins/org.eclipse.core.resources/.root
#rm -rf .metadata/.plugins/org.eclipse.core.resources/.safetable/
#rm -rf .metadata/.mylyn  Too broad

# More cruft that we can live without.  Possibly confuses Eclipse?
rm -f .metadata/.plugins/org.eclipse.core.resources/.projects/examples/.markers
rm -f .metadata/.plugins/org.eclipse.core.resources/.projects/src/.markers
rm -f .metadata/.plugins/org.eclipse.core.resources/.projects/tests/.markers
rm -f .metadata/.plugins/org.eclipse.core.resources/.root/.markers

#rm -rf .metadata/.plugins/org.eclipse.mylyn.bugzilla.core
#rm -rf .metadata/.mylyn/backup/

# Don't want to overwrite the Eclipse files, esp. in quickstart
#files="$files `find . -name .metadata`"
#files="$files `find . -name .project`"
#files="$files `find . -name .classpath`"

