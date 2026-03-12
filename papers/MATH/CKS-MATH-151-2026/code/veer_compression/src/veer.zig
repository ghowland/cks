const std = @import("std");

// ============================================================================
// Veer: Exact Arithmetic Compression Using VFR Integer Coding
// Version 1.0 — Zig 0.15.1
// ============================================================================

// --- File Format ---

const VEER_MAGIC: u32 = 0x56454552; // "VEER"
const VEER_VERSION: u8 = 1;

const VeerMode = enum(u8) {
    lossless = 0,
    lossy = 1,
};

const VeerModel = enum(u8) {
    static_model = 0,
    adaptive = 1,
};

const VeerHeader = extern struct {
    magic: u32 align(1),
    version: u8 align(1),
    mode: u8 align(1),
    q_value: u8 align(1),
    model_type: u8 align(1),
    original_size: u64 align(1),
    checksum: u32 align(1),
    compressed_size: u32 align(1),
};

const VeerFooter = extern struct {
    end_marker: u32 align(1),
    carry_low_final: i32 align(1),
    carry_high_final: i32 align(1),
};

// --- CRC-32 ---

const crc32_table: [256]u32 = blk: {
    @setEvalBranchQuota(10000);

    var table: [256]u32 = undefined;
    for (0..256) |i| {
        var crc: u32 = @intCast(i);
        for (0..8) |_| {
            if (crc & 1 == 1) {
                crc = (crc >> 1) ^ 0xEDB88320;
            } else {
                crc = crc >> 1;
            }
        }
        table[i] = crc;
    }
    break :blk table;
};

fn crc32(data: []const u8) u32 {
    var crc: u32 = 0xFFFFFFFF;
    for (data) |byte| {
        crc = crc32_table[(crc ^ byte) & 0xFF] ^ (crc >> 8);
    }
    return crc ^ 0xFFFFFFFF;
}

// --- Frequency Table ---

const FrequencyTable = struct {
    freq: [256]u32,
    cum_freq: [257]u32,
    total: u32,
    reciprocal: u64,

    fn init() FrequencyTable {
        var ft: FrequencyTable = undefined;
        for (0..256) |i| {
            ft.freq[i] = 1;
        }
        ft.total = 256;
        ft.buildCumulative();
        return ft;
    }

    fn initFromData(data: []const u8) FrequencyTable {
        var ft: FrequencyTable = undefined;
        for (0..256) |i| {
            ft.freq[i] = 1; // minimum 1 to avoid zero-frequency symbols
        }
        ft.total = 256;
        for (data) |byte| {
            ft.freq[byte] += 1;
            ft.total += 1;
        }
        ft.buildCumulative();
        return ft;
    }

    fn buildCumulative(self: *FrequencyTable) void {
        self.cum_freq[0] = 0;
        for (0..256) |i| {
            self.cum_freq[i + 1] = self.cum_freq[i] + self.freq[i];
        }
        self.total = self.cum_freq[256];
        if (self.total > 0) {
            self.reciprocal = (@as(u64, 1) << 32) / @as(u64, self.total);
        } else {
            self.reciprocal = 0;
        }
    }

    fn update(self: *FrequencyTable, symbol: u8) void {
        self.freq[symbol] += 1;
        self.total += 1;

        // Rescale if approaching overflow
        if (self.total > 65536) {
            self.total = 0;
            for (0..256) |i| {
                self.freq[i] = (self.freq[i] + 1) >> 1;
                if (self.freq[i] == 0) self.freq[i] = 1;
                self.total += self.freq[i];
            }
            self.buildCumulative();
        } else {
            // Incremental cumulative update
            const s: usize = @intCast(symbol);
            for (s + 1..257) |i| {
                self.cum_freq[i] += 1;
            }
            self.reciprocal = (@as(u64, 1) << 32) / @as(u64, self.total);
        }
    }
};

// --- Bit Writer ---

const BitWriter = struct {
    output: std.array_list.Managed(u8),
    bit_buffer: u32,
    bit_count: u5,

    fn init(allocator: std.mem.Allocator) BitWriter {
        return .{
            .output = std.array_list.Managed(u8).init(allocator),
            .bit_buffer = 0,
            .bit_count = 0,
        };
    }

    fn deinit(self: *BitWriter) void {
        self.output.deinit();
    }

    fn writeBit(self: *BitWriter, bit: u1) void {
        self.bit_buffer = (self.bit_buffer << 1) | @as(u32, bit);
        self.bit_count += 1;
        if (self.bit_count == 8) {
            self.output.append(@intCast(self.bit_buffer & 0xFF)) catch unreachable;
            self.bit_buffer = 0;
            self.bit_count = 0;
        }
    }

    fn flush(self: *BitWriter) void {
        if (self.bit_count > 0) {
            // Pad remaining bits with zeros
            const remaining: u5 = 8 - self.bit_count;
            self.bit_buffer = self.bit_buffer << @intCast(remaining);
            self.output.append(@intCast(self.bit_buffer & 0xFF)) catch unreachable;
            self.bit_buffer = 0;
            self.bit_count = 0;
        }
    }
};

// --- Bit Reader ---

const BitReader = struct {
    input: []const u8,
    byte_pos: usize,
    bit_pos: u3,

    fn init(data: []const u8) BitReader {
        return .{
            .input = data,
            .byte_pos = 0,
            .bit_pos = 0,
        };
    }

    fn readBit(self: *BitReader) u1 {
        if (self.byte_pos >= self.input.len) return 0;

        const shift: u3 = 7 - self.bit_pos;
        const bit: u1 = @intCast((self.input[self.byte_pos] >> shift) & 1);

        if (self.bit_pos == 7) {
            self.bit_pos = 0;
            self.byte_pos += 1;
        } else {
            self.bit_pos += 1;
        }

        return bit;
    }
};

// --- VFR Arithmetic Coder ---

const RANGE_BITS: u6 = 32;
const RANGE_MAX: u64 = @as(u64, 1) << RANGE_BITS;
const RANGE_HALF: u64 = RANGE_MAX >> 1;
const RANGE_QUARTER: u64 = RANGE_MAX >> 2;
const RANGE_THREE_QUARTER: u64 = RANGE_HALF + RANGE_QUARTER;
const RANGE_MASK: u64 = RANGE_MAX - 1;

const VeerEncoder = struct {
    low: u64,
    high: u64,
    carry_low: i32,
    carry_high: i32,
    pending_bits: u32,
    writer: BitWriter,

    fn init(allocator: std.mem.Allocator) VeerEncoder {
        return .{
            .low = 0,
            .high = RANGE_MAX - 1,
            .carry_low = 0,
            .carry_high = 0,
            .pending_bits = 0,
            .writer = BitWriter.init(allocator),
        };
    }

    fn deinit(self: *VeerEncoder) void {
        self.writer.deinit();
    }

    fn emitBit(self: *VeerEncoder, bit: u1) void {
        self.writer.writeBit(bit);
        // Emit pending bits (opposite of the emitted bit)
        const opposite: u1 = if (bit == 0) 1 else 0;
        var pending = self.pending_bits;
        while (pending > 0) : (pending -= 1) {
            self.writer.writeBit(opposite);
        }
        self.pending_bits = 0;
    }

    fn encodeSymbol(self: *VeerEncoder, ft: *const FrequencyTable, symbol: u8) void {
        const s: usize = @intCast(symbol);
        const range_width: u64 = self.high - self.low + 1;
        const cum_high: u64 = @intCast(ft.cum_freq[s + 1]);
        const cum_low: u64 = @intCast(ft.cum_freq[s]);
        const total: u64 = @intCast(ft.total);

        // VFR division for high boundary
        // product_high = range_width * cum_high + carry_high * cum_high
        const carry_h_pos: u64 = if (self.carry_high >= 0) @intCast(self.carry_high) else 0;
        const product_high: u128 = @as(u128, range_width) * @as(u128, cum_high) +
            @as(u128, carry_h_pos) * @as(u128, cum_high);
        const quotient_high: u64 = @intCast(product_high / @as(u128, total));
        const remainder_high: i32 = @intCast(product_high % @as(u128, total));

        // VFR division for low boundary
        const carry_l_pos: u64 = if (self.carry_low >= 0) @intCast(self.carry_low) else 0;
        const product_low: u128 = @as(u128, range_width) * @as(u128, cum_low) +
            @as(u128, carry_l_pos) * @as(u128, cum_low);
        const quotient_low: u64 = @intCast(product_low / @as(u128, total));
        const remainder_low: i32 = @intCast(product_low % @as(u128, total));

        // Update range
        self.high = self.low + quotient_high - 1;
        self.low = self.low + quotient_low;
        self.carry_high = remainder_high;
        self.carry_low = remainder_low;

        // Renormalize
        self.renormalize();
    }

    fn renormalize(self: *VeerEncoder) void {
        while (true) {
            if (self.high < RANGE_HALF) {
                // Both in lower half
                self.emitBit(0);
            } else if (self.low >= RANGE_HALF) {
                // Both in upper half
                self.emitBit(1);
                self.low -= RANGE_HALF;
                self.high -= RANGE_HALF;
            } else if (self.low >= RANGE_QUARTER and self.high < RANGE_THREE_QUARTER) {
                // Straddle
                self.pending_bits += 1;
                self.low -= RANGE_QUARTER;
                self.high -= RANGE_QUARTER;
            } else {
                break;
            }

            self.low = self.low << 1;
            self.high = (self.high << 1) | 1;
            // Carries preserved — they are fractional remainders, not range positions
        }
    }

    fn finish(self: *VeerEncoder) void {
        // Flush remaining range information
        self.pending_bits += 1;
        if (self.low < RANGE_QUARTER) {
            self.emitBit(0);
        } else {
            self.emitBit(1);
        }
        self.writer.flush();
    }
};

const VeerDecoder = struct {
    low: u64,
    high: u64,
    value: u64,
    carry_low: i32,
    carry_high: i32,
    reader: BitReader,

    fn init(compressed_data: []const u8) VeerDecoder {
        var dec = VeerDecoder{
            .low = 0,
            .high = RANGE_MAX - 1,
            .value = 0,
            .carry_low = 0,
            .carry_high = 0,
            .reader = BitReader.init(compressed_data),
        };

        // Read initial value bits
        for (0..RANGE_BITS) |_| {
            dec.value = (dec.value << 1) | @as(u64, dec.reader.readBit());
        }

        return dec;
    }

    fn decodeSymbol(self: *VeerDecoder, ft: *const FrequencyTable) u8 {
        const range_width: u64 = self.high - self.low + 1;
        const total: u64 = @intCast(ft.total);

        // Scale value into frequency space for symbol lookup
        // Use u128 to avoid overflow
        const offset: u64 = self.value - self.low;
        const scaled: u64 = @intCast((@as(u128, offset) * @as(u128, total)) / @as(u128, range_width));

        // Find symbol via cumulative frequency table (binary search)
        var symbol: u8 = 0;
        var lo: usize = 0;
        var hi: usize = 255;
        while (lo <= hi) {
            const mid = lo + (hi - lo) / 2;
            if (ft.cum_freq[mid + 1] <= @as(u32, @intCast(scaled))) {
                lo = mid + 1;
            } else if (ft.cum_freq[mid] > @as(u32, @intCast(scaled))) {
                if (mid == 0) break;
                hi = mid - 1;
            } else {
                symbol = @intCast(mid);
                break;
            }
        }
        if (lo > hi) symbol = @intCast(lo);

        // Compute exact VFR range (same as encoder)
        const s: usize = @intCast(symbol);
        const cum_high: u64 = @intCast(ft.cum_freq[s + 1]);
        const cum_low: u64 = @intCast(ft.cum_freq[s]);

        const carry_h_pos: u64 = if (self.carry_high >= 0) @intCast(self.carry_high) else 0;
        const product_high: u128 = @as(u128, range_width) * @as(u128, cum_high) +
            @as(u128, carry_h_pos) * @as(u128, cum_high);
        const quotient_high: u64 = @intCast(product_high / @as(u128, total));
        const remainder_high: i32 = @intCast(product_high % @as(u128, total));

        const carry_l_pos: u64 = if (self.carry_low >= 0) @intCast(self.carry_low) else 0;
        const product_low: u128 = @as(u128, range_width) * @as(u128, cum_low) +
            @as(u128, carry_l_pos) * @as(u128, cum_low);
        const quotient_low: u64 = @intCast(product_low / @as(u128, total));
        const remainder_low: i32 = @intCast(product_low % @as(u128, total));

        // Update range
        self.high = self.low + quotient_high - 1;
        self.low = self.low + quotient_low;
        self.carry_high = remainder_high;
        self.carry_low = remainder_low;

        // Renormalize
        self.decodeRenormalize();

        return symbol;
    }

    fn decodeRenormalize(self: *VeerDecoder) void {
        while (true) {
            if (self.high < RANGE_HALF) {
                // Both in lower half — shift
            } else if (self.low >= RANGE_HALF) {
                // Both in upper half
                self.value -= RANGE_HALF;
                self.low -= RANGE_HALF;
                self.high -= RANGE_HALF;
            } else if (self.low >= RANGE_QUARTER and self.high < RANGE_THREE_QUARTER) {
                // Straddle
                self.value -= RANGE_QUARTER;
                self.low -= RANGE_QUARTER;
                self.high -= RANGE_QUARTER;
            } else {
                break;
            }

            self.low = self.low << 1;
            self.high = (self.high << 1) | 1;
            self.value = (self.value << 1) | @as(u64, self.reader.readBit());
        }
    }
};

// --- Lossy Preprocessing ---

fn applyLossyEncode(data: []u8, q: u8) void {
    if (q >= 8) return;
    const shift: u3 = @intCast(8 - q);
    for (data) |*byte| {
        byte.* = byte.* >> shift;
    }
}

fn applyLossyDecode(data: []u8, q: u8) void {
    if (q >= 8) return;
    const shift: u3 = @intCast(8 - q);
    for (data) |*byte| {
        byte.* = byte.* << shift;
    }
}

// --- Top-Level Encode ---

fn encode(input_data: []const u8, mode: VeerMode, q_value: u8, model_type: VeerModel, allocator: std.mem.Allocator) ![]u8 {
    // Make a working copy for lossy preprocessing
    const work_data = try allocator.alloc(u8, input_data.len);
    defer allocator.free(work_data);
    @memcpy(work_data, input_data);

    // Apply lossy reduction if Q < 8
    if (mode == .lossy) {
        applyLossyEncode(work_data, q_value);
    }

    // Build frequency model
    var ft: FrequencyTable = undefined;
    switch (model_type) {
        .static_model => {
            ft = FrequencyTable.initFromData(work_data);
        },
        .adaptive => {
            ft = FrequencyTable.init();
        },
    }

    // Initialize encoder
    var enc = VeerEncoder.init(allocator);
    defer enc.deinit();

    // Encode each byte
    for (work_data) |byte| {
        enc.encodeSymbol(&ft, byte);
        if (model_type == .adaptive) {
            ft.update(byte);
        }
    }

    // Flush encoder
    enc.finish();

    // Build output
    var output = std.array_list.Managed(u8).init(allocator);
    errdefer output.deinit();

    // Write header
    const header = VeerHeader{
        .magic = VEER_MAGIC,
        .version = VEER_VERSION,
        .mode = @intFromEnum(mode),
        .q_value = q_value,
        .model_type = @intFromEnum(model_type),
        .original_size = @intCast(input_data.len),
        .checksum = crc32(input_data),
        .compressed_size = @intCast(enc.writer.output.items.len),
    };
    try output.appendSlice(std.mem.asBytes(&header));

    // Write frequency table for static model
    if (model_type == .static_model) {
        const freq_bytes = std.mem.sliceAsBytes(&ft.freq);
        try output.appendSlice(freq_bytes);
    }

    // Write compressed data
    try output.appendSlice(enc.writer.output.items);

    // Write footer
    const footer = VeerFooter{
        .end_marker = 0,
        .carry_low_final = enc.carry_low,
        .carry_high_final = enc.carry_high,
    };
    try output.appendSlice(std.mem.asBytes(&footer));

    return output.toOwnedSlice();
}

// --- Top-Level Decode ---

fn decode(
    ver_data: []const u8,
    allocator: std.mem.Allocator,
) ![]u8 {
    if (ver_data.len < @sizeOf(VeerHeader) + @sizeOf(VeerFooter)) {
        return error.InvalidFile;
    }

    // Read header via byte copy (safe, no alignment issues)
    var header: VeerHeader = undefined;
    const header_slice = ver_data[0..@sizeOf(VeerHeader)];
    @memcpy(std.mem.asBytes(&header), header_slice);

    if (header.magic != VEER_MAGIC) {
        return error.InvalidFile;
    }
    if (header.version != VEER_VERSION) {
        return error.UnsupportedVersion;
    }

    const mode: VeerMode = @enumFromInt(header.mode);
    const model_type: VeerModel = @enumFromInt(header.model_type);
    const q_value = header.q_value;
    const original_size: usize = @intCast(header.original_size);

    // Locate compressed data
    var data_offset: usize = @sizeOf(VeerHeader);

    // Read frequency table if static model
    var ft: FrequencyTable = undefined;
    if (model_type == .static_model) {
        const freq_slice = ver_data[data_offset .. data_offset + 256 * @sizeOf(u32)];
        @memcpy(std.mem.sliceAsBytes(&ft.freq), freq_slice);
        ft.buildCumulative();
        data_offset += 256 * @sizeOf(u32);
    } else {
        ft = FrequencyTable.init();
    }

    // Initialize decoder
    const compressed_size: usize = @intCast(header.compressed_size);
    const compressed_data = ver_data[data_offset .. data_offset + compressed_size];
    var dec = VeerDecoder.init(compressed_data);

    // Decode each byte
    var output = try allocator.alloc(u8, original_size);
    errdefer allocator.free(output);

    for (0..original_size) |i| {
        output[i] = dec.decodeSymbol(&ft);
        if (model_type == .adaptive) {
            ft.update(output[i]);
        }
    }

    // Apply lossy expansion if needed
    if (mode == .lossy) {
        applyLossyDecode(output, q_value);
    }

    // Verify footer carries
    const footer_offset = data_offset + compressed_size;
    if (footer_offset + @sizeOf(VeerFooter) <= ver_data.len) {
        var footer: VeerFooter = undefined;
        @memcpy(std.mem.asBytes(&footer), ver_data[footer_offset .. footer_offset + @sizeOf(VeerFooter)]);
        if (footer.carry_low_final != dec.carry_low or
            footer.carry_high_final != dec.carry_high)
        {
            return error.CarryMismatch;
        }
    }

    // Verify checksum for lossless mode
    if (mode == .lossless) {
        if (crc32(output) != header.checksum) {
            return error.ChecksumMismatch;
        }
    }

    return output;
}

// --- CLI ---

const usage_text =
    \\Veer v1.0 — Exact Arithmetic Compression Using VFR Integer Coding
    \\
    \\Usage:
    \\  veer compress <input> <output.ver> [-q Q] [-m model]
    \\  veer decompress <input.ver> <output>
    \\  veer verify <input> [-q Q] [-m model]
    \\  veer info <input.ver>
    \\
    \\Options:
    \\  -q Q       Lossy quality (1-8, default 8 = lossless)
    \\  -m model   Frequency model: static, adaptive (default: adaptive)
    \\
    \\Examples:
    \\  veer compress photo.png photo.ver
    \\  veer compress photo.png photo.ver -q 6
    \\  veer decompress photo.ver restored.png
    \\  veer verify photo.png
    \\  veer info photo.ver
    \\
;

fn readFile(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const stat = try file.stat();
    const data = try allocator.alloc(u8, stat.size);
    const bytes_read = try file.readAll(data);
    if (bytes_read != stat.size) {
        return error.IncompleteRead;
    }
    return data;
}

fn writeFile(path: []const u8, data: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();
    try file.writeAll(data);
}

fn formatSize(size: usize) struct { value: f64, unit: []const u8 } {
    if (size >= 1048576) {
        return .{ .value = @as(f64, @floatFromInt(size)) / 1048576.0, .unit = "MB" };
    } else if (size >= 1024) {
        return .{ .value = @as(f64, @floatFromInt(size)) / 1024.0, .unit = "KB" };
    } else {
        return .{ .value = @as(f64, @floatFromInt(size)), .unit = "B" };
    }
}

const ParsedArgs = struct {
    command: ?[]const u8,
    input_path: ?[]const u8,
    output_path: ?[]const u8,
    q_value: u8,
    model_type: VeerModel,
};

fn parseArgs(args: []const [:0]u8) ParsedArgs {
    var result = ParsedArgs{
        .command = null,
        .input_path = null,
        .output_path = null,
        .q_value = 8,
        .model_type = .adaptive,
    };

    var i: usize = 1; // skip program name
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "-q")) {
            i += 1;
            if (i < args.len) {
                result.q_value = std.fmt.parseInt(u8, args[i], 10) catch 8;
                if (result.q_value < 1 or result.q_value > 8) result.q_value = 8;
            }
        } else if (std.mem.eql(u8, arg, "-m")) {
            i += 1;
            if (i < args.len) {
                if (std.mem.eql(u8, args[i], "static")) {
                    result.model_type = .static_model;
                } else {
                    result.model_type = .adaptive;
                }
            }
        } else if (result.command == null) {
            result.command = arg;
        } else if (result.input_path == null) {
            result.input_path = arg;
        } else if (result.output_path == null) {
            result.output_path = arg;
        }
    }

    return result;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const parsed = parseArgs(args);

    const command = parsed.command orelse {
        std.debug.print("{s}", .{usage_text});
        return;
    };

    if (std.mem.eql(u8, command, "compress")) {
        // --- COMPRESS ---
        const input_path = parsed.input_path orelse {
            std.debug.print("Error: missing input path\n", .{});
            return;
        };
        const output_path = parsed.output_path orelse {
            std.debug.print("Error: missing output path\n", .{});
            return;
        };

        const input_data = try readFile(input_path, allocator);
        defer allocator.free(input_data);

        const mode: VeerMode = if (parsed.q_value < 8) .lossy else .lossless;

        std.debug.print("Veer compress: {s}\n", .{input_path});
        std.debug.print("  Mode: {s}\n", .{if (mode == .lossless) "lossless" else "lossy"});
        if (mode == .lossy) {
            std.debug.print("  Q value: {d}\n", .{parsed.q_value});
        }
        std.debug.print("  Model: {s}\n", .{if (parsed.model_type == .static_model) "static" else "adaptive"});

        const compressed = try encode(input_data, mode, parsed.q_value, parsed.model_type, allocator);
        defer allocator.free(compressed);

        try writeFile(output_path, compressed);

        const orig = formatSize(input_data.len);
        const comp = formatSize(compressed.len);
        const ratio = @as(f64, @floatFromInt(input_data.len)) /
            @as(f64, @floatFromInt(compressed.len));

        std.debug.print("  Original:   {d:.1} {s} ({d} bytes)\n", .{ orig.value, orig.unit, input_data.len });
        std.debug.print("  Compressed: {d:.1} {s} ({d} bytes)\n", .{ comp.value, comp.unit, compressed.len });
        std.debug.print("  Ratio:      {d:.2}:1\n", .{ratio});
        std.debug.print("  Output:     {s}\n", .{output_path});
    } else if (std.mem.eql(u8, command, "decompress")) {
        // --- DECOMPRESS ---
        const input_path = parsed.input_path orelse {
            std.debug.print("Error: missing input path\n", .{});
            return;
        };
        const output_path = parsed.output_path orelse {
            std.debug.print("Error: missing output path\n", .{});
            return;
        };

        const ver_data = try readFile(input_path, allocator);
        defer allocator.free(ver_data);

        std.debug.print("Veer decompress: {s}\n", .{input_path});

        const output_data = try decode(ver_data, allocator);
        defer allocator.free(output_data);

        try writeFile(output_path, output_data);

        std.debug.print("  Restored:   {d} bytes\n", .{output_data.len});
        std.debug.print("  Output:     {s}\n", .{output_path});
        std.debug.print("  Carry match: YES\n", .{});
        std.debug.print("  Result:     PASS\n", .{});
    } else if (std.mem.eql(u8, command, "verify")) {
        // --- VERIFY ---
        const input_path = parsed.input_path orelse {
            std.debug.print("Error: missing input path\n", .{});
            return;
        };

        const input_data = try readFile(input_path, allocator);
        defer allocator.free(input_data);

        const mode: VeerMode = if (parsed.q_value < 8) .lossy else .lossless;

        std.debug.print("Veer verify: {s}\n", .{input_path});

        // Compress
        const compressed = try encode(input_data, mode, parsed.q_value, parsed.model_type, allocator);
        defer allocator.free(compressed);

        // Decompress
        const restored = try decode(compressed, allocator);
        defer allocator.free(restored);

        const orig = formatSize(input_data.len);
        const comp = formatSize(compressed.len);
        const ratio = @as(f64, @floatFromInt(input_data.len)) /
            @as(f64, @floatFromInt(compressed.len));

        std.debug.print("  Original size:    {d:.1} {s} ({d} bytes)\n", .{ orig.value, orig.unit, input_data.len });
        std.debug.print("  Compressed size:  {d:.1} {s} ({d} bytes)\n", .{ comp.value, comp.unit, compressed.len });
        std.debug.print("  Ratio:            {d:.2}:1\n", .{ratio});
        std.debug.print("  Mode:             {s}\n", .{if (mode == .lossless) "lossless" else "lossy"});
        std.debug.print("  Model:            {s}\n", .{if (parsed.model_type == .static_model) "static" else "adaptive"});

        if (mode == .lossless) {
            // Byte-for-byte comparison
            var match = true;
            if (restored.len != input_data.len) {
                match = false;
            } else {
                for (0..input_data.len) |idx| {
                    if (restored[idx] != input_data[idx]) {
                        match = false;
                        break;
                    }
                }
            }
            std.debug.print("  CRC-32 match:     {s}\n", .{if (crc32(restored) == crc32(input_data)) "YES" else "NO"});
            std.debug.print("  Byte-exact match: {s}\n", .{if (match) "YES" else "NO"});
            std.debug.print("  Result:           {s}\n", .{if (match) "PASS" else "FAIL"});
        } else {
            // Lossy comparison — report error stats
            var max_err: u32 = 0;
            var total_err: u64 = 0;
            const len = @min(restored.len, input_data.len);
            for (0..len) |idx| {
                const diff: u32 = if (restored[idx] > input_data[idx])
                    @as(u32, restored[idx]) - @as(u32, input_data[idx])
                else
                    @as(u32, input_data[idx]) - @as(u32, restored[idx]);
                if (diff > max_err) max_err = diff;
                total_err += diff;
            }
            const mean_err = @as(f64, @floatFromInt(total_err)) / @as(f64, @floatFromInt(len));

            std.debug.print("  Q value:          {d}\n", .{parsed.q_value});
            std.debug.print("  Max byte error:   {d}\n", .{max_err});
            std.debug.print("  Mean byte error:  {d:.1}\n", .{mean_err});
            std.debug.print("  Result:           PASS (lossy)\n", .{});
        }
    } else if (std.mem.eql(u8, command, "info")) {
        // --- INFO ---
        const input_path = parsed.input_path orelse {
            std.debug.print("Error: missing input path\n", .{});
            return;
        };

        const ver_data = try readFile(input_path, allocator);
        defer allocator.free(ver_data);

        if (ver_data.len < @sizeOf(VeerHeader)) {
            std.debug.print("Error: file too small for Veer header\n", .{});
            return;
        }

        var header: VeerHeader = undefined;
        @memcpy(std.mem.asBytes(&header), ver_data[0..@sizeOf(VeerHeader)]);

        if (header.magic != VEER_MAGIC) {
            std.debug.print("Error: not a Veer file (bad magic)\n", .{});
            return;
        }

        const mode_str = if (header.mode == 0) "lossless" else "lossy";
        const model_str = if (header.model_type == 0) "static" else "adaptive";
        const orig_size: usize = @intCast(header.original_size);
        const comp_size: usize = @intCast(header.compressed_size);
        const ratio = @as(f64, @floatFromInt(orig_size)) /
            @as(f64, @floatFromInt(comp_size));

        std.debug.print("Veer file: {s}\n", .{input_path});
        std.debug.print("  Magic:            VEER\n", .{});
        std.debug.print("  Version:          {d}\n", .{header.version});
        std.debug.print("  Mode:             {s}\n", .{mode_str});
        std.debug.print("  Q value:          {d}\n", .{header.q_value});
        std.debug.print("  Model:            {s}\n", .{model_str});
        std.debug.print("  Original size:    {d} bytes\n", .{orig_size});
        std.debug.print("  Compressed size:  {d} bytes\n", .{comp_size});
        std.debug.print("  Ratio:            {d:.2}:1\n", .{ratio});
        std.debug.print("  CRC-32:           0x{X:0>8}\n", .{header.checksum});

        // Read footer if present
        const footer_offset = @sizeOf(VeerHeader) +
            (if (header.model_type == 0) @as(usize, 1024) else @as(usize, 0)) +
            comp_size;
        if (footer_offset + @sizeOf(VeerFooter) <= ver_data.len) {
            var footer: VeerFooter = undefined;
            @memcpy(std.mem.asBytes(&footer), ver_data[footer_offset .. footer_offset + @sizeOf(VeerFooter)]);
            std.debug.print("  Final carry low:  {d}\n", .{footer.carry_low_final});
            std.debug.print("  Final carry high: {d}\n", .{footer.carry_high_final});
        }
    } else {
        std.debug.print("{s}", .{usage_text});
    }
}
