const std = @import("std");

const GeneratorState = @import("state.zig").GeneratorState;
const Emitter = @import("emitter.zig").Emitter;
const CovPoint = @import("cov_point.zig").CovPoint;
const prologue = @import("prologue.zig");

const MovImmEmitter = @import("emitters/mov_imm.zig").MovImmEmitter;
const AluRegRegEmitter = @import("emitters/alu_reg_reg.zig").AluRegRegEmitter;
const LdrRegEmitter = @import("emitters/ldr_reg.zig").LdrRegEmitter;
const StrRegEmitter = @import("emitters/str_reg.zig").StrRegEmitter;
const LoadUseEmitter = @import("emitters/load_use.zig").LoadUseEmitter;
const ForwardingAluEmitter = @import("emitters/forwarding_alu.zig").ForwardingAluEmitter;
const StoreToLoadEmitter = @import("emitters/store_to_load.zig").StoreToLoadEmitter;
const BranchSkipEmitter  = @import("emitters/branch_skip.zig").BranchSkipEmitter;
const CacheLineSplitEmitter = @import("emitters/cache_line_split.zig").CacheLineSplitEmitter;

const num_dump_regs:   u8  = 10;
const bootstrap_count: u32 = 10;

const Strategy = enum {
    random,
    forwarding_stress,
    load_use_stress,
    store_to_load_forwarding,
    branch_dense,
    cache_line_split,
};

const Config = struct {
    seed:     u64        = 0,
    count:    u32        = 20,
    strategy: Strategy   = .random,
    out_path: []const u8 = "",
};

fn parseArgs(args: []const []const u8) !Config {
    var cfg = Config{};
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--seed") and i + 1 < args.len) {
            i += 1;
            cfg.seed = try std.fmt.parseInt(u64, args[i], 0);
        } else if (std.mem.eql(u8, arg, "--count") and i + 1 < args.len) {
            i += 1;
            cfg.count = try std.fmt.parseInt(u32, args[i], 10);
        } else if (std.mem.eql(u8, arg, "--out") and i + 1 < args.len) {
            i += 1;
            cfg.out_path = args[i];
        } else if (std.mem.eql(u8, arg, "--strategy") and i + 1 < args.len) {
            i += 1;
            cfg.strategy = std.meta.stringToEnum(Strategy, args[i]) orelse {
                std.debug.print("Unknown strategy: {s}\n", .{args[i]});
                return error.UnknownStrategy;
            };
        } else {
            std.debug.print("Unknown argument: {s}\n", .{arg});
            return error.UnknownArgument;
        }
    }
    if (cfg.out_path.len == 0) return error.MissingOutPath;
    return cfg;
}

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io  = init.io;

    const args = try init.minimal.args.toSlice(init.arena.allocator());

    const cfg = parseArgs(args) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        std.debug.print("Usage: stim_gen --out <path.S> [--seed N] [--count N] [--strategy <name>]\n", .{});
        std.debug.print("Strategies: random forwarding_stress load_use_stress store_to_load_forwarding branch_dense cache_line_split\n", .{});
        std.process.exit(1);
    };

    var seed = cfg.seed;
    if (seed == 0) {
        var seed_bytes: [8]u8 = undefined;
        io.random(&seed_bytes);
        seed = std.mem.readInt(u64, &seed_bytes, .little);
        std.debug.print("Generated seed: 0x{X:0>16}\n", .{seed});
    }

    const dirname = std.Io.Dir.path.dirname(cfg.out_path) orelse ".";
    try std.Io.Dir.cwd().createDirPath(io, dirname);

    const sig_path = try std.fmt.allocPrint(gpa, "{s}/signature.bin", .{dirname});
    defer gpa.free(sig_path);

    var out_file = try std.Io.Dir.cwd().createFile(io, cfg.out_path, .{});
    defer out_file.close(io);

    var write_buf: [4096]u8 = undefined;
    var writer = out_file.writer(io, &write_buf);
    const w = &writer.interface;

    var state = GeneratorState.init(gpa, seed);
    defer state.deinit();

    var e_mov_imm_a = MovImmEmitter { .allocator = gpa };
    var e_alu_reg_reg = AluRegRegEmitter { .allocator = gpa };
    var e_ldr_reg = LdrRegEmitter { .allocator = gpa };
    var e_str_reg = StrRegEmitter { .allocator = gpa };
    var e_load_use_a = LoadUseEmitter { .allocator = gpa };
    var e_load_use_b = LoadUseEmitter { .allocator = gpa };
    var e_forwarding_a = ForwardingAluEmitter { .allocator = gpa };
    var e_forwarding_b = ForwardingAluEmitter { .allocator = gpa };
    var e_forwarding_c = ForwardingAluEmitter { .allocator = gpa };
    var e_store_to_load_a = StoreToLoadEmitter { .allocator = gpa };
    var e_store_to_load_b = StoreToLoadEmitter { .allocator = gpa };
    var e_branch_skip_a = BranchSkipEmitter { .allocator = gpa };
    var e_branch_skip_b = BranchSkipEmitter { .allocator = gpa };
    var e_branch_skip_c = BranchSkipEmitter { .allocator = gpa };
    var e_cache_split_a = CacheLineSplitEmitter { .allocator = gpa };
    var e_cache_split_b = CacheLineSplitEmitter { .allocator = gpa };
    var e_cache_split_c = CacheLineSplitEmitter { .allocator = gpa };
    var e_bootstrap = MovImmEmitter { .allocator = gpa };

    var pool: [4]Emitter = switch (cfg.strategy) {
        .random => .{
            e_mov_imm_a.emitter(),
            e_alu_reg_reg.emitter(),
            e_ldr_reg.emitter(),
            e_str_reg.emitter(),
        },
        .forwarding_stress => .{
            e_forwarding_a.emitter(),
            e_forwarding_b.emitter(),
            e_forwarding_c.emitter(),
            e_mov_imm_a.emitter(),
        },
        .load_use_stress => .{
            e_load_use_a.emitter(),
            e_load_use_b.emitter(),
            e_str_reg.emitter(),
            e_mov_imm_a.emitter(),
        },
        .store_to_load_forwarding => .{
            e_store_to_load_a.emitter(),
            e_store_to_load_b.emitter(),
            e_mov_imm_a.emitter(),
            e_alu_reg_reg.emitter(),
        },
        .branch_dense => .{
            e_branch_skip_a.emitter(),
            e_branch_skip_b.emitter(),
            e_branch_skip_c.emitter(),
            e_mov_imm_a.emitter(),
        },
        .cache_line_split => .{
            e_cache_split_a.emitter(),
            e_cache_split_b.emitter(),
            e_cache_split_c.emitter(),
            e_mov_imm_a.emitter(),
        },
    };
    var bootstrap_em = e_bootstrap.emitter();

    try prologue.emitPrologue(w, &state, num_dump_regs, sig_path);

    for (0..bootstrap_count) |_| {
        if (bootstrap_em.tryEmit(&state)) |line| {
            defer gpa.free(line);
            try w.print("{s}\n", .{line});
        }
    }
    try w.print("\n", .{});

    for (0..cfg.count) |_| {
        state.getRng().shuffle(Emitter, &pool);
        var emitted = false;
        for (&pool) |*em| {
            if (em.tryEmit(&state)) |line| {
                defer gpa.free(line);
                try w.print("{s}\n", .{line});
                emitted = true;
                break;
            }
        }
        if (!emitted) {
            if (bootstrap_em.tryEmit(&state)) |line| {
                defer gpa.free(line);
                try w.print("{s}\n", .{line});
            }
        }
    }

    try prologue.emitEpilogue(w, num_dump_regs);
    try writer.flush();

    var stdout_buf: [2048]u8 = undefined;
    var out = std.Io.File.stdout().writer(io, &stdout_buf);
    const o = &out.interface;
    try o.print("Generator: {s}\n", .{cfg.out_path});
    try o.print("Signature: {s}\n", .{sig_path});
    try o.print("Seed:      0x{X:0>16}\n", .{seed});
    try o.print("Count:     {d}\n", .{cfg.count});
    try o.print("Coverage:", .{});
    var cov_iter = state.getCoverageHits().iterator();
    while (cov_iter.next()) |p| {
        try o.print(" {s}", .{p.name()});
    }
    try o.print("\n", .{});
    try out.flush();
}
