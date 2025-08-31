; ret_hijack.asm — x86-64 Linux, NASM syntax
; Demonstration: Normal return vs return address overwrite → ret hijack to pwned

global _start
default rel

section .text

; ---------------------------
; Print utility: print(buf=rsi, len=rdx)
; ---------------------------
print:
    mov     rax, 1          ; sys_write
    mov     rdi, 1          ; fd = stdout
    syscall
    ret

; ---------------------------
; Normal function call/return
; ---------------------------
vuln_normal:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32         ; simulate local variables
    leave
    ret

; ---------------------------
; Direct return address overwrite (demonstrates the essence)
; ---------------------------
vuln_overwrite:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32
    lea     rax, [rel pwned]    ; calculate pwned address
    mov     [rbp+8], rax        ; overwrite "saved return address"
    leave
    ret                         ; ← rip jumps to pwned

; ---------------------------
; Use out-of-bounds copy to "realistically" overwrite return address
; Local buffer 16B, attack payload 24B, last 8B is pwned address
; ---------------------------
vuln_memcpy_overflow:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32             ; [rbp-16 .. rbp-1] serves as local[16]

    ; Prepare "attack payload": first 16B arbitrary, last 8B write pwned address
    lea     rax, [rel pwned]
    mov     [attack_payload+16], rax

    ; rdi = destination local, rsi = source attack_payload, rcx = 24 bytes
    lea     rdi, [rbp-16]
    lea     rsi, [rel attack_payload]
    mov     rcx, 24
    rep movsb                    ; ← overflow 8B, exactly overwrite saved RIP at [rbp+8]

    leave
    ret                          ; ← jump to pwned

; ---------------------------
; Landing point after hijack
; ---------------------------
pwned:
    lea     rsi, [rel msg_pwned]
    mov     rdx, msg_pwned_len
    call    print
    mov     rax, 60              ; sys_exit
    mov     rdi, 42              ; exit code = 42 (distinctive)
    syscall

; ---------------------------
; Entry: first normal call, then demonstrate two types of hijack
; ---------------------------
_start:
    ; 1) Normal return
    call    vuln_normal
    lea     rsi, [rel msg_ok]
    mov     rdx, msg_ok_len
    call    print

    ; 2) Direct return address overwrite hijack
    call    vuln_overwrite
    ; Will only see this if hijack failed (normally won't reach here)
    lea     rsi, [rel msg_shouldnt]
    mov     rdx, msg_shouldnt_len
    call    print

    ; 3) Hijack via memcpy overflow (program exits in pwned, won't execute here)
    call    vuln_memcpy_overflow

    ; Final exit
    mov     rax, 60
    xor     rdi, rdi
    syscall

section .data
msg_ok:         db  "back from normal", 10
msg_ok_len      equ $-msg_ok

msg_pwned:      db  "*** PWNED: return address hijacked ***", 10
msg_pwned_len   equ $-msg_pwned

msg_shouldnt:   db  "[!] you should not see this", 10
msg_shouldnt_len equ $-msg_shouldnt

; 24B payload: first 16B arbitrary, last 8B filled with pwned address at runtime
attack_payload: db  "AAAAAAAAAAAAAAAA"   ; 16
                 dq  0                   ; placeholder, run-time write pwned

