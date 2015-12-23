# Set distribution
%define dist            .el7

Name:       pivotal-gemfirexd
Version:    @VERSION@
Release:    @BUILD_NUMBER@%{?dist}
Summary:    Pivotal GemFire XD
Group:      Applications/Databases
License:    Commercial
Vendor:     Pivotal Software, Inc.
Packager:   info@pivotal.io
URL:        http://pivotal.io/products/pivotal-gemfirexd
Obsoletes:  vfabric-sqlfire, pivotal-sqlfire
BuildArch:  noarch
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

# source1 is the sysV init script
Source1:    gemfirexd
# source2 is the sysconfig config file
Source2:    gemfirexd.sysconfig
Source3:    gemfirexd.properties

# name of the dir created when the jar is unzipped
%define JarDirName  @JARNAME@
# version string to aid in upgrades
%define InstallDir  /opt/pivotal/gemfirexd
%define DataDir     /var/lib/pivotal/gemfirexd
%define GroupName   pivotal
%define UserName    gfxd
# don't repack jars
#define __jar_repack    0
# Disable JAR compression
%define __os_install_post %{nil}
# Do not fail rpmbuild because of arch dependent binaries
%define _binaries_in_noarch_packages_terminate_build   0
# setting the users home dir to the data dir
%define UserHome    %{DataDir}
%define UserShell   /sbin/nologin
%define UserComment "Pivotal GemFire XD"
%define GFXD_LOG_DIR    /var/log/pivotal/gemfirexd
%define GFXD_LOG_NAME   gemfirexd-server.log 
%define InitScriptBuildName  gemfirexd.init
%define InitScriptProdName   gemfirexd
# names for the sysconfig file
%define ConfigFileBuildName gemfirexd.sysconfig
%define ConfigFileProdName  gemfirexd
%define PropertiesFile      gemfirexd.properties
%define _initddir           /etc/init.d

%description
Pivotal GemFire XD is memory-optimized data management software delivering
application data at runtime with horizontal scale and lightning-fast
performance while providing developers with the well-known SQL interface and
tools.

%prep

%build
echo "entering build"
#Note that in this section configure
#make %{?_smp_mflags}
# Remove files that are not needed in the rpm
rm -f %{_builddir}/%{name}-%{version}/i18n.properties
rm -rf %{_builddir}/%{name}-%{version}/META-INF
rm -f %{_builddir}/%{name}-%{version}/*.class
# remove Windows files
rm -f %{_builddir}/%{name}-%{version}/%{JarDirName}/bin/*.bat
#rm -rf %{_builddir}/%{name}-%{version}/%{JarDirName}/lib/adonet
rm -f %{_builddir}/%{name}-%{version}/%{JarDirName}/adonet/lib/*.pdb
rm -f %{_builddir}/%{name}-%{version}/%{JarDirName}/adonet/lib/debug/*.pdb
rm -rf %{_builddir}/%{name}-%{version}/%{JarDirName}/adonet/SQLFireDesigner
rm -rf %{_builddir}/%{name}-%{version}/%{JarDirName}/opensource

%pre

# create group and user account if they do not exist
if [ ! -n "`/usr/bin/getent group %{GroupName}`" ]; then
    %{_sbindir}/groupadd %{GroupName} 2> /dev/null
fi
if [ ! -n "`/usr/bin/getent passwd %{UserName}`" ]; then
    %{__mkdir} -p -m 755 %{UserHome}
    %{_sbindir}/useradd -g %{GroupName} -d %{UserHome} -s %{UserShell} -c %{UserComment} %{UserName} 2> /dev/null
    chown -R %{UserName}:%{GroupName} %{UserHome}
   
else
    %{__mkdir} -p -m 755 %{UserHome}
    chown %{UserName}:%{GroupName} %{UserHome}
fi


%install
echo "entering install"
rm -rf %{buildroot}
mkdir -p %{buildroot}%{InstallDir}/@JARNAME@/
cp -rp %{_sourcedir}/@JARNAME@/* %{buildroot}%{InstallDir}/@JARNAME@
# create the data dir
mkdir -p %{buildroot}/%{DataDir}
# prep to ghost the logfile to have it in the rpm db
mkdir -p %{buildroot}/%{GFXD_LOG_DIR}
touch %{buildroot}/%{GFXD_LOG_DIR}/%{GFXD_LOG_NAME}
mkdir -p %{buildroot}/etc/init.d/
cp -p %{_builddir}/%{InitScriptBuildName} %{buildroot}%{_initddir}/%{InitScriptProdName}
mkdir -p %{buildroot}/etc/sysconfig/
cp -p %{_builddir}/%{ConfigFileBuildName} %{buildroot}/etc/sysconfig/%{ConfigFileProdName}
echo "Copy Properties File"
cp -p %{_builddir}/%{PropertiesFile} %{buildroot}/%{InstallDir}/%{JarDirName}/
echo "Install Phase Complete"
#clean
echo "entering clean"

echo "entering files"
%files
%defattr(644, %{UserName}, %{GroupName}, 755)
%{InstallDir}/*
%defattr(755, %{UserName}, %{GroupName}, 755)
%{InstallDir}/%{JarDirName}/bin/*
%{InstallDir}/%{JarDirName}/tools/vsd/bin/*
%{DataDir}
%doc %{InstallDir}/%{JarDirName}/docs/index.html
%doc %{InstallDir}/%{JarDirName}/docs/support.html
%defattr(644, %{UserName}, %{GroupName})
%ghost %{GFXD_LOG_DIR}/%{GFXD_LOG_NAME}
%defattr(755, %{UserName}, root, 755)
%dir %{GFXD_LOG_DIR}
%defattr(755, root, root)
/etc/init.d/%{InitScriptProdName}
%defattr(644, root, root)
%config /etc/sysconfig/%{ConfigFileProdName}
%defattr(644, %{UserName}, %{GroupName})
%config %{InstallDir}/%{JarDirName}/%{PropertiesFile}


%post
#chown -R %{UserName}:%{GroupName} %{InstallDir}
# Add the init script to chkconfig
/sbin/chkconfig --add %{InitScriptProdName}
# allow the dir to be writable to the gfxd user
#chown %{UserName} %{GFXD_LOG_DIR}
# Add softlinks for sqlf to /usr/bin
ln -sf %{InstallDir}/%{JarDirName}/bin/sqlf %_bindir/sqlf
# Add softlinks for gfxd to /usr/bin
ln -sf %{InstallDir}/%{JarDirName}/bin/gfxd %_bindir/gfxd


%preun
/etc/init.d/%{InitScriptProdName} stop > /dev/null 2>&1
# If we are doing an erase
if [ $1 = 0 ]; then
   /sbin/chkconfig --del %{InitScriptProdName}
fi

%postun
# Check if we are performing an erase
if [ $1 = 0 ]; then
   # if the users home dir and data dir are empty, remove the user account
   if [ `ls -A %{UserHome} 2>/dev/null | wc -l` = "0" -a `ls -A %{DataDir} 2>/dev/null | wc -l` = "0" ] ; then
      # this will remove the group as well
      userdel %{UserName} > /dev/null
      if [ -d %{UserHome} ] ; then
         rmdir %{UserHome}
      fi
      if [ -d %{DataDir} ] ; then
         rmdir %{DataDir}
      fi
   fi
   if [ -h %_bindir/sqlf ]; then
      rm -f %_bindir/sqlf
   fi
   if [ -h %_bindir/gfxd ]; then
      rm -f %_bindir/gfxd
   fi

fi

%posttrans
 #This is for upgrades, where the uninstall sections of the old rpm are run 
 #after the installation of the new rpm, nuking anything run in the post
 #section. posttrans of the new package is the final thing to be run.
 #Below will come in handy for upgrades of old rpms without the fix.
 if [ ! -h %_bindir/sqlf ]; then
    ln -sf %{InstallDir}/%{JarDirName}/bin/sqlf %_bindir/sqlf
 fi
 if [ ! -h %_bindir/gfxd ]; then
    ln -sf %{InstallDir}/%{JarDirName}/bin/gfxd %_bindir/gfxd
 fi
 /sbin/chkconfig --add %{InitScriptProdName}
 # change the user home directory to point to the new location
 if [ "`eval echo ~%{UserName}`" != "%{UserHome}" ]; then
     usermod -d %{UserHome} -g %{GroupName} %{UserName}
 fi
 # create group and user account if they do not exist
 if [ ! -n "`/usr/bin/getent group %{GroupName}`" ]; then
     %{_sbindir}/groupadd %{GroupName} 2> /dev/null
 fi
 if [ ! -n "`/usr/bin/getent passwd %{UserName}`" ]; then
     %{__mkdir} -p -m 755 %{UserHome}
     %{_sbindir}/useradd -g %{GroupName} -d %{UserHome} -s %{UserShell} -c %{UserComment} %{UserName} 2> /dev/null
     chown -R %{UserName}:%{GroupName} %{UserHome}
 else
     %{__mkdir} -p -m 755 %{UserHome}
     usermod -g %{GroupName} -d %{UserHome} -s %{UserShell} -c %{UserComment} %{UserName} 2> /dev/null
     chown %{UserName}:%{GroupName} %{UserHome}
 fi

%changelog
* @RPM_DATE@ Pivotal Support <support@pivotal.io> @VERSION@-@BUILD_NUMBER@
- Pivotal GemFire XD 1.3.0
