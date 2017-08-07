# Configuration area

# Full path to Python. For Windows this is typically
# C:\Python27\python.exe; if it is in your path you don't need to change it.
PYTHON=python

# Full path to main.py in the optimizer. Depends on where it was unpacked.
OPTIMIZER=/l/pyoptimizer/main.py

# Which preprocessor to use. Use 'gcpp' for GNU cpp (typical on Linux);
# use 'mcpp' for mcpp.
PREPROC_KIND=mcpp

# Full path to the preprocessor. Depends on where you have downloaded it.
# If the preprocessor is mcpp and it is in your path, you can leave it as is.
PREPROC_PATH=mcpp

# Command to remove files in your system. Use 'del' for Windows.
RM=rm -f

# Name of the zipped file to generate
ZIP=AVsitter2.zip

# End of configuration area



# Note some of these scripts don't strictly need to be optimized for memory.

OPTIMIZED=[AV]sitA.lslo\
 [AV]sitB.lslo\
 [AV]adjuster.lslo\
 [AV]helper.lslo\
 [AV]root-security.lslo\
 [AV]root.lslo\
 [AV]select.lslo\
 Plugins/AVcamera/[AV]camera.lslo\
 Plugins/AVcontrol/LockGuard/[AV]LockGuard-object.lslo\
 Plugins/AVcontrol/LockGuard/[AV]LockGuard.lslo\
 Plugins/AVcontrol/Xcite!-Sensations/[AV]Xcite!.lslo\
 Plugins/AVcontrol/[AV]root-RLV-extra.lslo\
 Plugins/AVcontrol/[AV]root-RLV.lslo\
 Plugins/AVcontrol/[AV]root-control.lslo\
 Plugins/AVfaces/[AV]faces.lslo\
 Plugins/AVprop/[AV]menu.lslo\
 Plugins/AVprop/[AV]prop.lslo\
 Plugins/AVprop/[AV]object.lslo\
 Plugins/AVsequence/[AV]sequence.lslo\
 Utilities/AVpos-generator.lslo\
 Utilities/AVpos-shifter.lslo\
 Utilities/Anim-perm-checker.lslo\
 Utilities/MLP-converter.lslo\
 Utilities/Missing-anim-finder.lslo\
 Utilities/Updater/update-receiver.lslo\
 Utilities/Updater/update-sender.lslo

UNOPTIMIZED=

all: $(ZIP)

clean:
	$(RM) $(ZIP) $(OPTIMIZED)

optimized: $(OPTIMIZED)

$(ZIP): $(OPTIMIZED) $(UNOPTIMIZED)
	$(RM) $@
	zip $@ $(OPTIMIZED) $(UNOPTIMIZED)

%.lslo: %.lsl
	$(PYTHON) $(OPTIMIZER) -H -O addstrings,shrinknames,-extendedglobalexpr -p $(PREPROC_KIND) --precmd=$(PREPROC_PATH) $< -o $@

.PHONY : all clean optimized
