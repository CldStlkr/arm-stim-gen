const std = @import("std");

pub const CovPoint = enum(u8) {
    RawChain,
    LoadUseHazard,
    StoreToLoadFwd,
    BranchDense,
    CacheLineSplit,

    pub fn name(self: CovPoint) []const u8 {
        return switch (self) {
            .RawChain => "RawChain",
            .LoadUseHazard => "LoadUseHazard",
            .StoreToLoadFwd => "StoreToLoadFwd",
            .BranchDense => "BranchDense",
            .CacheLineSplit => "CacheLineSplit",
        };
    }
};
