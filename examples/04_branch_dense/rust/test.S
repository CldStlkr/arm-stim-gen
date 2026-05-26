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

  MOV x18, #0xAA0A
  MOV x1, #0x8C4A
  MOV x29, #0x885D
  MOV x12, #0x79BA
  MOV x14, #0x22C8
  MOV x11, #0x658C
  MOV x15, #0x0FFE
  MOV x3, #0xBA81
  MOV x15, #0x34F7
  MOV x16, #0xFAB0

  MOV x24, #0x1C6A
  MOV x3, #0x13F3
    CBZ x16, .Lskip_0
    NOP
.Lskip_0:
  MOV x1, #0x0A66
    CBZ x29, .Lskip_1
    NOP
.Lskip_1:
    CBZ x1, .Lskip_2
    NOP
.Lskip_2:
    CBZ x1, .Lskip_3
    NOP
.Lskip_3:
    CBNZ x18, .Lskip_4
    NOP
.Lskip_4:
    CBNZ x18, .Lskip_5
    NOP
.Lskip_5:
    CBNZ x16, .Lskip_6
    NOP
.Lskip_6:
    CBNZ x3, .Lskip_7
    NOP
.Lskip_7:
    CBZ x1, .Lskip_8
    NOP
.Lskip_8:
  MOV x18, #0x901D
    CBNZ x3, .Lskip_9
    NOP
.Lskip_9:
    CBZ x29, .Lskip_10
    NOP
.Lskip_10:
  MOV x2, #0x4A20
    CBNZ x1, .Lskip_11
    NOP
.Lskip_11:
    CBZ x18, .Lskip_12
    NOP
.Lskip_12:
    CBZ x14, .Lskip_13
    NOP
.Lskip_13:
    CBNZ x12, .Lskip_14
    NOP
.Lskip_14:
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
