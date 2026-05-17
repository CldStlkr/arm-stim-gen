.section .bss
result_buf: .space 40
.section .data
result_path: .asciz "/tmp/stim_result.bin"
.section .text
.global _start
_start:
    MOV x0, #1
    MOV x1, #2
    ADD x2, x0, x1
    MUL x3, x0, x1
    SUB x4, x1, x0
    ADRP x20, result_buf
    ADD  x20, x20, :lo12:result_buf
    STR x0, [x20, #0]
    STR x1, [x20, #8]
    STR x2, [x20, #16]
    STR x3, [x20, #24]
    STR x4, [x20, #32]
    MOV x0, #-100
    ADRP x1, result_path
    ADD  x1, x1, :lo12:result_path
    MOV x2, #577
    MOV x3, #0x1A4
    MOV x8, #56
    SVC #0
    MOV x1, x20
    MOV x2, #40
    MOV x8, #64
    SVC #0
    MOV x8, #93
    MOV x0, #0
    SVC #0
