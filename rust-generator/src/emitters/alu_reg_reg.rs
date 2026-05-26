use crate::emitter::Emitter;
use crate::state::GeneratorState;
use rand::RngExt;

pub struct AluRegRegEmitter;

impl Emitter for AluRegRegEmitter {
    fn try_emit(&mut self, state: &mut GeneratorState) -> Option<String> {
        let src1 = state.pick_initialized_gpr()?;
        let src2 = state.pick_initialized_gpr()?;
        let dst = state.pick_writable_gpr()?;

        const OPS: [&str; 6] = ["ADD", "SUB", "AND", "ORR", "EOR", "MUL"];
        let op = OPS[state.rng().random_range(0..OPS.len())];
        state.mark_scalar(dst);

        Some(format!("  {} x{}, x{}, x{}", op, dst, src1, src2))
    }
}
