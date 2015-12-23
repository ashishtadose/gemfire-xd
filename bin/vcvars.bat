:; if [ "x$SHELL" != "x/bin/bash" ]; then
@echo off
bash.exe "%0" %*
exit %ERRORLEVEL% 
else
#Begin the bash portion of the script
function legacy_vc_setup () {
  # Compatible with Visual Studio 6, can only build 32bit

  if [ "x$arch_bin" != "x" ]; then
    echo "ERROR: Visual Studio 6 only supports x86, upgrade to Visual Studio 8"
    exit -1
  fi
  VCVER=vc6
  VSCommonDir="`cygpath -d \"$VCINSTALLDIR/common\"`"
  MSDevDir="`cygpath -d \"$VSCommonDir/msdev98\"`"
  MSVCDir="`cygpath -d \"$VCINSTALLDIR/VC98\"`"
  VcOsDir=WINNT
  VCPATH="$MSDevDir\\BIN\;$MSVCDir\\BIN\;$VSCommonDir\\TOOLS\\$VcOsDir\;$VSCommonDir\\TOOLS\;$PATH"
  export PATH=`cygpath -mp "$VCPATH" | xargs cygpath -up`:$PATH
  export INCLUDE="$MSVCDir\\ATL\\INCLUDE\;$MSVCDir\\INCLUDE\;$MSVCDir\\MFC\\INCLUDE"
  export LIB="$MSVCDir\\LIB\;$MSVCDir\\MFC\\LIB"
}

function modern_vc_setup () {
  # Compatible with Visual Studio 10
   if [ -z "${VS10INSTALLDIR:-}" ]; then
    if [ -d "`cygpath 'c:\Program Files (x86)\Microsoft Visual Studio 10.0'`" ]; then
      export VS10INSTALLDIR=`cygpath -d 'c:\Program Files (x86)\Microsoft Visual Studio 10.0'`
    else
      echo "ERROR: Unable to determine Visual Studio version for env setup"
      exit -1
    fi  
  fi
  
  if [ -z "${MSSDK:-}" ]; then
    if [ -d "`cygpath 'C:\Program Files (x86)\Microsoft SDKs'`" ]; then
      export MSSDK=`cygpath -d 'C:\Program Files (x86)\Microsoft SDKs'`
    else
      echo "ERROR: Unable to determine Microsoft SDK path for env setup"
      exit -1
    fi  
  fi

  gf_arch_arg=32bit
  if [ "x$gf_arch_arg" == "x64bit" ]; then
    arch_bin="\\x86_amd64"
    arch_lib="\\amd64"
  elif [ "x$gf_arch_arg" == "x32bit" ]; then
    arch_bin=""
    arch_lib=""
  else
    echo "ERROR: Unable to determine Visual Studio version for env setup"
    exit -1
  fi
  # Compatible with Visual Studio 2010
  export VCINSTALLDIR="$VS10INSTALLDIR\VC"
  
  if [ -d "$VCINSTALLDIR" ]; then
    echo Setting environment for using Microsoft Visual Studio 2010 tools.
    export VCVER=vc10  
    export FrameworkDir="$SYSTEMROOT\\Microsoft.NET\\Framework"
    export FrameworkVersion=v4.0.30319
    export FrameworkSDKDir="$MSSDK\\Windows\\v7.0A"
    export DevEnvDir="$VS10INSTALLDIR\\Common7\\IDE"
  else
    echo "ERROR: Unable to determine Visual Studio version for env setup"
    exit -1
  fi

  VCPATH="$DevEnvDir;$VCINSTALLDIR\\BIN${arch_bin};$VS10INSTALLDIR\\Common7\\Tools;$VCINSTALLDIR\\Common7\\Tools\\bin;$FrameworkSDKDir\\bin;$FrameworkDir\\$FrameworkVersion"
  export PATH="`cygpath -up "$VCPATH"`:$PATH"
  export INCLUDE="$VCINSTALLDIR\\ATLMFC\\INCLUDE\;$VCINSTALLDIR\\INCLUDE\;$VCINSTALLDIR\\PlatformSDK\\include\;$FrameworkSDKDir\\include"
  export LIB="$VCINSTALLDIR\\ATLMFC\\LIB${arch_lib}\;$VCINSTALLDIR\\LIB${arch_lib}\;$FrameworkSDKDir\\lib${arch_lib}"
 echo PATH is $PATH
 echo lib is $LIB
 echo link.exe from `which link.exe`

}

function orig_modern_vc_setup () {
  # Outdated and may not work. 
  # Compatible with Visual Studio 2003 and 2005
  #export VSINSTALLDIR="$VCINSTALLDIR\Common7\IDE"
  export VSINSTALLDIR=C:\\PROGRA~2\\MICROS~2
  export FrameworkDir="$SYSTEMROOT\Microsoft.NET\Framework"

  DevEnvDir="$VSINSTALLDIR"

  if [ -d "$VCINSTALLDIR\VC" ]; then
    echo Setting environment for using Microsoft Visual Studio 2005 tools.
    MSVCDir="$VCINSTALLDIR\VC"
    VCVER=vc8
    export FrameworkSDKDir=${FrameworkSSDKDir:-"$VCINSTALLDIR\SDK\v2.0"}
    export FrameworkVersion=${FrameWorkVersion:-v2.0.50727}
    
  else
    echo "ERROR: Unable to determine Visual Studio version for env setup"
    exit -1
  fi

  VCPATH="$DevEnvDir\;$MSVCDir\\BIN${arch_bin};$VCINSTALLDIR\\Common7\\Tools;$VCINSTALLDIR\\Common7\\Tools\\bin;$FrameworkSDKDir\\bin;$FrameworkDir\\$FrameworkVersion"
  export PATH=`cygpath -mp "$VCPATH" | xargs cygpath -up`:$PATH
  export INCLUDE="$MSVCDir\\ATLMFC\\INCLUDE\;$MSVCDir\\INCLUDE\;$MSVCDir\\PlatformSDK\\include\;$FrameworkSDKDir\\include"
  export LIB="$MSVCDir\\ATLMFC\\LIB${arch_lib}\;$MSVCDir\\LIB${arch_lib}\;$MSVCDir\\PlatformSDK\\lib${arch_lib}\;$FrameworkSDKDir\\lib${arch_lib}"
}

if [ "x$GFLIB_MODEL" == "x64bit" ]; then
  arch_bin="\\x86_amd64"
  arch_lib="\\amd64"
elif [ "x$GFLIB_MODEL" == "x32bit" ]; then
  arch_bin=""
  arch_lib=""
else
  echo "ERROR: Unable to determine Visual Studio version for env setup"
  exit -1
fi

if [ -z "${VCINSTALLDIR:-}" ]; then
  if [ -d "`cygpath 'c:\devstudio60'`" ]; then
    export VCINSTALLDIR='c:\devstudio60'
  elif [ -d "`cygpath 'c:\Program Files\Microsoft Visual Studio 8'`" ]; then
    export VCINSTALLDIR=`cygpath -d 'c:\Program Files\Microsoft Visual Studio 8'`
  elif [ -d "`cygpath 'c:\Program Files\Microsoft Visual Studio .NET 2003'`" ]; then
    export VCINSTALLDIR=`cygpath -d 'c:\Program Files\Microsoft Visual Studio .NET 2003'`
  elif [ -d "`cygpath 'c:\Program Files\Microsoft Visual Studio 9.0'`" ]; then
    export VCINSTALLDIR=`cygpath -d 'c:\Program Files\Microsoft Visual Studio 9.0'`
  else
    echo "ERROR: Unable to determine Visual Studio version for env setup"
    exit -1
  fi  
fi

# uncomment to see setup output
# May need to set VSINSTALLDIR prior to rebuilding if not in environment
# This works for fool
#set -xv
export VSINSTALLDIR="${VSINSTALLDIR:-C:/PROGRA~2/MICROS~1.0}"
echo "Running vcvars.bat..."
modern_vc_setup 

make "$@"
fi

