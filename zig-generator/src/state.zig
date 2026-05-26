const std = @import("std");
const CovPoint = @import("cov_point.zig").CovPoint;

pub const RegionId = u32;

pub const RegKind = enum(u8) {
    Uninitialized,
    Scalar,
    Pointer,
    Reserved
};

pub const RegInfo = struct {
    kind: RegKind = .Uninitialized,
    region: ?RegionId = null,
    offset: u64 = 0,
};

pub const MemRegion = struct {
    id: RegionId,
    size: u64,
    base_reg: u8,
    watermark: u64,
    label: []const u8,
};

pub const GeneratorState = struct {
    pub const num_gprs:    u8 = 31;
    pub const scratch_reg: u8 = 20;
    pub const sig_pointer: u8 = 21;
    pub const scratch_pointer: u8 = 22;

    allocator: std.mem.Allocator,
    seed: u64,
    rng: std.Random.DefaultPrng,
    regions: std.ArrayList(MemRegion),
    regs: [num_gprs]RegInfo,
    last_written: ?u8,
    scratch_region_id: ?RegionId,
    label_counter: u32,
    coverage_hits: std.EnumSet(CovPoint),

    pub fn init(allocator: std.mem.Allocator, seed: u64) GeneratorState {
        var state = GeneratorState {
            .allocator = allocator,
            .seed = seed,
            .rng = std.Random.DefaultPrng.init(seed),
            .regions = .empty,
            .regs = undefined,
            .last_written = null,
            .scratch_region_id = null,
            .label_counter = 0,
            .coverage_hits = .{},
        };

        for (&state.regs) |*reg| reg.* = .{};
        state.regs[scratch_reg].kind = .Reserved;
        state.regs[sig_pointer].kind = .Reserved;
        state.regs[scratch_pointer].kind = .Reserved;
        return state;
    }


    pub fn deinit(self: *GeneratorState) void { self.regions.deinit(self.allocator); }

    pub fn getRng(self: *GeneratorState) std.Random { return self.rng.random(); }
    pub fn getSeed(self: *const GeneratorState) u64 { return self.seed; }
    pub fn kindOf(self: *const GeneratorState, reg: u8) RegKind { return self.regs[reg].kind; }
    pub fn infoOf(self: *const GeneratorState, reg: u8) RegInfo { return self.regs[reg]; }

    pub fn pickInitializedGpr(self: *GeneratorState) ?u8 {
        var candidates: [num_gprs]u8 = undefined;
        var count: usize = 0;

        for (0..num_gprs) |i| {
            const k = self.regs[i].kind;
            if (k == .Scalar or k == .Pointer) {
                candidates[count] = @intCast(i);
                count += 1;
            }
        }
        if (count == 0) return null;

        return candidates[self.rng.random().uintLessThan(usize, count)];
    }

    pub fn pickWritableGpr(self: *GeneratorState) ?u8 {
        var candidates: [num_gprs]u8 = undefined;
        var count: usize = 0;

        for (0..num_gprs) |i| {
            const k = self.regs[i].kind;
            if (k != .Reserved) {
                candidates[count] = @intCast(i);
                count += 1;
            }
        }
        if (count == 0) return null;

        return candidates[self.rng.random().uintLessThan(usize, count)];
    }

    pub fn pickPointerGpr(self: *GeneratorState, min_headroom: u64) ?u8 {
        var candidates: [num_gprs]u8 = undefined;
        var count: usize = 0;

        for (0..num_gprs) |i| {
            const k = self.regs[i].kind;
            if (k != .Pointer) continue;
            const info = self.regs[i];
            const region_id = info.region orelse continue;
            const mem = self.regions.items[region_id];
            const remaining: u64 = mem.size - info.offset;
            if (remaining >= min_headroom) {
                candidates[count] = @intCast(i);
                count += 1;
            }
        }
        if (count == 0) return null;

        return candidates[self.rng.random().uintLessThan(usize, count)];
    }

    pub fn markScalar(self: *GeneratorState, reg: u8) void {
        self.regs[reg] = .{ .kind = .Scalar };
        self.last_written = reg;
    }
    pub fn markPointer(self: *GeneratorState, reg: u8, region: RegionId, offset: u64) void {
        self.regs[reg] = .{ .kind = .Pointer, .region = region, .offset = offset };
    }

    pub fn markReserved(self: *GeneratorState, reg: u8) void { self.regs[reg] = .{ .kind = .Reserved }; }
    pub fn markUninitialized(self: *GeneratorState, reg: u8) void { self.regs[reg] = .{ .kind = .Uninitialized }; }

    pub fn nextLabelId(self: *GeneratorState) u32 {
        defer self.label_counter += 1;
        return self.label_counter;
    }



    pub fn getRegion(self: *const GeneratorState, id: RegionId) MemRegion { return self.regions.items[id]; }
    pub fn addRegion(self: *GeneratorState, size: u64, base_reg: u8, label: []const u8) !RegionId {
        const id: RegionId = @intCast(self.regions.items.len);
        try self.regions.append(self.allocator, .{
            .id = id,
            .size = size,
            .base_reg = base_reg,
            .watermark = 0,
            .label = label,
        });

        return id;
    }

    pub fn advanceWatermark(self: *GeneratorState, id: RegionId, bytes: u64) void { self.regions.items[id].watermark += bytes; }

    pub fn getScratchRegionId(self: *const GeneratorState) ?RegionId { return self.scratch_region_id; }
    pub fn setScratchRegionId(self: *GeneratorState, id: RegionId) void { self.scratch_region_id = id; }

    pub fn getLastWrittenReg(self: *const GeneratorState) ?u8 { return self.last_written; }

    pub fn hitCoverage(self: *GeneratorState, p: CovPoint) void { self.coverage_hits.insert(p); }
    pub fn getCoverageHits(self: *const GeneratorState) std.EnumSet(CovPoint) { return self.coverage_hits; }

};
