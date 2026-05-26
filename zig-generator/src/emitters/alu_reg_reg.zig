const std = @import("std");
const Emitter = @import("../emitter.zig").Emitter;
const GeneratorState = @import("../state.zig").GeneratorState;

pub const AluRegRegEmitter = struct {
    allocator: std.mem.Allocator,

    pub fn emitter(self: *AluRegRegEmitter) Emitter {
        return .{ .ptr = self, .vtable = &.{ .try_emit = tryEmit } };
    }

    fn tryEmit(ptr: *anyopaque, state: *GeneratorState) ?[]u8 {
        const self: *AluRegRegEmitter = @ptrCast(@alignCast(ptr));
        const src1 = state.pickInitializedGpr() orelse return null;
        const src2 = state.pickInitializedGpr() orelse return null;
        const dst  = state.pickWritableGpr()     orelse return null;
        const ops = [_][]const u8{ "ADD", "SUB", "AND", "ORR", "EOR", "MUL" };
        const op = ops[state.getRng().uintLessThan(usize, ops.len)];
        state.markScalar(dst);
        return std.fmt.allocPrint(self.allocator, "  {s} x{d}, x{d}, x{d}", .{ op, dst, src1, src2 }) catch null;
    }
};
