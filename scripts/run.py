#!/usr/bin/env python3
"""
Layer 2 orchestrator:
1: Assemble + link .S into ELF
2: Run under QEMU
3: Read /tmp/stim_result.bin written by the test itself
4: Parse register dump and verify against expected values
"""

import subprocess
import sys
import struct
from pathlib import Path

ROOT      = Path(__file__).parent.parent
TESTS_DIR = ROOT / "tests"

ASSEMBLER = "aarch64-linux-gnu-as"
LINKER    = "aarch64-linux-gnu-ld"
QEMU      = "qemu-aarch64"

RESULT_FILE = Path("/tmp/stim_result.bin")
NUM_REGS    = 5


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
        [LINKER, str(obj_path), "-o", str(elf_path)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Linker error:\n{result.stderr}")
        sys.exit(1)
    print(f"Linked:    {elf_path.name}")
    return elf_path


def run_qemu(elf_path: Path) -> int:
    # Remove any old result file
    if RESULT_FILE.exists():
        RESULT_FILE.unlink()

    result = subprocess.run(
        [QEMU, str(elf_path)],
        capture_output=True, text=True
    )
    print(f"QEMU exit code: {result.returncode}")
    if result.returncode != 0:
        print(f"QEMU stderr:\n{result.stderr}")
        sys.exit(1)
    return result.returncode


def parse_results() -> dict:
    if not RESULT_FILE.exists():
        print(f"Error: {RESULT_FILE} was not created by the test program")
        return {}
    data = RESULT_FILE.read_bytes()
    if len(data) < NUM_REGS * 8:
        print(f"Warning: result file is {len(data)} bytes, expected {NUM_REGS * 8}")

    regs = {}
    for i in range(min(NUM_REGS, len(data) // 8)):
        # <Q = < (little endian) Q (unsigned long long, 8 bytes)
        value = struct.unpack_from("<Q", data, i * 8)[0]
        regs[f"x{i}"] = value
    return regs


def verify(regs: dict) -> bool:
    expected = {
        "x0": 1,
        "x1": 2,
        "x2": 3,   # ADD x2, x0, x1
        "x3": 2,   # MUL x3, x0, x1
        "x4": 1,   # SUB x4, x1, x0
    }

    print("\n--- Register Verification ---")
    all_pass = True
    for reg, exp in expected.items():
        got = regs.get(reg)
        if got is None:
            print(f"  {reg}: MISSING")
            all_pass = False
            continue
        status = "PASS" if got == exp else "FAIL"
        if got != exp:
            all_pass = False
        print(f"  {reg}: expected={exp:#x}  got={got:#x}  [{status}]")

    print(f"\nOverall: {'PASS' if all_pass else 'FAIL'}")
    return all_pass


def main():
    asm_path = TESTS_DIR / "test_000.S"
    if not asm_path.exists():
        print(f"Error: {asm_path} not found. Run the generator first.")
        sys.exit(1)

    obj_path = assemble(asm_path)
    elf_path = link(obj_path)
    run_qemu(elf_path)
    regs = parse_results()
    if regs:
        verify(regs)


if __name__ == "__main__":
    main()
