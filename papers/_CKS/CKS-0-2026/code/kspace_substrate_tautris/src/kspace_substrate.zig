const std = @import("std");
const math = std.math;
const Physics = @import("physics.zig").Physics;

pub const KSpaceSubstrate = struct {
    size: i32,
    data: []f32,
    temp: []f32, // For updates
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: i32) !KSpaceSubstrate {
        const total = @as(usize, @intCast(size * size));
        const data = try allocator.alloc(f32, total);
        const temp = try allocator.alloc(f32, total);

        var substrate = KSpaceSubstrate{
            .size = size,
            .data = data,
            .temp = temp,
            .allocator = allocator,
        };

        try substrate.generate();
        return substrate;
    }

    fn generate(self: *KSpaceSubstrate) !void {
        const sources = [_]struct { x: f32, y: f32, amp: f32, freq: f32 }{
            .{ .x = 10, .y = 10, .amp = 0.8, .freq = 2.5 },
            .{ .x = 30, .y = 10, .amp = 0.8, .freq = 2.3 },
            .{ .x = 20, .y = 20, .amp = 0.9, .freq = 2.7 },
            .{ .x = 10, .y = 30, .amp = 0.7, .freq = 2.4 },
            .{ .x = 30, .y = 30, .amp = 0.8, .freq = 2.6 },
        };

        const size_f: f32 = @floatFromInt(self.size);
        var min_val: f32 = math.inf(f32);
        var max_val: f32 = -math.inf(f32);

        var y: i32 = 0;
        while (y < self.size) : (y += 1) {
            var x: i32 = 0;
            while (x < self.size) : (x += 1) {
                const wx = (@as(f32, @floatFromInt(x)) / size_f) * 40.0;
                const wy = (@as(f32, @floatFromInt(y)) / size_f) * 40.0;

                var value: f32 = 0.0;
                for (sources) |src| {
                    const dx = wx - src.x;
                    const dy = wy - src.y;
                    const r = @sqrt(dx * dx + dy * dy);
                    value += src.amp * @sin(src.freq * r) * @exp(-r / 15.0);
                }

                value += 0.3 * @sin(wx * 0.5) * @cos(wy * 0.5);
                value += 0.2 * @sin(wx * 0.8 + wy * 0.8);

                const idx = @as(usize, @intCast(y * self.size + x));
                self.data[idx] = value;

                if (value < min_val) min_val = value;
                if (value > max_val) max_val = value;
            }
        }

        const range = max_val - min_val;
        for (self.data) |*val| {
            val.* = ((val.* - min_val) / range) * 4.0 - 2.0;
        }
    }

    pub fn step(self: *KSpaceSubstrate, dt: f32, physics: *Physics) void {
        const coupling = @as(f32, @floatCast(physics.coupling_strength()));

        // Simple wave equation: d²φ/dt² = c² ∇²φ
        var y: i32 = 1;
        while (y < self.size - 1) : (y += 1) {
            var x: i32 = 1;
            while (x < self.size - 1) : (x += 1) {
                const idx = @as(usize, @intCast(y * self.size + x));
                const up = @as(usize, @intCast((y - 1) * self.size + x));
                const down = @as(usize, @intCast((y + 1) * self.size + x));
                const left = @as(usize, @intCast(y * self.size + (x - 1)));
                const right = @as(usize, @intCast(y * self.size + (x + 1)));

                const laplacian = self.data[up] + self.data[down] +
                    self.data[left] + self.data[right] -
                    4.0 * self.data[idx];

                self.temp[idx] = self.data[idx] + coupling * dt * laplacian;
            }
        }

        // Swap buffers
        const tmp = self.data;
        self.data = self.temp;
        self.temp = tmp;
    }

    pub fn injectPiece(self: *KSpaceSubstrate, blocks: []const [3]i32, physics: *Physics) void {
        const scale = @as(f32, @floatCast(physics.holographic_scale()));

        for (blocks) |block| {
            const kx = @as(i32, @intFromFloat(@as(f32, @floatFromInt(block[0])) * scale));
            const ky = @as(i32, @intFromFloat(@as(f32, @floatFromInt(block[2])) * scale));

            if (kx >= 0 and kx < self.size and ky >= 0 and ky < self.size) {
                const idx = @as(usize, @intCast(ky * self.size + kx));
                self.data[idx] += 0.5; // Inject energy
            }
        }
    }

    pub fn getValue(self: *KSpaceSubstrate, x: i32, y: i32) f32 {
        if (x < 0 or x >= self.size or y < 0 or y >= self.size) return 0;
        const idx = @as(usize, @intCast(y * self.size + x));
        return self.data[idx];
    }
};
