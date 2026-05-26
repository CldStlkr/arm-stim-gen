#pragma once

#include "state.hpp"
#include <ostream>
#include <string>

namespace stim {

// Emits seed comment, .data section (result_buf + scratch_buf),
// _start label, and pointer setup for x21 (sig) and x22 (scratch).
// Registers both regions in state; marks x21 as Pointer; sets scratch_region_id.
void emit_prologue(std::ostream& out, GeneratorState& state,
                   uint8_t num_regs, const std::string& sig_path);

// Emits the openat/write/exit syscall sequence.
// num_regs must match what was passed to emit_prologue.
void emit_epilogue(std::ostream& out, uint8_t num_regs);

} // namespace stim
