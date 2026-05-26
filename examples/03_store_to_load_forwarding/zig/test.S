// seed: 0x0000000000000003

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

  MOV x1, #0x6E30
  MOV x27, #0xD525
  MOV x17, #0x120F
  MOV x5, #0xD17C
  MOV x15, #0x072E
  MOV x16, #0x0980
  MOV x9, #0x90FF
  MOV x1, #0x3BC5
  MOV x5, #0xC15C
  MOV x24, #0x9A66

    STR x1, [x22, #0]
    LDR x26, [x22, #0]
  MOV x6, #0x9B70
    STR x9, [x22, #8]
    LDR x25, [x22, #8]
    STR x9, [x22, #16]
    LDR x28, [x22, #16]
  MOV x13, #0x991D
  EOR x29, x17, x1
  AND x29, x6, x9
    STR x9, [x22, #24]
    LDR x1, [x22, #24]
    STR x5, [x22, #32]
    LDR x25, [x22, #32]
  MUL x15, x28, x9
  AND x0, x6, x5
  MOV x4, #0xFC44
  MOV x24, #0x84A9
  SUB x9, x15, x4
  AND x26, x13, x28
    STR x4, [x22, #40]
    LDR x7, [x22, #40]
  ORR x29, x13, x17
    STR x27, [x22, #48]
    LDR x13, [x22, #48]
  MOV x29, #0x3FBF
    STR x25, [x22, #56]
    LDR x8, [x22, #56]
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
