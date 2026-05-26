#include "prologue.hpp"
#include <format>

namespace stim {

void emit_prologue(std::ostream& out, GeneratorState& state, uint8_t num_regs, const std::string& sig_path) {
  const uint64_t buf_size = static_cast<uint64_t>(num_regs) * 8;

  out << std::format("// seed: 0x{:016X}\n\n", state.seed());

  out << ".section .data\n";
  out << std::format("result_buf:  .space {}\n", buf_size);
  out << std::format("result_path: .asciz \"{}\"\n", sig_path);
  out << ".align 6\n";
  out << "scratch_buf: .space 256\n\n";

  out << ".section .text\n";
  out << ".global _start\n";
  out << "_start:\n";
  out << "  ADRP x21, result_buf\n";
  out << "  ADD  x21, x21, :lo12:result_buf\n";
  out << "  ADRP x22, scratch_buf\n";
  out << "  ADD  x22, x22, :lo12:scratch_buf\n\n";

  RegionId scratch_id = state.add_region(256, GeneratorState::kScratchPointer, "scratch_buf");
  state.set_scratch_region(scratch_id);
}

void emit_epilogue(std::ostream& out, uint8_t num_regs) {
  const uint64_t buf_size = static_cast<uint64_t>(num_regs) * 8;

  out << "epilogue:\n";
  for (uint8_t i = 0; i < num_regs; ++i) {
    out << std::format("  STR x{}, [x21, #{}]\n", i, i * 8);
  }

  out << "\n";
  out << "    MOV  x0, #-100\n";
  out << "    ADRP x1, result_path\n";
  out << "    ADD  x1, x1, :lo12:result_path\n";
  out << "    MOV  x2, #577\n";
  out << "    MOV  x3, #0x1A4\n";
  out << "    MOV  x8, #56\n";
  out << "    SVC  #0\n\n";

  out << "    MOV  x1, x21\n";
  out << std::format("    MOV  x2, #{}\n", buf_size);
  out << "    MOV  x8, #64\n";
  out << "    SVC  #0\n\n";

  out << "    MOV  x8, #93\n";
  out << "    MOV  x0, #0\n";
  out << "    SVC  #0\n";
}

} // namespace stim
