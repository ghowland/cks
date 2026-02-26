const std = @import("std");
const kspace = @import("k_space.zig");

/// X-Space Rendering Opcodes (0x40 - 0x4F)
/// Instructions for the Perceptual Display Driver.
pub const RenderOpcode = enum(i32) {
    BUFFER_PUSH = 0x40, // Ingest K-Space verified ledger
    BUFFER_POP = 0x41, // Release data after 15.19ms lag
    BILATERAL_SUM = 0x42, // Overlay Side A and Side B
    HEX_TO_XYZ = 0x43, // Translate dipoles to Cartesian space
    ALPHA_BLEND = 0x44, // Calculate transparency based on R-tension
};

/// Simple Cartesian Coordinate for X-Space Projection.
pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
};

/// The Perceptual Identity of a Soliton.
/// This represents the "Holographic Projection" seen by an observer.
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

/// A stored state of the K-Verse ledger, waiting for its Render-Deadline.
pub const LedgerSnapshot = struct {
    commit_n: u64, // The N-tick when this was verified in K-Space
    render_n: u64, // The N-tick + 15.19ms Offset
    nodes: []kspace.LatticeNode,
};

/// The X-Space Engine (The Renderer)
/// This operates at the Speed of Light (c), limited by the 15.19ms parity check.
pub const XSpaceEngine = struct {
    allocator: std.mem.Allocator,

    // Temporal Queue (The 15.19ms Pipeline)
    render_buffer: std.ArrayList(LedgerSnapshot),

    // Universal Constant for the Parity-Check Lag (RAID 1 Delay)
    pub const RENDER_LAG_TICKS: u64 = 64; // Approx 15.19ms at 0.237ms per tick

    pub fn init(allocator: std.mem.Allocator) XSpaceEngine {
        return .{
            .allocator = allocator,
            .render_buffer = std.ArrayList(LedgerSnapshot).init(allocator),
        };
    }

    /// RECEIVE: Ingests a verified ledger from the K-Space Engine.
    pub fn pushKSpaceLedger(self: *XSpaceEngine, current_n: u64, k_nodes: []kspace.LatticeNode) !void {
        const snapshot = LedgerSnapshot{
            .commit_n = current_n,
            .render_n = current_n + RENDER_LAG_TICKS,
            .nodes = try self.allocator.dupe(kspace.LatticeNode, k_nodes),
        };
        try self.render_buffer.append(snapshot);
    }

    /// PROCESS: Checks the buffer and renders frames that have hit their deadline.
    pub fn update(self: *XSpaceEngine, current_n: u64) ?[]HolographicSoliton {
        if (self.render_buffer.items.len == 0) return null;

        const next_up = self.render_buffer.items[0];
        if (current_n >= next_up.render_n) {
            const snapshot = self.render_buffer.orderedRemove(0);
            defer self.allocator.free(snapshot.nodes);
            return self.renderFrame(snapshot);
        }

        return null;
    }

    /// RENDER: Translates the Integer Ledger into a Holographic Frame.
    fn renderFrame(self: *XSpaceEngine, snapshot: LedgerSnapshot) []HolographicSoliton {
        var frame_objects = std.ArrayList(HolographicSoliton).init(self.allocator);

        for (snapshot.nodes) |k_node| {
            // 1. PERFORM THE BILATERAL SUM (Overlay Sides)
            const sum_v = k_node.sides[0].packet.value + k_node.sides[1].packet.value;
            const sum_r = k_node.sides[0].packet.remainder + k_node.sides[1].packet.remainder;

            // 2. HEX TO CARTESIAN (D=3 Dipole Mapping)
            // Simplified: Mapping the V-address to a hexagonal spiral
            const pos = RenderOps.hexToXYZ(k_node);

            // 3. KINETIC FOOTER TO BLUR
            // Reads the 12-bit transceiver footer to determine perceived velocity
            const momentum = k_node.sides[0].kinetic_footer.momentum_r;

            const h_soliton = HolographicSoliton{
                .k_id = snapshot.commit_n,
                .category = .Atom, // Simplified for single node
                .world_pos = pos,
                .visual_mass = @floatFromInt(sum_v),
                .vibrational_r = @floatFromInt(sum_r),
                .opacity = if (sum_r == 0) 1.0 else 0.5, // Remainder causes "Ghosting"
                .motion_blur = .{ .x = @floatFromInt(momentum), .y = 0, .z = 0 },
            };

            frame_objects.append(h_soliton) catch unreachable;
        }

        return frame_objects.toOwnedSlice() catch unreachable;
    }
};

/// Pure functions for geometric translation.
pub const RenderOps = struct {
    /// Translates the 3-Dipole Hex Grid into Euclidean 3D Space.
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

    /// Audit the Visibility of a node.
    /// If it was Padded (PAD_R), it renders as Dark Matter (Zero Opacity).
    pub fn getOpacity(side: kspace.LatticeNodeSide) f32 {
        if (side.packet.remainder > 0 and side.packet.value == 0) {
            return 0.0; // Dark Matter Case
        }
        return 1.0;
    }
};
