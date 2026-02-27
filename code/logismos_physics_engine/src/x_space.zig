const std = @import("std");
const kspace = @import("k_space.zig");

// X-Space Rendering Opcodes (0x40 - 0x4F)
// Instructions for the Perceptual Display Driver.
pub const RenderOpcode = enum(i32) {
    BUFFER_PUSH = 0x40, // Ingest K-Space verified ledger
    BUFFER_POP = 0x41, // Release data after 15.19ms lag
    BILATERAL_SUM = 0x42, // Overlay Side A and Side B
    HEX_TO_XYZ = 0x43, // Translate dipoles to Cartesian space
    ALPHA_BLEND = 0x44, // Calculate transparency based on R-tension
};

// Simple Cartesian Coordinate for X-Space Projection.
pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

// The Perceptual Identity of a Soliton.
// This represents the "Holographic Projection" seen by an observer.
pub const HolographicSoliton = struct {
    // Identity Link
    k_id: u64,
    category: kspace.SolitonDensityCategory,

    // Perceptual Geometry
    world_pos: Vec3,
    visual_mass: f32, // Combined (Va + Vb)
    vibrational_r: f32, // Combined (Ra + Rb) - The "Glow" or "Jitter"

    // Perceptual UI Qualities
    opacity: f32, // 1.0 = Word-locked, < 1.0 = Dark Matter/Frustrated
    motion_blur: Vec3, // Derived from the 12-bit Kinetic Footer
};

// A stored state of the K-Verse ledger, waiting for its Render-Deadline.
pub const LedgerSnapshot = struct {
    commit_n: u64, // The N-tick when this was verified in K-Space
    render_n: u64, // The N-tick + 15.19ms Offset
    // Store the processed summaries, not the raw hardware
    solitons: []HolographicSoliton,
};

// The X-Space Engine (The Renderer)
// This operates at the Speed of Light (c), limited by the 15.19ms parity check.
pub const XSpaceEngine = struct {
    allocator: std.mem.Allocator,

    // Temporal Queue (The 15.19ms Pipeline)
    render_buffer: std.array_list.Managed(LedgerSnapshot),

    // Universal Constant for the Parity-Check Lag (RAID 1 Delay)
    pub const RENDER_LAG_TICKS: u64 = 64; // Approx 15.19ms at 0.237ms per tick

    pub fn init(allocator: std.mem.Allocator) XSpaceEngine {
        return .{
            .allocator = allocator,
            .render_buffer = std.array_list.Managed(LedgerSnapshot).init(allocator),
        };
    }

    // RECEIVE: Ingests the pre-flattened Holographic summaries.
    pub fn pushKSpaceLedger(self: *XSpaceEngine, current_n: u64, h_solitons: []HolographicSoliton) !void {
        const dynamic_lag = calculateRenderLag(current_n);

        const snapshot = LedgerSnapshot{
            .commit_n = current_n,
            .render_n = current_n + dynamic_lag,
            .solitons = h_solitons,
        };
        try self.render_buffer.append(snapshot);
    }

    // PROCESS: Checks the buffer and renders frames that have hit their deadline.
    pub fn update(self: *XSpaceEngine, current_n: u64) ?[]HolographicSoliton {
        if (self.render_buffer.items.len == 0) return null;

        const next_up = self.render_buffer.items[0];
        if (current_n >= next_up.render_n) {
            const snapshot = self.render_buffer.orderedRemove(0);
            defer self.allocator.free(snapshot.solitons);
            return self.renderFrame(snapshot);
        }

        return null;
    }

    /// RENDER: Releases the pre-flattened Soliton data to the HUD/Screen.
    /// This function executes at Light Speed (c) once the 15.19ms lag expires.
    fn renderFrame(self: *XSpaceEngine, snapshot: LedgerSnapshot) []HolographicSoliton {
        // 1. Prepare the output slice
        // In this updated architecture, the K-Engine already provided
        // the pre-calculated summaries (V-sum, R-sum, Pos, Blur).
        var frame_objects = std.array_list.Managed(HolographicSoliton).init(self.allocator);

        // 2. RELEASE THE SNAPSHOT
        // We iterate over the pre-flattened summaries that have been
        // waiting in the RAID 1 parity buffer.
        for (snapshot.solitons) |h_soliton| {
            // We can apply final 'Screen-Space' post-processing here.
            // For example: Tone mapping based on Universal Impedance.

            var finalized_soliton = h_soliton;

            // APPLY RENDER-SPECIFIC JITTER
            // The 15.19ms lag creates a 'flicker' Fusion.
            // If the vibrational_r is high, we jitter the world position slightly.
            if (h_soliton.vibrational_r > 16.0) {
                finalized_soliton.world_pos.x += 0.05; // Sub-pixel jitter
            }

            // 3. COMMIT TO FRAME
            frame_objects.append(finalized_soliton) catch unreachable;
        }

        // 4. HANDOVER
        // Returns the collection of objects for the X-Space GPU implementation.
        return frame_objects.toOwnedSlice() catch unreachable;
    }

    /// GU v10: The Dynamic Jacobian Function
    /// Derives the 15.19ms render lag based on the growth of N.
    /// As the registry N grows, the complexity of the global sync increases.
    pub fn calculateRenderLag(current_n: u64) u64 {
        // Base J is 64 ticks (15.19ms) at the current epoch.
        // We add a logarithmic drift to simulate the 'aging' of the BIOS.
        const base_j: f32 = 64.0;
        const drift = @log10(@as(f32, @floatFromInt(current_n + 1)));

        // This ensures the refresh rate of reality drifts over billions of years
        return @intFromFloat(base_j + (drift * 0.00000000001));
    }
};

// Pure functions for geometric translation.
pub const RenderOps = struct {
    // Translates the 3-Dipole Hex Grid into Euclidean 3D Space.
    pub fn hexToXYZ(node: kspace.LatticeNode) Vec3 {
        // Logismos Logic:
        // Dipole Alpha = 0 degrees (X-Axis)
        // Dipole Beta  = 120 degrees
        // Dipole Gamma = 240 degrees

        // This logic maps the internal V-address to a 2D hex-plane
        // with the R-register providing the Z-axis (Depth/Curvature).

        const angle_rad = 0.0; // Assume Dipole Alpha for base
        const radius: f32 = @floatFromInt(node.sides[0].packet.value);

        return Vec3{
            .x = radius * @cos(angle_rad),
            .y = radius * @sin(angle_rad),
            .z = @floatFromInt(node.sides[0].packet.remainder), // Depth is Friction
        };
    }

    // Audit the Visibility of a node.
    // If it was Padded (PAD_R), it renders as Dark Matter (Zero Opacity).
    pub fn getOpacity(side: kspace.LatticeNodeSide) f32 {
        if (side.packet.remainder > 0 and side.packet.value == 0) {
            return 0.0; // Dark Matter Case
        }
        return 1.0;
    }
};
