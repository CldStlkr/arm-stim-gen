// seed: 0x0000000000000002

.section .data
result_buf:  .space 80
result_path: .asciz "./signature.bin"
.align 6
scratch_buf: .space 256

.section .text
.global _start
_start:
  ADRP x21, result_buf
  ADD  x21, x21, :lo12:result_buf
  ADRP x22, scratch_buf
  ADD  x22, x22, :lo12:scratch_buf

  MOV x24, #0x9E40
  MOV x18, #0xDD21
  MOV x13, #0xCC06
  MOV x9, #0x0DBD
  MOV x13, #0xE5E0
  MOV x14, #0x3AFD
  MOV x18, #0x0728
  MOV x30, #0x00C7
  MOV x15, #0x80F2
  MOV x6, #0xDABC

    STR x24, [x22, #0]
    STR x6, [x22, #8]
    LDR x28, [x22, #0]
    ORR x18, x28, x14
    LDR x3, [x22, #8]
    ADD x14, x3, x9
    LDR x29, [x22, #0]
    SUB x30, x29, x14
  MOV x1, #0xB748
  MOV x9, #0x7CC3
  MOV x2, #0x4FB2
    LDR x15, [x22, #8]
    ADD x10, x15, x15
    STR x2, [x22, #16]
    LDR x10, [x22, #16]
    ADD x9, x10, x14
    STR x9, [x22, #24]
    LDR x17, [x22, #0]
    ORR x29, x17, x9
    STR x3, [x22, #32]
    LDR x19, [x22, #16]
    AND x4, x19, x2
    LDR x1, [x22, #24]
    SUB x30, x1, x13
    LDR x27, [x22, #8]
    ORR x6, x27, x3
    LDR x6, [x22, #16]
    SUB x13, x6, x2
    STR x27, [x22, #40]
  MOV x3, #0x3370
epilogue:
  STR x0, [x21, #0]
  STR x1, [x21, #8]
  STR x2, [x21, #16]
  STR x3, [x21, #24]
  STR x4, [x21, #32]
  STR x5, [x21, #40]
  STR x6, [x21, #48]
  STR x7, [x21, #56]
  STR x8, [x21, #64]
  STR x9, [x21, #72]

    MOV  x0, #-100
    ADRP x1, result_path
    ADD  x1, x1, :lo12:result_path
    MOV  x2, #577
    MOV  x3, #0x1A4
    MOV  x8, #56
    SVC  #0

    MOV  x1, x21
    MOV  x2, #80
    MOV  x8, #64
    SVC  #0

    MOV  x8, #93
    MOV  x0, #0
    SVC  #0
