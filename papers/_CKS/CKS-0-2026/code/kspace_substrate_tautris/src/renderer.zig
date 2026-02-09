const std = @import("std");
const rl = @import("local_raylib.zig").rl;
const math = std.math;
const KSpaceSubstrate = @import("kspace_substrate.zig").KSpaceSubstrate;
const Physics = @import("physics.zig").Physics;
const Tautris = @import("tautris.zig").Tautris;

pub const Renderer = struct {
    camera: rl.Camera3D,

    pub fn init() Renderer {
        return Renderer{
            .camera = rl.Camera3D{
                .position = .{ .x = 15, .y = 25, .z = 15 },
                .target = .{ .x = 5, .y = 10, .z = 5 },
                .up = .{ .x = 0, .y = 1, .z = 0 },
                .fovy = 45,
                .projection = rl.CAMERA_PERSPECTIVE,
            },
        };
    }

    pub fn renderKSpace(self: *Renderer, substrate: *KSpaceSubstrate, x: i32, y: i32, width: i32, height: i32) void {
        _ = self;

        const sx_step = @max(1, @divFloor(substrate.size, width));
        const sy_step = @max(1, @divFloor(substrate.size, height));

        var py: i32 = 0;
        while (py < height) : (py += 1) {
            var px: i32 = 0;
            while (px < width) : (px += 1) {
                const sx = @min(px * sx_step, substrate.size - 1);
                const sy = @min(py * sy_step, substrate.size - 1);

                const value = substrate.getValue(sx, sy);
                const color = colormapDisplacement(value);
                rl.DrawPixel(x + px, y + py, color);
            }
        }
    }

    pub fn renderTautris3D(self: *Renderer, tautris: *Tautris, physics: *Physics, x: i32, y: i32, width: i32, height: i32) void {
        _ = physics;

        rl.BeginScissorMode(x, y, width, height);
        defer rl.EndScissorMode();

        rl.BeginMode3D(self.camera);
        defer rl.EndMode3D();

        // Draw grid
        rl.DrawGrid(20, 1.0);

        // Draw bounds
        rl.DrawCubeWires(
            rl.Vector3{ .x = 5, .y = 10, .z = 5 },
            10,
            20,
            10,
            rl.WHITE,
        );

        // Draw all soft bodies
        for (tautris.bodies.items) |*body| {
            const color = body.material.getColor();

            for (body.voxels.items) |voxel| {
                if (!voxel.active) continue;

                const pos = rl.Vector3{
                    .x = voxel.position[0],
                    .y = voxel.position[1],
                    .z = voxel.position[2],
                };

                // Always draw filled cube
                const size = voxel.size * 0.95; // Slightly smaller for gap
                rl.DrawCube(pos, size, size, size, color);

                // Dark wireframe for definition
                rl.DrawCubeWires(pos, voxel.size, voxel.size, voxel.size, rl.Color{ .r = 0, .g = 0, .b = 0, .a = 100 });
            }

            // Draw springs only for player-controlled piece
            if (body.is_player_controlled) {
                for (body.voxels.items, 0..) |v1, i| {
                    if (!v1.active) continue;
                    for (body.voxels.items[i + 1 ..]) |v2| {
                        if (!v2.active) continue;

                        const dx = v1.position[0] - v2.position[0];
                        const dy = v1.position[1] - v2.position[1];
                        const dz = v1.position[2] - v2.position[2];
                        const dist = @sqrt(dx * dx + dy * dy + dz * dz);

                        if (dist < 2.0) { // Only draw nearby connections
                            rl.DrawLine3D(
                                rl.Vector3{ .x = v1.position[0], .y = v1.position[1], .z = v1.position[2] },
                                rl.Vector3{ .x = v2.position[0], .y = v2.position[1], .z = v2.position[2] },
                                rl.Color{ .r = 255, .g = 255, .b = 0, .a = 150 },
                            );
                        }
                    }
                }
            }
        }
    }

    pub fn renderXSpace(self: *Renderer, substrate: *KSpaceSubstrate, physics: *Physics, x: i32, y: i32, width: i32, height: i32) void {
        _ = self;
        _ = physics;

        const sx_step = @max(1, @divFloor(substrate.size, width));
        const sy_step = @max(1, @divFloor(substrate.size, height));

        var py: i32 = 0;
        while (py < height) : (py += 1) {
            var px: i32 = 0;
            while (px < width) : (px += 1) {
                const sx = @min(px * sx_step, substrate.size - 1);
                const sy = @min(py * sy_step, substrate.size - 1);

                const value = substrate.getValue(sx, sy);
                const color = colormapXSpace(value);
                rl.DrawPixel(x + px, y + py, color);
            }
        }
    }

    fn colormapDisplacement(value: f32) rl.Color {
        var normalized = (value + 2.0) / 4.0;
        normalized = math.clamp(normalized, 0.0, 1.0);

        if (normalized < 0.5) {
            const t = normalized * 2.0;
            return rl.Color{
                .r = @intFromFloat(t * 255.0),
                .g = @intFromFloat(t * 255.0),
                .b = 255,
                .a = 255,
            };
        } else {
            const t = (normalized - 0.5) * 2.0;
            return rl.Color{
                .r = 255,
                .g = @intFromFloat((1.0 - t) * 255.0),
                .b = @intFromFloat((1.0 - t) * 255.0),
                .a = 255,
            };
        }
    }

    fn colormapXSpace(value: f32) rl.Color {
        var normalized = (value + 2.0) / 4.0;
        normalized = math.clamp(normalized, 0.0, 1.0);

        const r: u8 = @intFromFloat(normalized * 255.0);
        return rl.Color{ .r = r, .g = r, .b = r, .a = 255 };
    }
};
