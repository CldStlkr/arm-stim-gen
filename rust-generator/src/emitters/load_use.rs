use crate::coverage::CovPoint;
use crate::emitter::Emitter;
use crate::state::GeneratorState;
use rand::RngExt;

pub struct LoadUseEmitter;

impl Emitter for LoadUseEmitter {
    fn try_emit(&mut self, state: &mut GeneratorState) -> Option<String> {
        let scratch_id = state.get_scratch_region_id()?;
        let watermark = state.get_region(scratch_id).watermark;
        if watermark < 8 { return None; }
        let ldr_dst = state.pick_writable_gpr()?;
        let load_offset = state.rng().random_range(0..watermark / 8) * 8;
        let src2 = state.pick_initialized_gpr()?;
        let alu_dst = state.pick_writable_gpr()?;
        const OPS: [&str; 4] = ["ADD", "SUB", "AND", "ORR"];
        let op = OPS[state.rng().random_range(0..OPS.len())];
        state.hit_coverage(CovPoint::LoadUseHazard);
        state.mark_scalar(ldr_dst);
        state.mark_scalar(alu_dst);
        Some(format!(
            "    LDR x{}, [x22, #{}]\n    {} x{}, x{}, x{}",
            ldr_dst, load_offset, op, alu_dst, ldr_dst, src2
        ))
    }
}
