#include "../state.hpp"
#include "ldr_reg.hpp"
#include <format>
#include <random>

namespace stim {

std::optional<std::string> LdrRegEmitter::try_emit(GeneratorState& state) {
  const auto scratch_id = state.scratch_region_id();
  if (!scratch_id) return std::nullopt;

  const auto& scratch = state.region(*scratch_id);
  if (scratch.watermark < 8) return std::nullopt;

  auto dst = state.pick_writable_gpr();
  if (!dst) return std::nullopt;

  std::uniform_int_distribution<uint64_t> slot_dist(0, scratch.watermark / 8 - 1);
  const uint64_t offset = slot_dist(state.rng()) * 8;

  state.mark_scalar(*dst);
  return std::format("    LDR x{}, [x22, #{}]", *dst, offset);
}

} // namespace stim
