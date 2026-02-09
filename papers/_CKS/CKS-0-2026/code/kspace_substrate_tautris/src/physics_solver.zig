const std = @import("std");
const math = std.math;
const Tautris = @import("tautris.zig");
const Voxel = Tautris.Voxel;

pub const Contact = struct {
    voxel_a: *Voxel,
    voxel_b: ?*Voxel, // null if contacting floor
    normal: [3]f32,
    penetration: f32,
    friction: f32,
};

pub const PhysicsSolver = struct {
    contacts: std.array_list.Managed(Contact),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) PhysicsSolver {
        return PhysicsSolver{
            .contacts = std.array_list.Managed(Contact).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *PhysicsSolver) void {
        self.contacts.deinit();
    }

    fn detectBodyContacts(self: *PhysicsSolver, body_a: *Tautris.SoftBody, body_b: *Tautris.SoftBody) !void {
        for (body_a.voxels.items) |*voxel_a| {
            if (!voxel_a.active) continue;

            for (body_b.voxels.items) |*voxel_b| {
                if (!voxel_b.active) continue;

                const dx = voxel_a.position[0] - voxel_b.position[0];
                const dy = voxel_a.position[1] - voxel_b.position[1];
                const dz = voxel_a.position[2] - voxel_b.position[2];
                const dist_sq = dx * dx + dy * dy + dz * dz;

                const contact_dist = (voxel_a.size + voxel_b.size) * 0.5;
                const contact_dist_sq = contact_dist * contact_dist;

                if (dist_sq < contact_dist_sq and dist_sq > 0.0001) {
                    const dist = @sqrt(dist_sq);
                    const penetration = contact_dist - dist;

                    try self.contacts.append(Contact{
                        .voxel_a = voxel_a,
                        .voxel_b = voxel_b,
                        .normal = .{ dx / dist, dy / dist, dz / dist },
                        .penetration = penetration,
                        .friction = 0.5,
                    });
                }
            }
        }
    }

    pub fn solveContacts(self: *PhysicsSolver, iterations: u32) void {
        // Sequential impulse solver (like Box2D)
        var iter: u32 = 0;
        while (iter < iterations) : (iter += 1) {
            for (self.contacts.items) |*contact| {
                self.solveContact(contact);
            }
        }
    }

    pub fn detectContacts(self: *PhysicsSolver, tautris: *Tautris.Tautris) !void {
        self.contacts.clearRetainingCapacity();

        // Voxel-voxel contacts (all bodies)
        var i: usize = 0;
        while (i < tautris.bodies.items.len) : (i += 1) {
            var j: usize = i + 1;
            while (j < tautris.bodies.items.len) : (j += 1) {
                try self.detectBodyContacts(
                    &tautris.bodies.items[i],
                    &tautris.bodies.items[j],
                );
            }
        }

        // Voxel-floor contacts with continuous detection
        for (tautris.bodies.items) |*body| {
            for (body.voxels.items) |*voxel| {
                if (!voxel.active) continue;

                const half_size = voxel.size * 0.5;
                const bottom_y = voxel.position[1] - half_size;

                // Check if below or very close to floor
                if (bottom_y < 0.05) {
                    const penetration = -bottom_y;

                    try self.contacts.append(Contact{
                        .voxel_a = voxel,
                        .voxel_b = null,
                        .normal = .{ 0, 1, 0 },
                        .penetration = @max(penetration, 0.001), // Always some penetration
                        .friction = 0.7,
                    });
                }
            }
        }
    }

    fn solveContact(self: *PhysicsSolver, contact: *Contact) void {
        _ = self;

        const restitution: f32 = 0.3;

        if (contact.voxel_b) |voxel_b| {
            // Voxel-voxel contact (unchanged)
            const inv_mass_a = 1.0 / contact.voxel_a.mass;
            const inv_mass_b = 1.0 / voxel_b.mass;
            const total_inv_mass = inv_mass_a + inv_mass_b;

            // Stronger position correction
            const correction_factor: f32 = 0.4; // Increased from 0.2
            const slop: f32 = 0.005; // Smaller slop
            const correction = @max(contact.penetration - slop, 0.0) * correction_factor;

            const correction_a = correction * inv_mass_a / total_inv_mass;
            const correction_b = correction * inv_mass_b / total_inv_mass;

            contact.voxel_a.position[0] += contact.normal[0] * correction_a;
            contact.voxel_a.position[1] += contact.normal[1] * correction_a;
            contact.voxel_a.position[2] += contact.normal[2] * correction_a;

            voxel_b.position[0] -= contact.normal[0] * correction_b;
            voxel_b.position[1] -= contact.normal[1] * correction_b;
            voxel_b.position[2] -= contact.normal[2] * correction_b;

            const rel_vel = [3]f32{
                contact.voxel_a.velocity[0] - voxel_b.velocity[0],
                contact.voxel_a.velocity[1] - voxel_b.velocity[1],
                contact.voxel_a.velocity[2] - voxel_b.velocity[2],
            };

            const vel_along_normal = rel_vel[0] * contact.normal[0] +
                rel_vel[1] * contact.normal[1] +
                rel_vel[2] * contact.normal[2];

            if (vel_along_normal > 0) return;

            const j = -(1.0 + restitution) * vel_along_normal / total_inv_mass;

            const impulse = [3]f32{
                contact.normal[0] * j,
                contact.normal[1] * j,
                contact.normal[2] * j,
            };

            contact.voxel_a.velocity[0] += impulse[0] * inv_mass_a;
            contact.voxel_a.velocity[1] += impulse[1] * inv_mass_a;
            contact.voxel_a.velocity[2] += impulse[2] * inv_mass_a;

            voxel_b.velocity[0] -= impulse[0] * inv_mass_b;
            voxel_b.velocity[1] -= impulse[1] * inv_mass_b;
            voxel_b.velocity[2] -= impulse[2] * inv_mass_b;

            // Friction (unchanged)
            const tangent_vel = [3]f32{
                rel_vel[0] - contact.normal[0] * vel_along_normal,
                rel_vel[1] - contact.normal[1] * vel_along_normal,
                rel_vel[2] - contact.normal[2] * vel_along_normal,
            };

            const tangent_speed = @sqrt(tangent_vel[0] * tangent_vel[0] +
                tangent_vel[1] * tangent_vel[1] +
                tangent_vel[2] * tangent_vel[2]);

            if (tangent_speed > 0.0001) {
                const tangent = [3]f32{
                    tangent_vel[0] / tangent_speed,
                    tangent_vel[1] / tangent_speed,
                    tangent_vel[2] / tangent_speed,
                };

                const jt = -tangent_speed / total_inv_mass * contact.friction;

                const friction_impulse = [3]f32{
                    tangent[0] * jt,
                    tangent[1] * jt,
                    tangent[2] * jt,
                };

                contact.voxel_a.velocity[0] += friction_impulse[0] * inv_mass_a;
                contact.voxel_a.velocity[1] += friction_impulse[1] * inv_mass_a;
                contact.voxel_a.velocity[2] += friction_impulse[2] * inv_mass_a;

                voxel_b.velocity[0] -= friction_impulse[0] * inv_mass_b;
                voxel_b.velocity[1] -= friction_impulse[1] * inv_mass_b;
                voxel_b.velocity[2] -= friction_impulse[2] * inv_mass_b;
            }
        } else {
            // Voxel-floor contact - STRONG correction
            const half_size = contact.voxel_a.size * 0.5;

            // Hard constraint: never go below floor
            if (contact.voxel_a.position[1] < half_size) {
                contact.voxel_a.position[1] = half_size;
            }

            // Velocity impulse
            const vel_y = contact.voxel_a.velocity[1];

            if (vel_y < 0) {
                contact.voxel_a.velocity[1] = -vel_y * restitution;

                // Kill bounce if too small
                if (@abs(contact.voxel_a.velocity[1]) < 0.2) {
                    contact.voxel_a.velocity[1] = 0;
                }
            }

            // Friction
            contact.voxel_a.velocity[0] *= (1.0 - contact.friction * 0.5);
            contact.voxel_a.velocity[2] *= (1.0 - contact.friction * 0.5);
        }
    }
};
