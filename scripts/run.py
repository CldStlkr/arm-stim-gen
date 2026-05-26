#!/usr/bin/env python3
"""
Orchestrator: generate → assemble → link → QEMU → golden → (optional ISS diff)

Supports multiple generator backends (cpp, rust, zig). Each backend has its own
golden directory so their outputs are fully independent.

Single-test mode: one seed, full pipeline.
Batch mode (--batch N): N random seeds, aggregate coverage.
ISS mode (--bug): after QEMU golden verification, runs the intentionally-buggy
Python ISS and reports whether the bug was exposed by this test.
Analyze mode (--analyze): after generation, runs the post-hoc static hazard
analyzer on the .S file and reports measured hazard counts alongside coverage.
"""

import argparse
import random
import shutil
import struct
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from analyze import analyze as _static_analyze, ALL_HAZARDS

ROOT       = Path(__file__).resolve().parent.parent
TESTS_DIR  = ROOT / "tests"
GOLDEN_DIR = TESTS_DIR / "golden"
ISS        = Path(__file__).resolve().parent / "iss.py"

GENERATORS = {
    "cpp":  ROOT / "generator" / "build" / "stim_gen",
    "rust": ROOT / "rust-generator" / "target" / "release" / "rust-generator",
    "zig":  ROOT / "zig-generator" / "zig-out" / "bin" / "stim_gen",
}

ASSEMBLER = "aarch64-linux-gnu-as"
LINKER    = "aarch64-linux-gnu-ld"
QEMU      = "qemu-aarch64"

NUM_REGS = 10

ALL_COV_POINTS = [
    "RawChain",
    "LoadUseHazard",
    "StoreToLoadFwd",
    "BranchDense",
    "CacheLineSplit",
]

STRATEGIES = [
    "random",
    "forwarding_stress",
    "load_use_stress",
    "store_to_load_forwarding",
    "branch_dense",
    "cache_line_split",
]

BUGS = ["load_use", "store_to_load"]


def generate(binary: Path, seed: int, count: int, out_path: Path, strategy: str) -> set[str]:
    result = subprocess.run(
        [str(binary), "--seed", str(seed), "--count", str(count),
        "--out", str(out_path), "--strategy", strategy],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Generator error:\n{result.stderr}")
        sys.exit(1)
    print(f"Generated: {out_path.name}")
    return _parse_coverage(result.stdout)


def _parse_coverage(stdout: str) -> set[str]:
    for line in stdout.splitlines():
        if line.startswith("Coverage:"):
            parts = line.split()
            return set(parts[1:]) if len(parts) > 1 else set()
    return set()


def assemble(asm_path: Path) -> Path:
    obj_path = asm_path.with_suffix(".o")
    result = subprocess.run(
        [ASSEMBLER, str(asm_path), "-o", str(obj_path)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Assembler error:\n{result.stderr}")
        sys.exit(1)
    print(f"Assembled: {obj_path.name}")
    return obj_path


def link(obj_path: Path) -> Path:
    elf_path = obj_path.with_suffix(".elf")
    result = subprocess.run(
        [LINKER, "-Ttext=0x400000", str(obj_path), "-o", str(elf_path)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Linker error:\n{result.stderr}")
        sys.exit(1)
    print(f"Linked:    {elf_path.name}")
    return elf_path


def run_qemu(elf_path: Path) -> None:
    result = subprocess.run(
        [QEMU, str(elf_path)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"QEMU stderr:\n{result.stderr}")
        sys.exit(1)
    print("QEMU:      exit 0")


def verify_or_record(sig_path: Path, golden_path: Path) -> bool:
    if not sig_path.exists():
        print(f"Error: signature not written: {sig_path}")
        sys.exit(1)

    sig_data = sig_path.read_bytes()

    if not golden_path.exists():
        golden_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(sig_path, golden_path)
        print(f"Golden:    recorded ({golden_path.name})")
        return True

    golden_data = golden_path.read_bytes()
    if sig_data == golden_data:
        print("Golden:    PASS")
        return True

    print("Golden:    FAIL")
    _print_diff(sig_data, golden_data)
    return False


def _print_diff(sig: bytes, golden: bytes) -> None:
    print("\n--- Signature diff ---")
    count = min(len(sig), len(golden)) // 8
    for i in range(count):
        got = struct.unpack_from("<Q", sig,    i * 8)[0]
        exp = struct.unpack_from("<Q", golden, i * 8)[0]
        if got != exp:
            print(f"  x{i:<2}: got={got:#018x}  golden={exp:#018x}")


def run_iss(asm_path: Path, golden_path: Path, bugs: list[str]) -> bool:
    cmd = [sys.executable, str(ISS), "--asm", str(asm_path), "--golden", str(golden_path)]
    for bug in bugs:
        cmd += ["--bug", bug]
    result = subprocess.run(cmd, capture_output=True, text=True)
    exposed = result.returncode != 0
    print(f"ISS:       {'exposed' if exposed else 'not triggered'}  bugs={bugs}")
    for line in result.stdout.splitlines():
        print(f"  {line}")
    return exposed


def run_one(
    seed: int, count: int, strategy: str, generator: str,
    bugs: list[str], do_analyze: bool = False
) -> tuple[bool, set[str], bool | None, dict[str, int] | None]:
    binary   = GENERATORS[generator]
    test_dir = TESTS_DIR / generator / f"{seed:#018x}_{strategy}"
    test_dir.mkdir(parents=True, exist_ok=True)

    asm_path    = test_dir / "test.S"
    sig_path    = test_dir / "signature.bin"
    golden_path = GOLDEN_DIR / generator / f"{seed:#018x}_{strategy}.bin"

    hits     = generate(binary, seed, count, asm_path, strategy)
    obj_path = assemble(asm_path)
    elf_path = link(obj_path)
    run_qemu(elf_path)
    ok = verify_or_record(sig_path, golden_path)

    hazard_counts: dict[str, int] | None = None
    if do_analyze:
        hazard_counts = _static_analyze(asm_path)

    iss_exposed: bool | None = None
    if bugs and golden_path.exists():
        iss_exposed = run_iss(asm_path, golden_path, bugs)

    return ok, hits, iss_exposed, hazard_counts


def print_coverage_report(cov_counts: dict, total: int, strategy: str, generator: str) -> None:
    print(f"\n--- Coverage Report ({total} test{'s' if total > 1 else ''}, strategy={strategy}, generator={generator}) ---")
    for point in ALL_COV_POINTS:
        n   = cov_counts[point]
        pct = 100 * n // total if total > 0 else 0
        print(f"  {point:<20} {n:>3} / {total}  ({pct:>3}%)")


def print_hazard_report(hazard_totals: dict, total: int, strategy: str, generator: str) -> None:
    print(f"\n--- Hazard Report ({total} test{'s' if total > 1 else ''}, strategy={strategy}, generator={generator}) ---")
    for h in ALL_HAZARDS:
        n   = hazard_totals[h]
        avg = n / total if total > 0 else 0.0
        print(f"  {h:<20} {n:>5} total  ({avg:>5.1f} avg/test)")


def main():
    parser = argparse.ArgumentParser(description="ARM stimulus generator orchestrator")
    parser.add_argument("--seed",      type=lambda x: int(x, 0), default=0,
                        help="RNG seed (0 = random, accepts 0x hex)")
    parser.add_argument("--count",     type=int, default=20,
                        help="Instructions to generate (default: 20)")
    parser.add_argument("--strategy",  choices=STRATEGIES, default="random")
    parser.add_argument("--batch",     type=int, default=1,
                        help="Number of tests to run (default: 1)")
    parser.add_argument("--generator", choices=list(GENERATORS), default="cpp",
                        help="Generator backend (default: cpp)")
    parser.add_argument("--bug",       action="append", default=[], dest="bugs",
                        choices=BUGS,
                        help="Enable an ISS bug and run ISS diff after QEMU")
    parser.add_argument("--analyze",   action="store_true", default=False,
                        help="Run post-hoc static hazard analysis on each generated .S")
    args = parser.parse_args()

    generator = args.generator
    strategy  = args.strategy
    count     = args.count
    bugs      = args.bugs

    binary = GENERATORS[generator]
    if not binary.exists():
        print(f"Error: generator binary not found: {binary}")
        if generator == "rust":
            print("  Build with: cargo build --release --manifest-path rust-generator/Cargo.toml")
        elif generator == "cpp":
            print("  Build with: cmake --build generator/build")
        sys.exit(1)

    if args.batch == 1:
        seed = args.seed if args.seed != 0 else random.getrandbits(64)
        print(f"Seed:      {seed:#018x}")
        print(f"Count:     {count}")
        print(f"Strategy:  {strategy}")
        print(f"Generator: {generator}\n")

        ok, hits, iss_exposed, hazard_counts = run_one(
            seed, count, strategy, generator, bugs, do_analyze=args.analyze
        )

        print(f"Coverage:  {' '.join(sorted(hits)) if hits else '(none)'}")
        if hazard_counts is not None:
            print("Hazards:")
            for h in ALL_HAZARDS:
                if hazard_counts[h] > 0:
                    print(f"  {h:<20} {hazard_counts[h]}")
        sys.exit(0 if ok else 1)

    else:
        print(f"Batch:     {args.batch} tests")
        print(f"Strategy:  {strategy}")
        print(f"Generator: {generator}")
        print(f"Count:     {count}\n")

        cov_counts        = defaultdict(int)
        hazard_totals     = defaultdict(int)
        all_ok            = True
        iss_exposed_count = 0

        for i in range(args.batch):
            seed = random.getrandbits(64)
            ok, hits, iss_exposed, hazard_counts = run_one(
                seed, count, strategy, generator, bugs, do_analyze=args.analyze
            )
            if not ok:
                all_ok = False
            if iss_exposed:
                iss_exposed_count += 1
            for point in hits:
                cov_counts[point] += 1
            if hazard_counts:
                for h in ALL_HAZARDS:
                    hazard_totals[h] += hazard_counts[h]
            status  = "PASS" if ok else "FAIL"
            iss_tag = f"  iss={'exposed' if iss_exposed else 'clean'}" if bugs else ""
            print(f"  [{i + 1:>{len(str(args.batch))}}/{args.batch}]  {seed:#018x}  {status}"
                f"  hits=[{', '.join(sorted(hits))}]{iss_tag}")

        print_coverage_report(cov_counts, args.batch, strategy, generator)
        if args.analyze:
            print_hazard_report(hazard_totals, args.batch, strategy, generator)
        if bugs:
            print(f"\n  ISS bug exposed: {iss_exposed_count} / {args.batch}")
        sys.exit(0 if all_ok else 1)


if __name__ == "__main__":
    main()
