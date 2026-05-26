#!/usr/bin/env python3
"""
Post-hoc static hazard analyzer for generated AArch64 assembly.

Parses a .S file produced by any stim_gen backend and counts actual
hazard pattern occurrences in the instruction stream, independent of
what emitters self-reported via hit_coverage().

Hazard definitions:
  RawChain      : ALU at N writes xD; ALU at N+1 reads xD as src1 or src2
  LoadUseHazard : LDR xD at N; any instruction at N+1 reads xD
  StoreToLoadFwd: STR [x22, #off] at N; LDR [x22, #off] at N+1 (same offset)
  BranchDense   : any CBZ or CBNZ instruction
  CacheLineSplit : any load or store at offset 60 (bytes [60,68) straddles 64-byte boundary)
"""
import argparse
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

ALL_HAZARDS = ["RawChain", "LoadUseHazard", "StoreToLoadFwd", "BranchDense", "CacheLineSplit"]

_ALU    = re.compile(r'(ADD|SUB|AND|ORR|EOR|MUL)\s+x(\d+),\s+x(\d+),\s+x(\d+)')
_LDR    = re.compile(r'LDR\s+x(\d+),\s+\[x(\d+),\s+#(\d+)\]')
_STR    = re.compile(r'STR\s+x(\d+),\s+\[x(\d+),\s+#(\d+)\]')
_MOV_I  = re.compile(r'MOV\s+x(\d+),\s+#')
_MOV_R  = re.compile(r'MOV\s+x(\d+),\s+x(\d+)')
_BRANCH = re.compile(r'(CBZ|CBNZ)\s+x(\d+),')


@dataclass
class Insn:
    raw:       str
    dst:       Optional[int]    = None
    srcs:      list[int]        = field(default_factory=list)
    is_alu:    bool             = False
    is_load:   bool             = False
    is_store:  bool             = False
    is_branch: bool             = False
    mem_off:   Optional[int]    = None


def _parse_insn(raw: str) -> Optional[Insn]:
    line = raw.strip().split("//")[0].strip()
    if not line or line.startswith(".") or line.endswith(":"):
        return None
    if line.startswith("ADRP") or ":lo12:" in line:
        return None

    insn = Insn(raw=line)

    if m := _ALU.match(line):
        insn.dst    = int(m.group(2))
        insn.srcs   = [int(m.group(3)), int(m.group(4))]
        insn.is_alu = True
    elif m := _LDR.match(line):
        insn.dst     = int(m.group(1))
        insn.srcs    = [int(m.group(2))]
        insn.is_load = True
        insn.mem_off = int(m.group(3))
    elif m := _STR.match(line):
        insn.srcs     = [int(m.group(1)), int(m.group(2))]
        insn.is_store = True
        insn.mem_off  = int(m.group(3))
    elif m := _MOV_R.match(line):
        insn.dst  = int(m.group(1))
        insn.srcs = [int(m.group(2))]
    elif m := _MOV_I.match(line):
        insn.dst = int(m.group(1))
    elif m := _BRANCH.match(line):
        insn.srcs      = [int(m.group(2))]
        insn.is_branch = True
    elif line == "NOP":
        pass
    else:
        return None

    return insn


def parse_asm(path: Path) -> list[Insn]:
    """Return the flat instruction list between _start: and epilogue:."""
    insns:   list[Insn] = []
    in_text = started   = False

    for raw in path.read_text().splitlines():
        line = raw.strip().split("//")[0].strip()
        if not line:
            continue
        if ".section .data" in line:
            in_text = False
            continue
        if ".section .text" in line:
            in_text = True
            continue
        if not in_text:
            continue
        if line == "_start:":
            started = True
            continue
        if not started:
            continue
        if line == "epilogue:":
            break
        parsed = _parse_insn(raw)
        if parsed is not None:
            insns.append(parsed)

    return insns


def count_hazards(insns: list[Insn]) -> dict[str, int]:
    counts: dict[str, int] = dict.fromkeys(ALL_HAZARDS, 0)

    for i, insn in enumerate(insns):
        if insn.is_branch:
            counts["BranchDense"] += 1

        if (insn.is_load or insn.is_store) and insn.mem_off == 60:
            counts["CacheLineSplit"] += 1

        if i == 0:
            continue

        prev = insns[i - 1]

        if (prev.is_alu and prev.dst is not None
                and insn.is_alu and prev.dst in insn.srcs):
            counts["RawChain"] += 1

        if (prev.is_load and prev.dst is not None
                and prev.dst in insn.srcs):
            counts["LoadUseHazard"] += 1

        if (prev.is_store and insn.is_load
                and prev.mem_off is not None
                and prev.mem_off == insn.mem_off):
            counts["StoreToLoadFwd"] += 1

    return counts


def analyze(path: Path) -> dict[str, int]:
    """Convenience: parse and count in one call."""
    return count_hazards(parse_asm(path))


def main() -> None:
    ap = argparse.ArgumentParser(description="Post-hoc static hazard analyzer")
    ap.add_argument("--asm", required=True, type=Path)
    args = ap.parse_args()

    insns  = parse_asm(args.asm)
    counts = count_hazards(insns)
    print(f"Instructions: {len(insns)}")
    for h in ALL_HAZARDS:
        print(f"  {h:<20} {counts[h]}")


if __name__ == "__main__":
    main()
