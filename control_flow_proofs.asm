; control_flow_proofs.asm — x86-64 Linux (NASM)
; Three demonstrations of control flow redirection:
; 1) mov rsp,fake_stack ; ret    - Stack pointer manipulation
; 2) push next ; jmp target      - Manual CALL simulation  
; 3) push target ; ret           - Direct RIP manipulation

global _start
default rel

section .text

; sys_write(1, rsi, rdx); return
print:
    mov     rax, 1
    mov     rdi, 1
    syscall
    ret

; _exit(code)
exit:
    mov     rax, 60
    syscall

_start:
; ------------------------------------------------------------------
; Demo 1: Fake stack + RET → RIP loaded from new stack top
; Demonstrates indirect RIP control via RSP manipulation
; ------------------------------------------------------------------
    lea     rax, [rel land1]       ; prepare landing address
    mov     [fake_stack], rax      ; fake_stack[0] = land1
    lea     rsp, [rel fake_stack]  ; RSP points to fake stack
    ret                            ; RIP ← [RSP] = land1

land1:
    lea     rsi, [rel msg1]
    mov     rdx, msg1_len
    call    print

; ------------------------------------------------------------------
; Demo 2: push next ; jmp target  ≡  call target
; Manual simulation of CALL instruction behavior
; ------------------------------------------------------------------
    lea     rax, [rel after_jmp]
    push    rax                    ; equivalent to CALL's "save return address"
    jmp     target2                ; equivalent to CALL's "jump"

target2:
    ret                            ; return to after_jmp

after_jmp:
    lea     rsi, [rel msg2]
    mov     rdx, msg2_len
    call    print

; ------------------------------------------------------------------
; Demo 3: push target ; ret  (Direct RIP modification via RET)
; ------------------------------------------------------------------
    lea     rax, [rel land3]
    push    rax
    ret

land3:
    lea     rsi, [rel msg3]
    mov     rdx, msg3_len
    call    print

; Exit program
    xor     rdi, rdi
    call    exit

section .data
msg1: db "OK: landed via fake RSP + RET", 10
msg1_len equ $-msg1
msg2: db "OK: PUSH next + JMP == CALL", 10
msg2_len equ $-msg2
msg3: db "OK: PUSH target + RET", 10
msg3_len equ $-msg3

section .bss
fake_stack: resq 8                 ; Reserve space for demonstration stack

