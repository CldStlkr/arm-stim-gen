#pragma once

#include "coverage.hpp"
#include <array>
#include <cstdint>
#include <optional>
#include <random>
#include <set>
#include <string>
#include <vector>

namespace stim {
// Register kinds track what the generator knows about each GPR's contents.
// Values are NOT tracked; only properties relevant to legality.
enum class RegKind : uint8_t {
  Uninitialized, //  Contents unknown; not safe to read
  Scalar,        // Holds some known initialized 64-bit value
  Pointer,       // Holds an address into a known memory region
  Reserved,      // Off-limits to the stimulus pool (e.g., x20, sp, xzr)
};

using RegionId = uint32_t;

struct MemRegion {
  RegionId id;
  uint64_t size;
  uint8_t base_reg;
  uint64_t watermark;
  std::string label;
};

struct RegInfo {
  RegKind kind = RegKind::Uninitialized;
  // Valid only when kind == Pointer
  std::optional<RegionId> region = std::nullopt;
  int64_t offset = 0;
};

class GeneratorState {
public:
  static constexpr uint8_t kNumGprs = 31;
  static constexpr uint8_t kScratchReg = 20;     // x20 reserved for syscall scratch
  static constexpr uint8_t kSigPointer = 21;     // x21: signature buffer base
  static constexpr uint8_t kScratchPointer = 22; // x22: scratch buffer base

  explicit GeneratorState(uint64_t seed);

  std::mt19937_64& rng() { return rng_; }
  uint64_t seed() const { return seed_; }

  RegKind kind_of(uint8_t reg) const;
  const RegInfo& info_of(uint8_t reg) const;

  std::optional<uint8_t> pick_initialized_gpr();
  std::optional<uint8_t> pick_writable_gpr();
  std::optional<uint8_t> pick_pointer_gpr(uint64_t min_headroom);

  void mark_scalar(uint8_t reg);
  void mark_pointer(uint8_t reg, RegionId region, int64_t offset);
  void mark_reserved(uint8_t reg);
  void mark_uninitialized(uint8_t reg);

  // Monotonically increasing counter for generating unique assembly labels
  // Resets to zero with each new GeneratorState. Used by branch emitters
  uint32_t next_label_id() { return label_counter_++; }

  RegionId add_region(uint64_t size, uint8_t base_reg, std::string label);
  const MemRegion& region(RegionId id) const;
  void advance_watermark(RegionId id, uint64_t bytes);

  // Set by emit_prologue; used by LDR/STR emitters to locate the scratch region.
  std::optional<RegionId> scratch_region_id() const { return scratch_region_id_; }
  void set_scratch_region(RegionId id) { scratch_region_id_ = id; }

  std::optional<uint8_t> last_written_reg() const { return last_written_; }

  void hit_coverage(CovPoint p) { coverage_hits_.insert(p); }
  const std::set<CovPoint>& coverage_hits() const { return coverage_hits_; }

private:
  uint64_t seed_;
  std::mt19937_64 rng_;
  std::vector<MemRegion> regions_;
  std::array<RegInfo, kNumGprs> regs_{};
  std::optional<uint8_t> last_written_{};
  std::optional<RegionId> scratch_region_id_ = std::nullopt;
  uint32_t label_counter_ = 0;
  std::set<CovPoint> coverage_hits_{};
};

} // namespace stim
