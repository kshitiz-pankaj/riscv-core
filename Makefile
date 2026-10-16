# Top-level Makefile
#
#   make sw     build software images (ELF, BIN, HEX, disassembly)
#   make spike  run hello on Spike with a commit log
#   make sim    run on the RTL core (arrives in Phase 1)
#   make test   run the checks that exist so far
#   make clean  remove build outputs

BUILD := build

# Toolchain -------------------------------------------------------------------

CROSS   ?= riscv64-unknown-elf-
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump

ARCH    := -march=rv32ima_zicsr_zifencei -mabi=ilp32
CFLAGS  := $(ARCH) -O2 -g -Wall -Wextra -ffreestanding -fno-builtin \
           -mcmodel=medany -Isw/common
LDFLAGS := $(ARCH) -nostdlib -nostartfiles -T sw/common/link.ld \
           -Wl,--no-warn-rwx-segments
LIBS    := -lgcc

SPIKE      ?= spike
SPIKE_ISA  := rv32ima_zicsr_zifencei
SPIKE_MEM  := 0x80000000:0x8000000

# Software --------------------------------------------------------------------

COMMON_SRCS := sw/common/crt0.S sw/common/uart.c
PROGRAMS    := hello

ELFS := $(PROGRAMS:%=$(BUILD)/sw/%.elf)

.PHONY: sw spike sim test clean

sw: $(ELFS) $(ELFS:.elf=.bin) $(ELFS:.elf=.hex) $(ELFS:.elf=.dump)

$(BUILD)/sw/%.elf: sw/tests/%.c $(COMMON_SRCS) sw/common/uart.h sw/common/link.ld
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(LDFLAGS) $(COMMON_SRCS) $< $(LIBS) -o $@

$(BUILD)/sw/%.bin: $(BUILD)/sw/%.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/sw/%.hex: $(BUILD)/sw/%.bin scripts/bin2hex.py
	python3 scripts/bin2hex.py $< $@

$(BUILD)/sw/%.dump: $(BUILD)/sw/%.elf
	$(OBJDUMP) -d $< > $@

# Spike (reference model) -----------------------------------------------------

# Commit log goes to stderr, UART output to stdout.
$(BUILD)/spike/%.log: $(BUILD)/sw/%.elf
	@mkdir -p $(dir $@)
	$(SPIKE) --isa=$(SPIKE_ISA) -m$(SPIKE_MEM) -l --log-commits $< \
	    > $(BUILD)/spike/$*.out 2> $@
	@cat $(BUILD)/spike/$*.out

spike: $(BUILD)/spike/hello.log
	@echo "Commit log: $<  ($$(grep -c ' 3 0x' $<) committed instructions)"

# RTL simulation --------------------------------------------------------------

sim:
	@echo "No RTL yet: the core and its Verilator harness arrive in Phase 1."
	@exit 1

# Tests -----------------------------------------------------------------------

test: $(BUILD)/spike/hello.log
	@grep -q "Hello from RV32!" $(BUILD)/spike/hello.out \
	    && grep -q "6 \* 7 = 0x0000002a" $(BUILD)/spike/hello.out \
	    && echo "PASS  hello (spike)" \
	    || { echo "FAIL  hello (spike)"; exit 1; }

clean:
	rm -rf $(BUILD)
