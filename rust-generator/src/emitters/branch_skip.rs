use crate::coverage::CovPoint;
use crate::emitter::Emitter;
use crate::state::GeneratorState;
use rand::RngExt;

pub struct BranchSkipEmitter;

impl Emitter for BranchSkipEmitter {
    fn try_emit(&mut self, state: &mut GeneratorState) -> Option<String> {
        let src = state.pick_initialized_gpr()?;
        const OPS: [&str; 2] = ["CBZ", "CBNZ"];
        let op = OPS[state.rng().random_range(0..2)];
        let n = state.next_label_id();
        state.hit_coverage(CovPoint::BranchDense);
        Some(format!(
            "    {} x{}, .Lskip_{}\n    NOP\n.Lskip_{}:",
            op, src, n, n
        ))
    }
}
