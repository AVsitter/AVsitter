# Creating a release version

## Needed tools

To create a release version like the ones available for download, you need to have the following tools:

### For Linux

- **zip**. It comes in most distributions, e.g. for Debian or Ubuntu use `sudo apt-get install zip`; if it isn't available in yours, try this link: <http://www.info-zip.org/Zip.html#Downloads>
- **Python**. It comes in most distributions, e.g. for Debian or Ubuntu use `sudo apt-get install python`; if it isn't available in yours, try this link: <https://www.python.org/downloads/>.
- **make**. It comes in most distributions, e.g. for Debian or Ubuntu use `sudo apt-get install make`; if it isn't available in yours, try this link: <https://www.gnu.org/software/make/#download>.
- **GNU cpp**. It comes in most distributions, e.g. for Debian or Ubuntu use `sudo apt-get install cpp`. If it isn't available in yours, or you have trouble installing it, you can instead use **mcpp**, which is much more lightweight and is included in most distributions. It is also available at this link: <http://mcpp.sourceforge.net/download.html>. **gcpp** comes preconfigured by default in Makefile. For **mcpp**, you need to set `PREPROC_KIND=mcpp` and `PREPROC_PATH=mcpp` in the Makefile.
- [**LSL-PyOptimizer**](https://github.com/Sei-Lisa/LSL-PyOptimizer). Currently the latest master branch is used to create the releases, which you can download by clicking on the `Code` button near the top right of the linked page.

### For Mac OS/X

- **zip** (comes preinstalled)
- **Python** (comes preinstalled)
- **make** - It comes as part of the command line develompent tools (Xcode) which you can install for free. Open a terminal and type `make`; if you don't have it installed, it will prompt you to install it. Xcode can also be installed manually from <https://developer.apple.com/>.
- **cpp** - Should come as part of the command line development tools where **make** is.
- [**LSL-PyOptimizer**](https://github.com/Sei-Lisa/LSL-PyOptimizer). Currently the latest master branch is used to create the releases, which you can download by clicking on the `Code` button near the top right of the linked page.

### For Windows (x86)

- [**zip**](http://www.info-zip.org/Zip.html#Downloads)
- [**Python**](https://www.python.org/downloads/)
- [**make**](http://gnuwin32.sourceforge.net/packages/make.htm#download)
- [**mcpp**](http://mcpp.sourceforge.net/download.html). `Makefile` comes preconfigured for **gcpp**, therefore you need to edit it by setting `PREPROC_KIND=mcpp` and `PREPROC_PATH=\full\path\to\mcpp`.
- [**LSL-PyOptimizer**](https://github.com/Sei-Lisa/LSL-PyOptimizer). Currently the latest master branch is used to create the releases, which you can download by clicking on the `Code` button near the top right of the linked page.

For processors other than x86, you need to find the above utilities for your processor.

## Creating the release

Once you have the required tools, edit the Makefile in the AVsitter2 folder to suit your needs, then using a terminal (also called command interpreter, shell, console... depending on the operating system) change to that folder using `cd <path-to-folder>` and type `make`. That should generate a file called `AVsitter2.zip` with the packaged version for SL, and another file called `AVsitter2-oss.zip` with the packaged version for OpenSim.

If you only want the Second Life optimized scripts without zipping them, use `make optimized`. The optimized files will have an `.lslo` extension, and they are ready to be copied and pasted each into a Second Life script.

If you only want the OpenSim scripts without zipping them, use `make opensim`. The OpenSim files will have an `.oss` extension.

If you only want the SL zip, use `make AVsitter2.zip`; if you only want the OS zip, use `make AVsitter2-oss.zip`.

If you want to remove the optimized scripts and the zip files, use `make clean` (you can regenerate them at any time by typing `make`).
