// seed: 0x0000000000000001

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

  MOV x3, #0x22EB
  MOV x12, #0x0561
  MOV x9, #0xE94E
  MOV x13, #0x130D
  MOV x15, #0xA29E
  MOV x2, #0x8E61
  MOV x25, #0x38BC
  MOV x11, #0x3FF1
  MOV x8, #0xCDA0
  MOV x13, #0x451A

  MOV x12, #0x4E62
  EOR x1, x12, x3
  AND x14, x1, x8
  MOV x27, #0x5EDF
  ORR x7, x27, x25
  MOV x30, #0x9BD4
  MOV x4, #0xCBB3
  AND x0, x4, x14
  MOV x5, #0x0322
  MUL x6, x5, x2
  EOR x24, x6, x0
  SUB x13, x24, x11
  ORR x16, x13, x11
  EOR x17, x16, x9
  ADD x0, x17, x7
  ADD x7, x0, x17
  EOR x27, x7, x30
  MUL x1, x27, x17
  AND x8, x1, x1
  ADD x2, x8, x13
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
