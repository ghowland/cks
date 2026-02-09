const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});
const math = std.math;

const ViewState = struct {
    center_x: f32 = 20.0,
    center_y: f32 = 20.0,
    zoom: f32 = 1.0,
};

const WaveSource = struct {
    x: f32,
    y: f32,
    amplitude: f32,
    frequency: f32,
};

const KSpaceSubstrate = struct {
    size: i32,
    data: []f32,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, size: i32) !KSpaceSubstrate {
        const total = @as(usize, @intCast(size * size));
        const data = try allocator.alloc(f32, total);

        var substrate = KSpaceSubstrate{
            .size = size,
            .data = data,
            .allocator = allocator,
        };

        try substrate.generate();

        return substrate;
    }

    pub fn deinit(self: *KSpaceSubstrate) void {
        self.allocator.free(self.data);
    }

    fn generate(self: *KSpaceSubstrate) !void {
        std.debug.print("Generating {}x{} substrate...\n", .{ self.size, self.size });

        // Wave sources (cymatic interference patterns)
        const sources = [_]WaveSource{
            .{ .x = 10.0, .y = 10.0, .amplitude = 0.8, .frequency = 2.5 },
            .{ .x = 30.0, .y = 10.0, .amplitude = 0.8, .frequency = 2.3 },
            .{ .x = 20.0, .y = 20.0, .amplitude = 0.9, .frequency = 2.7 },
            .{ .x = 10.0, .y = 30.0, .amplitude = 0.7, .frequency = 2.4 },
            .{ .x = 30.0, .y = 30.0, .amplitude = 0.8, .frequency = 2.6 },
        };

        const size_f: f32 = @floatFromInt(self.size);

        var min_val: f32 = math.inf(f32);
        var max_val: f32 = -math.inf(f32);

        // Generate substrate values
        var y: i32 = 0;
        while (y < self.size) : (y += 1) {
            var x: i32 = 0;
            while (x < self.size) : (x += 1) {
                const world_x = (@as(f32, @floatFromInt(x)) / size_f) * 40.0;
                const world_y = (@as(f32, @floatFromInt(y)) / size_f) * 40.0;

                var value: f32 = 0.0;

                // Sum wave sources
                for (sources) |src| {
                    const dx = world_x - src.x;
                    const dy = world_y - src.y;
                    const r = @sqrt(dx * dx + dy * dy);
                    value += src.amplitude * @sin(src.frequency * r) * @exp(-r / 15.0);
                }

                // Add fine structure
                value += 0.3 * @sin(world_x * 0.5) * @cos(world_y * 0.5);
                value += 0.2 * @sin(world_x * 0.8 + world_y * 0.8);

                const idx = @as(usize, @intCast(y * self.size + x));
                self.data[idx] = value;

                if (value < min_val) min_val = value;
                if (value > max_val) max_val = value;
            }
        }

        // Normalize to [-2, 2]
        const range = max_val - min_val;
        for (self.data) |*val| {
            val.* = ((val.* - min_val) / range) * 4.0 - 2.0;
        }

        std.debug.print("Substrate generation complete\n", .{});
    }

    fn colormapDisplacement(value: f32) rl.Color {
        // Normalize from [-2, 2] to [0, 1]
        var normalized = (value + 2.0) / 4.0;
        normalized = math.clamp(normalized, 0.0, 1.0);

        var r: u8 = 0;
        var g: u8 = 0;
        var b: u8 = 0;

        if (normalized < 0.5) {
            // Blue to white
            const t = normalized * 2.0;
            r = @intFromFloat(t * 255.0);
            g = @intFromFloat(t * 255.0);
            b = 255;
        } else {
            // White to red
            const t = (normalized - 0.5) * 2.0;
            r = 255;
            g = @intFromFloat((1.0 - t) * 255.0);
            b = @intFromFloat((1.0 - t) * 255.0);
        }

        return rl.Color{ .r = r, .g = g, .b = b, .a = 255 };
    }

    pub fn renderToTexture(self: *KSpaceSubstrate, view: ViewState, width: i32, height: i32, allocator: std.mem.Allocator) !rl.Image {
        const pixels = try allocator.alloc(rl.Color, @intCast(width * height));
        defer allocator.free(pixels);

        // Calculate world space view bounds
        const half_w = (@as(f32, @floatFromInt(width)) / 2.0) / view.zoom;
        const half_h = (@as(f32, @floatFromInt(height)) / 2.0) / view.zoom;

        const world_x_min = view.center_x - half_w;
        const world_x_max = view.center_x + half_w;
        const world_y_min = view.center_y - half_h;
        const world_y_max = view.center_y + half_h;

        // Map to substrate coordinates
        const size_f: f32 = @floatFromInt(self.size);
        const substrate_x_min = @as(i32, @intFromFloat((world_x_min / 40.0) * size_f));
        const substrate_x_max = @as(i32, @intFromFloat((world_x_max / 40.0) * size_f));
        const substrate_y_min = @as(i32, @intFromFloat((world_y_min / 40.0) * size_f));
        const substrate_y_max = @as(i32, @intFromFloat((world_y_max / 40.0) * size_f));

        // Render each pixel
        var sy: i32 = 0;
        while (sy < height) : (sy += 1) {
            var sx: i32 = 0;
            while (sx < width) : (sx += 1) {
                const t_x = @as(f32, @floatFromInt(sx)) / @as(f32, @floatFromInt(width));
                const t_y = @as(f32, @floatFromInt(sy)) / @as(f32, @floatFromInt(height));

                const sub_x_f = @as(f32, @floatFromInt(substrate_x_min)) + t_x * @as(f32, @floatFromInt(substrate_x_max - substrate_x_min));
                const sub_y_f = @as(f32, @floatFromInt(substrate_y_min)) + t_y * @as(f32, @floatFromInt(substrate_y_max - substrate_y_min));

                const sub_x = math.clamp(@as(i32, @intFromFloat(sub_x_f)), 0, self.size - 1);
                const sub_y = math.clamp(@as(i32, @intFromFloat(sub_y_f)), 0, self.size - 1);

                const idx = @as(usize, @intCast(sub_y * self.size + sub_x));
                const value = self.data[idx];

                const pixel_idx = @as(usize, @intCast(sy * width + sx));
                pixels[pixel_idx] = colormapDisplacement(value);
            }
        }

        // Create image
        const img = rl.Image{
            .data = pixels.ptr,
            .width = width,
            .height = height,
            .mipmaps = 1,
            .format = rl.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,
        };

        // Load image copy (raylib will manage memory)
        return rl.ImageCopy(img);
    }

    pub fn drawToScreen(self: *KSpaceSubstrate, view: ViewState, width: i32, height: i32) void {
        // Calculate world space view bounds
        const half_w = (@as(f32, @floatFromInt(width)) / 2.0) / view.zoom;
        const half_h = (@as(f32, @floatFromInt(height)) / 2.0) / view.zoom;

        const world_x_min = view.center_x - half_w;
        const world_x_max = view.center_x + half_w;
        const world_y_min = view.center_y - half_h;
        const world_y_max = view.center_y + half_h;

        // Map to substrate coordinates
        const size_f: f32 = @floatFromInt(self.size);
        const substrate_x_min = @as(i32, @intFromFloat((world_x_min / 40.0) * size_f));
        const substrate_x_max = @as(i32, @intFromFloat((world_x_max / 40.0) * size_f));
        const substrate_y_min = @as(i32, @intFromFloat((world_y_min / 40.0) * size_f));
        const substrate_y_max = @as(i32, @intFromFloat((world_y_max / 40.0) * size_f));

        // Draw pixels
        var sy: i32 = 0;
        while (sy < height) : (sy += 1) {
            var sx: i32 = 0;
            while (sx < width) : (sx += 1) {
                const t_x = @as(f32, @floatFromInt(sx)) / @as(f32, @floatFromInt(width));
                const t_y = @as(f32, @floatFromInt(sy)) / @as(f32, @floatFromInt(height));

                const sub_x_f = @as(f32, @floatFromInt(substrate_x_min)) + t_x * @as(f32, @floatFromInt(substrate_x_max - substrate_x_min));
                const sub_y_f = @as(f32, @floatFromInt(substrate_y_min)) + t_y * @as(f32, @floatFromInt(substrate_y_max - substrate_y_min));

                const sub_x = math.clamp(@as(i32, @intFromFloat(sub_x_f)), 0, self.size - 1);
                const sub_y = math.clamp(@as(i32, @intFromFloat(sub_y_f)), 0, self.size - 1);

                const idx = @as(usize, @intCast(sub_y * self.size + sub_x));
                const value = self.data[idx];

                const color = colormapDisplacement(value);
                rl.DrawPixel(sx, sy, color);
            }
        }
    }
};

fn findNextFilename(allocator: std.mem.Allocator) ![]const u8 {
    const prefix = "kspace_cymatic_substrate_";
    const ext = ".png";

    // Try to open current directory
    var dir = std.fs.cwd();

    var counter: u32 = 0;
    while (counter < 10000) : (counter += 1) {
        // Format filename
        const filename = try std.fmt.allocPrint(
            allocator,
            "{s}{d:0>4}{s}",
            .{ prefix, counter, ext },
        );
        defer allocator.free(filename);

        // Check if file exists
        const file = dir.openFile(filename, .{}) catch {
            // File doesn't exist, use this name
            return try std.fmt.allocPrint(
                allocator,
                "{s}{d:0>4}{s}",
                .{ prefix, counter, ext },
            );
        };
        file.close();
    }

    // Fallback if all 10000 slots taken
    return try std.fmt.allocPrint(
        allocator,
        "{s}9999{s}",
        .{ prefix, ext },
    );
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initial screen settings
    const initial_width: i32 = 1200;
    const initial_height: i32 = 900;

    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);
    rl.InitWindow(initial_width, initial_height, "K-Space Substrate Viewer");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    // Generate substrate (2048x2048 for high quality)
    var substrate = try KSpaceSubstrate.init(allocator, 2048);
    defer substrate.deinit();

    // View state
    var view = ViewState{};

    // Movement settings
    const pan_speed: f32 = 0.1;
    const zoom_speed: f32 = 1.05;

    while (!rl.WindowShouldClose()) {
        // Get current window dimensions
        const screen_width = rl.GetScreenWidth();
        const screen_height = rl.GetScreenHeight();

        // Handle input
        const dt = rl.GetFrameTime();
        const move_speed = (pan_speed * 60.0 * dt) / view.zoom;

        // Movement (smooth with delta time)
        if (rl.IsKeyDown(rl.KEY_LEFT) or rl.IsKeyDown(rl.KEY_A)) {
            view.center_x -= move_speed;
        }
        if (rl.IsKeyDown(rl.KEY_RIGHT) or rl.IsKeyDown(rl.KEY_D)) {
            view.center_x += move_speed;
        }
        if (rl.IsKeyDown(rl.KEY_UP) or rl.IsKeyDown(rl.KEY_W)) {
            view.center_y -= move_speed;
        }
        if (rl.IsKeyDown(rl.KEY_DOWN) or rl.IsKeyDown(rl.KEY_S)) {
            view.center_y += move_speed;
        }

        // Zoom
        if (rl.IsKeyDown(rl.KEY_EQUAL) or rl.IsKeyDown(rl.KEY_KP_ADD)) {
            view.zoom *= zoom_speed;
        }
        if (rl.IsKeyDown(rl.KEY_MINUS) or rl.IsKeyDown(rl.KEY_KP_SUBTRACT)) {
            view.zoom /= zoom_speed;
            view.zoom = @max(0.1, view.zoom);
        }

        // Reset
        if (rl.IsKeyPressed(rl.KEY_R)) {
            view = ViewState{};
        }

        // Save to PNG
        if (rl.IsKeyPressed(rl.KEY_SPACE)) {
            std.debug.print("Saving image...\n", .{});

            // Find next available filename
            const filename = try findNextFilename(allocator);
            defer allocator.free(filename);

            // Render current view to image
            const img = try substrate.renderToTexture(view, screen_width, screen_height, allocator);
            defer rl.UnloadImage(img);

            // Export as PNG
            const success = rl.ExportImage(img, filename.ptr);
            if (success) {
                std.debug.print("Saved: {s}\n", .{filename});
            } else {
                std.debug.print("Failed to save image\n", .{});
            }
        }

        // Clamp view
        view.center_x = math.clamp(view.center_x, 0.0, 40.0);
        view.center_y = math.clamp(view.center_y, 0.0, 40.0);

        // Render
        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.BLACK);

        // Draw substrate
        substrate.drawToScreen(view, screen_width, screen_height);

        // Draw UI overlay
        const fps = rl.GetFPS();
        var buffer: [256]u8 = undefined;

        const fps_text = std.fmt.bufPrintZ(&buffer, "FPS: {d}", .{fps}) catch "FPS: --";
        rl.DrawText(fps_text.ptr, 20, 20, 20, rl.WHITE);

        const zoom_text = std.fmt.bufPrintZ(&buffer, "Zoom: {d:.2}x", .{view.zoom}) catch "Zoom: --";
        rl.DrawText(zoom_text.ptr, 20, 45, 20, rl.WHITE);

        const pos_text = std.fmt.bufPrintZ(&buffer, "Pos: ({d:.1}, {d:.1})", .{ view.center_x, view.center_y }) catch "Pos: --";
        rl.DrawText(pos_text.ptr, 20, 70, 20, rl.WHITE);

        const size_text = std.fmt.bufPrintZ(&buffer, "Size: {d}x{d}", .{ screen_width, screen_height }) catch "Size: --";
        rl.DrawText(size_text.ptr, 20, 95, 20, rl.WHITE);

        rl.DrawText("Arrow/WASD: Move | +/-: Zoom | R: Reset | Space: Save PNG | ESC: Quit", 20, screen_height - 30, 20, rl.WHITE);
    }
}
