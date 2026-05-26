const std = @import("std");
const GeneratorState = @import("state.zig").GeneratorState;

pub const Emitter = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        try_emit: *const fn(ptr: *anyopaque, state: *GeneratorState) ?[]u8,
    };

    pub fn tryEmit(self: Emitter, state: *GeneratorState) ?[]u8 {
        return self.vtable.try_emit(self.ptr, state);
    }
};
