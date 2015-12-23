#!/bin/bash -x

# Script to configure VS 2010 environment for ADO.NET components

function modern_vc_setup () {
  if [ -z "${VSINSTALLDIR:-}" ]; then
    if [ -d "`cygpath 'c:\Program Files (x86)\Microsoft Visual Studio 10.0'`" ]; then
      export VSINSTALLDIR=`cygpath -d 'c:\Program Files (x86)\Microsoft Visual Studio 10.0'`
    else
      echo "WARNING: Unable to find Visual Studio 2010 install location, will not able to build ADO.NET components"
    fi  
  fi

  # Compatible with Visual Studio 2010
  export VCINSTALLDIR="$VSINSTALLDIR\VC"
  export MSSDK=`cygpath -d 'c:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A'`

  if [ -d "$VCINSTALLDIR" ]; then
    echo Setting environment for using Microsoft Visual Studio 2010 tools.
    export VCVER=vc10
    export FrameworkDir="$SYSTEMROOT\\Microsoft.NET\\Framework"
    export FrameworkVersion=v4.0.30319
    export FrameworkSDKDir="$VSINSTALLDIR\\SDK\\$FrameworkVersion"
    export DevEnvDir="$VSINSTALLDIR\\Common7\\IDE"
  fi

  VCPATH="$DevEnvDir;$VCINSTALLDIR\\BIN${arch_bin};$VSINSTALLDIR\\Common7\\Tools;$VCINSTALLDIR\\Common7\\Tools\\bin;$FrameworkSDKDir\\bin;$FrameworkDir\\$FrameworkVersion;$MSSDK\\Bin"
  export PATH="`cygpath -up "$VCPATH"`:$PATH"
  export INCLUDE="$VCINSTALLDIR\\ATLMFC\\INCLUDE\;$VCINSTALLDIR\\INCLUDE\;$VCINSTALLDIR\\PlatformSDK\\include\;$FrameworkSDKDir\\include;$MSSDK\\Include"
  export LIB="$VCINSTALLDIR\\ATLMFC\\LIB${arch_lib}\;$VCINSTALLDIR\\LIB${arch_lib}\;$VCINSTALLDIR\\PlatformSDK\\lib${arch_lib}\;$FrameworkSDKDir\\lib${arch_lib};;$MSSDK\\Lib"
}

echo "Running vcvars32_vs10.sh"
modern_vc_setup
