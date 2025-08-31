; rop_overflow.asm — Overflow-based ROP demonstration (x86-64, NASM, Linux)
; Run: ./rop_overflow
; Expected output: [ROP] hello via real stack overflow!

global _start
default rel

section .text

; ===== 一些简单的 gadget（每个都以 ret 收尾） =====
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

g_syscall_ret:             ; syscall ; ret
    syscall
    ret

; ===== Vulnerable function: write oversized "input" to local buffer, overwrite return address =====
vuln_overflow_rop:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32                 ; local buf[32] placed at [rbp-32 .. rbp-1]

    ; 这三寄存器供 rep movsb 使用：RDI=dst, RSI=src, RCX=len
    lea     rdi, [rbp-32]           ; 目的：局部缓冲区
    lea     rsi, [rel attack_payload]
    mov     rcx, attack_payload_len ; 拷贝长度 > 32 → 溢出！

    rep movsb                        ; 把 payload “泼”到栈上：
                                     ; 覆盖 old RBP（[rbp]）和 saved RIP（[rbp+8]）
                                     ; saved RIP 被写成第一个 gadget 地址

    leave                            ; mov rsp, rbp ; pop rbp
    ret                              ; ← 这里直接“返回”到 g_pop_rdi（ROP 开始）

; ===== 程序入口：调用脆弱函数，剩下让 ROP 接管 =====
_start:
    call    vuln_overflow_rop

    ; 正常不会到这里（ROP 最终 exit(0)）
    mov     rax, 60
    xor     rdi, rdi
    syscall

section .data
msg:        db  "[ROP] hello via real stack overflow!", 10
msg_len     equ $-msg

; ===== 溢出载荷（按真实栈布局铺链）=====
; 栈布局回顾（高地址在上）：
;   [rbp+8]  = saved RIP     ← 我们要覆盖成第一个 gadget (g_pop_rdi)
;   [rbp]    = old RBP       ← 先随便填
;   [rbp-32]..[rbp-1] = buf  ← 先填满 32 字节
;
; 因此 payload 组织：
;   32B 填充（占满 buf）
; + 8B  覆盖 old RBP（任意）
; + 8B  覆盖 saved RIP = g_pop_rdi
; + 后续紧跟整条 ROP 链（按“返回地址 / 参数”交替排）
attack_payload:
    ; 1) 填满 buf[32]
    db  "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"      ; 32

    ; 2) 覆盖 old RBP（随便填）
    dq  0x4242424242424242

    ; 3) 从这里开始是“真实返回地址区域”及其后的栈内容：
    ;    链：write(1, msg, len) ; exit(0)
    dq  g_pop_rdi               ; ret → 到这儿：进入 gadget
    dq  1                       ;     rdi = 1 (stdout)

    dq  g_pop_rsi
    dq  msg                     ;     rsi = &msg

    dq  g_pop_rdx
    dq  msg_len                 ;     rdx = len

    dq  g_mov_rax_1             ;     rax = SYS_write
    dq  g_syscall_ret           ;     syscall ; ret

    dq  g_pop_rdi
    dq  0                       ;     rdi = 0

    dq  g_mov_rax_60            ;     rax = SYS_exit
    dq  g_syscall_ret           ;     syscall ; ret

attack_payload_len equ $-attack_payload

