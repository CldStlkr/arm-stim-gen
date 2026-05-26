#include "../state.hpp"
#include "load_use.hpp"
#include <array>
#include <format>
#include <random>
#include <string_view>

namespace stim {

std::optional<std::string> LoadUseEmitter::try_emit(GeneratorState& state) {
  const auto scratch_id = state.scratch_region_id();
  if (!scratch_id) return std::nullopt;

  const auto& scratch = state.region(*scratch_id);
  if (scratch.watermark < 8) return std::nullopt;

  auto ldr_dst = state.pick_writable_gpr();
  if (!ldr_dst) return std::nullopt;

  std::uniform_int_distribution<uint64_t> slot_dist(0, scratch.watermark / 8 - 1);
  const uint64_t load_offset = slot_dist(state.rng()) * 8;

  auto src2 = state.pick_initialized_gpr();
  if (!src2) return std::nullopt;

  auto alu_dst = state.pick_writable_gpr();
  if (!alu_dst) return std::nullopt;

  static constexpr std::array<std::string_view, 4> ops = {"ADD", "SUB", "AND", "ORR"};
  std::uniform_int_distribution<size_t> op_dist(0, ops.size() - 1);
  const auto op = ops[op_dist(state.rng())];

  state.hit_coverage(CovPoint::LoadUseHazard);
  state.mark_scalar(*ldr_dst);
  state.mark_scalar(*alu_dst);
  return std::format("    LDR x{}, [x22, #{}]\n    {} x{}, x{}, x{}", *ldr_dst, load_offset, op, *alu_dst, *ldr_dst,
                     *src2);
}

} // namespace stim
