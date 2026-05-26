#include "state.hpp"

namespace stim {

// Seed RNG, reserve the two registers
GeneratorState::GeneratorState(uint64_t seed) : seed_{seed}, rng_{seed} {
  regs_[kScratchReg].kind = RegKind::Reserved;
  regs_[kSigPointer].kind = RegKind::Reserved;
  regs_[kScratchPointer].kind = RegKind::Reserved;
}

// Read-only window into regs_
RegKind GeneratorState::kind_of(uint8_t reg) const { return regs_[reg].kind; }
const RegInfo& GeneratorState::info_of(uint8_t reg) const { return regs_[reg]; }

// Source operand selector. Safe to read
std::optional<uint8_t> GeneratorState::pick_initialized_gpr() {
  std::vector<uint8_t> candidates{};
  for (uint8_t i = 0; i < kNumGprs; ++i) {
    auto k = regs_[i].kind;
    if (k == RegKind::Scalar || k == RegKind::Pointer) candidates.push_back(i);
  }

  if (candidates.empty()) return std::nullopt;
  std::uniform_int_distribution<size_t> dist(0, candidates.size() - 1);
  return candidates[dist(rng_)];
}

// Destination selector. Safe to write
std::optional<uint8_t> GeneratorState::pick_writable_gpr() {
  std::vector<uint8_t> candidates{};
  for (uint8_t i = 0; i < kNumGprs; ++i) {
    if (regs_[i].kind != RegKind::Reserved) candidates.push_back(i);
  }

  if (candidates.empty()) return std::nullopt;

  std::uniform_int_distribution<size_t> dist(0, candidates.size() - 1);
  return candidates[dist(rng_)];
}

// Memory address selector. Bounds-checked
std::optional<uint8_t> GeneratorState::pick_pointer_gpr(uint64_t min_headroom) {
  std::vector<uint8_t> candidates{};
  for (uint8_t i = 0; i < kNumGprs; ++i) {
    if (regs_[i].kind != RegKind::Pointer) continue;
    const auto& info = regs_[i];
    const auto& mem = regions_[*info.region];
    uint64_t remaining = mem.size - static_cast<uint64_t>(info.offset);
    if (remaining >= min_headroom) candidates.push_back(i);
  }
  if (candidates.empty()) return std::nullopt;
  std::uniform_int_distribution<size_t> dist(0, candidates.size() - 1);
  return candidates[dist(rng_)];
}

/*
 * These four mark* functions are for Emmiter feedback. Mark to update state.
 */
void GeneratorState::mark_scalar(uint8_t reg) {
  regs_[reg] = RegInfo{RegKind::Scalar, std::nullopt, 0};
  last_written_ = reg;
}
void GeneratorState::mark_pointer(uint8_t reg, RegionId region, int64_t offset) {
  regs_[reg] = RegInfo{RegKind::Pointer, region, offset};
}
void GeneratorState::mark_reserved(uint8_t reg) { regs_[reg] = RegInfo{RegKind::Reserved, std::nullopt, 0}; }
void GeneratorState::mark_uninitialized(uint8_t reg) { regs_[reg] = RegInfo{RegKind::Uninitialized, std::nullopt, 0}; }

// Memory Region bookkeeping
RegionId GeneratorState::add_region(uint64_t size, uint8_t base_reg, std::string label) {
  RegionId id = static_cast<RegionId>(regions_.size());
  regions_.push_back(MemRegion{id, size, base_reg, 0, std::move(label)});
  return id;
}

const MemRegion& GeneratorState::region(RegionId id) const { return regions_[id]; }

void GeneratorState::advance_watermark(RegionId id, uint64_t bytes) { regions_[id].watermark += bytes; }
} // namespace stim
