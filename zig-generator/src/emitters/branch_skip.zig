const std = @import("std");
const Emitter = @import("../emitter.zig").Emitter;
const GeneratorState = @import("../state.zig").GeneratorState;

pub const BranchSkipEmitter = struct {
    allocator: std.mem.Allocator,

    pub fn emitter(self: *BranchSkipEmitter) Emitter {
        return .{ .ptr = self, .vtable = &.{ .try_emit = tryEmit } };
    }


  fn tryEmit(ptr: *anyopaque, state: *GeneratorState) ?[]u8 {
      const self: *BranchSkipEmitter = @ptrCast(@alignCast(ptr));
      const src = state.pickInitializedGpr() orelse return null;
      const ops = [_][]const u8{ "CBZ", "CBNZ" };
      const op  = ops[state.getRng().uintLessThan(usize, ops.len)];
      const n   = state.nextLabelId();
      state.hitCoverage(.BranchDense);
      return std.fmt.allocPrint(self.allocator,
          "  {s} x{d}, .Lskip_{d}\n  NOP\n.Lskip_{d}:",
          .{ op, src, n, n },
      ) catch null;
  }
};
