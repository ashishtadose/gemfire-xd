#!/bin/bash
#set -xv

#Usage: deploy.sh project_name buildmaster_email group_email svn_url destination_dir cruisecontrol_dir smtp_server

#Example1: deploy.sh gemfire-trunk kirk.lund@gemstone.com fabricdev@gemstone.com https://svn.gemstone.com/repos/gemfire/trunk/ /export/bobo3/users/klund/cruisecontrol /export/gcm/where/java/cruisecontrol/cruisecontrol-2.8.3 mail.gemstone.com

#Example2: deploy.sh prFeb07_branch kirk.lund@gemstone.com partitionedregions@gemstone.com https://svn.gemstone.com/repos/gemfire/branches/prFeb07_branch/ /export/bobo3/users/klund/cruisecontrol /export/gcm/where/java/cruisecontrol/cruisecontrol-2.8.3 mail.gemstone.com

if ! ( which ant > /dev/null 2>&1 || which ant.bat > /dev/null 2>&1 ); then
  echo "ERROR: cannot find ant with 'which ant' add it to your PATH"
  echo "i.e. export PATH=/export/gcm/where/java/ant/apache-ant-1.8.4/bin:\$PATH"
  exit 1
fi

if [ -z "$JAVA_HOME" -o ! -d "$JAVA_HOME" ]; then
  echo "ERROR: invalid JAVA_HOME setting JAVA_HOME=\"$JAVA_HOME\""
  echo "i.e. export JAVA_HOME=/export/gcm/where/jdk/1.6.0_26/<platform>"
  exit 1
fi

if [ ! -f deploy.xml ]; then
  echo "ERROR: Script must be launched from same directory as deploy.xml"
  exit 1
fi

if [ $# -ne 7 ]; then
  echo "ERROR: usage $0 <product_name> <buildmaster_email> <group_email> <svn_url> <destination_dir> <cruisecontrol_dir> <mail.gemstone.com|mail.pune.gemstone.com>"
  exit 1
fi

ant --noconfig -Dproject_name=$1 -Dbuildmaster_email=$2 -Dgroup_email=$3 -Dsvn_url=$4 -Ddestination_dir=$5 -Dcruisecontrol_dir=$6 -Dsmtp.server=$7 -buildfile deploy.xml 
