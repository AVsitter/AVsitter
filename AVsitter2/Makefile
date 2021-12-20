# Configuration area

# Full path to Python. For Windows this is typically
# C:\Python27\python.exe; if it is in your path you don't need to change it.
PYTHON=python3

# Full path to main.py in the optimizer. Depends on where it was unpacked.
OPTIMIZER=/l/pyoptimizer/main.py

# Which preprocessor to use. Use 'gcpp' for GNU cpp (typical on Linux/OSX);
# use 'mcpp' for mcpp.
PREPROC_KIND=gcpp

# Full path to the preprocessor. Depends on where you have downloaded it.
# If the preprocessor is GNU cpp and it is in your path, leave it as cpp.
PREPROC_PATH=cpp

# Full path to the zip program (zip.exe for Windows). Depends on where you
# have downloaded it. If it is in your path you don't need to change it.
ZIP=zip

# Name of the zipped file to generate for SL
SLZIP=AVsitter2.zip

# Name of the zipped file to generate for OpenSim
OSZIP=AVsitter2-oss.zip

# End of configuration area


# Version being compiled (LSL string)
VERSION="2.2p04"


# Note some of these scripts don't strictly need to be optimized for memory.

OPTIMIZED=[AV]sitA.lslo\
 [AV]sitB.lslo\
 [AV]adjuster.lslo\
 [AV]helperscript.lslo\
 [AV]root-security.lslo\
 [AV]root.lslo\
 [AV]select.lslo\
 Plugins/AVcamera/[AV]camera.lslo\
 Plugins/AVcontrol/Xcite!-Sensations/[AV]Xcite!.lslo\
 Plugins/AVcontrol/[AV]root-RLV-extra.lslo\
 Plugins/AVcontrol/[AV]root-RLV.lslo\
 Plugins/AVcontrol/[AV]root-control.lslo\
 Plugins/AVfaces/[AV]faces.lslo\
 Plugins/AVfavs/[AV]favs.lslo\
 Plugins/AVprop/[AV]menu.lslo\
 Plugins/AVprop/[AV]prop.lslo\
 Plugins/AVprop/[AV]object.lslo\
 Plugins/AVsequence/[AV]sequence.lslo\
 Utilities/AVpos-generator.lslo\
 Utilities/Anim-perm-checker.lslo\
 Utilities/MLP-converter.lslo\
 Utilities/Missing-anim-finder.lslo

UNOPTIMIZED=Plugins/AVcontrol/LockGuard/[AV]LockGuard.lsl\
 Plugins/AVcontrol/LockGuard/[AV]LockGuard-object.lsl\
 Utilities/AVpos-shifter.lsl\
 Utilities/Noob-detector.lsl

OPENSIM=[AV]sitA.oss\
 [AV]sitB.oss\
 [AV]adjuster.oss\
 [AV]helperscript.oss\
 [AV]root.oss\
 [AV]root-security.oss\
 [AV]select.oss\
 Plugins/AVcamera/[AV]camera.oss\
 Plugins/AVfaces/[AV]faces.oss\
 Plugins/AVprop/[AV]menu.oss\
 Plugins/AVprop/[AV]object.oss\
 Plugins/AVprop/[AV]prop.oss\
 Plugins/AVsequence/[AV]sequence.oss\
 Utilities/Anim-perm-checker.oss\
 Utilities/AVpos-generator.oss\
 Utilities/AVpos-shifter.oss\
 Utilities/Missing-anim-finder.oss\
 Utilities/MLP-converter.oss\
 Utilities/Noob-detector.oss

all: $(SLZIP) $(OSZIP)

clean:
	$(PYTHON) build-aux.py rm $(SLZIP) $(OSZIP) $(OPTIMIZED) $(OPENSIM)

optimized: $(OPTIMIZED)

opensim: $(OPENSIM)

$(SLZIP): $(OPTIMIZED) $(UNOPTIMIZED)
	$(PYTHON) build-aux.py rm $@
	$(ZIP) $@ $(OPTIMIZED) $(UNOPTIMIZED)

%.lslo %.lslt: %.lsl
	$(PYTHON) $(OPTIMIZER) -H -O addstrings,shrinknames,-extendedglobalexpr -p $(PREPROC_KIND) --precmd=$(PREPROC_PATH) $(OFLAGS) $< -o $@

$(OSZIP): $(OPENSIM)
	$(PYTHON) build-aux.py rm $@
	$(ZIP) $@ $(OPENSIM)

%.oss: %.lsl
	$(PYTHON) build-aux.py oss-process $< > $@

# Bash only, probably GNU make only
setvars:
	for name in $(addprefix ',$(addsuffix ',$(OPTIMIZED:.lslo=.lsl))) $(addprefix ',$(addsuffix ',$(UNOPTIMIZED))); do $(PYTHON) build-aux.py setvars "$$name" version='$(VERSION)' ; done

release: setvars all

.PHONY : all clean optimized opensim setvars release
