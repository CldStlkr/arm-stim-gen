use crate::emitter::Emitter;
use crate::state::GeneratorState;
use rand::RngExt;

pub struct MovImmEmitter;

impl Emitter for MovImmEmitter {
    fn try_emit(&mut self, state: &mut GeneratorState) -> Option<String> {
        let dst = state.pick_writable_gpr()?;
        let imm: u32 = state.rng().random_range(0..=0xFFFFu32);
        state.mark_scalar(dst);
        Some(format!("  MOV x{}, #0x{:04X}", dst, imm))
    }
}

