#include "mov_imm.hpp"
#include <format>
#include <random>

namespace stim {
std::optional<std::string> MovImmEmitter::try_emit(GeneratorState& state) {
  auto dst = state.pick_writable_gpr();
  if (!dst) return std::nullopt;

  std::uniform_int_distribution<uint32_t> dist(0, 0xFFFF);
  uint32_t imm = dist(state.rng());

  state.mark_scalar(*dst);
  return std::format("  MOV x{}, #0x{:04X}", *dst, imm);
}
} // namespace stim
