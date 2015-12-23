# Set distribution
%define dist            .el5

Name:       pivotal-helios
Version:    @VERSION@
Release:    1%{?dist}
Summary:    Pivotal Helios
Group:      Applications/Databases
License:    Commercial
Vendor:     Pivotal, Inc.
Packager:   support@vmware.com
URL:        http://www.vmware.com/products/application-platform/vfabric-gemfirexd/overview.html
# source1 is the sysV init script
Source1:    pivotal-helios
# source2 is the sysconfig config file
Source2:    helios.sysconfig
Source3:    helios.properties
BuildArch:  noarch
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

# name of the dir created when the jar is unzipped
%define JarDirName  @JARNAME@
# version string to aid in upgrades
%define InstallDir  /usr/lib/gphd/pivotal-helios
%define DataDir     /etc/gphd/pivotal/helios
%define GroupName   pivotal
%define UserName    helios
# setting the users home dir to the data dir
%define UserHome    %{DataDir}
%define UserShell   /sbin/nologin
%define UserComment "Pivotal Helios"
%define HELIOS_LOG_DIR    /var/log/pivotal/helios 
%define HELIOS_LOG_NAME   helios-server.log 
# Same as the script in source1
%define InitScript  pivotal-helios 
# names for the sysconfig file
%define ConfigFileBuildName helios.sysconfig
%define ConfigFileProdName  helios 
%define PropertiesFile      helios.properties
%define _initddir           /etc/init.d
# don't repack jars
%define __os_install_post %{nil}
# Do not fail rpmbuild because of arch dependent binaries
%define _binaries_in_noarch_packages_terminate_build 0

%description
Pivotal Helios is memory-optimized data management software delivering
application data at runtime with horizontal scale and lightning-fast
performance while providing developers with the well-known SQL interface and
tools.

%prep

%build
echo "entering build"
#Note that in this section configure


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
mkdir -p %{buildroot}/%{HELIOS_LOG_DIR}
touch %{buildroot}/%{HELIOS_LOG_DIR}/%{HELIOS_LOG_NAME}
#mkdir -p %{buildroot}/etc/init.d/
#cp -p %{_builddir}/%{InitScript} %{buildroot}%{_initddir}/
#mkdir -p %{buildroot}/etc/sysconfig/
#cp -p %{_builddir}/%{ConfigFileBuildName} %{buildroot}/etc/sysconfig/%{ConfigFileProdName}
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
%ghost %{HELIOS_LOG_DIR}/%{HELIOS_LOG_NAME}
%defattr(755, %{UserName}, root, 755)
%dir %{HELIOS_LOG_DIR}
%defattr(755, root, root)
#/etc/init.d/%{InitScript}
%defattr(644, root, root)
#%config /etc/sysconfig/%{ConfigFileProdName}
#%defattr(644, %{UserName}, %{GroupName})
#%config %{InstallDir}/%{JarDirName}/%{PropertiesFile}


%post
#chown -R %{UserName}:%{GroupName} %{InstallDir}
# Add the init script to chkconfig
#/sbin/chkconfig --add %{InitScript}
# allow the dir to be writable to the gemfirexd user
#chown %{UserName} %{GFXD_LOG_DIR}
# Add softlinks for gfxd to /usr/bin
ln -sf %{InstallDir}/%{JarDirName}/bin/gfxd %_bindir/gfxd
# Create the default server startup directory
if [ ! -d %{DataDir}/server ]; then
   %{__mkdir} -p -m 755 %{DataDir}/server
   chown %{UserName}:%{GroupName} %{DataDir}/server
fi


%preun
#/etc/init.d/%{InitScript} stop > /dev/null 2>&1
# If we are doing an erase
#if [ $1 = 0 ]; then
#   /sbin/chkconfig --del %{InitScript}
#fi

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
   if [ -h %_bindir/gfxd ]; then
      rm -f %_bindir/gfxd
   fi
fi

%posttrans
 #This is for upgrades, where the uninstall sections of the old rpm are run 
 #after the installation of the new rpm, nuking anything run in the post
 #section. posttrans of the new package is the final thing to be run.
 #Below will come in handy for upgrades of old rpms without the fix.
 if [ ! -h %_bindir/gfxd ]; then
    ln -sf %{InstallDir}/%{JarDirName}/bin/gfxd %_bindir/gfxd
 fi
 #/sbin/chkconfig --add %{InitScript}
 # change the user home directory to point to the new location
 usermod -d %{UserHome} -g %{GroupName} %{UserName}


%changelog
* Tue Jul 23 2013 Pivotal Support 1.0.0-1
- Initial RPM for ICM Integration