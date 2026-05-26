// seed: 0x0000000000000005

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

  MOV x18, #0x09DA
  MOV x6, #0xAD09
  MOV x2, #0x18A9
  MOV x3, #0xB012
  MOV x25, #0x3834
  MOV x1, #0x9259
  MOV x7, #0xECAD
  MOV x7, #0x4CCE
  MOV x4, #0x7164
  MOV x30, #0xD847

  STR x1, [x22, #60]
  LDR x14, [x22, #60]
  STR x3, [x22, #60]
  LDR x13, [x22, #60]
  MOV x26, #0x14CC
  STR x2, [x22, #60]
  LDR x7, [x22, #60]
  STR x25, [x22, #60]
  LDR x26, [x22, #60]
  STR x30, [x22, #60]
  LDR x17, [x22, #60]
  STR x2, [x22, #60]
  LDR x4, [x22, #60]
  STR x6, [x22, #60]
  LDR x7, [x22, #60]
  MOV x27, #0xAFB0
  STR x30, [x22, #60]
  LDR x12, [x22, #60]
  STR x17, [x22, #60]
  LDR x12, [x22, #60]
  MOV x19, #0xC9DF
  STR x12, [x22, #60]
  LDR x23, [x22, #60]
  STR x17, [x22, #60]
  LDR x7, [x22, #60]
  STR x2, [x22, #60]
  LDR x12, [x22, #60]
  MOV x8, #0x2718
  STR x17, [x22, #60]
  LDR x8, [x22, #60]
  STR x8, [x22, #60]
  LDR x16, [x22, #60]
  STR x17, [x22, #60]
  LDR x27, [x22, #60]
  MOV x12, #0x0D25
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
