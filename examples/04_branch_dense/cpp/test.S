// seed: 0x0000000000000004

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

  MOV x24, #0x742E
  MOV x16, #0x0FF3
  MOV x15, #0x0E6F
  MOV x26, #0x09E0
  MOV x24, #0xC668
  MOV x18, #0x729E
  MOV x13, #0x5F73
  MOV x28, #0xB018
  MOV x10, #0x337B
  MOV x28, #0xBD92

    CBZ x28, .Lskip_0
    NOP
.Lskip_0:
    CBNZ x28, .Lskip_1
    NOP
.Lskip_1:
  MOV x7, #0x39D1
    CBZ x26, .Lskip_2
    NOP
.Lskip_2:
    CBZ x28, .Lskip_3
    NOP
.Lskip_3:
    CBZ x28, .Lskip_4
    NOP
.Lskip_4:
    CBZ x18, .Lskip_5
    NOP
.Lskip_5:
  MOV x19, #0x93F8
  MOV x3, #0x0F3D
    CBNZ x10, .Lskip_6
    NOP
.Lskip_6:
    CBNZ x7, .Lskip_7
    NOP
.Lskip_7:
    CBZ x24, .Lskip_8
    NOP
.Lskip_8:
    CBNZ x18, .Lskip_9
    NOP
.Lskip_9:
    CBZ x15, .Lskip_10
    NOP
.Lskip_10:
    CBZ x13, .Lskip_11
    NOP
.Lskip_11:
    CBNZ x24, .Lskip_12
    NOP
.Lskip_12:
    CBZ x19, .Lskip_13
    NOP
.Lskip_13:
  MOV x28, #0xE329
    CBZ x24, .Lskip_14
    NOP
.Lskip_14:
  MOV x8, #0x57E3
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
