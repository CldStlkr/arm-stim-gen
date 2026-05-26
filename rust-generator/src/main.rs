use std::fs::File;
use std::io::{BufWriter, Write};
use std::path::PathBuf;

use clap::{Parser, ValueEnum};
use rand::{RngExt, seq::SliceRandom };
use rust_generator::{
    emitter::Emitter,
    emitters::{
        alu_reg_reg::AluRegRegEmitter,
        branch_skip::BranchSkipEmitter,
        cache_line_split::CacheLineSplitEmitter,
        forwarding_alu::ForwardingAluEmitter,
        ldr_reg::LdrRegEmitter,
        load_use::LoadUseEmitter,
        mov_imm::MovImmEmitter,
        store_to_load::StoreToLoadEmitter,
        str_reg::StrRegEmitter,
    },
    prologue::{emit_epilogue, emit_prologue},
    state::GeneratorState,
};

const NUM_DUMP_REGS: u8 = 10;
const BOOTSTRAP_COUNT: u32 = 10;

#[derive(Debug, Clone, Copy, ValueEnum)]
#[value(rename_all = "snake_case")]
enum Strategy {
    Random,
    ForwardingStress,
    LoadUseStress,
    StoreToLoadForwarding,
    BranchDense,
    CacheLineSplit,
}

#[derive(Parser)]
#[command(about = "AArch64 stimulus generator")]
struct Config {
    #[arg(long)]
    out: PathBuf,

    #[arg(long, default_value_t = 0)]
    seed: u64,

    #[arg(long, default_value_t = 20)]
    count: u32,

    #[arg(long, value_enum, default_value_t = Strategy::Random)]
    strategy: Strategy,
}

fn build_emitter_pool(strategy: Strategy) -> Vec<Box<dyn Emitter>> {
    match strategy {
        Strategy::ForwardingStress => vec![
            Box::new(ForwardingAluEmitter),
            Box::new(ForwardingAluEmitter),
            Box::new(ForwardingAluEmitter),
            Box::new(MovImmEmitter),
        ],
        Strategy::LoadUseStress => vec![
            Box::new(LoadUseEmitter),
            Box::new(LoadUseEmitter),
            Box::new(StrRegEmitter),
            Box::new(MovImmEmitter),
        ],
        Strategy::StoreToLoadForwarding => vec![
            Box::new(StoreToLoadEmitter),
            Box::new(StoreToLoadEmitter),
            Box::new(MovImmEmitter),
            Box::new(AluRegRegEmitter),
        ],
        Strategy::BranchDense => vec![
            Box::new(BranchSkipEmitter),
            Box::new(BranchSkipEmitter),
            Box::new(BranchSkipEmitter),
            Box::new(MovImmEmitter),
        ],
        Strategy::CacheLineSplit => vec![
            Box::new(CacheLineSplitEmitter),
            Box::new(CacheLineSplitEmitter),
            Box::new(CacheLineSplitEmitter),
            Box::new(MovImmEmitter),
        ],
        Strategy::Random => vec![
            Box::new(MovImmEmitter),
            Box::new(AluRegRegEmitter),
            Box::new(LdrRegEmitter),
            Box::new(StrRegEmitter),
        ],
    }
}

fn main() {
    let mut cfg = Config::parse();

    if cfg.seed == 0 {
        cfg.seed = rand::rng().random::<u64>();
        eprintln!("Generated seed: 0x{:016X}", cfg.seed);
    }

    let sig_path = cfg.out
        .parent()
        .unwrap_or(std::path::Path::new("."))
        .join("signature.bin");

    if let Some(parent) = cfg.out.parent() {
        std::fs::create_dir_all(parent).unwrap();
    }

    let file = File::create(&cfg.out).unwrap_or_else(|_| {
        eprintln!("Error: could not open {}", cfg.out.display());
        std::process::exit(1);
    });
    let mut out = BufWriter::new(file);

    let mut state = GeneratorState::new(cfg.seed);
    let mut emitters = build_emitter_pool(cfg.strategy);
    let mut bootstrap = MovImmEmitter;

    emit_prologue(&mut out, &mut state, NUM_DUMP_REGS, sig_path.to_str().unwrap());

    for _ in 0..BOOTSTRAP_COUNT {
        if let Some(line) = bootstrap.try_emit(&mut state) {
            writeln!(out, "{}", line).unwrap();
        }
    }
    writeln!(out).unwrap();

    for _ in 0..cfg.count {
        emitters.shuffle(state.rng());
        let mut emitted = false;
        for emitter in emitters.iter_mut() {
            if let Some(line) = emitter.try_emit(&mut state) {
                writeln!(out, "{}", line).unwrap();
                emitted = true;
                break;
            }
        }
        if !emitted && let Some(line) = bootstrap.try_emit(&mut state) {
            writeln!(out, "{}", line).unwrap();
        }
    }

    emit_epilogue(&mut out, NUM_DUMP_REGS);

    println!("Generator: {}", cfg.out.display());
    println!("Signature: {}", sig_path.display());
    println!("Seed:      0x{:016X}", cfg.seed);
    println!("Count:     {}", cfg.count);
    print!("Coverage:");
    for p in state.get_coverage_hits() {
        print!(" {:?}", p);
    }
    println!();
}
