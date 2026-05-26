use crate::emitter::Emitter;
use crate::state::GeneratorState;

pub struct StrRegEmitter;

impl Emitter for StrRegEmitter{
    fn try_emit(&mut self, state: &mut GeneratorState) -> Option<String> {
        let scratch_id = state.get_scratch_region_id()?;
        let (watermark, size) = {
            let s = state.get_region(scratch_id);
            (s.watermark, s.size)
        };

        if watermark >= size { return None; }
        let src = state.pick_initialized_gpr()?;
        state.advance_watermark(scratch_id, 8);

        Some(format!("  STR x{}, [x22, #{}]", src, watermark))
    }
}
