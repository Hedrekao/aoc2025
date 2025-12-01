const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const picked_day = b.option(usize, "day", "The day to build (1-25)") orelse 0;

    const utils = b.addModule("utils", .{
        .root_source_file = b.path("src/utils.zig"),
        .target = target,
    });

    if (picked_day != 0) {
        const day_module_name = b.fmt("day{d}", .{picked_day});
        const day_source_file = b.path(b.fmt("src/day{d}.zig", .{picked_day}));

        const day_module = b.addModule(day_module_name, .{
            .root_source_file = day_source_file,
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "utils", .module = utils },
            },
        });

        const day_exe = b.addExecutable(.{
            .name = day_module_name,
            .root_module = day_module,
        });

        b.installArtifact(day_exe);

        const run_day_step = b.step("run", "Run the selected day");

        const run_day_cmd = b.addRunArtifact(day_exe);
        run_day_step.dependOn(&run_day_cmd.step);

        run_day_cmd.step.dependOn(b.getInstallStep());

        const day_args = [_][]u8{day_module_name};
        run_day_cmd.addArgs(&day_args);
        if (b.args) |args| {
            run_day_cmd.addArgs(args);
        }

        return;
    }

}
