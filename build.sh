#!/bin/bash
# Set BASEDIR to be the toplevel checkout directory.
# We do this so that BASEDIR can be used elsewhere if needed
#set -xv
exec 0<&-
BASEDIR=`/usr/bin/dirname $0`
OLDPWD=$PWD
cd $BASEDIR
export BASEDIR=`/usr/bin/dirname $PWD`
cd $OLDPWD

unset CLASSPATH
export CLASSPATH

unset GEMFIRE
export GEMFIRE

export JAVA_VERSION=${ALT_JAVA_VERSION:-1.7.0_72}

PING="ping -c 1"
if [ `uname` = "SunOS" ]; then
  export GCMDIR=${GCMDIR:-"/gcm"}
  export JAVA_HOME=${ALT_JAVA_HOME:-$GCMDIR/where/jdk/${JAVA_VERSION}/sparc.Solaris}
  # for JVM debugging
  # export JAVA_HOME=/export/avocet2/users/otisa/j2se142debug
  logfile=buildSol.log
  if [ -d "/export/gcm/where/std11_gfe/bin" ]; then
    # Studio 11 version CC: Sun C++ 5.8 Patch 121017-05 2006/08/30
    export SunCompilerDir=/export/gcm/where/std11_gfe/bin
  else
    echo "Sun Studio 11 compiler not found";
  fi

  # Studio 11 version CC: Sun C++ 5.8 Patch 121017-05 2006/08/30
  SunCompilerVer=`$SunCompilerDir/CC -V 2>&1 `
  echo "Using Studio 11 at $SunCompilerDir "
  echo "    version: $SunCompilerVer "

elif [ `uname` = "Darwin" ]; then
  export GCMDIR=${GCMDIR:-"/export/gcm"}
    export JAVA_HOME=${ALT_JAVA_HOME:-/Library/Java/JavaVirtualMachines/jdk${JAVA_VERSION}.jdk/Contents/Home/}
  if [ ! -d $JAVA_HOME ]; then
    echo "Install Java JDK version ${JAVA_VERSION}."
# JAVA_HOME=`/usr/libexec/java_home -F -v ${JAVA_VERSION}`
#cat << __HERE__
#    Upgrade to Leopard Please, or set ALT_JAVA_HOME to the soylatte VM
#    #example setup
#    export ALT_JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk${JAVA_VERSION}.jdk/Contents/Home
#    #Also add these to buildmac.properties
#    javac.secondary=${gcm.dir}/where/jdk/1.6.0_3/i386.darwin
#    default.testVM=${gcm.dir}/where/jdk/1.6.0_3/i386.darwin
#    default.testVM64=${gcm.dir}/where/jdk/1.6.0_3/i386.darwin
#__HERE__
    exit 1
  fi
  export GccCCompiler=/usr/bin/gcc
  export GccCplusplusCompiler=/usr/bin/g++
  GccCompilerVer=`$GccCCompiler --version 2>/dev/null | head -1  2>&1 `
  export GccMajorVer="3"
  echo "Using gcc version: $GccCompilerVer"
  logfile=buildMac.log
  export PATH=`dirname $GccCplusplusCompiler`:$PATH

elif [ `uname` = "Linux" ]; then
  export GCMDIR=${GCMDIR:-"/gcm"}
  export JAVA_HOME=${ALT_JAVA_HOME:-$GCMDIR/where/jdk/${JAVA_VERSION}/x86.linux}
  #export JAVA_HOME=/export/avocet2/users/otisa/j2se142debugLinux

  export GccCCompiler=/usr/bin/gcc
  export GccCplusplusCompiler=/usr/bin/g++
  GccCompilerVer=`$GccCCompiler --version | head -1  2>&1 `
  export GccMajorVer="3"

  # set vars for mono if available
  MONODIR="${GCMDIR}/where/csharp/mono-2.6/x86_64.linux"
  # check if xbuild from /gcm/where works on this machine
  OLD_LD_LIBRARY_PATH="${LD_LIBRARY_PATH}"
  if [ -z "${LD_LIBRARY_PATH}" ]; then
    export LD_LIBRARY_PATH="${MONODIR}/lib"
  else
    export LD_LIBRARY_PATH="${MONODIR}/lib:${LD_LIBRARY_PATH}"
  fi
  if "${MONODIR}/bin/xbuild" /version >/dev/null 2>/dev/null; then
    export PATH="${MONODIR}/bin:${PATH}"
  else
    # reset LD_LIBRARY_PATH
    export LD_LIBRARY_PATH="${OLD_LD_LIBRARY_PATH}"
  fi
  if which xbuild >/dev/null 2>/dev/null; then
    export XBUILD="`which xbuild`"
    export MONO="`which mono`"
    echo "Using mono from: ${MONO}"
  fi

  echo "Using gcc version: $GccCompilerVer"
  logfile=buildLinux.log
  #export PATH="`dirname $GccCplusplusCompiler`:$PATH"
  if [ -n "${XBUILD}" ]; then
    export PATH="`dirname ${XBUILD}`:${PATH}"
  fi
elif [ `uname` = "AIX" ]; then
  export GCMDIR=${GCMDIR:-"/gcm"}
  export JAVA_HOME=${ALT_JAVA_HOME:-$GCMDIR/where/jdk/1.6.0-ibm/RISC6000.AIX}
  #export GccCCompiler=/bin/gcc
  #export GccCplusplusCompiler=/bin/g++
  #GccCompilerVer=`$GccCCompiler --version | head -1  2>&1 `
  #export GccMajorVer="4"
  #echo "Using gcc version: $GccCompilerVer"
  logfile=buildAIX.log
  #export PATH=`dirname $GccCplusplusCompiler`:$PATH
  NO_BUILD_LOG=1
else
  echo "Defaulting to Windows build"
  # unset TERMCAP since it causes issues when used
  # with windows environment variables
  unset TERMCAP
  # suppress DOS path warnings
  if [ -z "${CYGWIN}" ]; then
    export CYGWIN="nodosfilewarning"
  else
    export CYGWIN="${CYGWIN} nodosfilewarning"
  fi

  # Set .NET/Visual Studio environment -->
  . ./buildfiles/vcvars32_vs10.sh
  
  PING="ping -n 1"
  rm -f .xbuildfailure
  cmd.exe /c .\\build.bat "$@"
  if [ -r .xbuildfailure ]; then
    read stat <.xbuildfailure
    rm -f .xbuildfailure
    exit $stat
  fi

fi

# setup the LDAP server for Pune/Beaverton networks;

if [ -z "${LDAP_SERVER_FQDN}" ]; then
  if expr `$PING ldap.pune.gemstone.com | sed -n 's/^.* time[^ ]\([0-9\.]*\).*$/\1/p'` '<' 50 >/dev/null 2>/dev/null; then
    LDAP_SERVER_FQDN="ldap.pune.gemstone.com"
  else
    LDAP_SERVER_FQDN="ldap.gemstone.com"
  fi
fi
export LDAP_SERVER_FQDN
echo "Using LDAP server: $LDAP_SERVER_FQDN"

# Configuring ANT environment
export ANT_HOME=${ALT_ANT_HOME:-$GCMDIR/where/java/ant/apache-ant-1.8.4}
export ANT_ARGS=${ALT_ANT_ARGS:-$ANT_ARGS}
export ANT_OPTS=${ALT_ANT_OPTS:-"-Xmx512m -Dhttp.proxyHost=proxy.vmware.com -Dhttp.proxyPort=3128"}

export PATH=$ANT_HOME/bin:$JAVA_HOME/bin:$PATH

function logant {
#  if [[ `uname` == "SunOS" || `uname` == "Linux" || `uname` == "AIX" ]]; then
    rm -f .xbuildfailure
    ( $ANT_HOME/bin/ant --noconfig "$@" || echo "$?" > .xbuildfailure ) 2>&1 | tee $logfile
    if [ -r .xbuildfailure ]; then
      read stat <.xbuildfailure
      rm -f .xbuildfailure
      exit $stat
    fi
#  else
    # cygwin tee causes hang on windows
#    $ANT_HOME/bin/ant --noconfig -DuseSSH=false "$@"
#  fi
}

echo "JAVA_HOME = $JAVA_HOME"
echo "ANT_HOME = $ANT_HOME"
echo "CLASSPATH = $CLASSPATH"
date

# ant likes to be in the directory that build.xml is in
if [[ "x$NO_BUILD_LOG" == "x" ]]; then
  logant "$@"
else
  echo "running $ANT_HOME/bin/ant "
  $ANT_HOME/bin/ant --noconfig "$@"
fi

