const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

const math = std.math;

const PI = math.pi;

// ============================================================================
// CONFIGURATION
// ============================================================================

const Config = struct {
    screen_width: i32 = 1600,
    screen_height: i32 = 900,
    target_fps: i32 = 60,
    step_mode: bool = false,

    // Visual
    bubble_min_radius: f32 = 2.0,
    bubble_max_radius: f32 = 8.0,
    edge_alpha: f32 = 0.3,

    // Physics
    evolution_dt: f32 = 0.05,
    coupling_beta: f32 = 0.5,
    oscillation_omega: f32 = 1.0,

    // Auto-step timing (when not in step mode)
    auto_step_delay: f32 = 0.5, // seconds between N increments
};

// ============================================================================
// COMPLEX NUMBER HELPERS
// ============================================================================

const Complex = struct {
    re: f32,
    im: f32,

    fn init(re: f32, im: f32) Complex {
        return .{ .re = re, .im = im };
    }

    fn fromPolar(r: f32, theta: f32) Complex {
        return .{
            .re = r * @cos(theta),
            .im = r * @sin(theta),
        };
    }

    fn add(self: Complex, other: Complex) Complex {
        return .{ .re = self.re + other.re, .im = self.im + other.im };
    }

    fn sub(self: Complex, other: Complex) Complex {
        return .{ .re = self.re - other.re, .im = self.im - other.im };
    }

    fn mul(self: Complex, scalar: f32) Complex {
        return .{ .re = self.re * scalar, .im = self.im * scalar };
    }

    fn abs(self: Complex) f32 {
        return @sqrt(self.re * self.re + self.im * self.im);
    }

    fn normalize(self: Complex) Complex {
        const magnitude = self.abs();
        if (magnitude < 1e-6) return Complex.init(1, 0);
        return .{ .re = self.re / magnitude, .im = self.im / magnitude };
    }

    fn angle(self: Complex) f32 {
        return math.atan2(self.im, self.re);
    }
};

// ============================================================================
// BUBBLE (K-SPACE NODE)
// ============================================================================

const Bubble = struct {
    id: usize,
    pos_k: rl.Vector2, // k-space position
    pos_x: rl.Vector2, // x-space position (for display)
    phase: Complex,
    neighbors: [3]?usize, // 3 neighbors max (hexagonal coordination)
    neighbor_count: usize,

    fn init(id: usize, x: f32, y: f32) Bubble {
        return .{
            .id = id,
            .pos_k = .{ .x = x, .y = y },
            .pos_x = .{ .x = 0, .y = 0 }, // Computed later
            .phase = Complex.init(1, 0),
            .neighbors = [_]?usize{null} ** 3,
            .neighbor_count = 0,
        };
    }

    fn addNeighbor(self: *Bubble, neighbor_id: usize) void {
        if (self.neighbor_count < 3) {
            self.neighbors[self.neighbor_count] = neighbor_id;
            self.neighbor_count += 1;
        }
    }
};

// ============================================================================
// CKS LATTICE
// ============================================================================

const CKSLattice = struct {
    allocator: std.mem.Allocator,
    M: i32,
    N: i32,
    bubbles: std.array_list.Managed(Bubble),

    // Physics constants
    t_p: f64 = 5.39e-44,
    coherence: f64 = 0,

    // Auto-evolution state
    evolution_time: f32 = 0,

    fn init(allocator: std.mem.Allocator) !CKSLattice {
        return .{
            .allocator = allocator,
            .M = 1,
            .N = 1,
            .bubbles = std.array_list.Managed(Bubble).init(allocator),
        };
    }

    fn deinit(self: *CKSLattice) void {
        self.bubbles.deinit();
    }

    fn reset(self: *CKSLattice) !void {
        self.bubbles.clearRetainingCapacity();
        self.M = 1;
        self.N = 1;
        self.evolution_time = 0;
        try self.constructLattice();
    }

    fn growToNextN(self: *CKSLattice) !void {
        // Find next M such that N = 3M²
        self.M += 1;
        self.N = 3 * self.M * self.M;
        try self.constructLattice();
    }

    fn constructLattice(self: *CKSLattice) !void {
        self.bubbles.clearRetainingCapacity();

        if (self.M == 1) {
            // N = 3: Equilateral triangle
            try self.bubbles.append(Bubble.init(0, 0, 0));
            try self.bubbles.append(Bubble.init(1, 1, 0));
            try self.bubbles.append(Bubble.init(2, 0.5, @sqrt(3.0) / 2.0));

            // Connect neighbors
            self.bubbles.items[0].addNeighbor(1);
            self.bubbles.items[0].addNeighbor(2);
            self.bubbles.items[1].addNeighbor(0);
            self.bubbles.items[1].addNeighbor(2);
            self.bubbles.items[2].addNeighbor(0);
            self.bubbles.items[2].addNeighbor(1);

            // X-space for triangle: same as k-space initially
            self.bubbles.items[0].pos_x = .{ .x = 0, .y = 0 };
            self.bubbles.items[1].pos_x = .{ .x = 1, .y = 0 };
            self.bubbles.items[2].pos_x = .{ .x = 0.5, .y = @sqrt(3.0) / 2.0 };
        } else {
            // Construct hexagonal lattice in 3 sectors
            var positions = std.array_list.Managed(rl.Vector2).init(self.allocator);
            defer positions.deinit();

            // Generate positions in 3 sectors
            var sector: i32 = 0;
            while (sector < 3) : (sector += 1) {
                const angle_offset = @as(f32, @floatFromInt(sector)) * 2.0 * PI / 3.0;

                var i: i32 = 0;
                while (i < self.M) : (i += 1) {
                    var j: i32 = 0;
                    while (j < self.M - i) : (j += 1) {
                        const fi = @as(f32, @floatFromInt(i));
                        const fj = @as(f32, @floatFromInt(j));

                        const r = fi + fj * 0.5;
                        const theta = math.atan2(fj * @sqrt(3.0) / 2.0, fi + fj * 0.5) + angle_offset;

                        const x = r * @cos(theta);
                        const y = r * @sin(theta);

                        try positions.append(.{ .x = x, .y = y });
                    }
                }
            }

            // Remove duplicates
            var unique_positions = std.array_list.Managed(rl.Vector2).init(self.allocator);
            defer unique_positions.deinit();

            const tolerance = 1e-4;
            for (positions.items) |pos| {
                var is_duplicate = false;
                for (unique_positions.items) |existing| {
                    const dx = pos.x - existing.x;
                    const dy = pos.y - existing.y;
                    const dist = @sqrt(dx * dx + dy * dy);
                    if (dist < tolerance) {
                        is_duplicate = true;
                        break;
                    }
                }
                if (!is_duplicate) {
                    try unique_positions.append(pos);
                }
            }

            // Create bubbles
            for (unique_positions.items, 0..) |pos, id| {
                try self.bubbles.append(Bubble.init(id, pos.x, pos.y));
            }

            // Connect neighbors by distance
            for (self.bubbles.items, 0..) |*bubble, i| {
                var distances = std.array_list.Managed(struct { dist: f32, id: usize }).init(self.allocator);
                defer distances.deinit();

                for (self.bubbles.items, 0..) |other, j| {
                    if (i == j) continue;

                    const dx = bubble.pos_k.x - other.pos_k.x;
                    const dy = bubble.pos_k.y - other.pos_k.y;
                    const dist = @sqrt(dx * dx + dy * dy);

                    try distances.append(.{ .dist = dist, .id = j });
                }

                // Sort by distance
                std.mem.sort(@TypeOf(distances.items[0]), distances.items, {}, struct {
                    fn lessThan(_: void, a: @TypeOf(distances.items[0]), b: @TypeOf(distances.items[0])) bool {
                        return a.dist < b.dist;
                    }
                }.lessThan);

                // Take 3 nearest
                const num_neighbors = @min(distances.items.len, 3);
                for (0..num_neighbors) |k| {
                    bubble.addNeighbor(distances.items[k].id);
                }
            }

            // Compute x-space positions via inverse Fourier transform
            try self.computeXSpacePositions();
        }

        // Update N to actual count
        self.N = @intCast(self.bubbles.items.len);

        // Compute coherence
        const fN = @as(f64, @floatFromInt(self.N));
        self.coherence = 1.0 - 1.0 / (2.0 * @sqrt(fN / 3.0));
    }

    fn computeXSpacePositions(self: *CKSLattice) !void {
        // Inverse Fourier Transform: k-space -> x-space
        // For each point in x-space, we sum: ψ(x) = Σ_k φ(k) exp(i k·x)

        const n = self.bubbles.items.len;
        if (n == 0) return;

        // Create a real-space grid (different from k-space grid)
        var x_positions = std.array_list.Managed(rl.Vector2).init(self.allocator);
        defer x_positions.deinit();

        // Generate real-space sampling grid (Cartesian, not hexagonal)
        const grid_size = @as(i32, @intFromFloat(@ceil(@sqrt(@as(f32, @floatFromInt(n))))));
        const spacing: f32 = 1.5;

        var ix: i32 = 0;
        while (ix < grid_size) : (ix += 1) {
            var iy: i32 = 0;
            while (iy < grid_size) : (iy += 1) {
                if (x_positions.items.len >= n) break;

                const x = (@as(f32, @floatFromInt(ix)) - @as(f32, @floatFromInt(grid_size)) / 2.0) * spacing;
                const y = (@as(f32, @floatFromInt(iy)) - @as(f32, @floatFromInt(grid_size)) / 2.0) * spacing;

                try x_positions.append(.{ .x = x, .y = y });
            }
            if (x_positions.items.len >= n) break;
        }

        // Compute inverse Fourier transform for each x-space point
        for (self.bubbles.items, 0..) |*bubble, idx| {
            if (idx >= x_positions.items.len) break;

            const x_pos = x_positions.items[idx];
            var sum_re: f32 = 0;
            var sum_im: f32 = 0;

            // Sum over all k-modes: Σ_k φ(k) exp(i k·x)
            for (self.bubbles.items) |k_bubble| {
                const k_dot_x = k_bubble.pos_k.x * x_pos.x + k_bubble.pos_k.y * x_pos.y;

                // exp(i k·x) = cos(k·x) + i sin(k·x)
                const cos_kx = @cos(k_dot_x);
                const sin_kx = @sin(k_dot_x);

                // φ(k) * exp(i k·x)
                sum_re += k_bubble.phase.re * cos_kx - k_bubble.phase.im * sin_kx;
                sum_im += k_bubble.phase.re * sin_kx + k_bubble.phase.im * cos_kx;
            }

            // Normalize
            const norm = 1.0 / @as(f32, @floatFromInt(n));
            sum_re *= norm;
            sum_im *= norm;

            // Map amplitude to position variation
            const amplitude = @sqrt(sum_re * sum_re + sum_im * sum_im);
            const phase_angle = math.atan2(sum_im, sum_re);

            // Create visually distinct x-space position
            const radial_scale = 1.0 + amplitude * 2.0;
            bubble.pos_x = .{
                .x = x_pos.x * radial_scale + @cos(phase_angle) * amplitude,
                .y = x_pos.y * radial_scale + @sin(phase_angle) * amplitude,
            };
        }
    }

    fn setPhaseWave(self: *CKSLattice, wavelength: f32, dir_x: f32, dir_y: f32) void {
        const k_mag = 2.0 * PI / wavelength;
        const norm = @sqrt(dir_x * dir_x + dir_y * dir_y);
        const kx = k_mag * dir_x / norm;
        const ky = k_mag * dir_y / norm;

        for (self.bubbles.items) |*bubble| {
            const phase_angle = kx * bubble.pos_k.x + ky * bubble.pos_k.y;
            bubble.phase = Complex.fromPolar(1.0, phase_angle);
        }
    }

    fn evolveStep(self: *CKSLattice, dt: f32, omega: f32, beta: f32) void {
        var new_phases = self.allocator.alloc(Complex, self.bubbles.items.len) catch return;
        defer self.allocator.free(new_phases);

        for (self.bubbles.items, 0..) |bubble, i| {
            // Natural oscillation: -iω φ
            const d_phi_natural = Complex.init(
                omega * bubble.phase.im,
                -omega * bubble.phase.re,
            );

            // Coupling: β Σ(φⱼ - φₖ)
            var d_phi_coupling = Complex.init(0, 0);
            for (bubble.neighbors[0..bubble.neighbor_count]) |maybe_neighbor| {
                if (maybe_neighbor) |neighbor_id| {
                    const phi_j = self.bubbles.items[neighbor_id].phase;
                    const diff = phi_j.sub(bubble.phase);
                    d_phi_coupling = d_phi_coupling.add(diff.mul(beta));
                }
            }

            const d_phi = d_phi_natural.add(d_phi_coupling);
            new_phases[i] = bubble.phase.add(d_phi.mul(dt)).normalize();
        }

        for (self.bubbles.items, 0..) |*bubble, i| {
            bubble.phase = new_phases[i];
        }

        self.evolution_time += dt;
    }
};

// ============================================================================
// CAMERA / VIEWPORT
// ============================================================================

const Camera = struct {
    offset: rl.Vector2,
    zoom: f32,
    target_zoom: f32,
    zoom_speed: f32 = 0.1,

    fn init() Camera {
        return .{
            .offset = .{ .x = 0, .y = 0 },
            .zoom = 1.0,
            .target_zoom = 1.0,
        };
    }

    fn update(self: *Camera) void {
        // Smooth zoom
        self.zoom += (self.target_zoom - self.zoom) * self.zoom_speed;
    }

    fn fitBounds(self: *Camera, min_x: f32, max_x: f32, min_y: f32, max_y: f32, canvas_width: f32, canvas_height: f32) void {
        const width = max_x - min_x;
        const height = max_y - min_y;

        if (width < 1e-6 or height < 1e-6) {
            self.target_zoom = 1.0;
            self.offset = .{ .x = 0, .y = 0 };
            return;
        }

        const zoom_x = canvas_width / (width * 1.2);
        const zoom_y = canvas_height / (height * 1.2);
        self.target_zoom = @min(zoom_x, zoom_y);

        const center_x = (min_x + max_x) / 2.0;
        const center_y = (min_y + max_y) / 2.0;

        self.offset = .{
            .x = canvas_width / 2.0 - center_x * self.target_zoom,
            .y = canvas_height / 2.0 - center_y * self.target_zoom,
        };
    }

    fn worldToScreen(self: Camera, pos: rl.Vector2) rl.Vector2 {
        return .{
            .x = pos.x * self.zoom + self.offset.x,
            .y = pos.y * self.zoom + self.offset.y,
        };
    }
};

// ============================================================================
// RENDERER
// ============================================================================

const Renderer = struct {
    config: Config,
    camera_k: Camera,
    camera_x: Camera,

    panel_width: f32,
    canvas_left: f32,
    canvas_width: f32,

    fn init(config: Config) Renderer {
        const panel_width = @as(f32, @floatFromInt(config.screen_width)) * 0.1;
        const canvas_left = panel_width;
        const canvas_width = @as(f32, @floatFromInt(config.screen_width)) * 0.8;

        return .{
            .config = config,
            .camera_k = Camera.init(),
            .camera_x = Camera.init(),
            .panel_width = panel_width,
            .canvas_left = canvas_left,
            .canvas_width = canvas_width,
        };
    }

    fn updateCameras(self: *Renderer, lattice: *CKSLattice) void {
        if (lattice.bubbles.items.len == 0) return;

        // Compute k-space bounds
        var min_x_k: f32 = lattice.bubbles.items[0].pos_k.x;
        var max_x_k: f32 = min_x_k;
        var min_y_k: f32 = lattice.bubbles.items[0].pos_k.y;
        var max_y_k: f32 = min_y_k;

        // Compute x-space bounds
        var min_x_x: f32 = lattice.bubbles.items[0].pos_x.x;
        var max_x_x: f32 = min_x_x;
        var min_y_x: f32 = lattice.bubbles.items[0].pos_x.y;
        var max_y_x: f32 = min_y_x;

        for (lattice.bubbles.items) |bubble| {
            min_x_k = @min(min_x_k, bubble.pos_k.x);
            max_x_k = @max(max_x_k, bubble.pos_k.x);
            min_y_k = @min(min_y_k, bubble.pos_k.y);
            max_y_k = @max(max_y_k, bubble.pos_k.y);

            min_x_x = @min(min_x_x, bubble.pos_x.x);
            max_x_x = @max(max_x_x, bubble.pos_x.x);
            min_y_x = @min(min_y_x, bubble.pos_x.y);
            max_y_x = @max(max_y_x, bubble.pos_x.y);
        }

        const canvas_height = @as(f32, @floatFromInt(self.config.screen_height));

        // K-space camera (left half of canvas)
        self.camera_k.fitBounds(min_x_k, max_x_k, min_y_k, max_y_k, self.canvas_width / 2.0, canvas_height);
        self.camera_k.offset.x += self.canvas_left;

        // X-space camera (right half of canvas)
        self.camera_x.fitBounds(min_x_x, max_x_x, min_y_x, max_y_x, self.canvas_width / 2.0, canvas_height);
        self.camera_x.offset.x += self.canvas_left + self.canvas_width / 2.0;

        self.camera_k.update();
        self.camera_x.update();
    }

    fn render(self: *Renderer, lattice: *CKSLattice) void {
        rl.ClearBackground(rl.Color{ .r = 20, .g = 20, .b = 30, .a = 255 });

        const canvas_height = @as(f32, @floatFromInt(self.config.screen_height));

        // Draw split line
        const split_x = self.canvas_left + self.canvas_width / 2.0;
        rl.DrawLineEx(
            .{ .x = split_x, .y = 0 },
            .{ .x = split_x, .y = canvas_height },
            2.0,
            rl.Color{ .r = 80, .g = 80, .b = 100, .a = 255 },
        );

        // Render k-space (left)
        self.renderLattice(lattice, self.camera_k, true);

        // Render x-space (right)
        self.renderLattice(lattice, self.camera_x, false);

        // Render stats panels
        self.renderStats(lattice);
    }

    fn renderLattice(self: *Renderer, lattice: *CKSLattice, camera: Camera, is_k_space: bool) void {
        // Draw edges
        for (lattice.bubbles.items) |bubble| {
            for (bubble.neighbors[0..bubble.neighbor_count]) |maybe_neighbor| {
                if (maybe_neighbor) |neighbor_id| {
                    const pos1_world = if (is_k_space) bubble.pos_k else bubble.pos_x;
                    const pos2_world = if (is_k_space)
                        lattice.bubbles.items[neighbor_id].pos_k
                    else
                        lattice.bubbles.items[neighbor_id].pos_x;

                    const pos1 = camera.worldToScreen(pos1_world);
                    const pos2 = camera.worldToScreen(pos2_world);

                    rl.DrawLineEx(
                        pos1,
                        pos2,
                        1.5,
                        rl.Color{ .r = 100, .g = 100, .b = 120, .a = @intFromFloat(self.config.edge_alpha * 255.0) },
                    );
                }
            }
        }

        // Draw bubbles
        const radius_scale = camera.zoom;
        const bubble_radius = std.math.clamp(
            self.config.bubble_min_radius + radius_scale * 0.5,
            self.config.bubble_min_radius,
            self.config.bubble_max_radius,
        );

        for (lattice.bubbles.items) |bubble| {
            const pos_world = if (is_k_space) bubble.pos_k else bubble.pos_x;
            const pos = camera.worldToScreen(pos_world);

            // Color from phase angle
            const phase_angle = bubble.phase.angle();
            const hue = (phase_angle + PI) / (2.0 * PI);
            const color = hsvToRgb(hue, 0.8, 0.9);

            rl.DrawCircleV(pos, bubble_radius, color);
            rl.DrawCircleLines(
                @intFromFloat(pos.x),
                @intFromFloat(pos.y),
                bubble_radius,
                rl.Color{ .r = 0, .g = 0, .b = 0, .a = 180 },
            );
        }

        // Label
        const label = if (is_k_space) "k-space" else "x-space";
        const split_x = self.canvas_left + self.canvas_width / 2.0;
        const label_x = if (is_k_space) self.canvas_left + 10 else split_x + 10;
        rl.DrawText(label, @intFromFloat(label_x), 10, 20, rl.WHITE);
    }

    fn renderStats(self: *Renderer, lattice: *CKSLattice) void {
        const left_panel_x: i32 = 10;
        const right_panel_x: i32 = @intFromFloat(@as(f32, @floatFromInt(self.config.screen_width)) - self.panel_width + 10);
        var y: i32 = 10;
        const line_height: i32 = 25;
        const font_size: i32 = 18;

        // Left panel - K-space stats
        rl.DrawText("K-SPACE", left_panel_x, y, font_size, rl.YELLOW);
        y += line_height;

        var buf: [256]u8 = undefined;

        // M
        const m_text = std.fmt.bufPrintZ(&buf, "M = {d}", .{lattice.M}) catch "M = ?";
        rl.DrawText(m_text.ptr, left_panel_x, y, font_size, rl.WHITE);
        y += line_height;

        // N
        const n_text = std.fmt.bufPrintZ(&buf, "N = {d}", .{lattice.N}) catch "N = ?";
        rl.DrawText(n_text.ptr, left_panel_x, y, font_size, rl.WHITE);
        y += line_height;

        // Coherence
        const c_text = std.fmt.bufPrintZ(&buf, "C = {d:.6}", .{lattice.coherence}) catch "C = ?";
        rl.DrawText(c_text.ptr, left_panel_x, y, font_size, rl.WHITE);
        y += line_height;

        // Phase tension
        const beta = 2.0 * PI / @as(f64, @floatFromInt(lattice.N));
        const beta_text = std.fmt.bufPrintZ(&buf, "β = {d:.2}", .{beta}) catch "β = ?";
        rl.DrawText(beta_text.ptr, left_panel_x, y, font_size, rl.WHITE);
        y += line_height;

        // Alpha_em
        const alpha_em = 1.0 / 137.036;
        const alpha_text = std.fmt.bufPrintZ(&buf, "α_em = {d:.6}", .{alpha_em}) catch "α = ?";
        rl.DrawText(alpha_text.ptr, left_panel_x, y, font_size, rl.WHITE);

        // Right panel - X-space stats (same values)
        y = 10;
        rl.DrawText("X-SPACE", right_panel_x, y, font_size, rl.YELLOW);
        y += line_height;

        rl.DrawText(m_text.ptr, right_panel_x, y, font_size, rl.WHITE);
        y += line_height;

        rl.DrawText(n_text.ptr, right_panel_x, y, font_size, rl.WHITE);
        y += line_height;

        rl.DrawText(c_text.ptr, right_panel_x, y, font_size, rl.WHITE);
        y += line_height;

        rl.DrawText(beta_text.ptr, right_panel_x, y, font_size, rl.WHITE);
        y += line_height;

        rl.DrawText(alpha_text.ptr, right_panel_x, y, font_size, rl.WHITE);

        // Bottom instructions
        const bottom_y = self.config.screen_height - 30;
        const instructions = if (self.config.step_mode)
            "STEP MODE: SPACE=Next N | R=Reset | ESC=Quit"
        else
            "AUTO MODE: SPACE=Reset | ESC=Quit";

        const text_width = rl.MeasureText(instructions, 16);
        const text_x = @divTrunc(self.config.screen_width - text_width, 2);
        rl.DrawText(instructions, text_x, bottom_y, 16, rl.LIGHTGRAY);
    }
};

// ============================================================================
// UTILITY
// ============================================================================

fn hsvToRgb(h: f32, s: f32, v: f32) rl.Color {
    const c = v * s;
    const x = c * (1.0 - @abs(@mod(h * 6.0, 2.0) - 1.0));
    const m = v - c;

    var r: f32 = 0;
    var g: f32 = 0;
    var b: f32 = 0;

    const h_sector = h * 6.0;
    if (h_sector < 1.0) {
        r = c;
        g = x;
        b = 0;
    } else if (h_sector < 2.0) {
        r = x;
        g = c;
        b = 0;
    } else if (h_sector < 3.0) {
        r = 0;
        g = c;
        b = x;
    } else if (h_sector < 4.0) {
        r = 0;
        g = x;
        b = c;
    } else if (h_sector < 5.0) {
        r = x;
        g = 0;
        b = c;
    } else {
        r = c;
        g = 0;
        b = x;
    }

    return rl.Color{
        .r = @intFromFloat((r + m) * 255.0),
        .g = @intFromFloat((g + m) * 255.0),
        .b = @intFromFloat((b + m) * 255.0),
        .a = 255,
    };
}

// ============================================================================
// MAIN
// ============================================================================

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse args
    var config = Config{};

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip(); // Skip program name
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--step")) {
            config.step_mode = true;
        }
    }

    // Initialize window
    rl.InitWindow(config.screen_width, config.screen_height, "CKS Lattice Growth");
    defer rl.CloseWindow();

    rl.SetTargetFPS(config.target_fps);

    // Initialize lattice
    var lattice = try CKSLattice.init(allocator);
    defer lattice.deinit();

    try lattice.constructLattice();
    lattice.setPhaseWave(4.0, 1.0, 0.5);

    // Initialize renderer
    var renderer = Renderer.init(config);

    var auto_step_timer: f32 = 0;

    // Main loop
    while (!rl.WindowShouldClose()) {
        const dt = rl.GetFrameTime();

        // Input
        if (rl.IsKeyPressed(rl.KEY_SPACE)) {
            if (config.step_mode) {
                // Step to next N
                try lattice.growToNextN();
                lattice.setPhaseWave(4.0, 1.0, 0.5);
            } else {
                // Reset
                try lattice.reset();
                lattice.setPhaseWave(4.0, 1.0, 0.5);
                auto_step_timer = 0;
            }
        }

        if (rl.IsKeyPressed(rl.KEY_R)) {
            try lattice.reset();
            lattice.setPhaseWave(4.0, 1.0, 0.5);
            auto_step_timer = 0;
        }

        // Auto-step (if not in step mode)
        if (!config.step_mode) {
            auto_step_timer += dt;
            if (auto_step_timer >= config.auto_step_delay) {
                auto_step_timer = 0;
                try lattice.growToNextN();
                lattice.setPhaseWave(4.0, 1.0, 0.5);
            }
        }

        // Evolve phases
        lattice.evolveStep(config.evolution_dt, config.oscillation_omega, config.coupling_beta);

        // Update cameras to keep lattice on screen
        renderer.updateCameras(&lattice);

        // Render
        rl.BeginDrawing();
        renderer.render(&lattice);
        rl.EndDrawing();
    }
}
