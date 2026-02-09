const std = @import("std");
const math = std.math;
const rl = @import("local_raylib.zig").rl;

const Physics = @import("physics.zig").Physics;
const KSpaceSubstrate = @import("kspace_substrate.zig").KSpaceSubstrate;
const PhysicsSolver = @import("physics_solver.zig").PhysicsSolver;

pub const Material = enum {
    stone,
    jello,
    mud,
    metal,
    glass,

    pub fn stiffness(self: Material) f32 {
        return switch (self) {
            .stone => 10.0, // Reduced from 50
            .jello => 0.5, // Reduced from 2
            .mud => 2.0, // Reduced from 10
            .metal => 20.0, // Reduced from 100
            .glass => 15.0, // Reduced from 80
        };
    }

    pub fn damping(self: Material) f32 {
        return switch (self) {
            .stone => 0.85,
            .jello => 0.98,
            .mud => 0.99,
            .metal => 0.8,
            .glass => 0.85,
        };
    }

    pub fn density(self: Material) f32 {
        return switch (self) {
            .stone => 2500.0,
            .jello => 1000.0,
            .mud => 1800.0,
            .metal => 7800.0,
            .glass => 2500.0,
        };
    }

    pub fn fracture_threshold(self: Material) f32 {
        return switch (self) {
            .stone => 15.0,
            .jello => 1000.0,
            .mud => 1000.0,
            .metal => 25.0,
            .glass => 8.0,
        };
    }

    pub fn getColor(self: Material) rl.Color {
        return switch (self) {
            .stone => rl.Color{ .r = 128, .g = 128, .b = 128, .a = 255 },
            .jello => rl.Color{ .r = 255, .g = 100, .b = 100, .a = 180 },
            .mud => rl.Color{ .r = 139, .g = 69, .b = 19, .a = 255 },
            .metal => rl.Color{ .r = 192, .g = 192, .b = 192, .a = 255 },
            .glass => rl.Color{ .r = 100, .g = 150, .b = 255, .a = 120 }, // Bright blue transparent
        };
    }
};

pub const Voxel = struct {
    position: [3]f32,
    velocity: [3]f32,
    rest_position: [3]f32,
    mass: f32,
    material: Material,
    active: bool,
    size: f32, // Physical size in meters

    pub fn applyForce(self: *Voxel, force: [3]f32, dt: f32) void {
        const accel = [3]f32{
            force[0] / self.mass,
            force[1] / self.mass,
            force[2] / self.mass,
        };

        self.velocity[0] += accel[0] * dt;
        self.velocity[1] += accel[1] * dt;
        self.velocity[2] += accel[2] * dt;
    }

    pub fn integrate(self: *Voxel, dt: f32, damping: f32) void {
        self.position[0] += self.velocity[0] * dt;
        self.position[1] += self.velocity[1] * dt;
        self.position[2] += self.velocity[2] * dt;

        self.velocity[0] *= damping;
        self.velocity[1] *= damping;
        self.velocity[2] *= damping;
    }
};

pub const SoftBody = struct {
    voxels: std.array_list.Managed(Voxel),
    material: Material,
    center_of_mass: [3]f32,
    is_player_controlled: bool,

    pub fn init(allocator: std.mem.Allocator, blocks: [4][3]i32, position: [3]f32, material: Material) !SoftBody {
        var voxels = std.array_list.Managed(Voxel).init(allocator);

        const block_size: f32 = 0.5; // Each block is still 0.5m
        const voxel_size: f32 = 0.25; // But subdivided into 0.25m voxels (2×2×2 = 8 voxels per block)
        const voxel_volume = voxel_size * voxel_size * voxel_size;
        const voxel_mass = material.density() * voxel_volume / 8.0; // Divide mass by 8

        // For each of the 4 blocks, create 2×2×2 = 8 voxels
        for (blocks) |block| {
            const block_origin = [3]f32{
                position[0] + @as(f32, @floatFromInt(block[0])) * block_size,
                position[1] + @as(f32, @floatFromInt(block[1])) * block_size,
                position[2] + @as(f32, @floatFromInt(block[2])) * block_size,
            };

            // Subdivide each block into 2×2×2 grid
            var ix: i32 = 0;
            while (ix < 2) : (ix += 1) {
                var iy: i32 = 0;
                while (iy < 2) : (iy += 1) {
                    var iz: i32 = 0;
                    while (iz < 2) : (iz += 1) {
                        const offset = [3]f32{
                            @as(f32, @floatFromInt(ix)) * voxel_size,
                            @as(f32, @floatFromInt(iy)) * voxel_size,
                            @as(f32, @floatFromInt(iz)) * voxel_size,
                        };

                        try voxels.append(Voxel{
                            .position = .{
                                block_origin[0] + offset[0],
                                block_origin[1] + offset[1],
                                block_origin[2] + offset[2],
                            },
                            .velocity = .{ 0, 0, 0 },
                            .rest_position = .{
                                @as(f32, @floatFromInt(block[0])) * block_size + offset[0],
                                @as(f32, @floatFromInt(block[1])) * block_size + offset[1],
                                @as(f32, @floatFromInt(block[2])) * block_size + offset[2],
                            },
                            .mass = voxel_mass,
                            .material = material,
                            .active = true,
                            .size = voxel_size,
                        });
                    }
                }
            }
        }

        return SoftBody{
            .voxels = voxels,
            .material = material,
            .center_of_mass = position,
            .is_player_controlled = true,
        };
    }

    pub fn updatePhysics(self: *SoftBody, dt: f32, gravity: f32, physics: *Physics) void {
        _ = physics;
        _ = gravity;

        const earth_gravity: f32 = 9.81;
        const stiff = self.material.stiffness();
        const damp = self.material.damping();

        const safe_dt = @min(dt, 0.016);

        // Apply gravity
        for (self.voxels.items) |*voxel| {
            if (!voxel.active) continue;
            voxel.applyForce(.{ 0, -earth_gravity * voxel.mass, 0 }, safe_dt);
        }

        // Spring forces between nearby voxels
        var i: usize = 0;
        while (i < self.voxels.items.len) : (i += 1) {
            if (!self.voxels.items[i].active) continue;

            var j: usize = i + 1;
            while (j < self.voxels.items.len) : (j += 1) {
                if (!self.voxels.items[j].active) continue;

                const v1 = &self.voxels.items[i];
                const v2 = &self.voxels.items[j];

                // Rest distance
                const dx_rest = v1.rest_position[0] - v2.rest_position[0];
                const dy_rest = v1.rest_position[1] - v2.rest_position[1];
                const dz_rest = v1.rest_position[2] - v2.rest_position[2];
                const rest_dist = @sqrt(dx_rest * dx_rest + dy_rest * dy_rest + dz_rest * dz_rest);

                // Only connect voxels that are close in rest state
                if (rest_dist > 0.5) continue; // Max 0.5m connection (neighboring voxels)
                if (rest_dist < 0.01) continue;

                // Current distance
                const dx = v1.position[0] - v2.position[0];
                const dy = v1.position[1] - v2.position[1];
                const dz = v1.position[2] - v2.position[2];
                const dist = @sqrt(dx * dx + dy * dy + dz * dz);

                if (dist < 0.05 or dist > 2.0) continue;

                // Spring force
                const displacement = dist - rest_dist;
                const max_displacement: f32 = 0.5;
                const clamped_displacement = std.math.clamp(displacement, -max_displacement, max_displacement);
                const force_mag = stiff * clamped_displacement;

                const max_force: f32 = 20.0;
                const clamped_force = std.math.clamp(force_mag, -max_force, max_force);

                const force = [3]f32{
                    (dx / dist) * clamped_force,
                    (dy / dist) * clamped_force,
                    (dz / dist) * clamped_force,
                };

                v1.applyForce(.{ -force[0], -force[1], -force[2] }, safe_dt);
                v2.applyForce(.{ force[0], force[1], force[2] }, safe_dt);
            }
        }

        // Integrate
        for (self.voxels.items) |*voxel| {
            if (!voxel.active) continue;
            voxel.integrate(safe_dt, damp);

            const max_velocity: f32 = 20.0;
            voxel.velocity[0] = std.math.clamp(voxel.velocity[0], -max_velocity, max_velocity);
            voxel.velocity[1] = std.math.clamp(voxel.velocity[1], -max_velocity, max_velocity);
            voxel.velocity[2] = std.math.clamp(voxel.velocity[2], -max_velocity, max_velocity);

            // NaN check
            if (std.math.isNan(voxel.position[0]) or
                std.math.isNan(voxel.position[1]) or
                std.math.isNan(voxel.position[2]))
            {
                voxel.position = .{ 5, 10, 5 };
                voxel.velocity = .{ 0, 0, 0 };
                voxel.active = false;
            }
        }

        self.updateCenterOfMass();
    }

    pub fn handleCollisions(self: *SoftBody, floor_y: f32) void {
        for (self.voxels.items) |*voxel| {
            if (!voxel.active) continue;

            // Floor collision
            if (voxel.position[1] < floor_y) {
                voxel.position[1] = floor_y;
                voxel.velocity[1] = -voxel.velocity[1] * 0.5; // Bounce with energy loss

                // Friction
                voxel.velocity[0] *= 0.9;
                voxel.velocity[2] *= 0.9;
            }

            // Wall collisions
            if (voxel.position[0] < 0) {
                voxel.position[0] = 0;
                voxel.velocity[0] = -voxel.velocity[0] * 0.5;
            }
            if (voxel.position[0] > 10) {
                voxel.position[0] = 10;
                voxel.velocity[0] = -voxel.velocity[0] * 0.5;
            }
            if (voxel.position[2] < 0) {
                voxel.position[2] = 0;
                voxel.velocity[2] = -voxel.velocity[2] * 0.5;
            }
            if (voxel.position[2] > 10) {
                voxel.position[2] = 10;
                voxel.velocity[2] = -voxel.velocity[2] * 0.5;
            }
        }
    }

    pub fn checkFracture(self: *SoftBody, physics: *Physics) bool {
        _ = physics;
        const threshold = self.material.fracture_threshold();

        // Check if any voxel is under too much stress
        for (self.voxels.items) |*voxel| {
            if (!voxel.active) continue;

            const speed_sq = voxel.velocity[0] * voxel.velocity[0] +
                voxel.velocity[1] * voxel.velocity[1] +
                voxel.velocity[2] * voxel.velocity[2];

            if (speed_sq > threshold * threshold) {
                return true;
            }
        }

        return false;
    }

    pub fn fracture(self: *SoftBody) void {
        // Simple fracture: disable random voxels
        for (self.voxels.items) |*voxel| {
            if (rl.GetRandomValue(0, 3) == 0) {
                voxel.active = false;
            }
        }
    }

    fn updateCenterOfMass(self: *SoftBody) void {
        var sum_x: f32 = 0;
        var sum_y: f32 = 0;
        var sum_z: f32 = 0;
        var count: f32 = 0;

        for (self.voxels.items) |voxel| {
            if (!voxel.active) continue;
            sum_x += voxel.position[0];
            sum_y += voxel.position[1];
            sum_z += voxel.position[2];
            count += 1;
        }

        if (count > 0) {
            self.center_of_mass = .{
                sum_x / count,
                sum_y / count,
                sum_z / count,
            };
        }
    }

    pub fn applyPlayerControl(self: *SoftBody, force: [3]f32) void {
        if (!self.is_player_controlled) return;

        for (self.voxels.items) |*voxel| {
            if (!voxel.active) continue;
            voxel.velocity[0] += force[0];
            voxel.velocity[1] += force[1];
            voxel.velocity[2] += force[2];
        }
    }
};

pub const Tautris = struct {
    bodies: std.array_list.Managed(SoftBody),
    current_body: ?usize,
    spawn_timer: f32,
    spawn_interval: f32,
    max_spawn_time: f32,
    allocator: std.mem.Allocator,
    score: u32,
    solver: PhysicsSolver, // Add this

    pub fn handleInput(self: *Tautris) void {
        if (self.current_body) |idx| {
            var force = [3]f32{ 0, 0, 0 };
            const control_strength: f32 = 2.0; // Newtons of force

            if (rl.IsKeyDown(rl.KEY_A) or rl.IsKeyDown(rl.KEY_LEFT)) {
                force[0] = -control_strength;
            }
            if (rl.IsKeyDown(rl.KEY_D) or rl.IsKeyDown(rl.KEY_RIGHT)) {
                force[0] = control_strength;
            }
            if (rl.IsKeyDown(rl.KEY_W) or rl.IsKeyDown(rl.KEY_UP)) {
                force[2] = -control_strength;
            }
            if (rl.IsKeyDown(rl.KEY_S)) {
                force[2] = control_strength;
            }
            if (rl.IsKeyDown(rl.KEY_DOWN)) {
                force[1] = -control_strength * 3;
            }

            self.bodies.items[idx].applyPlayerControl(force);
        }
    }

    fn spawnPiece(self: *Tautris) !void {
        const pieces = [_][4][3]i32{
            .{ .{ 0, 0, 0 }, .{ 1, 0, 0 }, .{ 2, 0, 0 }, .{ 3, 0, 0 } }, // I
            .{ .{ 0, 0, 0 }, .{ 1, 0, 0 }, .{ 0, 0, 1 }, .{ 1, 0, 1 } }, // O
            .{ .{ 0, 0, 0 }, .{ 1, 0, 0 }, .{ 2, 0, 0 }, .{ 1, 0, 1 } }, // T
            .{ .{ 1, 0, 0 }, .{ 2, 0, 0 }, .{ 0, 0, 1 }, .{ 1, 0, 1 } }, // S
        };

        const materials = [_]Material{ .stone, .jello, .mud, .metal, .glass };

        const piece_idx = @mod(@as(usize, @intCast(rl.GetRandomValue(0, 100))), pieces.len);
        const mat_idx = @mod(@as(usize, @intCast(rl.GetRandomValue(0, 100))), materials.len);

        const body = try SoftBody.init(
            self.allocator,
            pieces[piece_idx],
            .{ 5.0, 18.0, 5.0 }, // Spawn at center, high up
            materials[mat_idx],
        );

        // No initial velocity - let gravity do the work
        for (body.voxels.items) |*voxel| {
            voxel.velocity = .{ 0, 0, 0 };
        }

        try self.bodies.append(body);
        self.current_body = self.bodies.items.len - 1;
        self.spawn_timer = 0;
    }

    fn getBodyVelocitySquared(self: *Tautris, idx: usize) f32 {
        var sum: f32 = 0;
        var count: f32 = 0;
        for (self.bodies.items[idx].voxels.items) |voxel| {
            if (!voxel.active) continue;
            sum += voxel.velocity[0] * voxel.velocity[0] +
                voxel.velocity[1] * voxel.velocity[1] +
                voxel.velocity[2] * voxel.velocity[2];
            count += 1;
        }
        if (count == 0) return 0;
        return sum / count;
    }

    pub fn updateSubstrateCoupling(self: *Tautris, substrate: *KSpaceSubstrate, physics: *Physics) void {
        const scale = @as(f32, @floatCast(physics.holographic_scale() * 50.0));

        for (self.bodies.items) |*body| {
            for (body.voxels.items) |voxel| {
                if (!voxel.active) continue;

                const kx = @as(i32, @intFromFloat(voxel.position[0] * scale));
                const ky = @as(i32, @intFromFloat(voxel.position[2] * scale));

                if (kx >= 0 and kx < substrate.size and ky >= 0 and ky < substrate.size) {
                    const idx = @as(usize, @intCast(ky * substrate.size + kx));

                    const speed = @sqrt(voxel.velocity[0] * voxel.velocity[0] +
                        voxel.velocity[1] * voxel.velocity[1] +
                        voxel.velocity[2] * voxel.velocity[2]);
                    substrate.data[idx] += speed * 0.002;
                }
            }
        }
    }

    pub fn updatePhysics(self: *SoftBody, dt: f32, gravity: f32, physics: *Physics) void {
        _ = physics;
        _ = gravity;

        const earth_gravity: f32 = 9.81;
        const stiff = self.material.stiffness();
        const damp = self.material.damping();

        const safe_dt = @min(dt, 0.016);

        // Apply gravity
        for (self.voxels.items) |*voxel| {
            if (!voxel.active) continue;
            voxel.applyForce(.{ 0, -earth_gravity * voxel.mass, 0 }, safe_dt);
        }

        // Internal voxel-voxel repulsion (prevent collapse)
        var i: usize = 0;
        while (i < self.voxels.items.len) : (i += 1) {
            if (!self.voxels.items[i].active) continue;

            var j: usize = i + 1;
            while (j < self.voxels.items.len) : (j += 1) {
                if (!self.voxels.items[j].active) continue;

                const v1 = &self.voxels.items[i];
                const v2 = &self.voxels.items[j];

                const dx = v1.position[0] - v2.position[0];
                const dy = v1.position[1] - v2.position[1];
                const dz = v1.position[2] - v2.position[2];
                const dist = @sqrt(dx * dx + dy * dy + dz * dz);

                // CRITICAL: Hard repulsion if too close
                const min_dist = (v1.size + v2.size) * 0.4;
                if (dist < min_dist and dist > 0.001) {
                    const overlap = min_dist - dist;
                    const push = overlap / dist * 0.5;

                    v1.position[0] += dx * push;
                    v1.position[1] += dy * push;
                    v1.position[2] += dz * push;

                    v2.position[0] -= dx * push;
                    v2.position[1] -= dy * push;
                    v2.position[2] -= dz * push;

                    continue; // Skip spring if repelling
                }

                // Rest distance
                const dx_rest = v1.rest_position[0] - v2.rest_position[0];
                const dy_rest = v1.rest_position[1] - v2.rest_position[1];
                const dz_rest = v1.rest_position[2] - v2.rest_position[2];
                const rest_dist = @sqrt(dx_rest * dx_rest + dy_rest * dy_rest + dz_rest * dz_rest);

                if (rest_dist < 0.01) continue;
                if (dist < 0.1 or dist > 5.0) continue; // Skip if too close or too far

                // Spring force
                const displacement = dist - rest_dist;
                const max_displacement: f32 = 1.0;
                const clamped_displacement = std.math.clamp(displacement, -max_displacement, max_displacement);
                const force_mag = stiff * clamped_displacement;

                const max_force: f32 = 50.0;
                const clamped_force = std.math.clamp(force_mag, -max_force, max_force);

                const force = [3]f32{
                    (dx / dist) * clamped_force,
                    (dy / dist) * clamped_force,
                    (dz / dist) * clamped_force,
                };

                v1.applyForce(.{ -force[0], -force[1], -force[2] }, safe_dt);
                v2.applyForce(.{ force[0], force[1], force[2] }, safe_dt);
            }
        }

        // Integrate
        for (self.voxels.items) |*voxel| {
            if (!voxel.active) continue;
            voxel.integrate(safe_dt, damp);

            const max_velocity: f32 = 20.0; // Reduced from 50
            voxel.velocity[0] = std.math.clamp(voxel.velocity[0], -max_velocity, max_velocity);
            voxel.velocity[1] = std.math.clamp(voxel.velocity[1], -max_velocity, max_velocity);
            voxel.velocity[2] = std.math.clamp(voxel.velocity[2], -max_velocity, max_velocity);

            // NaN check
            if (std.math.isNan(voxel.position[0]) or
                std.math.isNan(voxel.position[1]) or
                std.math.isNan(voxel.position[2]))
            {
                voxel.position = .{ 5, 10, 5 };
                voxel.velocity = .{ 0, 0, 0 };
                voxel.active = false;
            }
        }

        self.updateCenterOfMass();
    }

    pub fn init(allocator: std.mem.Allocator) !Tautris {
        var tautris = Tautris{
            .bodies = std.array_list.Managed(SoftBody).init(allocator),
            .current_body = null,
            .spawn_timer = 0,
            .spawn_interval = 3.0,
            .max_spawn_time = 5.0,
            .allocator = allocator,
            .score = 0,
            .solver = PhysicsSolver.init(allocator),
        };

        try tautris.spawnPiece();

        return tautris;
    }

    pub fn deinit(self: *Tautris) void {
        self.solver.deinit();
    }

    pub fn update(self: *Tautris, dt: f32, physics: *Physics) void {
        // Update all bodies
        for (self.bodies.items) |*body| {
            body.updatePhysics(dt, 0, physics);

            if (body.checkFracture(physics)) {
                body.fracture();
            }
        }

        // Detect all contacts
        self.solver.detectContacts(self) catch {};

        // Solve contacts iteratively (like Box2D)
        self.solver.solveContacts(10);

        // Check if current piece has settled
        if (self.current_body) |idx| {
            const settled = self.bodies.items[idx].center_of_mass[1] < 0.5 and
                self.getBodyVelocitySquared(idx) < 0.5;

            const timeout = self.spawn_timer >= self.max_spawn_time;

            if (settled or timeout) {
                self.bodies.items[idx].is_player_controlled = false;
                self.spawn_timer = 0;
                self.current_body = null;
            }
        }

        // Spawn new piece
        if (self.current_body == null) {
            self.spawn_timer += dt;
            if (self.spawn_timer >= 0.5) {
                self.spawnPiece() catch {};
            }
        } else {
            self.spawn_timer += dt;
        }
    }
};
