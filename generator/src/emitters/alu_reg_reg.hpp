#pragma once
#include "../emitter.hpp"

namespace stim {
class AluRegRegEmitter : public Emitter {
public:
  std::optional<std::string> try_emit(GeneratorState& state) override;
};
} // namespace stim
