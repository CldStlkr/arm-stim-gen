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

  MOV x17, #0x7DC1
  MOV x7, #0xBF68
  MOV x15, #0xAB75
  MOV x17, #0x8923
  MOV x8, #0xBEEF
  MOV x19, #0xD891
  MOV x7, #0x3A0E
  MOV x6, #0xFDA9
  MOV x18, #0xB384
  MOV x13, #0x712E

  STR x19, [x22, #60]
  LDR x19, [x22, #60]
  STR x6, [x22, #60]
  LDR x17, [x22, #60]
  MOV x24, #0xAFB7
  STR x8, [x22, #60]
  LDR x26, [x22, #60]
  STR x6, [x22, #60]
  LDR x25, [x22, #60]
  MOV x4, #0x683A
  MOV x25, #0xE6FD
  STR x13, [x22, #60]
  LDR x24, [x22, #60]
  STR x24, [x22, #60]
  LDR x27, [x22, #60]
  STR x27, [x22, #60]
  LDR x13, [x22, #60]
  STR x7, [x22, #60]
  LDR x15, [x22, #60]
  STR x6, [x22, #60]
  LDR x8, [x22, #60]
  MOV x9, #0xF21A
  STR x27, [x22, #60]
  LDR x11, [x22, #60]
  STR x25, [x22, #60]
  LDR x25, [x22, #60]
  STR x17, [x22, #60]
  LDR x27, [x22, #60]
  STR x8, [x22, #60]
  LDR x29, [x22, #60]
  STR x9, [x22, #60]
  LDR x11, [x22, #60]
  STR x29, [x22, #60]
  LDR x25, [x22, #60]
  STR x18, [x22, #60]
  LDR x28, [x22, #60]
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
