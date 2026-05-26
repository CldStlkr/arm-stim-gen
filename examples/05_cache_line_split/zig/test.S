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

  MOV x8, #0xF6A1
  MOV x2, #0xD006
  MOV x14, #0xC419
  MOV x12, #0x239E
  MOV x27, #0x9B92
  MOV x28, #0x9DED
  MOV x29, #0x7BAE
  MOV x16, #0x7F2B
  MOV x23, #0x895D
  MOV x2, #0xA8F1

  STR x16, [x22, #60]
  LDR x1, [x22, #60]
  MOV x4, #0xB5C6
  MOV x30, #0x165C
  MOV x18, #0xF801
  STR x12, [x22, #60]
  LDR x30, [x22, #60]
  STR x16, [x22, #60]
  LDR x15, [x22, #60]
  STR x18, [x22, #60]
  LDR x30, [x22, #60]
  MOV x15, #0xFFB5
  STR x2, [x22, #60]
  LDR x5, [x22, #60]
  STR x29, [x22, #60]
  LDR x2, [x22, #60]
  MOV x5, #0x168E
  STR x8, [x22, #60]
  LDR x13, [x22, #60]
  STR x1, [x22, #60]
  LDR x29, [x22, #60]
  STR x12, [x22, #60]
  LDR x5, [x22, #60]
  STR x2, [x22, #60]
  LDR x19, [x22, #60]
  STR x13, [x22, #60]
  LDR x28, [x22, #60]
  STR x14, [x22, #60]
  LDR x9, [x22, #60]
  STR x18, [x22, #60]
  LDR x9, [x22, #60]
  STR x19, [x22, #60]
  LDR x8, [x22, #60]
  STR x16, [x22, #60]
  LDR x8, [x22, #60]
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
