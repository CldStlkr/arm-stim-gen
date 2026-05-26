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

  MOV x23, #0x2318
  MOV x13, #0x7935
  MOV x28, #0xB993
  MOV x15, #0x1BF1
  MOV x11, #0x0E44
  MOV x6, #0x74B6
  MOV x7, #0x7E74
  MOV x12, #0x566A
  MOV x26, #0xAAF7
  MOV x8, #0x436F

  ADD x30, x8, x13
  SUB x1, x30, x12
  SUB x11, x1, x6
  MOV x12, #0xB6D6
  ADD x17, x12, x6
  EOR x23, x17, x8
  MOV x18, #0xBB45
  MOV x27, #0x7B67
  SUB x0, x27, x13
  ADD x0, x0, x7
  AND x23, x0, x15
  SUB x12, x23, x28
  ADD x4, x12, x26
  MOV x6, #0x9AD9
  MOV x17, #0x9FF7
  ORR x10, x17, x11
  MUL x5, x10, x1
  MUL x28, x5, x15
  AND x24, x28, x12
  ORR x16, x24, x10
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
