use crate::coverage::CovPoint;
use crate::emitter::Emitter;
use crate::state::{GeneratorState, RegKind};
use rand::RngExt;

pub struct ForwardingAluEmitter;

impl Emitter for ForwardingAluEmitter {
    fn try_emit(&mut self, state: &mut GeneratorState) -> Option<String> {
        let (src1, used_bias) = if let Some(last) = state.get_last_written_reg() {
            if state.kind_of(last) == RegKind::Scalar {
                (last, true)
            } else {
                (state.pick_initialized_gpr()?, false)
            }
        } else {
            (state.pick_initialized_gpr()?, false)
        };
        let src2 = state.pick_initialized_gpr()?;
        let dst = state.pick_writable_gpr()?;
        const OPS: [&str; 6] = ["ADD", "SUB", "AND", "ORR", "EOR", "MUL"];
        let op = OPS[state.rng().random_range(0..OPS.len())];                                                                         if used_bias { state.hit_coverage(CovPoint::RawChain); }                                                                      state.mark_scalar(dst);
        Some(format!("  {} x{}, x{}, x{}", op, dst, src1, src2))
}                                                                                                                         }
