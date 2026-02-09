const std = @import("std");
const rl = @import("local_raylib.zig").rl;
const Physics = @import("physics.zig").Physics;
const Tautris = @import("tautris.zig").Tautris;
const math = std.math;

pub const UI = struct {
    n_slider_value: f32,

    pub fn init() UI {
        return UI{
            .n_slider_value = 60.0,
        };
    }

    pub fn update(self: *UI, physics: *Physics) void {
        if (rl.IsKeyDown(rl.KEY_N)) {
            const wheel = rl.GetMouseWheelMove();
            self.n_slider_value += wheel * 0.5;
            self.n_slider_value = math.clamp(self.n_slider_value, 50.0, 70.0);
        }

        physics.N = math.pow(f64, 10.0, self.n_slider_value);
    }

    pub fn render(
        self: *UI,
        physics: *Physics,
        tautris: *Tautris,
        mode: anytype,
    ) void {
        var buffer: [256]u8 = undefined;

        var text = std.fmt.bufPrintZ(&buffer, "N = 10^{d:.1}", .{self.n_slider_value}) catch "N";
        rl.DrawText(text.ptr, 10, 10, 20, rl.LIME);

        text = std.fmt.bufPrintZ(&buffer, "α⁻¹ = {d:.3}", .{physics.alpha_em_inv()}) catch "α";
        rl.DrawText(text.ptr, 10, 35, 18, rl.WHITE);

        text = std.fmt.bufPrintZ(&buffer, "Bodies: {d}", .{tautris.bodies.items.len}) catch "Bodies";
        rl.DrawText(text.ptr, 10, 60, 18, rl.WHITE);

        text = std.fmt.bufPrintZ(&buffer, "Score: {d}", .{tautris.score}) catch "Score";
        rl.DrawText(text.ptr, 10, 85, 20, rl.YELLOW);

        const mode_text = if (mode == .kspace) "K-SPACE" else "X-SPACE";
        rl.DrawText(mode_text, 10, 120, 24, rl.ORANGE);

        const help_y = rl.GetScreenHeight() - 140;
        rl.DrawText("Soft-Body Physics Simulation", 10, help_y, 18, rl.LIGHTGRAY);
        rl.DrawText("WASD/Arrows: Apply force", 10, help_y + 25, 16, rl.GRAY);
        rl.DrawText("Down: Drop faster", 10, help_y + 45, 16, rl.GRAY);
        rl.DrawText("TAB: K/X mode | P: Pause", 10, help_y + 65, 16, rl.GRAY);
        rl.DrawText("N+Wheel: Adjust physics", 10, help_y + 85, 16, rl.GRAY);
        rl.DrawText("Space: Screenshot | F1: UI", 10, help_y + 105, 16, rl.GRAY);
    }
};
