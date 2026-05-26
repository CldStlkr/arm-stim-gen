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

  MOV x1, #0x5AFB
  MOV x26, #0x6CDC
  MOV x18, #0x614E
  MOV x9, #0xF4EA
  MOV x6, #0x59D0
  MOV x23, #0xB6FD
  MOV x25, #0x3736
  MOV x1, #0x0003
  MOV x1, #0xCF57
  MOV x8, #0x251A

  MOV x14, #0xD790
  STR x23, [x22, #0]
    LDR x7, [x22, #0]
    ADD x18, x7, x18
    LDR x6, [x22, #0]
    ORR x10, x6, x23
    LDR x6, [x22, #0]
    ORR x14, x6, x26
    LDR x3, [x22, #0]
    AND x9, x3, x23
  STR x1, [x22, #8]
  MOV x11, #0x8527
    LDR x15, [x22, #8]
    SUB x6, x15, x23
  STR x1, [x22, #16]
  STR x15, [x22, #24]
  STR x3, [x22, #32]
    LDR x16, [x22, #8]
    SUB x0, x16, x11
    LDR x15, [x22, #32]
    AND x0, x15, x26
  STR x1, [x22, #40]
  STR x23, [x22, #48]
  MOV x15, #0x8F37
  MOV x18, #0xA082
    LDR x23, [x22, #16]
    AND x10, x23, x9
  STR x9, [x22, #56]
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
