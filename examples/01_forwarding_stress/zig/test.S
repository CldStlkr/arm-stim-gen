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

  MOV x25, #0x963F
  MOV x2, #0x05CD
  MOV x5, #0xE720
  MOV x30, #0x0363
  MOV x2, #0xF026
  MOV x28, #0x9F6C
  MOV x2, #0xEE50
  MOV x2, #0xF428
  MOV x15, #0xA4F7
  MOV x29, #0x4080

  MOV x11, #0x15D0
  MOV x17, #0xE524
  MOV x17, #0xAAF0
  MOV x28, #0x2095
  MOV x25, #0x0602
  MOV x2, #0xD7E6
  MOV x4, #0x08D7
  MOV x11, #0x82BB
  MOV x10, #0xFBDE
  MOV x4, #0xBBBA
  MOV x7, #0x8CC8
  MOV x30, #0x701F
  MOV x6, #0x4911
  MOV x11, #0x488E
  MOV x16, #0x5E4B
  MOV x28, #0x37FB
  MOV x23, #0x16A2
  MOV x1, #0x8626
  MOV x9, #0x8DA4
  MOV x23, #0x98A3
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
