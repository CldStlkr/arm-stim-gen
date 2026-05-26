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

  MOV x28, #0xD9A9
  MOV x24, #0xECE1
  MOV x7, #0x22C9
  MOV x6, #0x1982
  MOV x0, #0xAF93
  MOV x18, #0xF7E8
  MOV x25, #0x21FD
  MOV x5, #0x114F
  MOV x30, #0x90E3
  MOV x9, #0x623F

  MOV x13, #0x6FE1
  MOV x13, #0x20F1
  MOV x11, #0x5BA5
    STR x9, [x22, #0]
  MOV x14, #0xC8EE
    LDR x24, [x22, #0]
    SUB x10, x24, x24
  MOV x25, #0x0582
    LDR x2, [x22, #0]
    AND x1, x2, x9
  MOV x25, #0xA90E
    LDR x5, [x22, #0]
    ADD x29, x5, x5
    LDR x11, [x22, #0]
    AND x3, x11, x13
    STR x29, [x22, #8]
  MOV x7, #0x9886
    LDR x11, [x22, #0]
    AND x8, x11, x30
  MOV x13, #0xA41E
    LDR x5, [x22, #8]
    AND x10, x5, x10
  MOV x2, #0xA09A
    LDR x23, [x22, #0]
    AND x18, x23, x14
  MOV x30, #0x3B8E
  MOV x3, #0x7A82
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
