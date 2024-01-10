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
    MKDIR = mkdir $(subst /,\,$(1)) > nul 2>&1 || (exit 0)
    RMDIR = rmdir /s /q
    RM = del /Q /F
    PYTHON = python3
else
    RM_WILDCARD = rm -f
    MKDIR = mkdir -p $(1)
    RMDIR = rm -rf
    RM = rm -f
    PYTHON = python3
endif

# SCAD Compiler
SCADC?=openscad

# Parametric Generator
PARAGEN?=parameter_generator.py

# Variation Generator
VARGEN?=parameter_variants.py

# Variation Generator
HTMLGEN?=parameter_html.py

# Project input files
INPUTS = $(wildcard models/*.json)

# Data about all variants from project input files
INPUT_DATA = $(shell $(PYTHON) $(VARGEN) $(INPUTS) --PrintTarget)

################################################################################
.PHONY: all variants png models clean dev
all: variants png models out/index.html

# Turn variant data "{project}:{variant}:{json_path}:{scad_path}" into variables and rule details
define INPUT_DATA_template =
PROJECT_DATA     += $(3):$(1)
VARIANTS         += $(1).$(2)
VARIANTS_TARGETS += out/variants/$(1).$(2).json
PNG_TARGETS      += out/png/$(1).$(2).png
STL_TARGETS      += out/stl/$(1).$(2).stl

out/variants/$(1).$(2).json: $(3)
out/variants/$(1).$(2).json out/png/$(1).$(2).png out/stl/$(1).$(2).stl: override JSON_PATH=$(3)
out/variants/$(1).$(2).json out/png/$(1).$(2).png out/stl/$(1).$(2).stl: override SCAD_PATH=$(4)
out/variants/$(1).$(2).json out/png/$(1).$(2).png out/stl/$(1).$(2).stl: override PARAMETER_SET=$(2)
endef

$(foreach X,$(INPUT_DATA),$(eval $(call INPUT_DATA_template,$(word 1,$(subst :, ,$X)),$(word 2,$(subst :, ,$X)),$(word 3,$(subst :, ,$X)),$(word 4,$(subst :, ,$X)))))

# Sort and deduplicate "{json_path}:{project}" values
INPUT_PROJECTS = $(sort $(PROJECT_DATA))

# explicit wildcard expansion suppresses errors when no files are found
include $(wildcard deps/*.deps)

variants: $(VARIANTS_TARGETS)
png: $(PNG_TARGETS)
models: $(STL_TARGETS)

out deps:
	$(call MKDIR,$@)

out/variants out/png out/stl: | out
	$(call MKDIR,$@)

# Generate Variation
out/variants/%.json: | out/variants
	$(PYTHON) $(VARGEN) $(JSON_PATH) --WriteSingle $(PARAMETER_SET)

# Generate PNG
out/png/%.png: out/variants/%.json $(SCAD_PATH) | out/png deps
	$(SCADC) -o $@ -d $(patsubst out/variants/%.json,deps/%.png.deps,$<) -p $< -P $(PARAMETER_SET) $(SCAD_PATH)

# Generate STL
out/stl/%.stl: out/variants/%.json $(SCAD_PATH) | out/stl deps
	$(SCADC) -o $@ -d $(patsubst out/variants/%.json,deps/%.stl.deps,$<) -p $< -P $(PARAMETER_SET) $(SCAD_PATH)

out/index.html: $(PNG_TARGETS) $(STL_TARGETS) $(HTMLGEN) | out
	$(info want to render index page  $(JSON_PATH) $(PNG_TARGETS) $(STL_TARGETS))
	$(PYTHON) $(HTMLGEN) $(INPUT_PROJECTS) --Output $@

# Clean Up
clean:
	- $(RMDIR) out
	- $(RMDIR) deps

# Used during development of this makefile
dev:
	$(info INPUTS : $(INPUTS))
	$(info INPUT_PROJECTS : $(INPUT_PROJECTS))
	$(info INPUT_DATA : $(INPUT_DATA))
	$(info VARIANTS : $(VARIANTS))
	$(info VARIANTS_TARGETS : $(VARIANTS_TARGETS))
	$(info PNG_TARGETS : $(PNG_TARGETS))
	$(info STL_TARGETS : $(STL_TARGETS))


