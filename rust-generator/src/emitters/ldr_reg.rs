use crate::emitter::Emitter;
use crate::state::GeneratorState;
use rand::RngExt;

pub struct LdrRegEmitter;

impl Emitter for LdrRegEmitter{
    fn try_emit(&mut self, state: &mut GeneratorState) -> Option<String> {
        let scratch_id = state.get_scratch_region_id()?;
        let watermark = state.get_region(scratch_id).watermark;
        let dst = state.pick_writable_gpr()?;
        let offset = state.rng().random_range(0..watermark / 8) * 8;
        state.mark_scalar(dst);


        Some(format!("  LDR x{}, [x22, #{}]", dst, offset))
    }
}
