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

  MOV x19, #0x9809
  MOV x7, #0x0598
  MOV x4, #0x7911
  MOV x17, #0xF4D2
  MOV x11, #0x2417
  MOV x5, #0xD658
  MOV x17, #0x21B1
  MOV x1, #0xE8D5
  MOV x2, #0x6D7F
  MOV x16, #0xBA47

    CBNZ x7, .Lskip_0
    NOP
.Lskip_0:
    CBNZ x11, .Lskip_1
    NOP
.Lskip_1:
    CBNZ x2, .Lskip_2
    NOP
.Lskip_2:
    CBNZ x4, .Lskip_3
    NOP
.Lskip_3:
  MOV x5, #0x8C49
    CBZ x2, .Lskip_4
    NOP
.Lskip_4:
    CBNZ x19, .Lskip_5
    NOP
.Lskip_5:
    CBZ x16, .Lskip_6
    NOP
.Lskip_6:
  MOV x3, #0x2D94
    CBNZ x7, .Lskip_7
    NOP
.Lskip_7:
  MOV x11, #0x7665
    CBZ x16, .Lskip_8
    NOP
.Lskip_8:
    CBZ x11, .Lskip_9
    NOP
.Lskip_9:
    CBZ x11, .Lskip_10
    NOP
.Lskip_10:
    CBNZ x11, .Lskip_11
    NOP
.Lskip_11:
    CBNZ x1, .Lskip_12
    NOP
.Lskip_12:
    CBNZ x7, .Lskip_13
    NOP
.Lskip_13:
    CBZ x16, .Lskip_14
    NOP
.Lskip_14:
    CBZ x1, .Lskip_15
    NOP
.Lskip_15:
    CBNZ x2, .Lskip_16
    NOP
.Lskip_16:
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
