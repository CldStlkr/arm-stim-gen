#pragma once

#include "state.hpp"
#include <optional>
#include <string>

namespace stim {
class Emitter {
public:
  virtual ~Emitter() = default;
  /*
   * Attempt to emit one instruction given the current generator state.
   * Return assembly line on success, nullopt if current state cannot
   * legally support this instruction (e.g. not enough initialized registers).
   * Will not mutate state if returning nullopt
   */

  virtual std::optional<std::string> try_emit(GeneratorState& state) = 0;
};
} // namespace stim
