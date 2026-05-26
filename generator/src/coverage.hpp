#pragma once
#include <cstdint>
#include <string_view>

namespace stim {
enum class CovPoint : uint8_t {
  RawChain,
  LoadUseHazard,
  StoreToLoadFwd,
  BranchDense,
  CacheLineSplit,
};

constexpr std::string_view cov_point_name(CovPoint p) {
  switch (p) {
  case CovPoint::RawChain:
    return "RawChain";
  case CovPoint::LoadUseHazard:
    return "LoadUseHazard";
  case CovPoint::StoreToLoadFwd:
    return "StoreToLoadFwd";
  case CovPoint::BranchDense:
    return "BranchDense";
  case CovPoint::CacheLineSplit:
    return "CacheLineSplit";
  }
  return "Unknown";
}
} // namespace stim
