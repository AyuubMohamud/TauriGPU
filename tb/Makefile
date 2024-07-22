# MAKEFILE

SIM ?= verilator

PWD=$(shell pwd)

export PYTHONPATH := $(PWD)/../model:$(PYTHONPATH)

VERILOG_SOURCES = $(wildcard $(PWD)/../rtl/core/fp/*.sv)
				  
TOPLEVEL := fpu
COCOTB_TEST_MODULES := test_fp

include $(shell cocotb-config --makefiles)/Makefile.sim

EXTRA_ARGS += -g2012

VERILOG_INCLUDE_DIRS = $(PWD)/../rtl/core/fp

$(info Sources: $(VERILOG_SOURCES))

PYTHONPATH := $(PWD):$(PYTHONPATH)

export MODULE := $(COCOTB_TEST_MODULES)