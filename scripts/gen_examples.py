#!/usr/bin/env python3
"""
Populate examples/ with .S and golden outputs for each generator.

Five examples, one per strategy. Each uses the same fixed seed across all three
generators so the assembly can be compared side by side. Each generator produces
its own golden since RNG state handling differs between backends.

Output layout:
  examples/
    01_forwarding_stress/
      cpp/   test.S  golden.bin  golden.txt
      rust/  test.S  golden.bin  golden.txt
      zig/   test.S  golden.bin  golden.txt
    02_load_use_stress/
      ...
"""
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

GENERATORS = {
    "cpp":  ROOT / "generator" / "build" / "stim_gen",
    "rust": ROOT / "rust-generator" / "target" / "release" / "rust-generator",
    "zig":  ROOT / "zig-generator" / "zig-out" / "bin" / "stim_gen",
}

ASSEMBLER = "aarch64-linux-gnu-as"
LINKER    = "aarch64-linux-gnu-ld"
QEMU      = "qemu-aarch64"

EXAMPLES = [
    ("01_forwarding_stress",        "forwarding_stress",        0x0000000000000001),
    ("02_load_use_stress",          "load_use_stress",          0x0000000000000002),
    ("03_store_to_load_forwarding", "store_to_load_forwarding", 0x0000000000000003),
    ("04_branch_dense",             "branch_dense",             0x0000000000000004),
    ("05_cache_line_split",         "cache_line_split",         0x0000000000000005),
]

COUNT        = 20
NUM_SIG_REGS = 10
OUT_DIR      = ROOT / "examples"


def run_cmd(cmd: list[str], label: str) -> None:
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"  error: {label}\n{r.stderr.strip()}")
        sys.exit(1)


def assemble_link_qemu(asm_path: Path) -> Path:
    obj = asm_path.with_suffix(".o")
    elf = asm_path.with_suffix(".elf")
    sig = asm_path.parent / "signature.bin"
    run_cmd([ASSEMBLER, str(asm_path), "-o", str(obj)], "assemble")
    run_cmd([LINKER, "-Ttext=0x400000", str(obj), "-o", str(elf)], "link")
    run_cmd([QEMU, str(elf)], "qemu")
    if not sig.exists():
        print(f"  error: signature not written at {sig}")
        sys.exit(1)
    return sig


def golden_txt(sig_bytes: bytes) -> str:
    lines = []
    for i in range(NUM_SIG_REGS):
        val = struct.unpack_from("<Q", sig_bytes, i * 8)[0]
        lines.append(f"x{i:<2} = {val:#018x}")
    return "\n".join(lines) + "\n"


def main() -> None:
    missing = [g for g, p in GENERATORS.items() if not p.exists()]
    if missing:
        for g in missing:
            print(f"error: {g} binary not found: {GENERATORS[g]}")
        sys.exit(1)

    OUT_DIR.mkdir(exist_ok=True)

    for dir_name, strategy, seed in EXAMPLES:
        example_dir = OUT_DIR / dir_name
        print(f"\n{dir_name}  seed={seed:#018x}  strategy={strategy}")

        with tempfile.TemporaryDirectory() as _tmp:
            tmp = Path(_tmp)

            for gen, binary in GENERATORS.items():
                gen_tmp = tmp / gen
                gen_tmp.mkdir()
                asm_path = gen_tmp / "test.S"

                run_cmd(
                    [str(binary), "--seed", str(seed), "--count", str(COUNT),
                     "--out", str(asm_path), "--strategy", strategy],
                    f"generate ({gen})",
                )

                sig_path  = assemble_link_qemu(asm_path)
                sig_bytes = sig_path.read_bytes()

                dest = example_dir / gen
                dest.mkdir(parents=True, exist_ok=True)

                # rewrite the baked-in signature path so the .S is self-contained
                asm_text = asm_path.read_text().replace(
                    str(sig_path), "./signature.bin"
                )
                (dest / "test.S").write_text(asm_text)
                (dest / "golden.bin").write_bytes(sig_bytes)
                (dest / "golden.txt").write_text(golden_txt(sig_bytes))

                preview = "  ".join(
                    f"x{i}={struct.unpack_from('<Q', sig_bytes, i*8)[0]:#010x}"
                    for i in range(4)
                )
                print(f"  {gen:<6}  {len(asm_path.read_text().splitlines()):>3} lines  {preview} ...")

    print(f"\nDone. Written to {OUT_DIR}/")


if __name__ == "__main__":
    main()
