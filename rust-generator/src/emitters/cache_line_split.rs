use crate::coverage::CovPoint;
use crate::emitter::Emitter;
use crate::state::GeneratorState;

pub struct CacheLineSplitEmitter;

impl Emitter for CacheLineSplitEmitter {
    fn try_emit(&mut self, state: &mut GeneratorState) -> Option<String> {
        let src = state.pick_initialized_gpr()?;
        let dst = state.pick_writable_gpr()?;
        state.hit_coverage(CovPoint::CacheLineSplit);
        state.mark_scalar(dst);
        Some(format!("  STR x{}, [x22, #60]\n  LDR x{}, [x22, #60]", src, dst))
    }
}
