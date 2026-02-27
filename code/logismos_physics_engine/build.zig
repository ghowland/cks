const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .Debug,
    });

    const exe = b.addExecutable(.{
        .name = "logismos",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Allow turning off the console with: -Dsubsystem=Windows
    const subsystem = b.option(std.Target.SubSystem, "subsystem", "Set the subsystem (Console or Windows)") orelse .Console;
    exe.subsystem = subsystem;

    // 32MB Stack: Clay UIElement must be nested quite signifucantly, and JSON parsing is descent recursion.  32x from 1MB default.
    //TODO: AFter dr.Path Text -> []i32 may be able to remove this, as it's Text that blows everything out
    exe.stack_size = 64 * 1024 * 1024; // 64MB

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        // This is the specific flag that fixes your error:
        .linux_display_backend = .X11,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    // Run step
    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run src");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
