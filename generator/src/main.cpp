#include <algorithm>
#include <expected>
#include <filesystem>
#include <format>
#include <fstream>
#include <iostream>
#include <memory>
#include <random>
#include <string>
#include <vector>

#include "coverage.hpp"
#include "emitter.hpp"
#include "emitters/alu_reg_reg.hpp"
#include "emitters/branch_skip.hpp"
#include "emitters/cache_line_split.hpp"
#include "emitters/forwarding_alu.hpp"
#include "emitters/ldr_reg.hpp"
#include "emitters/load_use.hpp"
#include "emitters/mov_imm.hpp"
#include "emitters/store_to_load.hpp"
#include "emitters/str_reg.hpp"
#include "prologue.hpp"
#include "state.hpp"

namespace fs = std::filesystem;

namespace {
constexpr uint8_t kNumDumpRegs = 10;
constexpr uint8_t kBootstrapCount = 10;
} // namespace

namespace stim {

enum class Strategy : uint8_t {
  Random,
  ForwardingStress,
  LoadUseStress,
  StoreToLoadFwd,
  BranchDense,    // next session
  CacheLineSplit, // next session
};

struct Config {
  uint64_t seed = 0;
  uint32_t count = 20;
  Strategy strategy = Strategy::Random;
  fs::path out_path;
};

std::expected<Config, std::string> parse_args(int argc, char** argv) {
  Config cfg{};
  for (int i = 1; i < argc; ++i) {
    std::string arg{argv[i]};
    if (arg == "--seed" && i + 1 < argc) {
      cfg.seed = std::stoull(argv[++i], nullptr, 0);
    } else if (arg == "--count" && i + 1 < argc) {
      cfg.count = static_cast<uint32_t>(std::stoul(argv[++i]));
    } else if (arg == "--out" && i + 1 < argc) {
      cfg.out_path = argv[++i];
    } else if (arg == "--strategy" && i + 1 < argc) {
      std::string s{argv[++i]};
      if (s == "random") cfg.strategy = Strategy::Random;
      else if (s == "forwarding_stress") cfg.strategy = Strategy::ForwardingStress;
      else if (s == "load_use_stress") cfg.strategy = Strategy::LoadUseStress;
      else if (s == "store_to_load_forwarding") cfg.strategy = Strategy::StoreToLoadFwd;
      else if (s == "branch_dense") cfg.strategy = Strategy::BranchDense;
      else if (s == "cache_line_split") cfg.strategy = Strategy::CacheLineSplit;
      else return std::unexpected(std::format("Unknown strategy: {}", s));
    } else {
      return std::unexpected(std::format("Unknown argument: {}", arg));
    }
  }
  if (cfg.out_path.empty()) return std::unexpected(std::string{"--out is required"});
  return cfg;
}

std::vector<std::unique_ptr<Emitter>> build_emitter_pool(Strategy strategy) {
  std::vector<std::unique_ptr<Emitter>> pool;
  switch (strategy) {
  case Strategy::ForwardingStress:
    pool.push_back(std::make_unique<ForwardingAluEmitter>());
    pool.push_back(std::make_unique<ForwardingAluEmitter>());
    pool.push_back(std::make_unique<ForwardingAluEmitter>());
    pool.push_back(std::make_unique<MovImmEmitter>());
    break;
  case Strategy::LoadUseStress:
    pool.push_back(std::make_unique<LoadUseEmitter>());
    pool.push_back(std::make_unique<LoadUseEmitter>());
    pool.push_back(std::make_unique<StrRegEmitter>());
    pool.push_back(std::make_unique<MovImmEmitter>());
    break;
  case Strategy::StoreToLoadFwd:
    pool.push_back(std::make_unique<StoreToLoadEmitter>());
    pool.push_back(std::make_unique<StoreToLoadEmitter>());
    pool.push_back(std::make_unique<MovImmEmitter>());
    pool.push_back(std::make_unique<AluRegRegEmitter>());
    break;
  case Strategy::BranchDense:
    pool.push_back(std::make_unique<BranchSkipEmitter>());
    pool.push_back(std::make_unique<BranchSkipEmitter>());
    pool.push_back(std::make_unique<BranchSkipEmitter>());
    pool.push_back(std::make_unique<MovImmEmitter>());
    break;
  case Strategy::CacheLineSplit:
    pool.push_back(std::make_unique<CacheLineSplitEmitter>());
    pool.push_back(std::make_unique<CacheLineSplitEmitter>());
    pool.push_back(std::make_unique<CacheLineSplitEmitter>());
    pool.push_back(std::make_unique<MovImmEmitter>());
    break;
  default:
    pool.push_back(std::make_unique<MovImmEmitter>());
    pool.push_back(std::make_unique<AluRegRegEmitter>());
    pool.push_back(std::make_unique<LdrRegEmitter>());
    pool.push_back(std::make_unique<StrRegEmitter>());
    break;
  }
  return pool;
}

} // namespace stim

int main(int argc, char** argv) {
  auto result = stim::parse_args(argc, argv);
  if (!result) {
    std::cerr << "Error: " << result.error() << "\n";
    std::cerr << "Usage: stim_gen --out <path.S> [--seed N] [--count N] [--strategy <name>]\n";
    std::cerr << "Strategies: random  forwarding_stress  load_use_stress  store_to_load_forwarding\n";
    return 1;
  }

  auto cfg = std::move(*result);

  if (cfg.seed == 0) {
    cfg.seed = std::random_device{}();
    std::cerr << std::format("Generated seed: 0x{:016X}\n", cfg.seed);
  }

  fs::path sig_path = cfg.out_path.parent_path() / "signature.bin";
  fs::create_directories(cfg.out_path.parent_path());

  std::ofstream out{cfg.out_path};
  if (!out) {
    std::cerr << std::format("Error: could not open {}\n", cfg.out_path.string());
    return 1;
  }

  stim::GeneratorState state{cfg.seed};
  auto emitters = stim::build_emitter_pool(cfg.strategy);

  stim::emit_prologue(out, state, kNumDumpRegs, sig_path.string());

  stim::MovImmEmitter bootstrap{};
  for (uint32_t i = 0; i < kBootstrapCount; ++i) {
    if (auto line = bootstrap.try_emit(state)) out << *line << "\n";
  }
  out << "\n";

  for (uint32_t i = 0; i < cfg.count; ++i) {
    std::shuffle(emitters.begin(), emitters.end(), state.rng());
    bool emitted = false;
    for (const auto& emitter : emitters) {
      if (auto line = emitter->try_emit(state)) {
        out << *line << "\n";
        emitted = true;
        break;
      }
    }
    if (!emitted) {
      if (auto line = bootstrap.try_emit(state)) out << *line << "\n";
    }
  }

  stim::emit_epilogue(out, kNumDumpRegs);

  std::cout << std::format("Generator: {}\n", cfg.out_path.string());
  std::cout << std::format("Signature: {}\n", sig_path.string());
  std::cout << std::format("Seed:      0x{:016X}\n", cfg.seed);
  std::cout << std::format("Count:     {}\n", cfg.count);
  std::cout << "Coverage:";
  for (const auto& p : state.coverage_hits()) {
    std::cout << " " << stim::cov_point_name(p);
  }
  std::cout << "\n";

  return 0;
}
