#include "../state.hpp"
#include "forwarding_alu.hpp"
#include <array>
#include <format>
#include <random>
#include <string_view>

namespace stim {
std::optional<std::string> ForwardingAluEmitter::try_emit(GeneratorState& state) {
  // Bias src1 toward the last-written register. No RNG raw if the bias applies.
  // Falls back to a random initialized GPR if the last_written is abesnt.
  bool used_bias = false;
  uint8_t src1_reg;
  if (auto last = state.last_written_reg(); last.has_value() && state.kind_of(*last) == RegKind::Scalar) {
    src1_reg = *last;
    used_bias = true;
  } else {
    auto picked = state.pick_initialized_gpr();
    if (!picked) return std::nullopt;
    src1_reg = *picked;
  }

  auto src2 = state.pick_initialized_gpr();
  if (!src2) return std::nullopt;

  auto dst = state.pick_writable_gpr();
  if (!dst) return std::nullopt;

  static constexpr std::array<std::string_view, 6> ops = {"ADD", "SUB", "AND", "ORR", "EOR", "MUL"};
  std::uniform_int_distribution<size_t> op_dist(0, ops.size() - 1);
  const auto op = ops[op_dist(state.rng())];

  if (used_bias) state.hit_coverage(CovPoint::RawChain);
  state.mark_scalar(*dst);
  return std::format("  {} x{}, x{}, x{}", op, *dst, src1_reg, *src2);
}
} // namespace stim
