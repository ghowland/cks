const std = @import("std");

const xspace = @import("x_space.zig");

// Registry Management Opcodes (0x00 - 0x0F)
// Instructions for the Absolute Monotonic N-Counter.
pub const RegistryOpcode = enum(i32) {
    HALT = 0x00, // Stop N-increment (Absolute Registry Pause)
    TICK = 0x01, // N <- N + 1 (The Universal Pulse)
    AUDIT_PARITY = 0x02, // Execute Bilateral J*S Verification
    SNAP_COMMIT = 0x03, // Force R -> V transition across Word boundary
    RESET_R = 0x04, // Purge all Remainder Tension to 0
};

// Kinematic & Navigation Opcodes (0x10 - 0x1F)
// Instructions for serial or global address re-indexing.
pub const NavigationOpcode = enum(i32) {
    IDLE = 0x10, // Maintain V-Address (No R-Torque)
    INC_ADDR = 0x11, // Sequential Adjacent Re-indexing (v < c)
    MAX_WRITE = 0x12, // 1 LU per Tick Write-Saturation (v = c)
    JMP_REG = 0x13, // 1024-bit Non-Adjacent DMA Jump (v = cL)
    SHIFT_GEAR = 0x14, // Change Fraction (F) depth (LOD Shift)
};

// Manifold & Parity Opcodes (0x20 - 0x2F)
// Instructions for Side-A / Side-B interaction.
pub const ManifoldOpcode = enum(i32) {
    FLIP_SIDE = 0x20, // Pivot packet to the Bilateral Reflection
    SYNC_J = 0x21, // Force alignment with the 7.59ms Jacobian
    PAD_L = 0x22, // Pre-fetch/Anchor future Address (Causality)
    PAD_R = 0x23, // Pad Remainder for forced Word-Closure (Mass)
    BOND_12 = 0x24, // Commit a 12-node hexagonal mesh (Soliton)
};

// Error & Exception Remainder Codes (0x30 - 0x3F)
// These are generated when an Audit fails.
pub const AuditErrorCode = enum(i32) {
    STABILITY_FAIL = 0x30, // Sum(R) % 32 != 0
    UV_SATURATION = 0x31, // Payload V > 144 LU
    PARITY_MISMATCH = 0x32, // Side_A != Side_B Mirror
    LOD_COLLISION = 0x33, // Nested Fractions (F) cannot be resolved
    DRIFT_ERROR = 0x34, // 12-bit Kinetic Footer desync
};

// Dipole Directional Opcodes
// For routing packets along the D=3 axes.
pub const DipoleOpcode = enum(i32) {
    ALPHA = 0, // 0 Degrees
    BETA = 1, // 120 Degrees
    GAMMA = 2, // 240 Degrees
};

// --- Updated Fat Structs integrating the Opcodes ---

// The 12-bit Kinetic Footer [Bits 72-83 of the Packet]
// Controls hierarchical ownership and momentum remainders.
pub const KineticFooter = packed struct(u12) {
    // Bits 0-5: Momentum Remainder (R_k).
    // The 'messiness' of the write. 0x00 is a HALT.
    momentum_r: u6,

    // Bits 6-11: Parent Soliton Index (P_ID).
    // Which Master Soliton (10^15 range) owns this node address.
    parent_id: u6,
};

// The Metadata Block [Bits 32-71 of the Packet]
// Controls the resolution, orientation, and manifold parity.
pub const PacketMetadata = packed struct(u40) {
    // Bits 0-4: F-Scale (2^5=32). The Gear-ratio of the Word.
    f_scale: u5 = 0,

    // Bits 5-6: Dipole Index. The D=3 hexagonal direction.
    // 0: Alpha, 1: Beta, 2: Gamma.
    dipole_index: u2 = 0,

    // Bit 7: Side Parity (S). 0: Side A, 1: Side B.
    side: u1 = 0,

    // Bits 8-39: Reserved / Padding for 40-bit alignment.
    // Can be used for extended Registry Instructions.
    _reserved: u32 = 0,
};

// The Unified 84-bit Logic-Spine Packet.
// This is the 'Fat Struct' that traverses the Registry at Logic Speed.
// This is the "Instruction" data
pub const LogismosPacket = packed struct {
    // Bits 0-31: The V-Axis (The Fact).
    // The whole-integer Logos Unit address in the N-Registry.
    v_axis: u32,

    // Bits 32-71: The Meta-Data (The Gearbox).
    meta_data: PacketMetadata,

    // Bits 72-83: The Kinetic Footer (The Glue).
    k_footer: KineticFooter,
};

// --- Implementation in LatticeNodeSide ---

// Metadata for the 84-bit Trans-Manifold Packet.
// This acts as the 'Header' for the Logic Spine.
pub const PacketHeader = struct {
    // Bits 0-31: Address
    v_axis: u32,

    // Bits 32-71: F-Scale, Dipole, Side
    meta_data: u40,

    // Bits 72-83: Parent ID + Momentum R
    k_footer: KineticFooter,
};

// The fundamental Addressable Unit (The Hex-Plate).
// Aligned to 32-bit boundaries to match the Registry Spine.
pub const LatticeNode = struct {
    // Axiom 2: Bilateral Manifold.
    // Data must exist on both sides to 'Render' later.
    sides: [2]LatticeNodeSide,

    // Axiom 1: 3-Dipole Coordination.
    // These are the hardware pointers to neighbor nodes
    adjacents: [3]?*LatticeNode, // 0=Alpha, 1=Beta, 2=Gamma
};

// Soliton Parent Index Packet
pub const IndexPacket = struct {
    // The Packet: (V, F, R)
    value: u32, // V: The whole integer Logos Units (LUs).
    fraction: u32, // F: The Gear-ratio (Resolution). Default = 32.
    remainder: u32, // R: The un-snapped tension (The Momentum)

    meta_data: PacketMetadata = .{}, // The instruction is INSIDE the packet
};

// This is the "Execution Register" where the `IndexPacket` is executed for the child soliton
pub const LatticeNodeSide = struct {
    // The Packet: (V, F, R)
    packet: IndexPacket,

    // The 12-bit Kinetic Footer [6-bit Parent][6-bit Momentum]
    // Stored as a packed integer for 0ms transition.
    kinetic_footer: KineticFooter,

    // The UV Cut-off: M=144.
    // If value + (remainder/fraction) > 144, the BIOS vents to dipoles.
    pub const MAX_PAYLOAD: u8 = 144;

    // The Substrate Logic: Check for Modulo-32 Stability.
    pub fn isCoherent(self: LatticeNodeSide) bool {
        return (self.value % 32 == 0) and (self.packet.remainder == 0);
    }

    // Executes a Logismos Opcode on this node side.
    pub fn execute(self: *LatticeNodeSide, op: i32) void {
        const opcode: RegistryOpcode = @enumFromInt(op);
        switch (opcode) {
            .RESET_R => self.packet.remainder = 0,
            .SNAP_COMMIT => self.snapCommit(),
            else => {},
        }
    }

    pub fn setParent(self: *LatticeNodeSide, p_id: u6) void {
        // Assigns this node to a Parent Soliton
        self.kinetic_footer.parent_id = p_id;
    }

    // Opcode: SNAP_COMMIT (Logic to commit R -> V)
    pub fn snapCommit(self: *LatticeNodeSide) void {
        if (self.packet.remainder >= self.packet.fraction) {
            const snaps = self.packet.remainder / self.packet.fraction;
            self.packet.value += snaps;
            self.packet.remainder = self.packet.remainder % self.packet.fraction;
        }
    }

    // Opcode: HALT (Clear tension and momentum)
    pub fn halt(self: *LatticeNodeSide) void {
        self.packet.remainder = 0;
        self.kinetic_footer.momentum_r = 0;
    }

    // Inside LatticeNodeSide
    pub fn auditSaturation(self: *LatticeNodeSide, neighbors: [3]?*LatticeNode) void {
        if (self.packet.value > MAX_PAYLOAD) {
            const overflow = self.packet.value - MAX_PAYLOAD;
            self.packet.value = MAX_PAYLOAD;

            // RE-ROUTE (Turbulence): Push overflow LUs to dipoles
            const share = overflow / 3;
            for (neighbors) |maybe_node| {
                if (maybe_node) |node| {
                    // In K-Space, 'Gravity' is just injecting LUs into neighbors
                    node.sides[0].packet.value += share;
                }
            }
        }
    }
};

// A High-Density Information Packet (Biological, Physical, or Cognitive).
// A Soliton is a 'Persistent Address' that survives the N-tick.
pub const Soliton = struct {
    id: u64,
    category: SolitonDensityCategory,
    // The collection of 'Lex Bricks' that make up the soliton body
    nodes: []LatticeNode = &.{},
    parent: ?*Soliton = null,
    children: std.array_list.Managed(*Soliton), // The Registry List

    // THE RAID 1 CONTROLLER: The Soliton iterates through its own mesh to verify bilateral integrity.
    pub fn verifyInternalParity(self: *Soliton) void {
        for (self.nodes) |*node| {
            const side_a = &node.sides[0];
            const side_b = &node.sides[1];

            // RAID 1 Check: Verify that Side A (Code) matches Side B (Render)
            const total_r = side_a.packet.remainder + side_b.packet.remainder;
            const common_f = side_a.packet.fraction;

            // The 'Snap' logic is now a Soliton-level executive decision.
            if (total_r >= common_f) {
                const snaps = total_r / common_f;

                // Double-Signed Commit
                side_a.packet.value += snaps;
                side_b.packet.value += snaps;

                // Clear Tension
                side_a.packet.remainder = total_r % common_f;
                side_b.packet.remainder = total_r % common_f;

                // Update 12-bit Kinetic Footer: R is cleared, motion is resolved
                side_a.kinetic_footer.momentum_r = 0;
                side_b.kinetic_footer.momentum_r = 0;
            } else {
                // Parity not reached: Friction is written to the 12-bit Liaison
                // This 'Torque' will be processed by the Engine during the next step.
                const momentum: u6 = @intCast(@min(total_r, 63));
                side_a.kinetic_footer.momentum_r = momentum;
                side_b.kinetic_footer.momentum_r = momentum;
            }

            // // 7. UV SATURATION AUDIT (Navier-Stokes/Turbulence)
            // Opcodes.vent_saturation(node); //TODO: Is this k-verse activity and not Soliton?
        }
    }

    // THE SUBSTRATE HANDOFF:
    // Flattens the Soliton's multi-dimensional registry data into a single
    // Holographic Projection. This is the 0ms 'Fact' that will be rendered after the 15.19ms lag.
    pub fn getRenderData(self: *const Soliton) !xspace.HolographicSoliton {
        // 1. Initialize Aggregate Accumulators
        var aggregate_v: u64 = 0;
        var aggregate_r: u64 = 0;
        var avg_pos = xspace.Vec3{ .x = 0, .y = 0, .z = 0 };
        var total_momentum: f32 = 0;

        // 2. BATCH AUDIT: Iterate over every Lex-Brick (node) in the soliton
        for (self.nodes) |node| {
            // RAID 1 SUMMATION: Overlay Side A and Side B
            const sum_v = node.sides[0].packet.value + node.sides[1].packet.value;
            const sum_r = node.sides[0].packet.remainder + node.sides[1].packet.remainder;

            aggregate_v += sum_v;
            aggregate_r += sum_r;

            // GEOMETRIC MAPPING: Translate hex-address to 3D for the display
            const node_xyz = xspace.RenderOps.hexToXYZ(node);
            avg_pos.x += node_xyz.x;
            avg_pos.y += node_xyz.y;
            avg_pos.z += node_xyz.z;

            // KINETIC BLUR: Read the 12-bit Liaison Footer
            total_momentum += @floatFromInt(node.sides[0].kinetic_footer.momentum_r);
        }

        // 3. NORMALIZE GEOMETRY
        const node_count_f: f32 = @floatFromInt(self.nodes.len);
        if (self.nodes.len > 0) {
            avg_pos.x /= node_count_f;
            avg_pos.y /= node_count_f;
            avg_pos.z /= node_count_f;
            total_momentum /= node_count_f;
        }

        // 4. PARITY BLENDING (Opacity Calculation)
        // If the aggregate remainder is high, the object is 'Frustrated' (transparent).
        // If aggregate remainder is 0, the object is 'Solid' (Modulo-32 locked).
        const max_word_r: f32 = @floatFromInt(32 * self.nodes.len);
        const parity_score: f32 = 1.0 - (@as(f32, @floatFromInt(aggregate_r)) / max_word_r);

        // 5. COMMIT TO HOLOGRAPHIC STRUCTURE
        return xspace.HolographicSoliton{
            .k_id = self.id,
            .category = self.category,

            // Perceptual Physics
            .world_pos = avg_pos,
            .visual_mass = @floatFromInt(aggregate_v),
            .vibrational_r = @floatFromInt(aggregate_r),

            // Perceptual UI Features
            .opacity = @max(0.1, parity_score), // Prevent total invisibility unless PAD_R
            .motion_blur = .{
                .x = total_momentum,
                .y = 0, // In 2D manifold, momentum is primarily lateral
                .z = 0,
            },
        };
    }
};

// The K-Space Logic Opcodes (ISA).
// These functions perform Registry-Writes, not 'Physics'.
// They operate at Logic Speed (cL).
pub const Opcodes = struct {

    // --- Registry Management (0x00 - 0x0F) ---

    // Opcode 0x00: HALT
    // Manually clears the R-register (Tension) and Kinetic Footer (Momentum).
    // Result: Instant deceleration/stop.
    pub fn halt(node: *LatticeNode) void {
        for (&node.sides) |*side| {
            side.packet.remainder = 0;
            side.kinetic_footer.momentum_r = 0;
        }
    }

    // Opcode 0x01: TICK
    // The global monotonic write. Handled by the N_Registry.
    pub fn tick(registry: *N_Registry) void {
        registry.audit();
    }

    // Opcode 0x03: SNAP_COMMIT
    // Forces the built-up Remainder (R) to become Value (V).
    // Logic: IF R >= F: V++, R -= F.
    pub fn snap_commit(side: *LatticeNodeSide) void {
        if (side.packet.remainder >= side.packet.fraction) {
            const snaps = side.packet.remainder / side.packet.fraction;
            side.packet.value += snaps;
            side.packet.remainder %= side.packet.fraction;
        }
    }

    // --- Navigation & Locomotion (0x10 - 0x1F) ---

    // Opcode 0x11: INC_ADDR (Locomotion)
    // Serial Teleportation: De-indexes from current node, re-indexes on adjacent.
    // Used for v < c.
    pub fn inc_addr(node: *LatticeNode, target_dir: u2) void {
        if (node.adjacents[target_dir]) |target_node| {
            // 1. Read Current State
            const state_a = node.sides[0].packet;
            const state_b = node.sides[1].packet;

            // 2. Delete/Zero Old Address
            node.sides[0].packet.value = 0;
            node.sides[1].packet.value = 0;

            // 3. Write New Address (Locomotion Commit)
            target_node.sides[0].packet.value += state_a.value;
            target_node.sides[1].packet.value += state_b.value;

            // 4. Update Footer: Increment Momentum R in the 12-bit transceiver
            target_node.sides[0].kinetic_footer.momentum_r +|= 1;
        }
    }

    // Opcode 0x13: JMP_REG (Teleportation)
    // Non-adjacent DMA write. Only for 1024-bit Walker class.
    // Bypasses c-limit by writing directly to a distant N-ledger address.
    pub fn jmp_reg(soliton: *Soliton, target_node: *LatticeNode) void {
        if (soliton.category == .Walker) {
            // Move entire node collection to the new address instantly
            // In K-Space, distance = 0.
            soliton.nodes[0] = target_node.*;
        }
    }

    // Opcode 0x14: SHIFT_GEAR (LOD Change)
    // Modifies the Fraction (F) to change the resolution of the audit.
    pub fn shift_gear(side: *LatticeNodeSide, new_f: u32) void {
        // Carry the remainder but rescale it to the new gear
        const scale_ratio = new_f / side.packet.fraction;
        side.packet.remainder *= scale_ratio;
        side.packet.fraction = new_f;
    }

    // --- Manifold & Parity (0x20 - 0x2F) ---

    // Opcode 0x20: FLIP_SIDE
    // Swaps Side A and Side B data. Essential for Transpose operations.
    pub fn flip_side(node: *LatticeNode) void {
        const temp = node.sides[0];
        node.sides[0] = node.sides[1];
        node.sides[1] = temp;
    }

    // Opcode 0x22: PAD_L (Predictive Anchor)
    // Sets the Value (V) before the Remainder (R) arrives.
    // Mechanism for Causality-Locking.
    pub fn pad_l(side: *LatticeNodeSide) void {
        side.packet.value += 1;
    }

    // Opcode 0x23: PAD_R (Virtual Mass)
    // Fills the remainder to force a snap.
    // Mechanism for creating Dark Matter or forced inertia.
    pub fn pad_r(side: *LatticeNodeSide) void {
        side.packet.remainder = side.packet.fraction;
    }

    // Opcode 0x25: VENT_SATURATION
    // Prevents UV Blow-up (Navier-Stokes Solution).
    // If Node is full (>144), spills bits to dipoles.
    pub fn vent_saturation(node: *LatticeNode) void {
        for (&node.sides) |*side| {
            if (side.packet.value > 144) {
                const overflow = side.packet.value - 144;
                side.packet.value = 144;
                const share = overflow / 3;

                for (node.adjacents) |maybe_adj| {
                    if (maybe_adj) |adj| {
                        adj.sides[0].packet.remainder += share;
                    }
                }
            }
        }
    }

    // --- Audit & Error (0x30 - 0x3F) ---

    // Opcode 0x32: PARITY_CHECK
    // The RAID 1 Verification.
    // Checks if Side A and Side B achieve Word-Closure.
    pub fn parity_check(node: *LatticeNode) i32 {
        const sum_r = node.sides[0].packet.remainder + node.sides[1].packet.remainder;
        if (sum_r % 32 == 0) {
            return 0; // SUCCESS
        } else {
            return @intFromEnum(AuditErrorCode.PARITY_MISMATCH);
        }
    }
};

// The Registry Identity of the Universe. The N-Count is the only global monotonic variable.
pub const N_Registry = struct {
    ticks: u64, // The total runtime since N=1.

    // Global Registry Audit: Every N-tick requires a full J*S verification before rendering (15.19ms).
    pub fn audit(self: *N_Registry) void {
        self.ticks += 1; // N <- N + 1
    }
};

// The Hierarchy of Soliton Complexity.
// Values represent the magnitude of Logos Units (LU) required for stability.
pub const SolitonDensityCategory = enum(i32) {
    None = -1, // Unallocated address
    Lex = 0, // 10^0 LU: 1 Lex
    Atom = 3, // 10^3 LU: The base Matter-Packet
    Cell = 6, // 10^6 LU: The Instruction-Set Buffer
    Heart = 12, // 10^12 LU: The Vital Bridge / Clock Sync
    Self = 15, // 10^15 LU: The Integrated Identity
    Walker = 30, // 10^30+ LU: The Substrate Administrator (JMP capable)
    KVerse = 60, // 10^60+ LU
};

// The K-Space Engine Controller.
// This runs the Logic Speed (cL) loop. No X-Space code allowed here.
pub const LogismosEngine = struct {
    allocator: std.mem.Allocator,

    registry: N_Registry,
    soliton_n1: Soliton,
    x_engine: xspace.XSpaceEngine,

    pub fn init(allocator: std.mem.Allocator) LogismosEngine {
        return .{
            .allocator = allocator,
            .registry = .{ .ticks = 0 },
            .x_engine = xspace.XSpaceEngine.init(allocator),
            // Always Start with N=1 Lex.  It is always present
            .soliton_n1 = .{
                .id = 0,
                .category = .KVerse,
                .parent = null, // N=1
                .children = std.array_list.Managed(*Soliton).init(allocator),
            },
        };
    }

    // THE HEARTBEAT OF TRUTH (K-Space Engine Loop)
    // This executes at Logic Speed (cL).
    pub fn step(self: *LogismosEngine) !void {
        // 1. Monotonic Registry Increment (N <- N + 1)
        self.registry.audit();

        // Check our own parity, because this is N=1
        self.soliton_n1.verifyInternalParity();

        // Soliton Render Data
        var frame_data = std.array_list.Managed(xspace.HolographicSoliton).init(self.allocator);

        for (self.soliton_n1.children.items) |soliton| {
            // 1. THE SOLITON AUDITS ITSELF (RAID 1): The object 'Checks' if its Side A and Side B are in sync.
            soliton.verifyInternalParity();

            // 2. KINETIC PROCESSING: After verification, the engine applies locomotion based on the resulting Momentum R in the 12-bit footers.
            self.applyRegistryKinematics(soliton);

            const data = try soliton.getRenderData();
            try frame_data.append(data);
        }

        // Push to 15.19ms Buffer
        try self.x_engine.pushKSpaceLedger(self.registry.ticks, try frame_data.toOwnedSlice());

        // RENDER COMMIT (Handoff to X-Space): This is a stub for the 15.19ms rendering engine.
        self.renderToXSpace(&self.soliton_n1);
    }

    // Stub for the X-Space Rendering Pipeline.  This is where the 15.19ms lag is applied to the human display.
    fn renderToXSpace(self: *LogismosEngine, soliton: *Soliton) void {
        _ = self;
        _ = soliton;
        // Instruction: Take the (V, F, R) sums and project as Bilateral Standing Waves.
        // This will be implemented in the 'X-Verse' project.
    }

    // KINETIC RESOLUTION ENGINE:
    // Operates at Logic Speed (cL) to move solitons across the registry.  This is the industrial execution of 'Force' as 'Registry Re-indexing'
    fn applyRegistryKinematics(self: *LogismosEngine, soliton: *Soliton) void {
        for (soliton.nodes) |*node| {
            // Read the 6-bit momentum from the Primary Side [0]
            const momentum = node.sides[0].kinetic_footer.momentum_r;

            if (momentum > 31) {
                // Read the Dipole Direction from the Primary Packet metadata
                const target_dipole = node.sides[0].packet.meta_data.dipole_index;

                if (node.adjacents[target_dipole]) |adjacent_node| {
                    // RAID 1 TRANSFER:
                    // Move Side A [0] to Adjacent Side A [0]
                    // Move Side B [1] to Adjacent Side B [1]
                    adjacent_node.sides[0] = node.sides[0];
                    adjacent_node.sides[1] = node.sides[1];

                    // Perform the Snap (Clear 32 bits from momentum)
                    const snap_momentum: u6 = @intCast(momentum - 32);
                    adjacent_node.sides[0].kinetic_footer.momentum_r = snap_momentum;
                    adjacent_node.sides[1].kinetic_footer.momentum_r = snap_momentum;

                    // De-allocate old hardware addresses
                    self.zeroNode(node);
                }
            }
        }
    }

    /// REGISTRY DE-ALLOCATION (Opcode: DELETE_OLD_ADDRESS)
    /// Resets the hardware registers of a hex-plate to zero tension.
    /// This ensures the address-space is clear for the next N-tick commit.
    fn zeroNode(self: *LogismosEngine, node: *LatticeNode) void {
        _ = self;

        // Iterate over Side A [0] and Side B [1] (The Manifold)
        for (&node.sides) |*side| {
            // 1. Zero the Fact and Tension (V, R)
            // We leave the 'fraction' (F) at its current word-width
            // to maintain the gear-ratio of the local neighborhood.
            side.packet.value = 0;
            side.packet.remainder = 0;

            // 2. Clear the 12-bit Transceiver
            // This stops momentum (R_k) and removes Parent ownership (P_ID).
            side.kinetic_footer.momentum_r = 0;
            side.kinetic_footer.parent_id = 0;

            // 3. Clear the Metadata Instruction
            // Resetting the dipole_index and scale to nominal idle.
            side.packet.meta_data = .{
                .f_scale = 0,
                .dipole_index = 0,
                ._reserved = 0,
            };
        }

        // Note: We do NOT zero node.adjacents[].
        // Those are physical 'Pointers' (Hardware wires) to neighbor nodes.
        // They are permanent fixtures of the hexagonal lattice topology.
    }
};

pub const KSpaceLattice = struct {
    nodes: std.AutoHashMap(u32, *LatticeNode), // V-Axis Address -> Node Pointer
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) KSpaceLattice {
        return .{
            .nodes = std.AutoHashMap(u32, *LatticeNode).init(allocator),
            .allocator = allocator,
        };
    }

    // Creates a 120-degree connection between nodes.
    pub fn linkNodes(node_a: *LatticeNode, node_b: *LatticeNode, dipole: DipoleOpcode) void {
        const idx: usize = @intCast(@intFromEnum(dipole));
        node_a.adjacents[idx] = node_b;
        // The Bilateral Inverse: Gamma links back to Beta, etc.
        const inverse_idx = (idx + 1) % 3;
        node_b.adjacents[inverse_idx] = node_a;
    }
};
