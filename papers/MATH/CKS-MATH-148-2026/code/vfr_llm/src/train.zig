const std = @import("std");
const lib = @import("lib.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 4) {
        std.debug.print("Usage: {s} <tokens_file> <vocab_file> <weights_out> [epochs]\n", .{args[0]});
        return;
    }

    const tokens_path = args[1];
    const vocab_path = args[2];
    const weights_path = args[3];

    const num_epochs: u32 = if (args.len > 4)
        std.fmt.parseInt(u32, args[4], 10) catch 10
    else
        10;

    // load tokens
    const tokens = try lib.read_tokens(tokens_path, allocator);
    defer allocator.free(tokens);
    std.debug.print("Loaded {d} tokens from {s}\n", .{ tokens.len, tokens_path });

    // load vocab to verify size
    var tokenizer = try lib.Tokenizer.load(allocator, vocab_path);
    defer tokenizer.deinit();
    std.debug.print("Vocab size: {d}\n", .{tokenizer.vocab_size()});

    // check vocab fits our model
    if (tokenizer.vocab_size() > lib.VOCAB_SIZE) {
        std.debug.print("WARNING: vocab ({d}) > model VOCAB_SIZE ({d}), tokens above {d} will be clamped\n", .{
            tokenizer.vocab_size(), lib.VOCAB_SIZE, lib.VOCAB_SIZE,
        });
    }

    // initialize model
    var model = try lib.Model.init(allocator);
    defer model.deinit();

    const param_count = model.param_count();
    std.debug.print("Model parameters: {d} ({d:.1} MB at 6 bytes each)\n", .{
        param_count,
        @as(f32, @floatFromInt(param_count * 6)) / (1024.0 * 1024.0),
    });

    // initialize weights with random integers
    lib.init_model_weights(&model, 42);
    std.debug.print("Weights initialized (seed=42)\n", .{});

    // training config
    const lr_shift: u5 = 4; // learning rate = gradient >> 4
    const log_interval: u32 = 100;

    std.debug.print("\nTraining config:\n", .{});
    std.debug.print("  Epochs: {d}\n", .{num_epochs});
    std.debug.print("  Tokens: {d}\n", .{tokens.len});
    std.debug.print("  LR shift: {d} (effective: gradient / {d})\n", .{ lr_shift, @as(u32, 1) << lr_shift });
    std.debug.print("  Shell threshold: {d}\n", .{lib.SHELL_THRESHOLD});
    std.debug.print("  Log every: {d} steps\n", .{log_interval});

    std.debug.print("\n----------------------------------------------------\n", .{});
    std.debug.print("TRAINING\n", .{});
    std.debug.print("----------------------------------------------------\n\n", .{});

    // training loop
    var global_step: u64 = 0;
    const total_transitions: u64 = 0;

    for (0..num_epochs) |epoch| {
        var epoch_loss: i64 = 0;
        var epoch_steps: u32 = 0;
        var interval_loss: i64 = 0;
        var interval_steps: u32 = 0;

        // iterate through token pairs (input, target)
        if (tokens.len < 2) {
            std.debug.print("Not enough tokens to train\n", .{});
            return;
        }

        for (0..tokens.len - 1) |i| {
            var input_token = tokens[i];
            var target_token = tokens[i + 1];

            // clamp to vocab size
            if (input_token >= lib.VOCAB_SIZE) input_token = lib.SPECIAL_UNK;
            if (target_token >= lib.VOCAB_SIZE) target_token = lib.SPECIAL_UNK;

            // count transitions before
            const transitions_before: u64 = 0;
            _ = transitions_before;

            // forward + backward + update
            const loss = try lib.backward_and_update(
                &model,
                input_token,
                target_token,
                lr_shift,
                allocator,
            );

            epoch_loss += @as(i64, loss);
            epoch_steps += 1;
            interval_loss += @as(i64, loss);
            interval_steps += 1;
            global_step += 1;

            // log at intervals
            if (interval_steps >= log_interval) {
                const avg_loss = @divTrunc(interval_loss, @as(i64, interval_steps));

                // count shell pressure stats
                var max_r: i16 = 0;
                var sum_abs_r: i64 = 0;
                var weight_count: u64 = 0;
                // sample from output proj (representative)
                for (model.output_proj.weights) |w| {
                    const abs_r = if (w.r < 0) -w.r else w.r;
                    if (abs_r > max_r) max_r = abs_r;
                    sum_abs_r += @as(i64, abs_r);
                    weight_count += 1;
                }
                const mean_r = if (weight_count > 0) @divTrunc(sum_abs_r, @as(i64, @intCast(weight_count))) else 0;

                std.debug.print("  Epoch {d:>3} Step {d:>8} | Loss: {d:>6} | Max|R|: {d:>3} | Mean|R|: {d:>3}\n", .{
                    epoch, global_step, avg_loss, max_r, mean_r,
                });

                interval_loss = 0;
                interval_steps = 0;
            }
        }

        const avg_epoch_loss = if (epoch_steps > 0) @divTrunc(epoch_loss, @as(i64, epoch_steps)) else 0;
        std.debug.print("\n  -- Epoch {d} complete | Avg loss: {d} | Steps: {d} --\n\n", .{
            epoch, avg_epoch_loss, epoch_steps,
        });
    }

    _ = total_transitions;

    // save weights
    try lib.save_weights(weights_path, &model);
    std.debug.print("----------------------------------------------------\n", .{});
    std.debug.print("Saved weights to {s}\n", .{weights_path});
    std.debug.print("Total training steps: {d}\n", .{global_step});

    // print final weight statistics
    var final_max_r: i16 = 0;
    var final_max_v: i32 = 0;
    for (model.output_proj.weights) |w| {
        const abs_r = if (w.r < 0) -w.r else w.r;
        const abs_v = if (w.v < 0) -w.v else w.v;
        if (abs_r > final_max_r) final_max_r = abs_r;
        if (abs_v > final_max_v) final_max_v = abs_v;
    }
    std.debug.print("Output proj stats: max|V|={d}, max|R|={d}\n", .{ final_max_v, final_max_r });
}
