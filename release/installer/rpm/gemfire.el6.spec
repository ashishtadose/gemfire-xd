#Set Distribution
%define dist	.el6

Name: 		vfabric-gemfire		
Version:	@VERSION@
Release:	1%{?dist}
Summary: 	VMware vFabric GemFire
Group:		Applications/Internet
License:	Commercial
Vendor:         VMware, Inc.
Packager:       support@vmware.com
URL:		http://www.vmware.com/products/application-platform/vfabric-gemfire/overview.html

# source1 is the sysV init script
Source1:	cacheserver.init
# source2 is the sysconfig config file
Source2:	cacheserver.sysconfig
# source3 is the conf file for /etc/vmware/vfabric-gemfire
Source3:	cacheserver.conf

BuildArch:      noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

# name of the dir created when the jar is unzipped
%define JarDirName	@JARNAME@
# version string to aid in upgrades
%define InstallDir	/opt/vmware/vfabric-gemfire
%define GroupName	vfabric
%define UserName	gemfire
# setting the users home dir to the installation dir
%define UserHome	%{InstallDir}
%define UserShell	/sbin/nologin
%define UserComment	"vFabric GemFire" 	
%define LOG_DIR	/var/log/vmware/vfabric-gemfire/cacheserver
# Same as the script in source1
%define InitScriptBuildName	 cacheserver%{dist}.init
%define InitScriptProdName	 cacheserver
# names for the sysconfig file
%define ConfigFileBuildName	cacheserver.sysconfig
%define ConfigFileProdName	cacheserver 
# conf file
%define ConfFileBuildName	cacheserver.conf
%define ConfFileProdName	cacheserver.conf
%define ConfFileDir		/etc/vmware/vfabric-gemfire
%define GFSHScript		gfsh
%define GemFireScript		gemfire
%define GemFireJarSoftLink	/usr/share/java/gemfire-%{version}.jar
%define _initddir		/etc/init.d
# Required to fix the issue of the rpm failing with Arch dependent binaries
# in a norach package. Use rpmlint to determine which binaries rpmbuild
# thinks are arch-dependent
%define _binaries_in_noarch_packages_terminate_build 0
# Disable JAR compression
%define __os_install_post %{nil}

%description
VMware vFabric GemFire is a distributed data management platform providing
dynamic scalability, high performance, and database-like persistence. It blends
advanced techniques like replication, partitioning, data-aware routing, and
continuous querying.

%prep

%build
echo "Entering Build"
#Note that in this section configure
#make %{?_smp_mflags}
# Remove files that are not needed in the rpm
# remove Windows files
rm -f %{_sourcedir}/%{JarDirName}/bin/*.bat
rm -f %{_sourcedir}/%{JarDirName}/tools/vsd/bin/*.bat

%pre
# create group and user account if they do not exist
if [ ! -n "`/usr/bin/getent group %{GroupName}`" ]; then
    %{_sbindir}/groupadd %{GroupName} 2> /dev/null
fi
if [ ! -n "`/usr/bin/getent passwd %{UserName}`" ]; then
    %{__mkdir} -p -m 755 %{UserHome}
    %{_sbindir}/useradd -g %{GroupName} -d %{UserHome} -s %{UserShell} -c %{UserComment} %{UserName} 2> /dev/null
    chown -R %{UserName}:%{GroupName} %{UserHome}
elif [ `getent passwd gemfire | grep -c lib` -gt "0" ]; then
    # An old gemfire user account still exists, modify it 
    # cannot use -m here reliably
    usermod -d %{UserHome} -g %{GroupName} %{UserName}
    ##usermod -g %{GroupName} %{UserName}

else
    %{__mkdir} -p -m 755 %{UserHome}
    chown %{UserName}:%{GroupName} %{UserHome}
fi


%install
echo "Entering Install"
rm -rf %{buildroot}
mkdir -p %{buildroot}%{InstallDir}/@JARNAME@/
cp -rp %{_sourcedir}/@JARNAME@/* %{buildroot}%{InstallDir}/@JARNAME@
# prep to ghost the logfile to have it in the rpm db
mkdir -p %{buildroot}/%{LOG_DIR}
mkdir -p %{buildroot}%{_initddir}
cp -p %{_builddir}/%{InitScriptBuildName} %{buildroot}%{_initddir}/%{InitScriptProdName}
mkdir -p %{buildroot}/etc/sysconfig/
cp -p %{_builddir}/%{ConfigFileBuildName} %{buildroot}/etc/sysconfig/%{ConfigFileProdName}
mkdir -p %{buildroot}/%{ConfFileDir}
cp -p %{_builddir}/%{ConfFileBuildName} %{buildroot}/%{ConfFileDir}/%{ConfFileProdName}
mkdir -p %{buildroot}/usr/bin
#clean
echo "Entering Clean"

echo "Entering Files"
%files
%defattr(644, %{UserName}, %{GroupName}, 755)
%{InstallDir}/*
%defattr(755, %{UserName}, %{GroupName}, 755)
%{InstallDir}/%{JarDirName}/bin/*
%{InstallDir}/%{JarDirName}/tools/DiskConverterPre65to65/bin/*.sh
%{InstallDir}/%{JarDirName}/tools/vsd/bin/*
#%doc %{InstallDir}/%{JarDirName}/docs/INSTALL.txt
%doc %{InstallDir}/%{JarDirName}/docs/index.html
%doc %{InstallDir}/%{JarDirName}/docs/support.html
%defattr(755, %{UserName}, %{GroupName}, 755)
%dir %{LOG_DIR}
%defattr(755, root, root)
/%{_initddir}/%{InitScriptProdName}
%defattr(644, root, root)
%config /etc/sysconfig/%{ConfigFileProdName}
%defattr(644, %{UserName}, %{GroupName})
%config %{ConfFileDir}/%{ConfFileProdName}

%post
#chown -R %{UserName}:%{GroupName} %{InstallDir}
# In the event the user account already existed from an old rpm
# ensure perms get set on the vew home dir
chown %{UserName}:%{GroupName} %{UserHome}
# Add the init script to chkconfig
/sbin/chkconfig --add %{InitScriptProdName}
# allow the dir to be writable to the gemfire user
#chown -R %{UserName}:%{GroupName} %{LOG_DIR}
# Add softlinks for gemfire to /usr/share/java
if [ ! -d /usr/share/java ]; then
  mkdir -p /usr/share/java
fi
ln -sf %{InstallDir}/%{JarDirName}/lib/gemfire.jar %{GemFireJarSoftLink}
ln -sf %{InstallDir}/@JARNAME@/bin/%{GFSHScript} %{_bindir}/%{GFSHScript}
ln -sf %{InstallDir}/@JARNAME@/bin/%{GemFireScript} %{_bindir}/%{GemFireScript}

%preun
%{_initddir}/%{InitScriptProdName} stop > /dev/null 2>&1
# If we are doing an erase
if [ $1 = 0 ]; then
   /sbin/chkconfig --del %{InitScriptProdName}
fi

%postun
# Check if we are performing an erase
if [ $1 = 0 ]; then
   # if the users home dir is empty, remove the user account
   if [ `ls -A %{UserHome} | wc -l` = "0" ] ; then
      # this will remove the group as well
      userdel %{UserName} > /dev/null
      rmdir %{InstallDir}
   fi
   if [ -f %_bindir/%{GemFireScript} ]; then
      rm -f %_bindir/%{GemFireScript}
   fi
   if [ -f %_bindir/%{GFSHScript} ]; then
      rm -f %_bindir/%{GFSHScript}
   fi
fi

%posttrans
 #This is for upgrades, where the uninstall sections of the old rpm are run 
 #after the installation of the new rpm, nuking anything run in the post
 #section. posttrans of the new package is the final thing to be run.
 #Below will come in handy for upgrades of old rpms without the fix.
 /sbin/chkconfig --add %{InitScriptProdName}
 ln -sf %{InstallDir}/@JARNAME@/bin/%{GFSHScript} %{_bindir}/%{GFSHScript}
 ln -sf %{InstallDir}/@JARNAME@/bin/%{GemFireScript} %{_bindir}/%{GemFireScript}


%changelog
* Fri Oct 12 2012 VMware Support <support@vmware.com> 7.0-1
- GemFire 7.0 Release
* Mon Jun 11 2012 VMware Support <support@vmware.com> 6.6.3-2
- Add GA build #35763
* Fri Jun 1 2012 VMware Support <support@vmware.com> 6.6.3-1
- Initial release with RC build #35587

