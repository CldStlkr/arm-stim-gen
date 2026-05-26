#include "../state.hpp"
#include "cache_line_split.hpp"
#include <format>

namespace stim {
// scratch_buf is .align 6 (64-byte aligned). Offset 60 places an 8-byte
// access at bytes [60, 68), straddling the first internal 64-byte boundary.
std::optional<std::string> CacheLineSplitEmitter::try_emit(GeneratorState& state) {
  auto src = state.pick_initialized_gpr();
  if (!src) return std::nullopt;

  auto dst = state.pick_writable_gpr();
  if (!dst) return std::nullopt;

  state.hit_coverage(CovPoint::CacheLineSplit);
  state.mark_scalar(*dst);
  return std::format("  STR x{}, [x22, #60]\n  LDR x{}, [x22, #60]", *src, *dst);
}
} // namespace stim
