#! /bin/bash
#set -xv
#=========================================================================
# (c) Copyright 1986-2007, GemStone Systems, Inc. All Rights Reserved.
#
# Name - addfolder.sh
#
# Purpose - To add a message to a mail folder
#
# Arguments:
# 1 - folder to which to append
# 2 - file to append
# 3 - subject
#
# $Id$
#=========================================================================

theFolder=$1
theFile=$2
theSubject="$3"

lockName=${theFolder}.LCK
new_entry=/tmp/addfolder$$

DATECMD="+%a %h %d 19%y %H:%M"

lockfile () {
  # Wait until file "$1" does not exist and then create it

  thefile=$1
  while [ 1 ]; do
    mkdir $thefile >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      break
    fi
    owner=`ls -ld $thefile | awk '{ printf("%s",$3) }'`  # get owner of file
    echo `date "$DATECMD"`: " Waiting on lock file $thefile owned by $owner ..."
    sleep 10
  done
  }

cleanup () {
  status=$1
  if [ $status -ne 0 ]; then
    rm ${theFolder}
    if [ -f ${theFolder}.BAK ]; then
      mv ${theFolder}.BAK ${theFolder}
    fi
  else
    rm -f ${theFolder}.BAK
  fi
  rm -rf $lockName
  rm -f $new_entry
  exit $status
  }


lockfile $lockName
if [ ! -f $theFolder ]; then
  touch $theFolder
else
  mv $theFolder ${theFolder}.BAK
  cp ${theFolder}.BAK $theFolder
fi
chmod ugo+rw $theFolder

# Put header on
me="$USER"
if [ "$me" = "" ]; then
  if [ "$HOSTTYPE" = Symmetry ]; then
    me=`who am i | awk '{print $1}'`
  else
    me=`whoami 2>/dev/null`
  fi
fi
if [ "$me" = "" ]; then
  me=$LOGNAME
fi

cat >$new_entry <<END_CAT
From $me `date`
From: $me
To: $me
Date: `date`
Subject: $theSubject

END_CAT
if [ $? -ne 0 ]; then
  echo "addfolder.sh[Error]:  unable to create header"
  cleanup 1
fi

# Put contents of folder in, making sure that bogus From lines are fixed
sed -e '1,$ s/^From /~From /' <$theFile >>$new_entry
if [ $? -ne 0 ]; then
  echo "addfolder.sh[Error]:  unable to create body"
  cleanup 1
fi

# Obligatory trailer (yucch)
cat <<END_CAT >>$new_entry

END_CAT
if [ $? -ne 0 ]; then
  echo "addfolder.sh[Error]:  unable to create trailer"
  cleanup 1
fi

cat <$new_entry >>$theFolder
if [ $? -ne 0 ]; then
  echo "addfolder.sh[Error]:  unable to append new message to folder"
  cleanup 1
fi

cleanup 0
