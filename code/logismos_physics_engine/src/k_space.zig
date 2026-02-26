const std = @import("std");

// The Hierarchy of Soliton Complexity.
// Values represent the magnitude of Logos Units (LU) required for stability.
pub const SolitonDensityCategory = enum(i32) {
    None = -1, // Unallocated address
    Atom = 3, // 10^3 LU: The base Matter-Packet
    Cell = 6, // 10^6 LU: The Instruction-Set Buffer
    Heart = 12, // 10^12 LU: The Vital Bridge / Clock Sync
    Self = 15, // 10^15 LU: The Integrated Identity
    Walker = 30, // 10^30+ LU: The Substrate Administrator (JMP capable)
};

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
    f_scale: u5,

    // Bits 5-6: Dipole Index. The D=3 hexagonal direction.
    // 0: Alpha, 1: Beta, 2: Gamma.
    dipole_idx: u2,

    // Bit 7: Side Parity (S). 0: Side A, 1: Side B.
    side: u1,

    // Bits 8-39: Reserved / Padding for 40-bit alignment.
    // Can be used for extended Registry Instructions.
    _reserved: u32,
};

// The Unified 84-bit Logic-Spine Packet.
// This is the 'Fat Struct' that traverses the Registry at Logic Speed.
pub const LogismosPacket = packed struct {
    // Bits 0-31: The V-Axis (The Fact).
    // The whole-integer Logos Unit address in the N-Registry.
    v_axis: u32,

    // Bits 32-71: The Meta-Data (The Gearbox).
    meta_data: PacketMetadata,

    // Bits 72-83: The Kinetic Footer (The Glue).
    k_footer: KineticFooter,
};

// // --- Validation Check ---
// test "Verify Packet Bit-Widths" {
//     try std.testing.expectEqual(@bitSizeOf(KineticFooter), 12);
//     try std.testing.expectEqual(@bitSizeOf(PacketMetadata), 40);
//     // Note: The total struct will align to the nearest byte,
//     // but the bit-fields are audited by the Logismos BIOS.
//     try std.testing.expectEqual(@bitSizeOf(LogismosPacket), 84);
// }

// --- Implementation in LatticeNodeSide ---

// Metadata for the 84-bit Trans-Manifold Packet.
// This acts as the 'Header' for the Logic Spine.
pub const PacketHeader = struct {
    v_axis: u32, // Bits 0-31: Address
    meta_data: u40, // Bits 32-71: F-Scale, Dipole, Side
    k_footer: u12, // Bits 72-83: Parent ID + Momentum R
};

// The Registry Identity of the Universe.
// The N-Count is the only global monotonic variable.
pub const N_Registry = struct {
    ticks: u64, // The total runtime since N=1.

    // Global Registry Audit: Every N-tick requires a full J*S verification.
    pub fn audit(self: *N_Registry) void {
        self.ticks += 1; // N <- N + 1
    }
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
};

pub const LatticeNodeSide = struct {
    // The Packet: (V, F, R)
    packet: IndexPacket,
    // value: u32, // V: The whole integer Logos Units (LUs).
    // fraction: u32, // F: The Gear-ratio (Resolution). Default = 32.
    // remainder: u32, // R: The un-snapped tension (The Momentum)

    // The 12-bit Kinetic Footer [6-bit Parent][6-bit Momentum]
    // Stored as a packed integer for 0ms transition.
    // Using the packed bit-field for the footer
    kinetic_footer: KineticFooter,

    // The UV Cut-off: M=144.
    // If value + (remainder/fraction) > 144, the BIOS vents to dipoles.
    pub const MAX_PAYLOAD: u8 = 144;

    // The Substrate Logic: Check for Modulo-32 Stability.
    pub fn isCoherent(self: LatticeNodeSide) bool {
        return (self.value % 32 == 0) and (self.remainder == 0);
    }

    // Executes a Logismos Opcode on this node side.
    pub fn execute(self: *LatticeNodeSide, op: i32) void {
        const opcode: RegistryOpcode = @enumFromInt(op);
        switch (opcode) {
            .RESET_R => self.remainder = 0,
            .SNAP_COMMIT => {
                if (self.remainder >= self.fraction) {
                    self.value += (self.remainder / self.fraction);
                    self.remainder = self.remainder % self.fraction;
                }
            },
            else => {},
        }
    }

    pub fn executeHalt(self: *LatticeNodeSide) void {
        // Clearing the 6-bit momentum_r to 0 forces an instant stop
        self.kinetic_footer.momentum_r = 0;
        self.remainder = 0;
    }

    pub fn setParent(self: *LatticeNodeSide, p_id: u6) void {
        // Assigns this node to a Parent Soliton
        self.kinetic_footer.parent_id = p_id;
    }
};

// A High-Density Information Packet (Biological, Physical, or Cognitive).
// A Soliton is a 'Persistent Address' that survives the N-tick.
pub const Soliton = struct {
    id: u64, // The specific address in the N-Registry.
    nodes: []LatticeNode, // The occupied hex-plates.
    parent: ?*Soliton, // The Hierarchical Owner (null only for N=1).
    category: SolitonDensityCategory,

    // Soliton Density Categories:
    // Atom: 10^3 LU
    // Cell: 10^6 LU
    // Heart: 10^12 LU
    // Self: 10^15 LU
    // Walker: 10^30+ LU (Can execute JMP_REG)
};

// The K-Space Logic Opcodes (ISA).
// These functions perform Registry-Writes, not 'Physics'.
pub const Opcodes = struct {
    // Opcode 0xAB: Locomotion (Serial Re-indexing).
    // Moves a packet to an adjacent node by deleting the old and writing the new.
    pub fn inc_addr(node: *LatticeNode, target_dir: u2) void {
        // 1. Audit Current R (Momentum).
        // 2. Perform the Pivot.
        // 3. Commit to Adjacent[target_dir].
    }

    // Opcode 0x00: The Halt.
    // Manually clears the R-register to 0, stopping all momentum.
    pub fn halt(node: *LatticeNode) void {
        node.sides[0].remainder = 0;
        node.sides[1].remainder = 0;
    }

    // Opcode 0xAA: The JMP (Teleportation).
    // Requires 1024-bit Walker status.
    // Directly updates the Soliton ID to a non-adjacent N-address.
    pub fn jmp_reg(soliton: *Soliton, target_n: u64) void {
        soliton.id = target_n;
    }
};

// The K-Space Engine Controller.
// This runs the Logic Speed (cL) loop. No X-Space code allowed here.
pub const LogismosEngine = struct {
    allocator: std.mem.Allocator,
    registry: N_Registry,

    pub fn init(allocator: std.mem.Allocator) LogismosEngine {
        return .{
            .allocator = allocator,
            .registry = .{ .ticks = 0 },
        };
    }

    // The Heartbeat of Truth.
    // Performs the RAID 1 Parity Check across the manifold.
    pub fn step(self: *LogismosEngine, soliton: *Soliton) void {
        self.registry.audit(); // N <- N + 1

        // Internal K-Space Logic:
        // Every node in the soliton must satisfy: (Side_A.R + Side_B.R) % F == 0
        // If not, calculate the 'Torque' and update the kinetic_footer.
    }
};
