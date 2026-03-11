const std = @import("std");
const Allocator = std.mem.Allocator;

// --- Constants ----------------------------------------------

pub const SHELL_THRESHOLD: i16 = 32;
pub const OCTAVE: u8 = 2;
pub const OCTAVE_SHIFT: u5 = 10; // 5 * OCTAVE
pub const VOCAB_SIZE: u32 = 4096; //512; // Needs to be large enough to take different tokens, upgrading from 512
pub const D_MODEL: u32 = 128;
pub const N_LAYERS: u32 = 4;
pub const N_HEADS: u32 = 4;
pub const D_HEAD: u32 = D_MODEL / N_HEADS; // 32
pub const D_FF: u32 = D_MODEL * 4; // 512
pub const MAX_SEQ_LEN: u32 = 256;
pub const SPECIAL_PAD: u16 = 0;
pub const SPECIAL_BOS: u16 = 1;
pub const SPECIAL_EOS: u16 = 2;
pub const SPECIAL_UNK: u16 = 3;
pub const NUM_SPECIAL: u16 = 4;

// --- VFR Weight ---------------------------------------------

pub const VFRWeight = packed struct {
    v: i32 = 0,
    r: i16 = 0,

    pub fn update(self: *VFRWeight, grad: i32, lr_shift: u5) void {
        // scale gradient by learning rate (bit shift = divide)
        const scaled: i32 = if (lr_shift >= 31) 0 else -(grad >> @intCast(lr_shift));
        // accumulate in remainder
        self.r +%= @as(i16, @truncate(std.math.clamp(scaled, -32000, 32000)));
        // shell transitions
        while (self.r >= SHELL_THRESHOLD) {
            self.v += 1;
            self.r -= SHELL_THRESHOLD;
        }
        while (self.r <= -SHELL_THRESHOLD) {
            self.v -= 1;
            self.r += SHELL_THRESHOLD;
        }
    }
};

// --- Integer Tensor -----------------------------------------

pub const IntTensor = struct {
    data: []i32,
    rows: u32,
    cols: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator, rows: u32, cols: u32) !IntTensor {
        const data = try allocator.alloc(i32, @as(usize, rows) * @as(usize, cols));
        @memset(data, 0);
        return .{
            .data = data,
            .rows = rows,
            .cols = cols,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *IntTensor) void {
        self.allocator.free(self.data);
    }

    pub fn at(self: *const IntTensor, row: u32, col: u32) i32 {
        return self.data[@as(usize, row) * @as(usize, self.cols) + @as(usize, col)];
    }

    pub fn set(self: *IntTensor, row: u32, col: u32, val: i32) void {
        self.data[@as(usize, row) * @as(usize, self.cols) + @as(usize, col)] = val;
    }

    pub fn fill(self: *IntTensor, val: i32) void {
        @memset(self.data, val);
    }

    // get a row as a slice
    pub fn row_slice(self: *const IntTensor, row: u32) []const i32 {
        const start = @as(usize, row) * @as(usize, self.cols);
        return self.data[start .. start + @as(usize, self.cols)];
    }

    pub fn row_slice_mut(self: *IntTensor, row: u32) []i32 {
        const start = @as(usize, row) * @as(usize, self.cols);
        return self.data[start .. start + @as(usize, self.cols)];
    }
};

// --- Weight Matrix ------------------------------------------

pub const WeightMatrix = struct {
    weights: []VFRWeight,
    rows: u32,
    cols: u32,
    allocator: Allocator,

    pub fn init(allocator: Allocator, rows: u32, cols: u32) !WeightMatrix {
        const n = @as(usize, rows) * @as(usize, cols);
        const weights = try allocator.alloc(VFRWeight, n);
        @memset(weights, VFRWeight{ .v = 0, .r = 0 });
        return .{
            .weights = weights,
            .rows = rows,
            .cols = cols,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *WeightMatrix) void {
        self.allocator.free(self.weights);
    }

    pub fn at(self: *const WeightMatrix, row: u32, col: u32) *const VFRWeight {
        return &self.weights[@as(usize, row) * @as(usize, self.cols) + @as(usize, col)];
    }

    pub fn at_mut(self: *WeightMatrix, row: u32, col: u32) *VFRWeight {
        return &self.weights[@as(usize, row) * @as(usize, self.cols) + @as(usize, col)];
    }

    pub fn get_v(self: *const WeightMatrix, row: u32, col: u32) i32 {
        return self.at(row, col).v;
    }
};

// --- Layer Norm (simplified) --------------------------------

pub const LayerNorm = struct {
    scale: []VFRWeight, // [D_MODEL]
    bias: []VFRWeight, // [D_MODEL]
    allocator: Allocator,

    pub fn init(allocator: Allocator, dim: u32) !LayerNorm {
        const scale = try allocator.alloc(VFRWeight, dim);
        const bias = try allocator.alloc(VFRWeight, dim);
        // init scale to 1 (at octave 2, "1.0" = 1024, but we keep it simple: scale=1 means passthrough)
        for (scale) |*s| s.v = 1;
        @memset(bias, VFRWeight{ .v = 0, .r = 0 });
        return .{ .scale = scale, .bias = bias, .allocator = allocator };
    }

    pub fn deinit(self: *LayerNorm) void {
        self.allocator.free(self.scale);
        self.allocator.free(self.bias);
    }
};

// --- Transformer Block --------------------------------------

pub const TransformerBlock = struct {
    wq: WeightMatrix,
    wk: WeightMatrix,
    wv: WeightMatrix,
    wo: WeightMatrix,
    w1: WeightMatrix,
    w2: WeightMatrix,
    norm1: LayerNorm,
    norm2: LayerNorm,

    pub fn init(allocator: Allocator) !TransformerBlock {
        return .{
            .wq = try WeightMatrix.init(allocator, D_MODEL, D_MODEL),
            .wk = try WeightMatrix.init(allocator, D_MODEL, D_MODEL),
            .wv = try WeightMatrix.init(allocator, D_MODEL, D_MODEL),
            .wo = try WeightMatrix.init(allocator, D_MODEL, D_MODEL),
            .w1 = try WeightMatrix.init(allocator, D_MODEL, D_FF),
            .w2 = try WeightMatrix.init(allocator, D_FF, D_MODEL),
            .norm1 = try LayerNorm.init(allocator, D_MODEL),
            .norm2 = try LayerNorm.init(allocator, D_MODEL),
        };
    }

    pub fn deinit(self: *TransformerBlock) void {
        self.wq.deinit();
        self.wk.deinit();
        self.wv.deinit();
        self.wo.deinit();
        self.w1.deinit();
        self.w2.deinit();
        self.norm1.deinit();
        self.norm2.deinit();
    }
};

// --- Full Model ---------------------------------------------

pub const Model = struct {
    embedding: WeightMatrix,
    layers: []TransformerBlock,
    output_proj: WeightMatrix,
    allocator: Allocator,

    pub fn init(allocator: Allocator) !Model {
        const layers = try allocator.alloc(TransformerBlock, N_LAYERS);
        for (layers) |*layer| {
            layer.* = try TransformerBlock.init(allocator);
        }
        const model = Model{
            .embedding = try WeightMatrix.init(allocator, VOCAB_SIZE, D_MODEL),
            .layers = layers,
            .output_proj = try WeightMatrix.init(allocator, D_MODEL, VOCAB_SIZE),
            .allocator = allocator,
        };
        return model;
    }

    pub fn deinit(self: *Model) void {
        self.embedding.deinit();
        for (self.layers) |*layer| layer.deinit();
        self.allocator.free(self.layers);
        self.output_proj.deinit();
    }

    pub fn param_count(self: *const Model) usize {
        var count: usize = self.embedding.weights.len + self.output_proj.weights.len;
        for (self.layers) |*layer| {
            count += layer.wq.weights.len;
            count += layer.wk.weights.len;
            count += layer.wv.weights.len;
            count += layer.wo.weights.len;
            count += layer.w1.weights.len;
            count += layer.w2.weights.len;
            count += layer.norm1.scale.len;
            count += layer.norm1.bias.len;
            count += layer.norm2.scale.len;
            count += layer.norm2.bias.len;
        }
        return count;
    }
};

// --- Integer Matmul -----------------------------------------

/// Multiply activation vector (1 × cols) by weight matrix (cols × out_cols)
/// Result goes into out (1 × out_cols)
/// Uses i64 accumulator, shifts by OCTAVE_SHIFT
pub fn matmul_vec_weight(input: []const i32, w: *const WeightMatrix, output: []i32) void {
    const rows = w.rows;
    const cols = w.cols;
    for (0..cols) |j| {
        var acc: i64 = 0;
        for (0..rows) |i| {
            const a: i64 = @intCast(input[i]);
            const b: i64 = @intCast(w.weights[i * cols + j].v);
            acc += a * b;
        }
        output[j] = @intCast(std.math.clamp(acc >> OCTAVE_SHIFT, -2147483647, 2147483647));
    }
}

/// Multiply two activation vectors: dot product
pub fn dot_product(a: []const i32, b: []const i32) i32 {
    var acc: i128 = 0;
    for (a, b) |av, bv| {
        acc += @as(i128, av) * @as(i128, bv);
    }
    const result = acc >> OCTAVE_SHIFT;
    if (result > 2147483647) return 2147483647;
    if (result < -2147483647) return -2147483647;
    return @intCast(result);
}

/// Element-wise addition of two vectors, result in out
pub fn vec_add(a: []const i32, b: []const i32, out: []i32) void {
    for (a, b, out) |av, bv, *ov| {
        ov.* = av + bv;
    }
}

/// Element-wise addition, in place: a += b
pub fn vec_add_inplace(a: []i32, b: []const i32) void {
    for (a, b) |*av, bv| {
        const value: i64 = @as(i64, av.*) + @as(i64, bv);
        av.* = @intCast(std.math.clamp(value, -2147483647, 2147483647));
    }
}

/// Scale a vector by a scalar (with octave shift)
pub fn vec_scale(v: []const i32, scalar: i32, out: []i32) void {
    for (v, out) |val, *o| {
        const prod: i64 = @as(i64, val) * @as(i64, scalar);
        o.* = @intCast(std.math.clamp(prod >> OCTAVE_SHIFT, -2147483647, 2147483647));
    }
}

/// ReLU in place
pub fn relu(v: []i32) void {
    for (v) |*val| {
        if (val.* < 0) val.* = 0;
    }
}

/// Copy slice
pub fn vec_copy(dst: []i32, src: []const i32) void {
    @memcpy(dst, src);
}

// --- Integer Softmax ----------------------------------------

/// Integer softmax approximation
/// Maps i32 logits to i32 probabilities that sum to 1024
/// Uses shift-based exp approximation: exp(x) ≈ max(0, 1024 + x)
/// This is crude but gets the pipeline flowing
pub fn softmax_int(logits: []const i32, probs: []i32) void {
    // find max for numerical stability
    var max_val: i32 = logits[0];
    for (logits[1..]) |v| {
        if (v > max_val) max_val = v;
    }

    // exp approximation: clamped linear
    var sum: i64 = 0;
    for (logits, probs) |v, *p| {
        // const shifted = v - max_val; // now in range [-inf, 0]
        const shifted: i32 = @intCast(std.math.clamp(@as(i64, v) - @as(i64, max_val), -2048, 0));

        // piecewise linear exp approximation in integer
        // exp(x) ≈ max(1, 1024 + shifted) for shifted in reasonable range
        const exp_val: i32 = @max(1, @as(i32, 1024) + shifted);
        p.* = exp_val;
        sum += @as(i64, exp_val);
    }

    // normalize so sum = 1024
    if (sum > 0) {
        for (probs) |*p| {
            const a: i64 = (@as(i64, p.*) * 1024);
            const b: i64 = @divTrunc(a, sum);
            p.* = @intCast(b);
        }
    }
}

/// Argmax over i32 slice
pub fn argmax(values: []const i32) u32 {
    var best_idx: u32 = 0;
    var best_val: i32 = values[0];
    for (values[1..], 1..) |v, i| {
        if (v > best_val) {
            best_val = v;
            best_idx = @intCast(i);
        }
    }
    return best_idx;
}

// --- Cross-Entropy Gradient ---------------------------------

/// Compute gradient of cross-entropy loss w.r.t. logits
/// grad[i] = probs[i] - (1024 if i == target, else 0)
/// This is the standard softmax-CE gradient, in integer
pub fn ce_gradient(probs: []const i32, target: u16, grad: []i32) void {
    for (probs, grad, 0..) |p, *g, i| {
        if (i == target) {
            g.* = p - 1024; // prob - 1.0 (in our 1024 scale)
        } else {
            g.* = p;
        }
    }
}

/// Integer log loss: -log(prob[target])
/// Approximation: loss = 1024 - prob[target]
/// (crude but monotonic — lower prob = higher loss)
pub fn log_loss_int(probs: []const i32, target: u16) i32 {
    return 1024 - probs[@as(usize, target)];
}

// --- Weight Initialization ----------------------------------

pub const Xorshift = struct {
    state: u64,

    pub fn init(seed: u64) Xorshift {
        return .{ .state = if (seed == 0) 0xDEADBEEF else seed };
    }

    pub fn next(self: *Xorshift) u64 {
        var x = self.state;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.state = x;
        return x;
    }

    /// Random i32 in range [-range, +range]
    pub fn rand_i32(self: *Xorshift, range: i32) i32 {
        const val = self.next();
        const urange: u64 = @intCast(@as(i64, range) * 2 + 1);
        return @as(i32, @intCast(val % urange)) - range;
    }
};

pub fn init_weight_matrix(w: *WeightMatrix, rng: *Xorshift, range: i32) void {
    for (w.weights) |*weight| {
        weight.v = rng.rand_i32(range);
        weight.r = 0;
    }
}

pub fn init_model_weights(model: *Model, seed: u64) void {
    var rng = Xorshift.init(seed);
    // embedding: small values
    init_weight_matrix(&model.embedding, &rng, 32);
    // layers
    for (model.layers) |*layer| {
        init_weight_matrix(&layer.wq, &rng, 16);
        init_weight_matrix(&layer.wk, &rng, 16);
        init_weight_matrix(&layer.wv, &rng, 16);
        init_weight_matrix(&layer.wo, &rng, 16);
        init_weight_matrix(&layer.w1, &rng, 16);
        init_weight_matrix(&layer.w2, &rng, 16);
        // norms already initialized (scale=1, bias=0)
    }
    // output projection
    init_weight_matrix(&model.output_proj, &rng, 32);
}

// --- Checkpoint I/O -----------------------------------------

pub fn save_weights(path: []const u8, model: *const Model) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    var buf: [4096]u8 = undefined;
    var fw = file.writer(&buf);
    var writer: *std.Io.Writer = &fw.interface;

    // write embedding
    try writer.writeAll(std.mem.sliceAsBytes(model.embedding.weights));
    // write layers
    for (model.layers) |*layer| {
        try writer.writeAll(std.mem.sliceAsBytes(layer.wq.weights));
        try writer.writeAll(std.mem.sliceAsBytes(layer.wk.weights));
        try writer.writeAll(std.mem.sliceAsBytes(layer.wv.weights));
        try writer.writeAll(std.mem.sliceAsBytes(layer.wo.weights));
        try writer.writeAll(std.mem.sliceAsBytes(layer.w1.weights));
        try writer.writeAll(std.mem.sliceAsBytes(layer.w2.weights));
        try writer.writeAll(std.mem.sliceAsBytes(layer.norm1.scale));
        try writer.writeAll(std.mem.sliceAsBytes(layer.norm1.bias));
        try writer.writeAll(std.mem.sliceAsBytes(layer.norm2.scale));
        try writer.writeAll(std.mem.sliceAsBytes(layer.norm2.bias));
    }
    // write output proj
    try writer.writeAll(std.mem.sliceAsBytes(model.output_proj.weights));

    try writer.flush(); // MUST flush
}

pub fn load_weights(path: []const u8, model: *Model) !void {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buf: [4096]u8 = undefined;
    var reader = file.reader(&buf);
    // const reader = file.reader();

    // read embedding
    const embed_bytes = std.mem.sliceAsBytes(model.embedding.weights);
    const embed_read = try reader.read(embed_bytes);
    _ = embed_read;
    // read layers
    for (model.layers) |*layer| {
        _ = try reader.read(std.mem.sliceAsBytes(layer.wq.weights));
        _ = try reader.read(std.mem.sliceAsBytes(layer.wk.weights));
        _ = try reader.read(std.mem.sliceAsBytes(layer.wv.weights));
        _ = try reader.read(std.mem.sliceAsBytes(layer.wo.weights));
        _ = try reader.read(std.mem.sliceAsBytes(layer.w1.weights));
        _ = try reader.read(std.mem.sliceAsBytes(layer.w2.weights));
        _ = try reader.read(std.mem.sliceAsBytes(layer.norm1.scale));
        _ = try reader.read(std.mem.sliceAsBytes(layer.norm1.bias));
        _ = try reader.read(std.mem.sliceAsBytes(layer.norm2.scale));
        _ = try reader.read(std.mem.sliceAsBytes(layer.norm2.bias));
    }
    // read output proj
    _ = try reader.read(std.mem.sliceAsBytes(model.output_proj.weights));
}

// --- Tokenizer Types ----------------------------------------

pub const BPEMerge = struct {
    a: u16,
    b: u16,
    result: u16,
};

pub const Tokenizer = struct {
    vocab: std.array_list.Managed([]u8), // token id → byte sequence
    merges: std.array_list.Managed(BPEMerge),
    allocator: Allocator,

    pub fn init(allocator: Allocator) Tokenizer {
        return .{
            .vocab = std.array_list.Managed([]u8).init(allocator),
            .merges = std.array_list.Managed(BPEMerge).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Tokenizer) void {
        for (self.vocab.items) |item| self.allocator.free(item);
        self.vocab.deinit();
        self.merges.deinit();
    }

    pub fn vocab_size(self: *const Tokenizer) u32 {
        return @intCast(self.vocab.items.len);
    }

    pub fn load(allocator: Allocator, path: []const u8) !Tokenizer {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var tok = Tokenizer.init(allocator);
        errdefer tok.deinit();

        // read vocab size
        var vs_bytes: [4]u8 = undefined;
        _ = try file.readAll(&vs_bytes);
        const vs = std.mem.bytesToValue(u32, &vs_bytes);

        // read vocab entries
        for (0..vs) |_| {
            var len_bytes: [2]u8 = undefined;
            _ = try file.readAll(&len_bytes);
            const len = std.mem.bytesToValue(u16, &len_bytes);
            const entry = try allocator.alloc(u8, len);
            errdefer allocator.free(entry);
            _ = try file.readAll(entry);
            try tok.vocab.append(entry);
        }

        // read merge count
        var mc_bytes: [4]u8 = undefined;
        _ = try file.readAll(&mc_bytes);
        const mc = std.mem.bytesToValue(u32, &mc_bytes);

        // read merges
        for (0..mc) |_| {
            var merge_bytes: [@sizeOf(BPEMerge)]u8 = undefined;
            _ = try file.readAll(&merge_bytes);
            const merge = std.mem.bytesToValue(BPEMerge, &merge_bytes);
            try tok.merges.append(merge);
        }

        return tok;
    }

    pub fn save(self: *const Tokenizer, path: []const u8) !void {
        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();

        // write vocab size
        const vs: u32 = @intCast(self.vocab.items.len);
        try file.writeAll(std.mem.asBytes(&vs));

        // write each vocab entry: length (u16) + bytes
        for (self.vocab.items) |entry| {
            const len: u16 = @intCast(entry.len);
            try file.writeAll(std.mem.asBytes(&len));
            try file.writeAll(entry);
        }

        // write merge count
        const mc: u32 = @intCast(self.merges.items.len);
        try file.writeAll(std.mem.asBytes(&mc));

        // write merges
        for (self.merges.items) |merge| {
            try file.writeAll(std.mem.asBytes(&merge));
        }
    }

    /// Encode text to token ids using trained merges
    pub fn encode(self: *const Tokenizer, text: []const u8, allocator: Allocator) ![]u16 {
        // start with byte-level tokens
        var tokens = std.array_list.Managed(u16).init(allocator);
        for (text) |byte| {
            try tokens.append(@as(u16, NUM_SPECIAL) + @as(u16, byte));
        }

        // apply merges in order
        for (self.merges.items) |merge| {
            var i: usize = 0;
            while (i + 1 < tokens.items.len) {
                if (tokens.items[i] == merge.a and tokens.items[i + 1] == merge.b) {
                    tokens.items[i] = merge.result;
                    _ = tokens.orderedRemove(i + 1);
                    // don't increment i — check for another merge at same position
                } else {
                    i += 1;
                }
            }
        }

        return tokens.toOwnedSlice();
    }

    /// Decode token ids back to text
    pub fn decode(self: *const Tokenizer, tokens: []const u16, allocator: Allocator) ![]u8 {
        var result = std.array_list.Managed(u8).init(allocator);
        for (tokens) |token| {
            if (token < self.vocab.items.len) {
                try result.appendSlice(self.vocab.items[token]);
            }
        }
        return result.toOwnedSlice();
    }
};

// --- Token File I/O -----------------------------------------

pub fn write_tokens(path: []const u8, tokens: []const u16) !void {
    const count: u32 = @intCast(tokens.len);

    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();
    var write_buf: [4096]u8 = undefined;
    var fw = file.writer(&write_buf);
    const writer: *std.Io.Writer = &fw.interface;
    try writer.writeAll(std.mem.asBytes(&count));
    try writer.writeAll(std.mem.sliceAsBytes(tokens));
    try writer.flush();
}

// pub fn read_tokens(path: []const u8, allocator: Allocator) ![]u16 {
//     const file = try std.fs.cwd().openFile(path, .{});
//     defer file.close();
//     // const reader = file.reader();
//     var buf: [4096]u8 = undefined;
//     var reader = file.reader(&buf);
//     var count: u32 = undefined;
//     _ = try reader.read(std.mem.asBytes(&count));
//     const tokens = try allocator.alloc(u16, count);
//     _ = try reader.read(std.mem.sliceAsBytes(tokens));
//     return tokens;
// }

pub fn read_tokens(path: []const u8, allocator: Allocator) ![]u16 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    // read count (first 4 bytes)
    var count_bytes: [4]u8 = undefined;
    _ = try file.readAll(&count_bytes);
    const count = std.mem.bytesToValue(u32, &count_bytes);

    // allocate token buffer
    const tokens = try allocator.alloc(u16, count);
    errdefer allocator.free(tokens);

    // read token data
    _ = try file.readAll(std.mem.sliceAsBytes(tokens));

    return tokens;
}

// --- Forward Pass -------------------------------------------

/// Run one token through the model, return logits
/// This is the simplified v1 forward: single-token context (bigram)
pub fn forward(model: *const Model, token: u16, allocator: Allocator) ![]i32 {
    const d = D_MODEL;
    const vs = VOCAB_SIZE;

    // embedding lookup
    var x = try allocator.alloc(i32, d);
    defer allocator.free(x);
    for (0..d) |i| {
        x[i] = model.embedding.get_v(@intCast(token), @intCast(i));
    }

    // temp buffers
    const q = try allocator.alloc(i32, d);
    defer allocator.free(q);
    const k = try allocator.alloc(i32, d);
    defer allocator.free(k);
    const v = try allocator.alloc(i32, d);
    defer allocator.free(v);
    const attn_out = try allocator.alloc(i32, d);
    defer allocator.free(attn_out);
    const ff_hidden = try allocator.alloc(i32, D_FF);
    defer allocator.free(ff_hidden);
    const ff_out = try allocator.alloc(i32, d);
    defer allocator.free(ff_out);
    const proj_out = try allocator.alloc(i32, d);
    defer allocator.free(proj_out);

    // run through layers
    for (model.layers) |*layer| {
        // attention (simplified: single token, self-attention collapses to transform)
        matmul_vec_weight(x, &layer.wq, q);
        matmul_vec_weight(x, &layer.wk, k);
        matmul_vec_weight(x, &layer.wv, v);

        // score = dot(q, k) >> shift (scalar attention for single token)
        const score = dot_product(q, k);

        // attn_output = v scaled by score, projected through wo
        vec_scale(v, score, attn_out);
        matmul_vec_weight(attn_out, &layer.wo, proj_out);

        // residual
        vec_add_inplace(x, proj_out);

        // feedforward
        matmul_vec_weight(x, &layer.w1, ff_hidden);
        relu(ff_hidden);
        matmul_vec_weight(ff_hidden, &layer.w2, ff_out);

        // residual
        vec_add_inplace(x, ff_out);
    }

    // output projection: x → logits
    const logits = try allocator.alloc(i32, vs);
    matmul_vec_weight(x, &model.output_proj, logits);

    return logits;
}

// --- Backward Pass (simplified v1) --------------------------

/// Backward pass for one token. Returns gradients for all weights.
/// This is simplified: computes output gradient and propagates back.
/// For v1, we use a numerical-style approach per weight:
/// accumulate the gradient signal through the chain rule in integers.
///
/// The full chain rule backward is complex to write out for all layers,
/// so v1 uses a simpler approach: compute the loss gradient at the output,
/// then propagate it back through each layer using transposed matmuls.
pub fn backward_and_update(
    model: *Model,
    token: u16,
    target: u16,
    lr_shift: u5,
    allocator: Allocator,
) !i32 {
    const d = D_MODEL;
    const vs = VOCAB_SIZE;

    // -- Forward pass (saving activations) --
    // We need intermediate values for the backward pass

    // embedding
    var x_embed = try allocator.alloc(i32, d);
    defer allocator.free(x_embed);
    for (0..d) |i| {
        x_embed[i] = model.embedding.get_v(@intCast(token), @intCast(i));
    }

    // we'll store x at each layer boundary for gradient computation
    var layer_inputs = try allocator.alloc([]i32, N_LAYERS + 1);
    defer {
        for (layer_inputs) |li| allocator.free(li);
        allocator.free(layer_inputs);
    }
    layer_inputs[0] = try allocator.alloc(i32, d);
    vec_copy(layer_inputs[0], x_embed);

    // temp buffers for forward
    const q_buf = try allocator.alloc(i32, d);
    defer allocator.free(q_buf);
    const k_buf = try allocator.alloc(i32, d);
    defer allocator.free(k_buf);
    const v_buf = try allocator.alloc(i32, d);
    defer allocator.free(v_buf);
    const attn_buf = try allocator.alloc(i32, d);
    defer allocator.free(attn_buf);
    const proj_buf = try allocator.alloc(i32, d);
    defer allocator.free(proj_buf);
    const ff_pre = try allocator.alloc(i32, D_FF);
    defer allocator.free(ff_pre);
    const ff_post = try allocator.alloc(i32, D_FF);
    defer allocator.free(ff_post);
    const ff_out_buf = try allocator.alloc(i32, d);
    defer allocator.free(ff_out_buf);

    const x = try allocator.alloc(i32, d);
    defer allocator.free(x);
    vec_copy(x, x_embed);

    // store ff_pre activations per layer (for relu gradient)
    var ff_pre_acts = try allocator.alloc([]i32, N_LAYERS);
    defer {
        for (ff_pre_acts) |a| allocator.free(a);
        allocator.free(ff_pre_acts);
    }

    // store v_buf per layer (for attention gradient)
    var v_acts = try allocator.alloc([]i32, N_LAYERS);
    defer {
        for (v_acts) |a| allocator.free(a);
        allocator.free(v_acts);
    }

    var attn_scores = try allocator.alloc(i32, N_LAYERS);
    defer allocator.free(attn_scores);

    for (model.layers, 0..) |*layer, li| {
        matmul_vec_weight(x, &layer.wq, q_buf);
        matmul_vec_weight(x, &layer.wk, k_buf);
        matmul_vec_weight(x, &layer.wv, v_buf);

        const score = dot_product(q_buf, k_buf);
        attn_scores[li] = score;

        // save v for backward
        v_acts[li] = try allocator.alloc(i32, d);
        vec_copy(v_acts[li], v_buf);

        vec_scale(v_buf, score, attn_buf);
        matmul_vec_weight(attn_buf, &layer.wo, proj_buf);
        vec_add_inplace(x, proj_buf);

        // feedforward
        matmul_vec_weight(x, &layer.w1, ff_pre);

        // save pre-relu for backward
        ff_pre_acts[li] = try allocator.alloc(i32, D_FF);
        vec_copy(ff_pre_acts[li], ff_pre);

        vec_copy(ff_post, ff_pre);
        relu(ff_post);
        matmul_vec_weight(ff_post, &layer.w2, ff_out_buf);
        vec_add_inplace(x, ff_out_buf);

        // save layer output
        layer_inputs[li + 1] = try allocator.alloc(i32, d);
        vec_copy(layer_inputs[li + 1], x);
    }

    // -- Output logits + loss --
    const logits = try allocator.alloc(i32, vs);
    defer allocator.free(logits);
    matmul_vec_weight(x, &model.output_proj, logits);

    const probs = try allocator.alloc(i32, vs);
    defer allocator.free(probs);
    softmax_int(logits, probs);

    const loss = log_loss_int(probs, target);

    // -- Backward --

    // gradient of loss w.r.t. logits
    const d_logits = try allocator.alloc(i32, vs);
    defer allocator.free(d_logits);
    ce_gradient(probs, target, d_logits);

    // -- Update output projection --
    // d_output_proj[i][j] = x[i] * d_logits[j]
    // d_x from output = d_logits * output_proj^T
    var d_x = try allocator.alloc(i32, d);
    defer allocator.free(d_x);
    @memset(d_x, 0);

    for (0..d) |i| {
        for (0..vs) |j| {
            // gradient for weight
            const grad: i64 = @as(i64, x[i]) * @as(i64, d_logits[j]);
            const grad_i32: i32 = @intCast(grad >> OCTAVE_SHIFT);
            model.output_proj.at_mut(@intCast(i), @intCast(j)).update(grad_i32, lr_shift);

            // propagate gradient back to x
            const w_val: i64 = @intCast(model.output_proj.get_v(@intCast(i), @intCast(j)));
            d_x[i] = @intCast(@as(i64, d_x[i]) + (w_val * @as(i64, d_logits[j]) >> OCTAVE_SHIFT));
        }
    }

    // -- Backward through layers (reverse order) --
    const d_ff_out = try allocator.alloc(i32, d);
    defer allocator.free(d_ff_out);
    const d_ff_post = try allocator.alloc(i32, D_FF);
    defer allocator.free(d_ff_post);
    const d_ff_pre_buf = try allocator.alloc(i32, D_FF);
    defer allocator.free(d_ff_pre_buf);
    const d_attn_out = try allocator.alloc(i32, d);
    defer allocator.free(d_attn_out);
    const d_proj = try allocator.alloc(i32, d);
    defer allocator.free(d_proj);

    var li: usize = N_LAYERS;
    while (li > 0) {
        li -= 1;
        const layer = &model.layers[li];
        const layer_in = layer_inputs[li];

        // d_x is the gradient flowing back. residual means it passes through.

        // -- Feedforward backward --
        // d_ff_out = d_x (from residual)
        vec_copy(d_ff_out, d_x);

        // backward through w2: d_ff_post = d_ff_out × w2^T
        @memset(d_ff_post, 0);
        for (0..D_FF) |i| {
            for (0..d) |j| {
                const w_val: i64 = @intCast(layer.w2.get_v(@intCast(i), @intCast(j)));
                const out: i64 = @intCast(@as(i64, d_ff_post[i]) + (w_val * @as(i64, d_ff_out[j]) >> OCTAVE_SHIFT));
                d_ff_post[i] = @intCast(std.math.clamp(out, -2147483647, 2147483647));
            }
        }

        // update w2: grad = ff_post × d_ff_out^T
        // ff_post = relu(ff_pre)
        vec_copy(d_ff_pre_buf, ff_pre_acts[li]);
        relu(d_ff_pre_buf); // this gives us ff_post again
        for (0..D_FF) |i| {
            for (0..d) |j| {
                const grad: i64 = @as(i64, d_ff_pre_buf[i]) * @as(i64, d_ff_out[j]);
                const grad_i32: i32 = @intCast(std.math.clamp(grad >> OCTAVE_SHIFT, -2147483647, 2147483647));
                layer.w2.at_mut(@intCast(i), @intCast(j)).update(grad_i32, lr_shift);
            }
        }

        // relu gradient: zero where ff_pre was <= 0
        for (d_ff_post, ff_pre_acts[li]) |*dp, pre| {
            if (pre <= 0) dp.* = 0;
        }

        // backward through w1: d_x_ff = d_ff_pre × w1^T
        // also update w1
        for (0..d) |i| {
            var acc: i64 = 0;
            for (0..D_FF) |j| {
                // update w1
                const grad: i64 = @as(i64, layer_in[i]) * @as(i64, d_ff_post[j]);
                const grad_i32: i32 = @intCast(std.math.clamp(grad >> OCTAVE_SHIFT, -2147483647, 2147483647));

                layer.w1.at_mut(@intCast(i), @intCast(j)).update(grad_i32, lr_shift);

                // propagate
                const w_val: i64 = @intCast(layer.w1.get_v(@intCast(i), @intCast(j)));
                acc += w_val * @as(i64, d_ff_post[j]) >> OCTAVE_SHIFT;
            }
            d_x[i] = @intCast(std.math.clamp(acc, -2147483647, 2147483647));
        }

        // -- Attention backward (simplified) --
        // The attention was: proj = wo(score * v), residual add
        // gradient flows through residual, so d_x already has it

        // For v1 simplified: update wo, wv, wq, wk with approximate gradients
        // using the saved activations. This is rough but gets shell dynamics going.

        // update wo: grad = attn_out × d_x^T (approx: use score * v as attn_out)
        for (0..d) |i| {
            const v_scaled: i64 = @intCast(std.math.clamp(@as(i64, v_acts[li][i]) * @as(i64, attn_scores[li]) >> OCTAVE_SHIFT, -2147483647, 2147483647));

            for (0..d) |j| {
                const grad: i64 = v_scaled * @as(i64, d_x[j]) >> OCTAVE_SHIFT;
                const grad_i32: i32 = @intCast(std.math.clamp(grad, -100000, 100000));
                layer.wo.at_mut(@intCast(i), @intCast(j)).update(grad_i32, lr_shift);
            }
        }

        // update wv, wq, wk with simpler gradient signal
        // (proportional to d_x scaled by layer input)
        for (0..d) |i| {
            for (0..d) |j| {
                // const grad: i64 = @as(i64, layer_in[i]) * @as(i64, d_x[j]) >> OCTAVE_SHIFT;
                const grad: i64 = @intCast(std.math.clamp((@as(i128, layer_in[i]) * @as(i128, d_x[j])) >> OCTAVE_SHIFT, -2147483647, 2147483647));

                const grad_i32: i32 = @intCast(std.math.clamp(grad, -100000, 100000));
                layer.wv.at_mut(@intCast(i), @intCast(j)).update(grad_i32, lr_shift);
                layer.wq.at_mut(@intCast(i), @intCast(j)).update(grad_i32, lr_shift + 1);
                layer.wk.at_mut(@intCast(i), @intCast(j)).update(grad_i32, lr_shift + 1);
            }
        }

        // update embedding for this token
        for (0..d) |i| {
            model.embedding.at_mut(@intCast(token), @intCast(i)).update(d_x[i], lr_shift);
        }
    }

    return loss;
}
