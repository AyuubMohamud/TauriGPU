# MAKEFILE

SIM ?= verilator

# TRACE_FILE ?= $(TOPLEVEL)_dump.vcd
EXTRA_ARGS += --trace --trace-structs

# COCOTB_TEST_ARGS ?= --trace-file $(TRACE_FILE)
# export COCOTB_TEST_ARGS

PWD=$(shell pwd)

export PYTHONPATH := $(PWD)/../model:$(PYTHONPATH)

VERILOG_SOURCES = $(wildcard $(PWD)/../rtl/core/fp/*.sv)
				  
TOPLEVEL := fpu
COCOTB_TEST_MODULES := test_fp

include $(shell cocotb-config --makefiles)/Makefile.sim

VERILOG_INCLUDE_DIRS = $(PWD)/../rtl/core/fp

$(info Sources: $(VERILOG_SOURCES))

PYTHONPATH := $(PWD):$(PYTHONPATH)

export MODULE := $(COCOTB_TEST_MODULES)