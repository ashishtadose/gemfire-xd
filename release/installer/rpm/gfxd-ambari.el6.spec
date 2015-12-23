# Set distribution
%define dist            .el6

Name:       gfxd-ambari
Version:    @VERSION@
Release:    @BUILD_NUMBER@
Summary:    Pivotal GemFire XD
Group:      Applications/Databases
License:    Commercial
Vendor:     Pivotal Software, Inc.
Packager:   support@pivotal.io
URL:        http://pivotal.io/products/pivotal-gemfirexd
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Obsoletes:  gfxd < 1.0

# name of the dir created when the jar is unzipped
%define InstallDirName @JARNAME@
%define ProductName gfxd
%define InstallBase /usr/lib
%define InstallDir  %{InstallBase}/%{InstallDirName}
%define DataDir     /var/lib/%{ProductName}
%define GroupName   gpadmin
%define UserName    gfxd
# setting the users home dir to the data dir
%define UserHome    %{DataDir}
%define UserShell   /sbin/nologin
%define UserComment "%{summary}"
%define GFXD_LOG_DIR    /var/log/%{ProductName}
%define GFXD_LOCATOR_LOG_DIR   %{GFXD_LOG_DIR}/locator
%define GFXD_SERVER_LOG_DIR   %{GFXD_LOG_DIR}/server
%define GFXD_LOCATOR_LOG_NAME   gfxdlocator.log
%define GFXD_SERVER_LOG_NAME    gfxdserver.log
# Init scripts
%define InitBuildScript  gfxd-ambari.init
%define InitProdScript   gfxd
# names for the sysconfig file
%define ConfigFileBuildName gfxd-ambari.sysconfig
%define ConfigFileProdName  gfxd 
%define PropertiesFile      gemfirexd.properties
%define _initddir           /etc/init.d
# don't repack jars
%define __os_install_post %{nil}
# Do not fail rpmbuild because of arch dependent binaries
%define _binaries_in_noarch_packages_terminate_build 0

%description
%{summary} is memory-optimized data management software delivering
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
mkdir -p %{buildroot}%{InstallDir}
cp -rp %{_sourcedir}/%{InstallDirName}/* %{buildroot}%{InstallDir}
rm -f %{buildroot}%{InstallDir}/bin/gfxd.bat
# create the data dir
mkdir -p %{buildroot}/%{DataDir}
# prep to ghost the logfile to have it in the rpm db
mkdir -p %{buildroot}/%{GFXD_SERVER_LOG_DIR} %{buildroot}/%{GFXD_LOCATOR_LOG_DIR}
touch %{buildroot}/%{GFXD_SERVER_LOG_DIR}/%{GFXD_SERVER_LOG_NAME} %{buildroot}/%{GFXD_LOCATOR_LOG_DIR}/%{GFXD_LOCATOR_LOG_NAME}
mkdir -p %{buildroot}/etc/init.d/
cp -p %{_builddir}/%{InitBuildScript} %{buildroot}%{_initddir}/%{InitProdScript}
mkdir -p %{buildroot}/etc/sysconfig/
cp -p %{_builddir}/%{ConfigFileBuildName} %{buildroot}/etc/sysconfig/%{ConfigFileProdName}
echo "Copy Properties File"
cp -p %{_builddir}/%{PropertiesFile} %{buildroot}/%{InstallDir}
echo "Install Phase Complete"
#clean
echo "entering clean"

echo "entering files"
%files
%defattr(664, %{UserName}, %{GroupName}, 775)
#%{InstallDir}
%{InstallDir}/*
%defattr(775, %{UserName}, %{GroupName}, 775)
%{InstallDir}/bin/*
%{InstallDir}/examples/mapreduce/scripts/*.sh
%{InstallDir}/tools/vsd/bin/*
%{DataDir}
%doc %{InstallDir}/docs/index.html
%doc %{InstallDir}/docs/support.html
%defattr(644, %{UserName}, %{GroupName})
%ghost %{GFXD_LOCATOR_LOG_DIR}/%{GFXD_LOCATOR_LOG_NAME}
%ghost %{GFXD_SERVER_LOG_DIR}/%{GFXD_SERVER_LOG_NAME}
%defattr(755, %{UserName}, root, 775)
%dir %{GFXD_LOG_DIR}
%dir %{GFXD_SERVER_LOG_DIR}
%dir %{GFXD_LOCATOR_LOG_DIR}
%defattr(755, root, root)
/etc/init.d/%{InitProdScript}
%defattr(644, root, root)
%config /etc/sysconfig/%{ConfigFileProdName}
%defattr(644, %{UserName}, %{GroupName})
%config %{InstallDir}/%{PropertiesFile}

%post
#chown -R %{UserName}:%{GroupName} %{InstallDir}
# Add the init script to chkconfig
/sbin/chkconfig --add %{InitProdScript}
# allow the dir to be writable to the gemfirexd user
chown %{UserName} %{GFXD_LOG_DIR}
# Add softlinks for gfxd to /usr/bin
ln -sf %{InstallDir}/bin/gfxd %_bindir/gfxd
# Add softlinks for sqlf to /usr/bin
ln -sf %{InstallDir}/bin/sqlf %_bindir/sqlf
# Add symlink to /usr/lib/gfxd
ln -sf %{InstallDir} %{InstallBase}/%{ProductName}
# Create the default server startup directory
if [ ! -d %{DataDir}/server ]; then
   %{__mkdir} -p -m 755 %{DataDir}/server
   chown %{UserName}:%{GroupName} %{DataDir}/server
fi
mkdir -p /usr/share/doc/gphd/%{InstallDir}
cp -rp %{InstallDir}/docs /usr/share/doc/gphd/%{ProductName}


%preun
/etc/init.d/%{InitProdScript} stop > /dev/null 2>&1
# If we are doing an erase
if [ $1 = 0 ]; then
   /sbin/chkconfig --del %{InitProdScript}
fi

%postun
# Check if we are performing an erase
if [ $1 = 0 ]; then
   # if the users home dir and data dir are empty, remove the user account and logs
   if [ `ls -A %{UserHome} 2>/dev/null | wc -l` = "0" -a `ls -A %{DataDir} 2>/dev/null | wc -l` = "0" ] ; then
      # this will remove the group as well
      userdel %{UserName} > /dev/null
      if [ -d %{UserHome} ] ; then
         rmdir %{UserHome}
      fi
      if [ -d %{DataDir} ] ; then
         rmdir %{DataDir}
      fi
      if [ -d %{GFXD_LOG_DIR} ] ; then
         rmdir %{GFXD_LOG_DIR}
      fi
   fi
   if [ -h %_bindir/gfxd ]; then
      rm -f %_bindir/gfxd
   fi
   if [ -h %_bindir/sqlf ]; then
      rm -f %_bindir/sqlf
   fi
   
   if [ -h %{InstallBase}/%{ProductName} ]; then
      rm -f %{InstallBase}/%{ProductName}
   fi
   rm -rf %{InstallDir} /usr/share/doc/gphd/%{ProductName}
fi

%posttrans
 #This is for upgrades, where the uninstall sections of the old rpm are run 
 #after the installation of the new rpm, nuking anything run in the post
 #section. posttrans of the new package is the final thing to be run.
 #Below will come in handy for upgrades of old rpms without the fix.
 if [ ! -h %_bindir/gfxd ]; then
    ln -sf %{InstallDir}/bin/gfxd %_bindir/gfxd
 fi
 
 if [ ! -h %_bindir/sqlf ]; then
    ln -sf %{InstallDir}/bin/sqlf %_bindir/sqlf
 fi
 
 if [ ! -h %{InstallBase}/%{ProductName} ]; then
    ln -sf %{InstallDir} %{InstallBase}/%{ProductName}
 fi
 
 if [ -h %{InstallBase}/%{ProductName} ]; then
    rm -f  %{InstallBase}/%{ProductName}
    ln -sf %{InstallDir} %{InstallBase}/%{ProductName}
 fi
 
 if [ -d %{InstallBase}/Pivotal_GemFireXD_05Beta2 ]; then
    rm -rf %{InstallBase}/Pivotal_GemFireXD_05Beta2
 fi

 /sbin/chkconfig --add %{InitProdScript}
 # change the user home directory to point to the new location
 if [ "`eval echo ~%{UserName}`" != "%{UserHome}" ]; then
     usermod -d %{UserHome} -g %{GroupName} %{UserName}
 fi


%changelog
* @RPM_DATE@ Pivotal Support <support@pivotal.io> @VERSION@-@BUILD_NUMBER@
- Pivotal GemFire XD @VERSION@
* Mon Sep 15 2014 Pivotal Support <support@pivotal.io> 1.3.0
- Pivotal GemFire XD 1.3.0
* Fri Jan 31 2014 Pivotal Support 1.0.0
- Pivotal GemFire XD 1.0.0
