#! /bin/bash

# ----
# Following values are customized by redirect.pl
#JDK=/export/java/users/java_share/jdk/1.4.2_17/x86.linux
# ...or... /export/java/users/java_share/jdk/1.6.0_2/x86.linux/
JDK=/export/java/users/java_share/jdk/1.4.2_17/x86.linux

# Mylin wants a 1.5 JDK, so we'll hardwire this...
ECLIPSEJDK=/export/java/users/java_share/jdk/1.6.0_3/x86.linux

SVN=/export/fscott1/users/jpenney/subversion-1.4.6

#TODO: base directory for eclipse

#ver=31
#ver=322
#ver=33 # a.k.a. Europa
ver=34 # a.k.a. Ganymede
case $HOSTTYPE.$OSTYPE in
  i686.cygwin)
    ECLIPSE="/cygdrive/c/Program Files/eclipse$ver"
    LIB=
    ;;
  x86_64.linux*)
    ECLIPSE=/export/fscott1/users/jpenney/eclipse$ver
    LIB=$SVN/lib-x86.linux
    ;;
  i486.linux-gnu)
    ECLIPSE=/export/fscott1/users/jpenney/eclipse$ver
    LIB=$SVN/lib-x86.linux
    ;;
  i386.linux)
    ECLIPSE=/export/fscott1/users/jpenney/eclipse$ver
    LIB=$SVN/lib-x86.linux
    ;;
  sparc.solaris*)
    ECLIPSE=/export/slug1/users/jpenney/eclipse
    LIB=$SVN/lib-sparc.Solaris	# Not built!
    ;;
  *)
    echo "Don't know this arch"
    exit 1
    ;;
esac

# ----

export JAVA_HOME="$ECLIPSEJDK"
export LD_LIBRARY_PATH=$LIB:$LD_LIBRARY_PATH

export PATH=$JAVA_HOME/bin:$PATH
"$ECLIPSE/eclipse" "$@" -vmargs -Xmx768M -Djava.library.path=$LIB
