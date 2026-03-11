const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // shared library module
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ── tokenize ──
    const tokenize = b.addExecutable(.{
        .name = "zig-tokenize",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tokenize.zig"),
            .target = target,
            .optimize = optimize,
            // .strip = false,
        }),
    });
    tokenize.root_module.addImport("lib", lib_mod);
    b.installArtifact(tokenize);

    const run_tokenize = b.addRunArtifact(tokenize);
    if (b.args) |args| run_tokenize.addArgs(args);
    const tokenize_step = b.step("tokenize", "Run tokenizer");
    tokenize_step.dependOn(&run_tokenize.step);

    // ── train ──
    const train = b.addExecutable(.{
        .name = "zig-train",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/train.zig"),
            .target = target,
            .optimize = optimize,
            // .strip = false,
        }),
    });
    train.root_module.addImport("lib", lib_mod);
    b.installArtifact(train);

    const run_train = b.addRunArtifact(train);
    if (b.args) |args| run_train.addArgs(args);
    const train_step = b.step("train", "Run training");
    train_step.dependOn(&run_train.step);

    // ── infer ──
    const infer = b.addExecutable(.{
        .name = "zig-infer",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/infer.zig"),
            .target = target,
            .optimize = optimize,
            // .strip = false,
        }),
    });
    infer.root_module.addImport("lib", lib_mod);
    b.installArtifact(infer);

    const run_infer = b.addRunArtifact(infer);
    if (b.args) |args| run_infer.addArgs(args);
    const infer_step = b.step("infer", "Run inference");
    infer_step.dependOn(&run_infer.step);

    // ── eval ──
    const eval_exe = b.addExecutable(.{
        .name = "zig-eval",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/eval.zig"),
            .target = target,
            .optimize = optimize,
            // .strip = false,
        }),
    });
    eval_exe.root_module.addImport("lib", lib_mod);
    b.installArtifact(eval_exe);

    const run_eval = b.addRunArtifact(eval_exe);
    if (b.args) |args| run_eval.addArgs(args);
    const eval_step = b.step("eval", "Run evaluation");
    eval_step.dependOn(&run_eval.step);
}
