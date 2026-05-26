#include "../state.hpp"
#include "str_reg.hpp"
#include <format>

namespace stim {

std::optional<std::string> StrRegEmitter::try_emit(GeneratorState& state) {
  const auto scratch_id = state.scratch_region_id();
  if (!scratch_id) return std::nullopt;

  const auto& scratch = state.region(*scratch_id);
  if (scratch.watermark >= scratch.size) return std::nullopt;

  auto src = state.pick_initialized_gpr();
  if (!src) return std::nullopt;

  const uint64_t offset = scratch.watermark;
  state.advance_watermark(*scratch_id, 8);
  return std::format("    STR x{}, [x22, #{}]", *src, offset);
}

} // namespace stim
