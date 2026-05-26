const std = @import("std");
const GeneratorState = @import("state.zig").GeneratorState;

pub fn emitPrologue(writer: anytype, state: *GeneratorState, num_regs: u8, sig_path: []const u8) !void {
    const buf_size: u64 = @as(u64, num_regs) * 8;
    try writer.print("// seed: 0x{X:0>16}\n\n", .{state.getSeed()});
    try writer.print(".section .data\n", .{});
    try writer.print("result_buf:  .space {d}\n", .{buf_size});
    try writer.print("result_path: .asciz \"{s}\"\n", .{sig_path});
    try writer.print(".align 6\n", .{});
    try writer.print("scratch_buf: .space 256\n\n", .{});
    try writer.print(".section .text\n", .{});
    try writer.print(".global _start\n", .{});
    try writer.print("_start:\n", .{});
    try writer.print("  ADRP x21, result_buf\n", .{});
    try writer.print("  ADD  x21, x21, :lo12:result_buf\n", .{});
    try writer.print("  ADRP x22, scratch_buf\n", .{});
    try writer.print("  ADD  x22, x22, :lo12:scratch_buf\n\n", .{});
    const scratch_id = try state.addRegion(256, GeneratorState.scratch_pointer, "scratch_buf");
    state.setScratchRegionId(scratch_id);
}

pub fn emitEpilogue(writer: anytype, num_regs: u8) !void {
    const buf_size: u64 = @as(u64, num_regs) * 8;
    try writer.print("epilogue:\n", .{});
    for (0..num_regs) |i| {
        try writer.print("  STR x{d}, [x21, #{d}]\n", .{ i, i * 8 });
    }
    try writer.print("\n    MOV  x0, #-100\n", .{});
    try writer.print("    ADRP x1, result_path\n", .{});
    try writer.print("    ADD  x1, x1, :lo12:result_path\n", .{});
    try writer.print("    MOV  x2, #577\n", .{});
    try writer.print("    MOV  x3, #0x1A4\n", .{});
    try writer.print("    MOV  x8, #56\n", .{});
    try writer.print("    SVC  #0\n\n", .{});
    try writer.print("    MOV  x1, x21\n", .{});
    try writer.print("    MOV  x2, #{d}\n", .{buf_size});
    try writer.print("    MOV  x8, #64\n", .{});
    try writer.print("    SVC  #0\n\n", .{});
    try writer.print("    MOV  x8, #93\n", .{});
    try writer.print("    MOV  x0, #0\n", .{});
    try writer.print("    SVC  #0\n", .{});
}
