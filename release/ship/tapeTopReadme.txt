GemStone tape readme.txt

Products on this tape are in one of two forms: InstallShield installer
(with a setup.exe), a zip file, or a set of directory trees.

First, use the tar utility on your system to extract the product contents
from the tape.

For example:
   cd <installdir>
   tar -xf <tape_device>

This command will extract all the files from the tape in device
"<tape_device>" to "<installdir>" on your system. "<tape_device>" might
be of the form "/dev/rmt/0m" or "/dev/rmt0.1" and depends on your system's
type and setup.


For UNIX products:

After extracting the files from the tape there is a set of directory
trees with product trees or zip files.
To unzip a zip file use the <installdir>/utils/<ostype>/unzip utility.
For example:
   cd <installdir>
   ./utils/solaris/unzip ./<productdir>/solaris.zip
From this point, consult the product's printed installation
instructions or the specific readme.txt located in the product
directory.

For Windows NT products:

After extracting the files from tape there may be a setup.exe file in
the specified directory which runs the InstallShield installer.
Double click on this from an explorer to invoke the installer.
Consult the product's printed installation instructions or the readme.txt
in the same directory as the setup.exe for specific instructions.
There may be a zip file instead of a setup.exe file.
To unzip a zip file use the <installdir>\utils\<ostype>\unzip utility.
For example:
   cd <installdir>
   .\utils\win_nt\unzip .\<productdir>\win_nt.zip
From this point, consult the product's printed installation
instructions or the specific readme.txt located in the product
directory.

