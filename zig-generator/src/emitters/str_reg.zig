const std = @import("std");
const Emitter = @import("../emitter.zig").Emitter;
const GeneratorState = @import("../state.zig").GeneratorState;
pub const StrRegEmitter = struct {
    allocator: std.mem.Allocator,

    pub fn emitter(self: *StrRegEmitter) Emitter {
        return .{ .ptr = self, .vtable = &.{ .try_emit = tryEmit } };
    }

    fn tryEmit(ptr: *anyopaque, state: *GeneratorState) ?[]u8 {
        const self: *StrRegEmitter = @ptrCast(@alignCast(ptr));
        const scratch_id = state.getScratchRegionId() orelse return null;
        const scratch = state.getRegion(scratch_id);
        if (scratch.watermark >= scratch.size) return null;
        const src    = state.pickInitializedGpr() orelse return null;
        const offset = scratch.watermark;
        state.advanceWatermark(scratch_id, 8);
        return std.fmt.allocPrint(self.allocator, "  STR x{d}, [x22, #{d}]", .{ src, offset }) catch null;
    }
};
