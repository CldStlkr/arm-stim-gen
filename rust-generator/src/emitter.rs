use crate::state::GeneratorState;


pub trait Emitter {
    fn try_emit(&mut self, state: &mut GeneratorState) -> Option<String>;
}

