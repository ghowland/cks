const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "substrate_viewer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/kspace_substrate_viewer.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const subsystem = b.option(std.Target.SubSystem, "subsystem", "Set the subsystem") orelse .Console;
    exe.subsystem = subsystem;

    const raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = optimize,
    });

    // Get the compiled raylib artifact
    const raylib_artifact = raylib_dep.artifact("raylib");

    // Link it
    exe.linkLibrary(raylib_artifact);
    exe.linkLibC();

    // Add include path for C headers (for @cImport)
    exe.addIncludePath(raylib_dep.path("src"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the substrate viewer");
    run_step.dependOn(&run_cmd.step);
}
