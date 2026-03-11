const std = @import("std");
const lib = @import("lib.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 4) {
        std.debug.print("Usage: {s} <input_file> <tokens_out> <vocab_out>\n", .{args[0]});
        return;
    }

    const input_path = args[1];
    const tokens_path = args[2];
    const vocab_path = args[3];

    // read input file
    const input_file = try std.fs.cwd().openFile(input_path, .{});
    defer input_file.close();
    const input_data = try input_file.readToEndAlloc(allocator, 100 * 1024 * 1024); // 100MB max
    defer allocator.free(input_data);

    std.debug.print("Read {d} bytes from {s}\n", .{ input_data.len, input_path });

    // initialize tokenizer with byte-level vocab + special tokens
    var tokenizer = lib.Tokenizer.init(allocator);
    defer tokenizer.deinit();

    // special tokens: PAD, BOS, EOS, UNK
    const special_names = [_][]const u8{ "<PAD>", "<BOS>", "<EOS>", "<UNK>" };
    for (special_names) |name| {
        const entry = try allocator.alloc(u8, name.len);
        @memcpy(entry, name);
        try tokenizer.vocab.append(entry);
    }

    // byte-level tokens (256 entries)
    for (0..256) |byte_val| {
        const entry = try allocator.alloc(u8, 1);
        entry[0] = @intCast(byte_val);
        try tokenizer.vocab.append(entry);
    }

    std.debug.print("Initial vocab: {d} (4 special + 256 bytes)\n", .{tokenizer.vocab_size()});

    // convert input to initial token sequence (byte-level)
    var tokens = std.array_list.Managed(u16).init(allocator);
    defer tokens.deinit();
    for (input_data) |byte| {
        try tokens.append(@as(u16, lib.NUM_SPECIAL) + @as(u16, byte));
    }

    // BPE training loop
    const target_vocab = lib.VOCAB_SIZE;
    var merge_count: u32 = 0;

    while (tokenizer.vocab_size() < target_vocab) {
        // count all adjacent pairs
        // use a flat array as hash map: pair → count
        // key = a * 65536 + b (fits in u32 since tokens are u16)
        var pair_counts = std.AutoHashMap(u32, u32).init(allocator);
        defer pair_counts.deinit();

        var best_pair: u32 = 0;
        var best_count: u32 = 0;

        if (tokens.items.len < 2) break;

        for (0..tokens.items.len - 1) |i| {
            const pair_key = @as(u32, tokens.items[i]) * 65536 + @as(u32, tokens.items[i + 1]);
            const entry = try pair_counts.getOrPut(pair_key);
            if (!entry.found_existing) {
                entry.value_ptr.* = 0;
            }
            entry.value_ptr.* += 1;
            if (entry.value_ptr.* > best_count) {
                best_count = entry.value_ptr.*;
                best_pair = pair_key;
            }
        }

        if (best_count < 2) break; // no more useful merges

        const a: u16 = @intCast(best_pair / 65536);
        const b: u16 = @intCast(best_pair % 65536);
        const new_id: u16 = @intCast(tokenizer.vocab_size());

        // create merged vocab entry
        const entry_a = tokenizer.vocab.items[a];
        const entry_b = tokenizer.vocab.items[b];
        const merged = try allocator.alloc(u8, entry_a.len + entry_b.len);
        @memcpy(merged[0..entry_a.len], entry_a);
        @memcpy(merged[entry_a.len..], entry_b);
        try tokenizer.vocab.append(merged);

        // record merge
        try tokenizer.merges.append(.{ .a = a, .b = b, .result = new_id });

        // apply merge to token sequence
        var i: usize = 0;
        while (i + 1 < tokens.items.len) {
            if (tokens.items[i] == a and tokens.items[i + 1] == b) {
                tokens.items[i] = new_id;
                _ = tokens.orderedRemove(i + 1);
            } else {
                i += 1;
            }
        }

        merge_count += 1;
        if (merge_count % 50 == 0) {
            std.debug.print("  Merge {d}: vocab={d}, tokens={d}, best_count={d}\n", .{
                merge_count, tokenizer.vocab_size(), tokens.items.len, best_count,
            });
        }
    }

    std.debug.print("\nBPE complete: {d} merges, vocab size {d}\n", .{ merge_count, tokenizer.vocab_size() });
    std.debug.print("Token sequence: {d} bytes → {d} tokens (compression: {d:.1}×)\n", .{
        input_data.len,
        tokens.items.len,
        @as(f32, @floatFromInt(input_data.len)) / @as(f32, @floatFromInt(@max(tokens.items.len, 1))),
    });

    // save tokens
    try lib.write_tokens(tokens_path, tokens.items);
    std.debug.print("Saved tokens to {s}\n", .{tokens_path});

    // save vocab
    try tokenizer.save(vocab_path);
    std.debug.print("Saved vocab to {s}\n", .{vocab_path});
}
