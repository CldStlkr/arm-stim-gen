#include "alu_reg_reg.hpp"
#include <array>
#include <format>
#include <random>
#include <string_view>

namespace stim {

std::optional<std::string> AluRegRegEmitter::try_emit(GeneratorState& state) {
  auto src1 = state.pick_initialized_gpr();
  if (!src1) return std::nullopt;

  auto src2 = state.pick_initialized_gpr();
  if (!src2) return std::nullopt;

  auto dst = state.pick_writable_gpr();
  if (!dst) return std::nullopt;

  static constexpr std::array<std::string_view, 6> ops = {"ADD", "SUB", "AND", "ORR", "EOR", "MUL"};
  std::uniform_int_distribution<size_t> op_dist(0, ops.size() - 1);
  const auto op = ops[op_dist(state.rng())];

  state.mark_scalar(*dst);
  return std::format("  {} x{}, x{}, x{}", op, *dst, *src1, *src2);
}
} // namespace stim
