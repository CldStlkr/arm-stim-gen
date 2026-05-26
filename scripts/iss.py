#!/usr/bin/env python3
"""
Intentionally buggy AARCH64 ISS for differential testing against QEMU.

Executes the AARCH64 subset that stim_gen emits. Writes a register signature in the same
binary format as the QEMU-run test program. Compare --golden to find the divergences that
the generator's hazard strategies are deigned to expose.

Bugs (--big, repeatable):
    load_use      : ALU after LDR reads the pre-load register value
    store_to_load : LDR after STR to same address returns the pre-store value
"""

import argparse
import re
import struct
import sys
from pathlib import Path

MASK64 = (1 << 64) - 1
NUM_SIG_REGS = 10
SCRATCH_SIZE = 256

_MOV_IMM = re.compile(r'MOV\s+x(\d+),\s+#(-?\w+)')
_MOV_REG = re.compile(r'MOV\s+x(\d+),\s+x(\d+)')
_ALU     = re.compile(r'(ADD|SUB|AND|ORR|EOR|MUL)\s+x(\d+),\s+x(\d+),\s+x(\d+)')
_LDR     = re.compile(r'LDR\s+x(\d+),\s+\[x22,\s+#(\d+)\]')
_STR     = re.compile(r'STR\s+x(\d+),\s+\[x22,\s+#(\d+)\]')
_BRANCH  = re.compile(r'(CBZ|CBNZ)\s+x(\d+),\s+(\S+)')

def load_asm(path: Path) -> tuple[list[str], dict[str, int]]:
    insns: list[str] = []
    labels: dict[str, int] = {}
    in_text = started = False

    for raw in path.read_text().splitlines():
        line = raw.strip().split('//')[0].strip()
        if not line:
            continue
        if '.section .data' in line:
            in_text = False
            continue
        if '.section .text' in line:
            in_text = True
            continue
        if not in_text:
            continue
        if line == '_start:':
            started = True
            continue
        if not started:
            continue
        if line == 'epilogue:':
            break
        if line.endswith(':'):
            labels[line[:-1]] = len(insns)
            continue
        if line.startswith('ADRP') or ':lo12:' in line:
            insns.append(line)

    return (insns, labels)


def load_asm(path: Path) -> tuple[list[str], dict[str, int]]:
      insns:  list[str]       = []
      labels: dict[str, int]  = {}
      in_text = started = False

      for raw in path.read_text().splitlines():
          line = raw.strip().split('//')[0].strip()
          if not line:
              continue
          if '.section .data' in line:
              in_text = False
              continue
          if '.section .text' in line:
              in_text = True
              continue
          if not in_text:
              continue
          if line == '_start:':
              started = True
              continue
          if not started:
              continue
          if line == 'epilogue:':
              break
          if line.endswith(':'):
              labels[line[:-1]] = len(insns)
              continue
          if line.startswith('ADRP') or ':lo12:' in line:
              continue
          insns.append(line)

      return insns, labels


def run(insns: list[str], labels: dict[str, int], bugs: set[str]) -> list[int]:
    regs    = [0] * 31
    scratch = bytearray(SCRATCH_SIZE)

    last_ldr_dst:  int | None = None
    pre_ldr_val:   int        = 0
    last_str_addr: int | None = None
    pre_str_val:   int        = 0

    pc = 0
    while pc < len(insns):
        insn    = insns[pc]
        next_pc = pc + 1

        latch_ldr = last_ldr_dst;  last_ldr_dst  = None
        latch_str = last_str_addr; last_str_addr = None

        if m := _ALU.match(insn):
            op, d, s1, s2 = m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4))
            v1 = pre_ldr_val if ('load_use' in bugs and latch_ldr == s1) else regs[s1]
            v2 = pre_ldr_val if ('load_use' in bugs and latch_ldr == s2) else regs[s2]
            if   op == 'ADD': val = (v1 + v2) & MASK64
            elif op == 'SUB': val = (v1 - v2) & MASK64
            elif op == 'AND': val = v1 & v2
            elif op == 'ORR': val = v1 | v2
            elif op == 'EOR': val = v1 ^ v2
            else:             val = (v1 * v2) & MASK64
            regs[d] = val

        elif m := _LDR.match(insn):
            dst, off = int(m.group(1)), int(m.group(2))
            if 'store_to_load' in bugs and latch_str == off:
                val = pre_str_val
            else:
                val = struct.unpack_from('<Q', scratch, off)[0]
            pre_ldr_val  = regs[dst]
            last_ldr_dst = dst
            regs[dst] = val

        elif m := _STR.match(insn):
            src_reg, off = int(m.group(1)), int(m.group(2))
            pre_str_val   = struct.unpack_from('<Q', scratch, off)[0]
            last_str_addr = off
            struct.pack_into('<Q', scratch, off, regs[src_reg] & MASK64)

        elif m := _MOV_IMM.match(insn):
            dst = int(m.group(1))
            raw = m.group(2)
            imm = -int(raw[1:], 0) if raw.startswith('-') else int(raw, 0)
            regs[dst] = imm & MASK64

        elif m := _MOV_REG.match(insn):
            d, s = int(m.group(1)), int(m.group(2))
            regs[d] = regs[s]

        elif m := _BRANCH.match(insn):
            op, reg, label = m.group(1), int(m.group(2)), m.group(3)
            take = (regs[reg] == 0) if op == 'CBZ' else (regs[reg] != 0)
            if take:
                if label not in labels:
                    print(f"Error: unknown label {label!r}", file=sys.stderr)
                    sys.exit(1)
                next_pc = labels[label]

        elif insn != 'NOP':
            print(f"Warning: unrecognized instruction: {insn!r}", file=sys.stderr)

        pc = next_pc

    return regs[:NUM_SIG_REGS]


def diff(iss_sig: bytes, golden: bytes) -> bool:
    if iss_sig == golden:
        print("ISS:    PASS — matches QEMU golden")
        return True
    print("ISS:    FAIL — diverges from QEMU golden")
    print("\n--- Register diff (ISS vs QEMU) ---")
    for i in range(NUM_SIG_REGS):
        got = struct.unpack_from('<Q', iss_sig, i * 8)[0]
        exp = struct.unpack_from('<Q', golden,  i * 8)[0]
        if got != exp:
            print(f"  x{i:<2}: iss={got:#018x}  qemu={exp:#018x}")
    return False


def main():
    ap = argparse.ArgumentParser(description="Buggy AArch64 ISS for differential testing")
    ap.add_argument('--asm',    required=True, type=Path)
    ap.add_argument('--out',    type=Path, help="Write ISS signature here")
    ap.add_argument('--golden', type=Path, help="QEMU golden to diff against")
    ap.add_argument('--bug', action='append', default=[], dest='bugs',
                    choices=['load_use', 'store_to_load'],
                    help="Enable a deliberate bug (repeatable)")
    args = ap.parse_args()

    if not args.out and not args.golden:
        ap.error("at least one of --out or --golden is required")

    insns, labels = load_asm(args.asm)
    regs = run(insns, labels, set(args.bugs))
    sig  = struct.pack('<' + 'Q' * NUM_SIG_REGS, *regs)

    if args.out:
        args.out.write_bytes(sig)

    if args.golden:
        ok = diff(sig, args.golden.read_bytes())
        sys.exit(0 if ok else 1)
    else:
        sys.exit(0)


if __name__ == '__main__':
    main()
