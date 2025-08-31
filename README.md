# RETAlchemy: Return Address Manipulation Demonstrations

## Overview

RETAlchemy is an educational security research project that demonstrates various techniques for manipulating return addresses and control flow in x86-64 systems. This collection includes practical examples of Return-Oriented Programming (ROP), stack buffer overflows, and kernel-level exploitation techniques.

**⚠️ IMPORTANT: This project is for educational and defensive security research purposes only. All code should be run in isolated virtual environments.**

## Components

### 1. Control Flow Demonstrations (`control_flow_proofs.asm`)

This assembly program demonstrates three fundamental techniques for redirecting program execution:

- **Stack Pointer Manipulation**: Shows how modifying RSP can indirectly control RIP
- **Manual CALL Simulation**: Demonstrates the equivalence of `push + jmp` to `call`
- **Direct RIP Control**: Shows direct return address manipulation using `push + ret`

### 2. Return Address Hijacking (`ret_hijack.asm`)

Demonstrates classic return address hijacking through:

- **Normal Function Behavior**: Baseline comparison of legitimate function calls
- **Direct Overwrite**: Manual overwrite of saved return address on stack
- **Buffer Overflow**: Realistic overflow scenario using `memcpy`-style operations

### 3. Minimal ROP Chain (`rop_min.asm`)

A clean implementation of Return-Oriented Programming showing:

- Collection of ROP gadgets (pop/mov/syscall primitives)
- Fake stack construction with gadget addresses and parameters
- System call execution via ROP chain (write + exit)

### 4. Overflow-Based ROP (`rop_overflow.asm`)

Demonstrates realistic ROP exploitation through:

- Vulnerable function with unchecked buffer copy
- Stack layout corruption leading to ROP chain execution
- Complete payload construction mimicking real-world exploits

### 5. Kernel Module Exploitation

#### Vulnerable Kernel Module (`retalchemy_kmod.c`)
A deliberately vulnerable Linux kernel module that:
- Creates `/dev/retalchemy` character device
- Accepts arbitrary-length writes to fixed-size stack buffer
- Provides kernel stack overflow primitive for educational purposes

#### User-Space Exploit (`exploit_skeleton.c`)
Skeleton exploit demonstrating kernel ROP (kROP) techniques:
- Symbol resolution from `/proc/kallsyms`
- Kernel stack overflow via device write
- Privilege escalation payload using `commit_creds(prepare_kernel_cred(NULL))`

## Attack Scenarios in Real Environments

### 1. Application-Level Buffer Overflows

**Attacker Process:**
1. **Reconnaissance**: Identify vulnerable applications with stack-based buffers
2. **Fuzzing**: Send oversized inputs to trigger crashes and identify overflow points
3. **Offset Discovery**: Determine exact offset to overwrite return address
4. **Gadget Hunting**: Search binary/libraries for useful ROP gadgets using tools like ROPgadget
5. **Payload Construction**: Build ROP chain to bypass modern defenses (ASLR, DEP/NX)
6. **Exploitation**: Execute arbitrary code, often leading to shell access

**Real-World Examples:**
- Web server buffer overflows (Apache, Nginx modules)
- Network service vulnerabilities (SSH, FTP servers)
- Client-side applications (browsers, media players)

### 2. Kernel-Level Exploitation

**Attacker Process:**
1. **Vulnerability Research**: Identify kernel drivers with improper input validation
2. **Local Access**: Gain initial access to target system (often via other exploits)
3. **Device Interaction**: Interact with vulnerable kernel modules/drivers
4. **Stack Smashing**: Trigger kernel stack overflow via device I/O operations
5. **KASLR Bypass**: Use information leaks to defeat kernel ASLR
6. **kROP Chain**: Construct kernel-space ROP chain for privilege escalation
7. **Persistence**: Modify kernel structures for persistent access

**Real-World Examples:**
- Graphics driver vulnerabilities (NVIDIA, AMD)
- Network stack exploits (packet processing bugs)
- File system driver flaws (NTFS, ext4)
- Hardware abstraction layer bugs

### 3. Modern Defense Bypass Techniques

**Stack Canaries**: Attackers use information leaks or partial overwrites to bypass
**ASLR**: Memory disclosure bugs reveal base addresses for ROP gadget calculation
**DEP/NX Bit**: ROP chains execute existing code, bypassing non-executable stack protection
**Control Flow Integrity (CFI)**: Advanced ROP techniques using call-preceded gadgets
**Stack Isolation**: Kernel exploits target other memory regions or use SMEP/SMAP bypasses

## Educational Lab Setup

### Prerequisites
- Linux system (Ubuntu/Debian recommended)
- NASM assembler (`apt install nasm`)
- GCC compiler with development headers
- QEMU/KVM for isolated testing
- Root access for kernel module testing

### Quick Start with Makefile
```bash
# Build all programs
make all

# Build with debug symbols for GDB
make asm-debug c-debug

# Run specific demonstrations  
make test-control      # Control flow demos
make test-hijack       # Return address hijacking
make test-rop-min      # Minimal ROP chain
make test-rop-overflow # Overflow-based ROP

# Debug with GDB (requires debug build first)
make debug-hijack      # Start GDB with ret_hijack-debug
make debug-exploit     # Start GDB with exploit_skeleton-debug

# See all available targets
make help
```

### Manual Assembly Examples
```bash
# Compile and run control flow demonstrations
nasm -felf64 control_flow_proofs.asm -o control_flow_proofs.o
ld -o control_flow_proofs control_flow_proofs.o
./control_flow_proofs

# For debugging with GDB, add debug info during assembly
nasm -felf64 -g -F dwarf control_flow_proofs.asm -o control_flow_proofs.o
ld -o control_flow_proofs control_flow_proofs.o

# Similar for other ASM files
nasm -felf64 ret_hijack.asm -o ret_hijack.o
ld -o ret_hijack ret_hijack.o
./ret_hijack
```

### Debugging with GDB
```bash
# Compile with debug symbols
nasm -felf64 -g -F dwarf ret_hijack.asm -o ret_hijack.o
ld -o ret_hijack ret_hijack.o

# Debug with GDB
gdb ./ret_hijack
(gdb) break _start          # Set breakpoint at entry point
(gdb) break vuln_overwrite  # Set breakpoint at vulnerable function
(gdb) break pwned           # Set breakpoint at hijack target
(gdb) run                   # Start execution
(gdb) info registers        # Check register values
(gdb) x/10gx $rsp          # Examine stack contents
(gdb) stepi                 # Step through instructions
(gdb) continue              # Continue execution
```

### Kernel Module Testing
```bash
# Compile the vulnerable kernel module
make -C /lib/modules/$(uname -r)/build M=$PWD modules

# Load the module (creates /dev/retalchemy)
sudo insmod retalchemy_kmod.ko

# Compile and run the exploit skeleton
gcc -o exploit_skeleton exploit_skeleton.c
./exploit_skeleton

# For debugging the user-space exploit
gcc -g -o exploit_skeleton exploit_skeleton.c
gdb ./exploit_skeleton
(gdb) break main
(gdb) break resolve_kallsyms
(gdb) run
(gdb) print sym_commit_creds
(gdb) x/100gx p          # Examine payload buffer

# Clean up
sudo rmmod retalchemy_kmod
```

### Recommended VM Setup
For kernel exploitation testing:
```bash
# Boot kernel with weakened security
# Add to GRUB: nokaslr nosmep nosmap
# Or QEMU: -cpu qemu64,-smep,-smap

# Disable additional protections
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
echo 0 | sudo tee /proc/sys/kernel/kptr_restrict
```

## Security Implications

This project demonstrates attack primitives commonly used in:
- **APT Campaigns**: Advanced persistent threats often chain these techniques
- **Zero-Day Exploits**: Novel vulnerabilities frequently involve memory corruption
- **Privilege Escalation**: Local attackers use kernel bugs to gain root access
- **Exploit Kit Development**: Understanding these fundamentals helps analyze modern exploits

## Defensive Measures

Security professionals should understand these techniques to:
- **Implement Proper Input Validation**: Prevent buffer overflows at the source
- **Deploy Stack Protection**: Enable compiler-based protections (stack canaries, fortify source)
- **Configure ASLR/DEP**: Ensure memory protection features are enabled
- **Monitor System Calls**: Detect unusual privilege escalation attempts
- **Regular Security Updates**: Patch known vulnerabilities promptly
- **Code Auditing**: Review code for memory safety issues

## Disclaimer

This educational material is provided for legitimate security research and defensive purposes. Users are responsible for ensuring compliance with applicable laws and regulations. The authors disclaim responsibility for any misuse of this information.

## Further Reading

- Intel x86-64 Architecture Manual
- "The Shellcoder's Handbook" - Anley et al.
- "A Guide to Kernel Exploitation" - Perla & Oldani
- Linux Kernel Security Documentation
- OWASP Top 10 - Memory Safety Issues