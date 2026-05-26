#include "../state.hpp"
#include "store_to_load.hpp"
#include <format>

namespace stim {

std::optional<std::string> StoreToLoadEmitter::try_emit(GeneratorState& state) {
  const auto scratch_id = state.scratch_region_id();
  if (!scratch_id) return std::nullopt;

  const auto& scratch = state.region(*scratch_id);
  if (scratch.watermark >= scratch.size) return std::nullopt;

  auto src = state.pick_initialized_gpr();
  if (!src) return std::nullopt;

  auto dst = state.pick_writable_gpr();
  if (!dst) return std::nullopt;

  const uint64_t offset = scratch.watermark;
  state.hit_coverage(CovPoint::StoreToLoadFwd);
  state.advance_watermark(*scratch_id, 8);
  state.mark_scalar(*dst);
  return std::format("    STR x{}, [x22, #{}]\n    LDR x{}, [x22, #{}]", *src, offset, *dst, offset);
}

} // namespace stim
