use std::io::Write;
use crate::state::GeneratorState;

pub fn emit_prologue<W: Write>(out: &mut W, state: &mut GeneratorState, num_regs: u8, sig_path: &str) {
    let buf_size = num_regs as u64 * 8;
    writeln!(out, "// seed: 0x{:016X}\n", state.seed()).unwrap();
    writeln!(out, ".section .data").unwrap();
    writeln!(out, "result_buf:  .space {}", buf_size).unwrap();
    writeln!(out, "result_path: .asciz \"{}\"", sig_path).unwrap();
    writeln!(out, ".align 6").unwrap();
    writeln!(out, "scratch_buf: .space 256\n").unwrap();
    writeln!(out, ".section .text").unwrap();
    writeln!(out, ".global _start").unwrap();
    writeln!(out, "_start:").unwrap();
    writeln!(out, "  ADRP x21, result_buf").unwrap();
    writeln!(out, "  ADD  x21, x21, :lo12:result_buf").unwrap();
    writeln!(out, "  ADRP x22, scratch_buf").unwrap();
    writeln!(out, "  ADD  x22, x22, :lo12:scratch_buf\n").unwrap();
    let scratch_id = state.add_region(256, GeneratorState::SCRATCH_POINTER, "scratch_buf".to_string());
    state.set_scratch_region_id(scratch_id);
}

pub fn emit_epilogue<W: Write>(out: &mut W, num_regs: u8) {
    let buf_size = num_regs as u64 * 8;
    writeln!(out, "epilogue:").unwrap();
    for i in 0..num_regs {
        writeln!(out, "  STR x{}, [x21, #{}]", i, i as u64 * 8).unwrap();
    }
    writeln!(out, "\n    MOV  x0, #-100").unwrap();
    writeln!(out, "    ADRP x1, result_path").unwrap();
    writeln!(out, "    ADD  x1, x1, :lo12:result_path").unwrap();
    writeln!(out, "    MOV  x2, #577").unwrap();
    writeln!(out, "    MOV  x3, #0x1A4").unwrap();
    writeln!(out, "    MOV  x8, #56").unwrap();
    writeln!(out, "    SVC  #0\n").unwrap();
    writeln!(out, "    MOV  x1, x21").unwrap();
    writeln!(out, "    MOV  x2, #{}", buf_size).unwrap();
    writeln!(out, "    MOV  x8, #64").unwrap();
    writeln!(out, "    SVC  #0\n").unwrap();
    writeln!(out, "    MOV  x8, #93").unwrap();
    writeln!(out, "    MOV  x0, #0").unwrap();
    writeln!(out, "    SVC  #0").unwrap();
}
