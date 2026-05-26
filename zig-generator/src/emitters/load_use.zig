const std = @import("std");
const Emitter = @import("../emitter.zig").Emitter;
const GeneratorState = @import("../state.zig").GeneratorState;

pub const LoadUseEmitter = struct {
    allocator: std.mem.Allocator,

    pub fn emitter(self: *LoadUseEmitter) Emitter {
        return .{ .ptr = self, .vtable = &.{ .try_emit = tryEmit } };
    }

    fn tryEmit(ptr: *anyopaque, state: *GeneratorState) ?[]u8 {
        const self: *LoadUseEmitter = @ptrCast(@alignCast(ptr));
        const scratch_id = state.getScratchRegionId() orelse return null;
        const scratch = state.getRegion(scratch_id);
        if (scratch.watermark < 8) return null;
        const ldr_dst    = state.pickWritableGpr()    orelse return null;
        const load_offset = state.getRng().uintLessThan(u64, scratch.watermark / 8) * 8;
        const src2       = state.pickInitializedGpr() orelse return null;
        const alu_dst    = state.pickWritableGpr()    orelse return null;
        const ops = [_][]const u8{ "ADD", "SUB", "AND", "ORR" };
        const op = ops[state.getRng().uintLessThan(usize, ops.len)];
        state.hitCoverage(.LoadUseHazard);
        state.markScalar(ldr_dst);
        state.markScalar(alu_dst);
        return std.fmt.allocPrint(self.allocator,
            "  LDR x{d}, [x22, #{d}]\n  {s} x{d}, x{d}, x{d}",
            .{ ldr_dst, load_offset, op, alu_dst, ldr_dst, src2 },
        ) catch null;
    }
};
