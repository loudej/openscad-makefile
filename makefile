# This Makefile generates files for printing SCAD documents
# and is targeted towards single scad projects with multiple variations
# Copyright (C) 2022  Brian Khuu | https://briankhuu.com/
# License: GNU GPL v3 (or later)
## make all    Generate STL and all of it's variations
## make clean  delete all STL and all of it's variations
################################################################################


# OS DETECT https://stackoverflow.com/questions/714100/os-detecting-makefile
isWindows=
ifeq ($(OS),Windows_NT)
ifeq (, $(shell uname))
	isWindows=Yes
endif
endif
ifeq ($(isWindows),Yes)
    RM_WILDCARD = del /Q /F /S
    MKDIR = mkdir
    RMDIR = rmdir /s /q
    RM = del /Q /F
    PYTHON = python
else
    RM_WILDCARD = rm -f
    MKDIR = mkdir
    RMDIR = rm -rf
    RM = rm -f
    PYTHON = python3
endif

# SCAD Compiler
SCADC?=C:\Program Files\OpenSCAD\openscad.exe

# Parametric Generator
PARAGEN?=parameter_generator.py

# Variation Generator
VARGEN?=parameter_variants.py

# Variation Generator
HTMLGEN?=parameter_html.py

# Model Details
PROJNAME = test
SCAD_PATH = models/$(PROJNAME).scad
JSON_PATH = models/$(PROJNAME).json

# Get list of variants
ifneq ("$(wildcard $(JSON_PATH))","")
# parametric configuration json file found. return a list of variants used in this project
	VARIANTS = $(shell $(PYTHON) $(VARGEN) --JsonPath $(JSON_PATH) --PrintTarget)
else
# parametric configuration json file missing. Generate the missing file and return a list of variants that was just generated
	VARIANTS = $(shell $(PYTHON) $(PARAGEN) --JsonPath $(JSON_PATH) --PrintTarget --WriteParameter)
endif

# Get list of targets
VARIANTS_TARGETS = $(patsubst %,variants/%.json,$(VARIANTS))
PNG_TARGETS      = $(patsubst %,png/$(PROJNAME).%.png,$(VARIANTS))
STL_TARGETS      = $(patsubst %,stl/$(PROJNAME).%.stl,$(VARIANTS))
INDEX_HTML       = index.html

################################################################################
.PHONY: projects all variants png models clean dev

projects:
	$(MAKE) all PROJNAME=gridfinity_drill_holder_standard SCAD_PATH=drill_holder\gridfinity_drill_holder_standard.scad JSON_PATH=models/gridfinity_drill_holder_standard.json INDEX_HTML=index.gridfinity_drill_holder_standard.html
	$(MAKE) all PROJNAME=gridfinity-rebuilt-baseplate SCAD_PATH=gridfinity-rebuilt-openscad/gridfinity-rebuilt-baseplate.scad JSON_PATH=models/gridfinity-rebuilt-baseplate.json INDEX_HTML=index.gridfinity-rebuilt-baseplate.html
	$(MAKE) all PROJNAME=gridfinity-rebuilt-bins SCAD_PATH=gridfinity-rebuilt-openscad/gridfinity-rebuilt-bins.scad JSON_PATH=models/gridfinity-rebuilt-bins.json INDEX_HTML=index.gridfinity-rebuilt-bins.html
	$(MAKE) all PROJNAME=gridfinity_basic_cup SCAD_PATH=gridfinity_openscad/gridfinity_basic_cup.scad JSON_PATH=models/gridfinity_basic_cup.json INDEX_HTML=index.gridfinity_basic_cup.html
	$(MAKE) all PROJNAME=pegstr SCAD_PATH=pegstr/pegstr.scad JSON_PATH=models/pegstr.json INDEX_HTML=index.pegstr.html

all: $(JSON_PATH) variants png models $(INDEX_HTML)


# explicit wildcard expansion suppresses errors when no files are found
include $(wildcard deps/*.deps)

variants: $(VARIANTS_TARGETS)
png: $(PNG_TARGETS)
models: $(STL_TARGETS)

# Generate Variation
variants/%.json: $(JSON_PATH)
	-@ $(MKDIR) variants ||:
	$(PYTHON) $(VARGEN) --JsonPath $(JSON_PATH) --WriteSingle $(patsubst variants/%.json,%,$@)

# Generate PNG
png/$(PROJNAME).%.png: variants/%.json $(SCAD_PATH)
	-@ $(MKDIR) png ||:
	-@ $(MKDIR) deps ||:
	$(SCADC) --enable=fast-csg -o $@ -d $(patsubst variants/%.json,deps/%.png.deps,$<) -p $< -P $(patsubst variants/%.json,%,$<) $(SCAD_PATH)

# Generate STL
stl/$(PROJNAME).%.stl: variants/%.json $(SCAD_PATH)
	-@ $(MKDIR) stl ||:
	-@ $(MKDIR) deps ||:
	$(SCADC) --enable=fast-csg -o $@ -d $(patsubst variants/%.json,deps/%.stl.deps,$<) -p $< -P $(patsubst variants/%.json,%,$<) $(SCAD_PATH)

$(INDEX_HTML): $(JSON_PATH) $(PNG_TARGETS) $(STL_TARGETS) $(HTMLGEN)
	$(info want to render index page  $(JSON_PATH) $(PNG_TARGETS) $(STL_TARGETS))
	$(PYTHON) $(HTMLGEN) --ProjectName $(PROJNAME) --JsonPath $(JSON_PATH) --Output $@

# Clean Up
clean:
	- $(RMDIR) variants
	- $(RMDIR) png
	- $(RMDIR) stl
	- $(RMDIR) deps
	- $(RM) index.html

# Used during development of this makefile
dev:
	$(info SCAD_PATH : $(SCAD_PATH))
	$(info JSON_PATH : $(JSON_PATH))
	$(info VARIANTS : $(VARIANTS))
	$(info VARIANTS_TARGETS : $(VARIANTS_TARGETS))
	$(info PNG_TARGETS : $(PNG_TARGETS))
	$(info STL_TARGETS : $(STL_TARGETS))


