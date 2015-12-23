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
*/.fbprefs
.metadata
"

if [ ! -d .metadata ]; then
  echo "Hunh?  No .metadata folder!"
  exit 1
fi

echo "Saving eclipse environment..."
rm -f saveMetadata.zip
zip -qr saveMetadata.zip .metadata */.project */.settings */.classpath

. bin/eclipse/clean.sh

echo "Zipping transportable environment..."
quiet=-q
rm -f eclipse.zip
zip $quiet -r eclipse.zip $files

echo "Saving..."
offsite=bin/eclipse/metadata.zip

#echo "offsite=$offsite"
#exit 0
if [ -f $offsite ]; then
  mv  $offsite ${offsite}.bak
fi
mv eclipse.zip $offsite
ls -l $offsite ${offsite}.*

echo "Restoring eclipse environment"
unzip -qo saveMetadata.zip
