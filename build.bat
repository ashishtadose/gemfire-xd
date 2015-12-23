@echo off
set scriptdir=%~dp0
set BASEDIR=%scriptdir:\buildfiles\=%
if exist "%BASEDIR%\build.xml" @goto baseok
echo Could not determine BASEDIR location
verify other 2>nul
goto done
:baseok

set GEMFIRE=
set CYGWIN=nodosfilewarning

if not defined GCMDIR (
  set GCMDIR=J:\
)
if not exist %GCMDIR% (
  echo ERROR: unable to locate GCMDIR %GCMDIR% maybe you forgot to map the J: network drive to //samba/gcm
  verify other 2>nul
  goto done
)

set LDAP_SERVER_FQDN=ldap.gemstone.com
rem if exist \\pike\pike1\users (
rem  set LDAP_SERVER_FQDN=ldap.pune.gemstone.com
rem )


set MONODIR=%GCMDIR%\where\csharp\mono-2.6\x86_64.windows_NT
if not exist %MONODIR%\bin\xbuild.bat ( 
  echo Unable to locate MONODIR %MONODIR%
  set MONODIR=
)
  set PATH=%MONODIR%\bin;c:\Program Files ^(x86^)\MonoDevelop\bin;c:\Program Files ^(x86^)\GtkSharp\2.12\bin;%PATH%
  set XBUILD=%MONODIR%/bin/xbuild
  set MONO=%MONODIR%/bin/mono
  echo Using mono from: %MONODIR%

set JAVA_HOME=%GCMDIR%\where\jdk\1.7.0_72\x86.Windows_NT
if defined ALT_JAVA_HOME (
  set JAVA_HOME=%ALT_JAVA_HOME%
)
set ANT_HOME=%GCMDIR%\where\java\ant\apache-ant-1.8.4
if defined ALT_ANT_HOME (
  set ANT_HOME=%ALT_ANT_HOME%
)
set ANT_OPTS=-Xmx1024m -Dhttp.proxyHost=proxy.eng.vmware.com -Dhttp.proxyPort=3128
if defined ALT_ANT_OPTS (
  set ANT_OPTS=%ALT_ANT_OPTS%
)
set ANT_ARGS=%ANT_ARGS% -lib %GCMDIR%\where\java\jcraft\jsch\jsch-0.1.44\jsch-0.1.44.jar
set PATHOLD=%PATH%
set PATH=%JAVA_HOME%\bin;%PATH%

echo JAVA_HOME = %JAVA_HOME%
echo ANT_HOME = %ANT_HOME%
echo CLASSPATH = %CLASSPATH%
echo %DATE% %TIME%

echo running %ANT_HOME%\bin\ant.bat with ANT_OPTS=%ANT_OPTS% 
call %ANT_HOME%\bin\ant.bat %*
if not defined ERRORLEVEL set ERRORLEVEL=0

:done
echo %ERRORLEVEL% > .xbuildfailure
set ERRORLEVEL=
if defined PATHOLD set PATH=%PATHOLD%
