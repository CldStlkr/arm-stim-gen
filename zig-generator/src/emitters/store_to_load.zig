const std = @import("std");
const Emitter = @import("../emitter.zig").Emitter;
const GeneratorState = @import("../state.zig").GeneratorState;

pub const StoreToLoadEmitter = struct {
    allocator: std.mem.Allocator,

    pub fn emitter(self: *StoreToLoadEmitter) Emitter {
        return .{ .ptr = self, .vtable = &.{ .try_emit = tryEmit } };
    }


  fn tryEmit(ptr: *anyopaque, state: *GeneratorState) ?[]u8 {
      const self: *StoreToLoadEmitter = @ptrCast(@alignCast(ptr));
      const scratch_id = state.getScratchRegionId() orelse return null;
      const scratch = state.getRegion(scratch_id);
      if (scratch.watermark >= scratch.size) return null;
      const src    = state.pickInitializedGpr() orelse return null;
      const dst    = state.pickWritableGpr()    orelse return null;
      const offset = scratch.watermark;
      state.hitCoverage(.StoreToLoadFwd);
      state.advanceWatermark(scratch_id, 8);
      state.markScalar(dst);
      return std.fmt.allocPrint(self.allocator,
          "  STR x{d}, [x22, #{d}]\n  LDR x{d}, [x22, #{d}]",
          .{ src, offset, dst, offset },
      ) catch null;
  }
};
