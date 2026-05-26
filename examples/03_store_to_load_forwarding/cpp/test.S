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

  MOV x15, #0x321D
  MOV x16, #0x58AB
  MOV x15, #0x5C7E
  MOV x23, #0x6C33
  MOV x19, #0x2A87
  MOV x3, #0x975F
  MOV x15, #0xE9BF
  MOV x7, #0x053B
  MOV x7, #0xCAE0
  MOV x30, #0x7E59

  MOV x0, #0x13DD
  ORR x18, x7, x7
    STR x7, [x22, #0]
    LDR x12, [x22, #0]
    STR x19, [x22, #8]
    LDR x2, [x22, #8]
    STR x30, [x22, #16]
    LDR x17, [x22, #16]
    STR x12, [x22, #24]
    LDR x16, [x22, #24]
    STR x19, [x22, #32]
    LDR x30, [x22, #32]
  ADD x12, x2, x23
    STR x15, [x22, #40]
    LDR x12, [x22, #40]
    STR x19, [x22, #48]
    LDR x5, [x22, #48]
    STR x12, [x22, #56]
    LDR x16, [x22, #56]
  MOV x27, #0x53D7
  SUB x16, x3, x17
  MOV x3, #0x888A
    STR x17, [x22, #64]
    LDR x14, [x22, #64]
    STR x7, [x22, #72]
    LDR x16, [x22, #72]
    STR x30, [x22, #80]
    LDR x23, [x22, #80]
  ADD x27, x12, x17
    STR x2, [x22, #88]
    LDR x25, [x22, #88]
  MOV x8, #0x7EF8
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
