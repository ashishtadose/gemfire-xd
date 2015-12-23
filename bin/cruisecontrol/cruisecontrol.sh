#!/bin/bash
rm -f cc.pid *.log *.log.? *.ser

logfile=`date "+cruisecontrol_%Y_%m_%d_%H_%M_%S.log"`
exec </dev/null
exec 3>$logfile
exec 1>&3
exec 2>&3

if [ `uname` = "SunOS" ]; then
  export GCMDIR=${GCMDIR:-"/export/gcm"}
  export JAVA_HOME=${ALT_JAVA_HOME:-$GCMDIR/where/jdk/1.6.0_26/sparc.Solaris}
  ext=".sh" 
elif [ `uname` = "Linux" ]; then
  export GCMDIR=${GCMDIR:-"/export/gcm"}
  export JAVA_HOME=${ALT_JAVA_HOME:-$GCMDIR/where/jdk/1.6.0_26/x86.linux}
  ext=".sh" 
elif [ `uname` = "Darwin" ]; then
  export GCMDIR=${GCMDIR:-"/export/gcm"}
  export JAVA_HOME=${ALT_JAVA_HOME:-/System/Library/Frameworks/JavaVM.framework/Versions/1.5.0/Home}
  ext=".sh" 
elif [ `uname` = "AIX" ]; then
  export GCMDIR=${GCMDIR:-"/export/gcm"}
  export JAVA_HOME=${ALT_JAVA_HOME:-/usr/java6/jre}
  ext=".sh" 
else
  echo "Defaulting to Windows build"
  export GCMDIR=${GCMDIR:-"j:\\"}
  export JAVA_HOME=${ALT_JAVA_HOME:-$GCMDIR/where/jdk/1.6.0_26/x86.Windows_NT}
  ext=".bat" 
fi

#-- cruisecontrol --
export CRUISE_CONTROL_HOME=${CRUISE_CONTROL_HOME:-$GCMDIR/where/java/cruisecontrol/cruisecontrol-2.8.3}
export CC_HOST_NAME=`hostname | sed 's/\..*//'`
export CC_PLATFORM=`uname|sed 's/-.*//g'`
export CC_OPTS="-Xms512m -Xmx512m"
export JETTY_LOGS=`pwd`/cruisecontrol/jettylogs
#-------------------

echo "JETTY_LOGS = $JETTY_LOGS"
echo "JAVA_HOME = $JAVA_HOME"
date

#-- cruisecontrol --
echo "running $CRUISE_CONTROL_HOME/cruisecontrol${ext}"
$CRUISE_CONTROL_HOME/cruisecontrol${ext}
#-------------------
