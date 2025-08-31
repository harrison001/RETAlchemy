# RETAlchemy Makefile
# Educational security research project

# Assembly programs
ASM_SOURCES = control_flow_proofs.asm ret_hijack.asm rop_min.asm rop_overflow.asm
ASM_OBJECTS = $(ASM_SOURCES:.asm=.o)
ASM_TARGETS = $(ASM_SOURCES:.asm=)

# C programs
C_SOURCES = exploit_skeleton.c
C_TARGETS = $(C_SOURCES:.c=)

# Default target
all: asm-programs c-programs

# Assembly programs (normal compilation)
asm-programs: $(ASM_TARGETS)

# Assembly programs with debug symbols
asm-debug: $(ASM_TARGETS:%=%-debug)

# C programs
c-programs: $(C_TARGETS)

# C programs with debug symbols  
c-debug: $(C_TARGETS:%=%-debug)

# Pattern rules for assembly
%.o: %.asm
	nasm -felf64 $< -o $@

%-debug.o: %.asm
	nasm -felf64 -g -F dwarf $< -o $@

%: %.o
	ld -o $@ $<

%-debug: %-debug.o
	ld -o $@ $<

# Pattern rules for C
%: %.c
	gcc -o $@ $<

%-debug: %.c
	gcc -g -o $@ $<

# Kernel module (requires kernel headers)
kmod:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

kmod-clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

# Test targets (run programs)
test-control: control_flow_proofs
	./control_flow_proofs

test-hijack: ret_hijack
	./ret_hijack

test-rop-min: rop_min
	./rop_min

test-rop-overflow: rop_overflow
	./rop_overflow

test-exploit: exploit_skeleton
	./exploit_skeleton

# Debug targets (start GDB)
debug-control: control_flow_proofs-debug
	gdb ./control_flow_proofs-debug

debug-hijack: ret_hijack-debug
	gdb ./ret_hijack-debug

debug-rop-min: rop_min-debug
	gdb ./rop_min-debug

debug-rop-overflow: rop_overflow-debug
	gdb ./rop_overflow-debug

debug-exploit: exploit_skeleton-debug
	gdb ./exploit_skeleton-debug

# Clean targets
clean:
	rm -f $(ASM_OBJECTS) $(ASM_TARGETS) $(C_TARGETS)
	rm -f *-debug.o *-debug
	rm -f *.ko *.o *.mod.c *.mod.o *.symvers *.order

clean-all: clean kmod-clean

# Help
help:
	@echo "RETAlchemy Build System"
	@echo "======================="
	@echo ""
	@echo "Targets:"
	@echo "  all              - Build all programs"
	@echo "  asm-programs     - Build assembly programs"
	@echo "  asm-debug        - Build assembly programs with debug symbols"
	@echo "  c-programs       - Build C programs"
	@echo "  c-debug          - Build C programs with debug symbols"
	@echo "  kmod             - Build kernel module"
	@echo ""
	@echo "Test targets:"
	@echo "  test-control     - Run control flow demonstrations"
	@echo "  test-hijack      - Run return address hijacking demo"
	@echo "  test-rop-min     - Run minimal ROP demonstration"
	@echo "  test-rop-overflow - Run overflow-based ROP demo"
	@echo "  test-exploit     - Run exploit skeleton"
	@echo ""
	@echo "Debug targets (requires debug build):"
	@echo "  debug-control    - Debug control flow demo with GDB"
	@echo "  debug-hijack     - Debug hijacking demo with GDB"
	@echo "  debug-rop-min    - Debug minimal ROP with GDB"
	@echo "  debug-rop-overflow - Debug overflow ROP with GDB"
	@echo "  debug-exploit    - Debug exploit skeleton with GDB"
	@echo ""
	@echo "Clean targets:"
	@echo "  clean            - Remove built programs"
	@echo "  clean-all        - Remove all built files including kernel module"

.PHONY: all asm-programs asm-debug c-programs c-debug kmod kmod-clean clean clean-all help
.PHONY: test-control test-hijack test-rop-min test-rop-overflow test-exploit
.PHONY: debug-control debug-hijack debug-rop-min debug-rop-overflow debug-exploit