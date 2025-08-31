; rop_min.asm — Minimal ROP demonstration: fake_stack + ret chain
; Assemble & link:
;   nasm -felf64 rop_min.asm -o rop_min.o
;   ld -o rop_min rop_min.o
; Run: ./rop_min

global _start
default rel

section .text

; ---------------- Gadgets (Common ROP primitives) ----------------
g_pop_rdi:                 ; pop rdi ; ret
    pop     rdi
    ret

g_pop_rsi:                 ; pop rsi ; ret
    pop     rsi
    ret

g_pop_rdx:                 ; pop rdx ; ret
    pop     rdx
    ret

g_mov_rax_1:               ; mov rax, 1 ; ret      (SYS_write)
    mov     rax, 1
    ret

g_mov_rax_60:              ; mov rax, 60 ; ret     (SYS_exit)
    mov     rax, 60
    ret

g_syscall_ret:             ; syscall ; ret         (continue ROP after syscall)
    syscall
    ret

; ---------------- Entry: point RSP to chain, then ret to start ----------------
_start:
    ; Prepare ROP chain (see fake_chain layout in .data)
    lea     rsp, [rel fake_chain]  ; RSP points to our arranged "fake stack"
    ret                             ; RIP ← [RSP] = first gadget address

; Program won't reach here: final exit(0)
fallback_exit:
    mov     rax, 60                 ; SYS_exit
    xor     rdi, rdi
    syscall

section .data
msg:        db  "[ROP] hello from a pure assembly chain!", 10
msg_len     equ $-msg

; ---------------- Fake stack (ROP chain): each entry is "where to return/parameter value" ----------------
; Chain interpretation: write(1, msg, len) ; exit(0)
fake_chain:
    dq  g_pop_rdi
    dq  1

    dq  g_pop_rsi
    dq  msg

    dq  g_pop_rdx
    dq  msg_len

    dq  g_mov_rax_1
    dq  g_syscall_ret

    dq  g_pop_rdi
    dq  0

    dq  g_mov_rax_60
    dq  g_syscall_ret

