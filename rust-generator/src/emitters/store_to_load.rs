use crate::coverage::CovPoint;
use crate::emitter::Emitter;
use crate::state::GeneratorState;

pub struct StoreToLoadEmitter;

impl Emitter for StoreToLoadEmitter {
    fn try_emit(&mut self, state: &mut GeneratorState) -> Option<String> {
        let scratch_id = state.get_scratch_region_id()?;
        let (watermark, size) = {
            let s = state.get_region(scratch_id);
            (s.watermark, s.size)
        };
        if watermark >= size { return None; }
        let src = state.pick_initialized_gpr()?;
        let dst = state.pick_writable_gpr()?;
        state.hit_coverage(CovPoint::StoreToLoadFwd);
        state.advance_watermark(scratch_id, 8);
        state.mark_scalar(dst);
        Some(format!(
            "    STR x{}, [x22, #{}]\n    LDR x{}, [x22, #{}]",
            src, watermark, dst, watermark
        ))
    }
}
