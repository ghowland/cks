const std = @import("std");
const lib = @import("lib.zig");

const TestCase = struct {
    prompt: []const u8,
    should_contain: []const u8, // substring the output should contain (empty = just check compile)
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        const stderr = std.io.getStdErr().writer();
        try stderr.print("Usage: {s} <weights_file> <vocab_file> [test_file]\n", .{args[0]});
        return;
    }

    const weights_path = args[1];
    const vocab_path = args[2];

    const stdout = std.io.getStdOut().writer();

    // load model
    var model = try lib.Model.init(allocator);
    defer model.deinit();
    try lib.load_weights(weights_path, &model);
    try stdout.print("Loaded weights from {s}\n", .{weights_path});

    // load tokenizer
    var tokenizer = try lib.Tokenizer.load(allocator, vocab_path);
    defer tokenizer.deinit();
    try stdout.print("Loaded vocab ({d} tokens)\n", .{tokenizer.vocab_size()});

    // built-in test prompts (simple zig snippets to complete)
    const builtin_tests = [_]TestCase{
        .{ .prompt = "const std = @import(\"std\");", .should_contain = "" },
        .{ .prompt = "pub fn main()", .should_contain = "" },
        .{ .prompt = "var x: i32 = ", .should_contain = "" },
        .{ .prompt = "const allocator = std.", .should_contain = "" },
        .{ .prompt = "fn add(a: i32, b: i32)", .should_contain = "" },
    };

    // if test file provided, load it; otherwise use built-in tests
    const test_cases: []const TestCase = &builtin_tests;
    _ = test_cases;

    try stdout.print("\n{'─' ** 60}\n", .{});
    try stdout.print("EVALUATION\n", .{});
    try stdout.print("{'─' ** 60}\n\n", .{});

    var total: u32 = 0;
    var generated: u32 = 0;
    var compile_pass: u32 = 0;

    for (builtin_tests) |test_case| {
        total += 1;
        try stdout.print("Test {d}: \"{s}\"\n", .{ total, test_case.prompt });

        // tokenize prompt
        const prompt_tokens = try tokenizer.encode(test_case.prompt, allocator);
        defer allocator.free(prompt_tokens);

        // generate continuation
        var output = std.ArrayList(u8).init(allocator);
        defer output.deinit();

        try output.appendSlice(test_case.prompt);

        var current_token: u16 = if (prompt_tokens.len > 0)
            prompt_tokens[prompt_tokens.len - 1]
        else
            lib.SPECIAL_BOS;

        const max_gen: u32 = 200;
        for (0..max_gen) |_| {
            if (current_token >= lib.VOCAB_SIZE) current_token = lib.SPECIAL_UNK;

            const logits = try lib.forward(&model, current_token, allocator);
            defer allocator.free(logits);

            const next_token: u16 = @intCast(lib.argmax(logits));
            if (next_token == lib.SPECIAL_EOS) break;

            const token_slice = &[_]u16{next_token};
            const decoded = try tokenizer.decode(token_slice, allocator);
            defer allocator.free(decoded);

            if (decoded.len > 0) {
                try output.appendSlice(decoded);
            }

            current_token = next_token;
        }

        generated += 1;

        // show generated code (truncated)
        const gen_text = output.items;
        const show_len = @min(gen_text.len, 200);
        try stdout.print("  Generated ({d} bytes): {s}", .{ gen_text.len, gen_text[0..show_len] });
        if (gen_text.len > 200) try stdout.print("...", .{});
        try stdout.print("\n", .{});

        // try to compile the generated code
        // write to temp file
        const tmp_path = "data/eval_tmp.zig";
        {
            const tmp_file = try std.fs.cwd().createFile(tmp_path, .{});
            defer tmp_file.close();
            try tmp_file.writeAll(gen_text);
        }

        // attempt compilation
        const compile_result = std.process.Child.run(.{
            .allocator = allocator,
            .argv = &[_][]const u8{ "zig", "ast-check", tmp_path },
        }) catch |err| {
            try stdout.print("  Compile: SKIP (zig not found: {s})\n\n", .{@errorName(err)});
            continue;
        };
        defer allocator.free(compile_result.stdout);
        defer allocator.free(compile_result.stderr);

        if (compile_result.term.Exited == 0) {
            compile_pass += 1;
            try stdout.print("  Syntax: PASS ✓\n", .{});
        } else {
            try stdout.print("  Syntax: FAIL ✗\n", .{});
            // show first line of error
            if (compile_result.stderr.len > 0) {
                const first_line_end = std.mem.indexOf(u8, compile_result.stderr, "\n") orelse compile_result.stderr.len;
                const show_err = @min(first_line_end, 120);
                try stdout.print("  Error: {s}\n", .{compile_result.stderr[0..show_err]});
            }
        }

        try stdout.print("\n", .{});
    }

    // cleanup temp file
    std.fs.cwd().deleteFile("data/eval_tmp.zig") catch {};

    try stdout.print("{'─' ** 60}\n", .{});
    try stdout.print("RESULTS\n", .{});
    try stdout.print("{'─' ** 60}\n", .{});
    try stdout.print("  Total tests:    {d}\n", .{total});
    try stdout.print("  Generated:      {d}\n", .{generated});
    try stdout.print("  Syntax pass:    {d}/{d} ({d:.0}%)\n", .{
        compile_pass,
        total,
        if (total > 0) @as(f32, @floatFromInt(compile_pass)) / @as(f32, @floatFromInt(total)) * 100.0 else 0.0,
    });
    try stdout.print("\n  (Expected: 0% for toy model — the harness works)\n", .{});
}
