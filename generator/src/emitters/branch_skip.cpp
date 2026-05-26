#include "../state.hpp"
#include "branch_skip.hpp"
#include <array>
#include <format>
#include <random>
#include <string_view>

namespace stim {
std::optional<std::string> BranchSkipEmitter::try_emit(GeneratorState& state) {
  auto src = state.pick_initialized_gpr();
  if (!src) return std::nullopt;

  static constexpr std::array<std::string_view, 2> ops = {"CBZ", "CBNZ"};
  std::uniform_int_distribution<size_t> op_dist(0, 1);
  const auto op = ops[op_dist(state.rng())];

  const uint32_t n = state.next_label_id();
  state.hit_coverage(CovPoint::BranchDense);
  return std::format("    {} x{}, .Lskip_{}\n    NOP\n.Lskip_{}:", op, *src, n, n);
}
} // namespace stim
