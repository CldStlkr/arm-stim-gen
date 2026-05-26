const std = @import("std");
const Emitter = @import("../emitter.zig").Emitter;
const GeneratorState = @import("../state.zig").GeneratorState;

pub const LdrRegEmitter = struct {
    allocator: std.mem.Allocator,

    pub fn emitter(self: *LdrRegEmitter) Emitter {
        return .{ .ptr = self, .vtable = &.{ .try_emit = tryEmit } };
    }

    fn tryEmit(ptr: *anyopaque, state: *GeneratorState) ?[]u8 {
        const self: *LdrRegEmitter = @ptrCast(@alignCast(ptr));
        const scratch_id = state.getScratchRegionId() orelse return null;
        const scratch = state.getRegion(scratch_id);
        if (scratch.watermark < 8) return null;
        const dst    = state.pickWritableGpr() orelse return null;
        const offset = state.getRng().uintLessThan(u64, scratch.watermark / 8) * 8;
        state.markScalar(dst);
        return std.fmt.allocPrint(self.allocator, "  LDR x{d}, [x22, #{d}]", .{ dst, offset }) catch null;
    }
};
