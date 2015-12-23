This document describes how to setup eclipse to build gemfire. Eclipse will compile the classes to a separate location than the command line build.

Instructions
-------------

1. Get a checkout of gemfire.

2. Download the latest version of eclipse from eclipse.org.

3. (Optional, but recommended). There is an ant build option to copy build dependencies to your local machine. Put a line like this in in a file called buildlinux.properties (or buildwin.properties) in the root directory of your checkout. 

local.gcm.dir=/export/yourhost1/dsmith/gcm

Run './build.sh props'. This will copy those dependencies to your local directory. 

4. Start up eclipse. You must create a classpath variable to tell eclipse where to find the gcm directory. Go to Window->Preferences->Java->Build Path->Classpath variables and add a variable called GCM_DIR. Set the value to be the local gcm directory you specified, above. 

If you didn't do step 3 you can use /export/gcm.  On unix boxes the remote gcm directory should already be available at /export/gcm. Otherwise you can mount the volume filer:/vol/vol0/gcm. Ow windows it is \\samba.gemstone.com\gcm

5. Create a variable called JDK_DIR to point to /gcm/where/jdk/1.6.0_26/x86_64.linux or your preferred JDK. 

6. Go to Windows->Preferences->Ant->Runtime. Set your ANT_HOME to point to the version of ant in your local gcm directory. The version that ships with eclipse doesn't include some of the ant extensions we use. Eg /export/yourhost1/dsmith/gcm/where/java/ant/apache-ant-1.8.4

7. Copy all of the files from the project_files directory to the root directory of your checkout. Make sure you get all of the hidden files (starting with '.'), except for the .svn directory.

dan@project_files> cp -R .project .classpath .externalToolBuilders/ .settings/ ../../../

8. Generate a .classpath file by running:
   ./build.sh -Declipse.classpath.file=.classpath generate-eclipse-classpath

9 In your workspace, select File->Import and under the "General" folder choose "import existing projects into workspace." Import your checkout. It should build atomatically.

Note: 
1) It's better to turn off Project->Build automatically before importing and creating variables for JDK_DIR and GCM_DIR.

2) The first time to start eclipse, it's better to run with -Xmx2048m.

Explanation of the files
------------------------
.project - this is the project definition. It tells eclipse what type of project you have.
.classpath - this contains the classpath for the project
.externalToolBuilders - this contains a special ant builder which generates the properties needed for gemfire license code to work. The ant builder calls the task generate-eclipse-resources in the build.xml file.
.settings - This contains project settings. The only precanned settings you're getting are the code format settings. You can also import the gemstone_code_style.xml file into your workspace, if you prefer.

Rebuilding the .classpath file
------------------------------
If the .classpath file is out of date you can build a new one with the
GemFire build script.  Use the target generate-eclipse-classpath and give
it the property eclipse.classpath.file to tell it where to store the class
path.  For instance

  ./build.sh -Declipse.classpath.file=newcp.txt generate-eclipse-classpath

then copy the file to your checkout and rename it .classpath.  Depending
on your version of Eclipse you may need to restart the program to pick up
the change.  With the Kepler release you can just open the project properties
dialog and select the build-path section.  Eclipse will auto-refresh from
the .classpath file and start a new build.

Troubleshooting
---------------

> You get a popup window, or an error message in the console indicated that the ant build failed.

First, look at your problem screen to make sure your eclipse java compile succeeded. Often this is just caused by screwing up your build path. If that fails, open Window->Show View->Error Log. Open up the error message and see what it's complaining about.

If it complains that it can find the task type "if", then you probably are not using the /gcm ANT_HOME. Refer to the instructions above to set your ANT_HOME correctly.

If it complains about missing files or locations, Go to Project->Properties->Builders and edit BuildGemfireHiddenStuff. Make sure that output directory, build.xml location, etc. are all correct. You may want to change build.xml to ${workspace_loc:/Gemfire/build.xml} in the Buildfile box of Main tab.

> You get a LicenseException when trying to run a gemfire junit or dunit test.

Try the doing a Project->Build Project. The code to automatically generate the license information runs after the clean is executed.  It should generate a couple of files in your eclipse output directory:
 - a hidden directory, which contains a couple of serial number files
 - com/gemstone/gemfire/internal/GemFireVersion.properties
The code that does is is an part of our ant build.xml. It is invoked by an ant builder. You can look at the configuration under Project->Properties->Builders->BuildGemfireHiddenStuff. If that fails you can try doing a clean.

If you are still getting a LicenseException after doing a build on the project, look at the eclipse error log (Window->Show View->Error Log) to see if your ant build failed. If it's complaining about a missing taskdef, you might need to add the ant-contrib jar to your ant home. Under Window->Perferences->Ant, see what ANT_HOME you are using. Copy /export/gcm/where/java/ant/apache-ant??/lib/ant-contrib?? to your ANT_HOME/lib directory. You may need to reset ANT_HOME in eclipse to make it pick up the new jar.

> You get this exception running a test:
 Failed to parse element in version '<Could not find resource com/gemstone/gemfire/internal/GemFireVersion.properties>': For input string: "<Could not find resource com/gemstone/gemfire/internal/GemFireVersion". Cannot continue with only 0 version digits.

Same as above, do a Project-> Build. This exception indicates that your eclipse output directory is missing the GemFireVersion.properties file.

> You get an exception with this cause running a gemfirexd test:
Caused by: java.lang.NullPointerException
	at com.pivotal.gemfirexd.internal.impl.sql.catalog.DD_Version.getJBMSMinorVersionNumber(DD_Version.java:734)

Same as above, do a Project -> Build. This exception indicates your eclipse output directory is missing the gemfirexd generated resources.

> You have many junit "access" compilation errors

You are probably using a newer version of Eclipse.  Open the project->properties->Java Build Path and select the Libraries tab.  Remove the Eclipse JUnit folder from the build path.  The project already has a junit jar on the path.
D

> The BuildGemFireHiddenStuff builder fails with an error saying that "." is not a valid working copy.

We have no explanation for why this is happening so far, but you can work around the problem by choosing project->properties->builders and editing the task.  Select the properties tab and add this:
   infodir=${resource_loc:Gemfire}

If you've changed the name of your project in the .project file, use it instead of "Gemfire".  You'll also have to change the other properties for this task.

If you are getting the LicenseException type errors when running tests in eclipse and you can't get eclipse to generate the required license files,  you can generate the eclipse resources with the command line build:
./build.sh generate-eclipse-resources -Dclasses.dir=GEMFIRE_OUTPUT -Dgcm.dir=/export/gcm -Dhidden.dir=GEMFIRE_OUTPUT/hidden

> If your Eclipse uses Open JDK, you might see an error like this:
The method copyMemory(long, long, long) in the type Unsafe is not applicable for the arguments (Object, long, Object, long, long)
Switching to Oracle JDK might solve the problem: 
Window->Preferences->Java->Installed JREs->Add->Standard VM. In JRE Home, put /gcm/where/jdk/1.6.0_26/x86_64.linux or your preferred JDK.

Limitations, frustations, and ideas for improvement
---------------------------------------------------
The name of the project is saved in the .project file itself. That means that you have to edit that file to import more than one project into the same workspace. I've also had some  luck (with eclipse 3.5) by just by deleting the .project file and creating a new project existing source. It seems to find the .classpath file on its own.

The source path has a slightly agressive list of excludes. I basically excluded some test classes that I never use because they have dependencies that I didn't feel like tracking down. Feel to improve it if you need compile those files for some reason.

The ant build is much more sophisticated than the eclipse build. In the eclipse build, there is one classpath for the src, tests, examples, etc. The ant build compiles different things with different classpaths and different JDKs. Make sure to build with ant before checking anything in!
