const std = @import("std");
const kspace = @import("k_space.zig");
const xspace = @import("x_space.zig");

// THE CYMATIC CHLADNI VALIDATION
// Goal: Prove that physical patterns are the result of Registry Parity.
pub fn main() !void {
    // 1. INITIALIZE ALLOCATOR & ENGINES
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var k_engine = kspace.LogismosEngine.init(allocator);
    var x_engine = xspace.XSpaceEngine.init(allocator);

    // 2. CONSTRUCT THE HARDWARE (The Metal Plate)
    // We create a 128x128 Hex-Plate Registry.
    std.debug.print("Initializing Metal Plate Soliton (10^15 LU)...\n", .{});
    var plate = try createHexPlate(allocator, 128);
    try k_engine.soliton_n1.children.append(&plate);

    // 3. POPULATE THE SAND (10^3 LU Atoms)
    // We scatter 5000 individual sand solitons across the plate addresses.
    std.debug.print("Seeding Sand Solitons (5000 Units)...\n", .{});
    const sand_grains = try seedSand(allocator, &plate, 5000);
    for (sand_grains.items) |grain| {
        try k_engine.soliton_n1.children.append(grain);
    }

    // 4. THE INDUSTRIAL AUDIT LOOP
    // We run the engine at Logic Speed (cL).
    var frame_count: u32 = 0;
    const target_frames = 1000;

    std.debug.print("--- STARTING CYMATIC AUDIT ---\n", .{});
    while (frame_count < target_frames) : (frame_count += 1) {

        // PHASE A: THE SPEAKER INJECTION
        // We inject a cyclical 32-bit remainder pulse into the center node.
        const frequency: u32 = @intCast(@abs(@sin(@as(f32, @floatFromInt(frame_count)) * 0.1) * 32.0));
        injectSpeakerTension(&plate, frequency);

        // PHASE B: K-SPACE STEP (RAID 1 Audit + Kinematics)
        // This is where the plate vibrates and the sand 'steps' to stable nodes.
        k_engine.step();

        // PHASE C: X-SPACE RENDER (The 15.19ms Frame Handoff)
        // We check the Render Queue for a finalized frame.
        if (x_engine.update(k_engine.registry.ticks)) |h_solitons| {
            // Here, you would hand off h_solitons to a GPU/Display API.
            // For now, we audit the 'Thickness' of the pattern.
            renderCymaticHUD(h_solitons);
            allocator.free(h_solitons);
        }

        if (frame_count % 100 == 0) {
            std.debug.print("Tick N: {d} | Registry Parity Active...\n", .{k_engine.registry.ticks});
        }
    }
}

// --- HELPER FUNCTIONS ---

// Builds a hexagonal mesh of LatticeNodes.
fn createHexPlate(allocator: std.mem.Allocator, size: usize) !kspace.Soliton {
    const nodes = try allocator.alloc(kspace.LatticeNode, size * size);

    // Initialize nodes with 32-bit Word defaults
    for (nodes) |*node| {
        node.sides[0] = .{
            .packet = .{ .value = 1, .fraction = 32, .remainder = 0 },
            .kinetic_footer = .{ .momentum_r = 0, .parent_id = 1 },
        };
        node.sides[1] = node.sides[0]; // Set Bilateral Mirror
    }

    return kspace.Soliton{
        .id = 1,
        .category = .Self, // Plate has 'Identity' depth
        .nodes = nodes,
        .parent = null,
        .children = std.ArrayList(*kspace.Soliton).init(allocator),
    };
}

// Scatters sand grain solitons onto random nodes of the plate.
fn seedSand(allocator: std.mem.Allocator, plate: *kspace.Soliton, count: usize) !std.ArrayList(*kspace.Soliton) {
    var grains = std.ArrayList(*kspace.Soliton).init(allocator);
    var prng = std.rand.DefaultPrng.init(42);
    const random = prng.random();

    for (0..count) |i| {
        const grain = try allocator.create(kspace.Soliton);
        const node_idx = random.intRangeAtMost(usize, 0, plate.nodes.len - 1);

        // Point sand to a single node address
        var node_slice = try allocator.alloc(kspace.LatticeNode, 1);
        node_slice[0] = plate.nodes[node_idx];

        grain.* = .{
            .id = 100 + i,
            .category = .Atom,
            .nodes = node_slice,
            .parent = plate,
            .children = std.ArrayList(*kspace.Soliton).init(allocator),
        };
        try grains.append(grain);
    }
    return grains;
}

// Opcode Trigger: The Speaker.
// Directly oscillates the R-register of the center nodes.
fn injectSpeakerTension(plate: *kspace.Soliton, frequency_r: u32) void {
    const center_idx = plate.nodes.len / 2;
    // Inject remainder tension (Frustration)
    plate.nodes[center_idx].sides[0].packet.remainder = frequency_r;
    // Parity requires the mirror to see the tension too
    plate.nodes[center_idx].sides[1].packet.remainder = frequency_r;
}

// Basic Console Renderer for the Cymatic Patterns.
fn renderCymaticHUD(solitons: []xspace.HolographicSoliton) void {
    var stable_count: usize = 0;
    for (solitons) |s| {
        if (s.opacity > 0.9) stable_count += 1;
    }
    // Success Criteria: Stable Count represents the sand forming a pattern at R=0.
    // std.debug.print("Render: {d} grains have reached stable nodes.\n", .{stable_count});
}
