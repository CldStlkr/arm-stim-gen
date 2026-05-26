const std = @import("std");
const Emitter = @import("../emitter.zig").Emitter;
const GeneratorState = @import("../state.zig").GeneratorState;

pub const CacheLineSplitEmitter = struct {
    allocator: std.mem.Allocator,

    pub fn emitter(self: *CacheLineSplitEmitter) Emitter {
        return .{ .ptr = self, .vtable = &.{ .try_emit = tryEmit } };
    }


  fn tryEmit(ptr: *anyopaque, state: *GeneratorState) ?[]u8 {
      const self: *CacheLineSplitEmitter = @ptrCast(@alignCast(ptr));
      const src = state.pickInitializedGpr() orelse return null;
      const dst = state.pickWritableGpr()    orelse return null;
      state.hitCoverage(.CacheLineSplit);
      state.markScalar(dst);
      return std.fmt.allocPrint(self.allocator,
          "  STR x{d}, [x22, #60]\n  LDR x{d}, [x22, #60]",
          .{ src, dst },
      ) catch null;
  }
};
