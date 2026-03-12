const std = @import("std");
const lib = @import("lib.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 4) {
        std.debug.print("Usage: {s} <weights_file> <vocab_file> \"<prompt>\" [max_tokens]\n", .{args[0]});
        return;
    }

    const weights_path = args[1];
    const vocab_path = args[2];
    const prompt = args[3];
    const max_tokens: u32 = if (args.len > 4)
        std.fmt.parseInt(u32, args[4], 10) catch 100
    else
        100;

    // load model
    var model = try lib.Model.init(allocator);
    defer model.deinit();
    try lib.load_weights(weights_path, &model);
    std.debug.print("Loaded weights from {s}\n", .{weights_path});

    // load tokenizer
    var tokenizer = try lib.Tokenizer.load(allocator, vocab_path);
    defer tokenizer.deinit();
    std.debug.print("Loaded vocab ({d} tokens) from {s}\n", .{ tokenizer.vocab_size(), vocab_path });

    // tokenize prompt
    const prompt_tokens = try tokenizer.encode(prompt, allocator);
    defer allocator.free(prompt_tokens);
    std.debug.print("Prompt: \"{s}\" → {d} tokens\n", .{ prompt, prompt_tokens.len });

    std.debug.print("\n----------------------------------------------------\nGENERATED OUTPUT:\n----------------------------------------------------\n", .{});

    // print the prompt first
    std.debug.print("{s}", .{prompt});

    // generate tokens autoregressively
    // start from the last prompt token
    var current_token: u16 = if (prompt_tokens.len > 0)
        prompt_tokens[prompt_tokens.len - 1]
    else
        lib.SPECIAL_BOS;

    for (0..max_tokens) |_| {
        // clamp token
        if (current_token >= lib.VOCAB_SIZE) current_token = lib.SPECIAL_UNK;

        // forward pass: get logits for next token
        const logits = try lib.forward(&model, current_token, allocator);
        defer allocator.free(logits);

        // greedy: argmax
        const next_token: u16 = @intCast(lib.argmax(logits));

        // stop on EOS
        if (next_token == lib.SPECIAL_EOS) break;

        // decode and print this token
        const token_slice = &[_]u16{next_token};
        const decoded: []u8 = try tokenizer.decode(token_slice, allocator);
        defer allocator.free(decoded);

        if (decoded.len > 0) {
            std.debug.print("{s}", .{decoded});
        }

        current_token = next_token;
    }

    std.debug.print("\n----------------------------------------------------\n", .{});
    std.debug.print("Generation complete.\n", .{});
}
