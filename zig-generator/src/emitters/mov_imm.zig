const std = @import("std");
const Emitter = @import("../emitter.zig").Emitter;
const GeneratorState = @import("../state.zig").GeneratorState;

pub const MovImmEmitter = struct {
    allocator: std.mem.Allocator,

    pub fn emitter(self: *MovImmEmitter) Emitter {
        return .{
            .ptr = self,
            .vtable = &.{ .try_emit = tryEmit, },
        };
    }

    fn tryEmit(ptr: *anyopaque, state: *GeneratorState) ?[]u8 {
        const self: *MovImmEmitter = @ptrCast(@alignCast(ptr));
        const dst = state.pickWritableGpr() orelse return null;
        const imm = state.getRng().uintAtMost(u32, 0xFFFF);
        state.markScalar(dst);

        return std.fmt.allocPrint(self.allocator, "  MOV x{d}, #0x{X:0>4}", .{dst, imm}) catch null;
    }
};
