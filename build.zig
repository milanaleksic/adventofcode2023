const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "adventofcode2023",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run unit tests");

    var dir = try std.fs.cwd().openIterableDir("src", .{});
    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        const ext = std.fs.path.extension(entry.basename);
        const include_file = std.mem.startsWith(u8, entry.path, "day") and
            std.mem.endsWith(u8, ext, ".zig");

        if (include_file) {
            const run_unit_tests = b.addRunArtifact(b.addTest(.{
                .name = entry.path,
                .root_source_file = .{ .path = b.pathJoin(&.{ "src", entry.path }) },
                .target = target,
                .optimize = optimize,
            }));
            test_step.dependOn(&run_unit_tests.step);
        }
    }
}
