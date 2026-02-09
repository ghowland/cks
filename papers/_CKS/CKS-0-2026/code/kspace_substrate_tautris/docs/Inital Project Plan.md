# K-Space Physics tautris - Project Plan

## Overview
Physics playground combining discrete k-space substrate mechanics with traditional tautris gameplay. Three-panel view: k-space visualization (left), 3D tautris gameplay (center), x-space projection (right). All physics derived from N with real-time parameter control.

---

## Architecture

### Core Modules

```
src/
├── main.zig                    # Entry point, main loop
├── kspace_substrate.zig        # Core physics (from working viewer)
├── physics_params.zig          # Derivations from N (α, masses, forces)
├── tautris_game.zig            # Game logic, collision, scoring
├── renderer_3d.zig            # Raylib 3D tautris blocks
├── renderer_kspace.zig        # 2D k-space field visualization
├── renderer_xspace.zig        # 2D/3D x-space projection
├── ui_controls.zig            # Sliders, toggles, info panels
└── spectrum.zig               # Light wavelength/color mapping
```

---

## Phase 1: Foundation (Working Substrate + Basic Structure)

### 1.1 Project Setup
- [x] Copy working `kspace_substrate_viewer.zig`
- [ ] Create modular structure (split into files above)
- [ ] Set up build.zig with all modules
- [ ] Basic window layout (3 panels)

### 1.2 Physics Engine
```zig
// physics_params.zig
pub const PhysicsState = struct {
    N: f64,  // Bubble count (age of universe)
    
    // Derived quantities (all pure functions of N)
    pub fn alpha_em_inv(self: PhysicsState) f64;
    pub fn alpha_w_inv(self: PhysicsState) f64;
    pub fn alpha_s_inv(self: PhysicsState) f64;
    pub fn alpha_g(self: PhysicsState) f64;
    
    pub fn mass_ratio_muon(self: PhysicsState) f64;
    pub fn mass_ratio_tau(self: PhysicsState) f64;
    
    pub fn dark_energy_density(self: PhysicsState) f64;
    pub fn holographic_scale(self: PhysicsState) f64;
    
    pub fn gravity_coupling(self: PhysicsState) f64;
    pub fn speed_of_light_bubbles(self: PhysicsState) f64;
};
```

### 1.3 Substrate Integration
- [ ] Port working KSpaceSubstrate to module
- [ ] Add time evolution: `substrate.step(dt, physics)`
- [ ] Add particle injection (tautris blocks modify field)
- [ ] Add field query methods for rendering

---

## Phase 2: tautris Game Logic

### 2.1 Core Game
```zig
// tautris_game.zig
pub const tautrisGame = struct {
    grid: [20][10][10]bool,  // 3D grid (height, x, z)
    current_piece: Tetromino,
    position: Vec3i,
    rotation: Quaternion,
    score: u32,
    level: u32,
    
    pub fn update(self: *tautrisGame, dt: f32) void;
    pub fn moveLeft(self: *tautrisGame) void;
    pub fn moveRight(self: *tautrisGame) void;
    pub fn moveForward(self: *tautrisGame) void;
    pub fn moveBackward(self: *tautrisGame) void;
    pub fn rotate(self: *tautrisGame, axis: Axis) void;
    pub fn drop(self: *tautrisGame) void;
    pub fn checkCollision(self: *tautrisGame) bool;
    pub fn lockPiece(self: *tautrisGame) void;
    pub fn clearLines(self: *tautrisGame) u32;
    pub fn injectIntoSubstrate(self: *tautrisGame, substrate: *KSpaceSubstrate) void;
};

pub const Tetromino = enum {
    I, O, T, S, Z, J, L,
    
    pub fn getBlocks(self: Tetromino) [4]Vec3i;
    pub fn getColor(self: Tetromino, spectrum: Spectrum) rl.Color;
};
```

### 2.2 Physics Integration
- [ ] Each block = localized k-mode excitation
- [ ] Block mass affects gravity (α_g from N)
- [ ] Locked blocks create standing waves in substrate
- [ ] Line clears = energy release (particle annihilation)

---

## Phase 3: Rendering System

### 3.1 Panel Layout
```
┌─────────────┬──────────────┬─────────────┐
│             │              │             │
│  K-Space    │   3D tautris  │  X-Space    │
│  (2D Field) │  (3D Game)   │  (2D Proj)  │
│             │              │             │
│  400x900    │   800x900    │  400x900    │
│             │              │             │
└─────────────┴──────────────┴─────────────┘
       ↑              ↑              ↑
   Substrate    Raylib 3D      Inverse
   Amplitude     Camera       Fourier
```

### 3.2 K-Space Renderer (Left Panel)
```zig
// renderer_kspace.zig
pub fn renderKSpace(
    substrate: *KSpaceSubstrate,
    x: i32, y: i32, width: i32, height: i32,
    view: ViewState,
) void {
    // Same as working viewer
    // Color by phase amplitude
    // Show wave interference patterns
}
```

### 3.3 3D tautris Renderer (Center Panel)
```zig
// renderer_3d.zig
pub fn rendertautris3D(
    game: *tautrisGame,
    physics: PhysicsState,
    spectrum: Spectrum,
    camera: rl.Camera3D,
) void {
    rl.BeginMode3D(camera);
    defer rl.EndMode3D();
    
    // Grid (10x10x20)
    drawGrid();
    
    // Locked pieces
    for (game.grid) |layer, y| {
        for (layer) |row, x| {
            for (row) |cell, z| {
                if (cell) drawBlock(x, y, z, ...);
            }
        }
    }
    
    // Current falling piece
    drawTetromino(game.current_piece, game.position, game.rotation);
    
    // Ghost piece (preview landing)
    drawGhost(game);
}

fn drawBlock(x: i32, y: i32, z: i32, color: rl.Color) void {
    const pos = rl.Vector3{
        .x = @floatFromInt(x),
        .y = @floatFromInt(y),
        .z = @floatFromInt(z),
    };
    rl.DrawCube(pos, 0.9, 0.9, 0.9, color);
    rl.DrawCubeWires(pos, 1.0, 1.0, 1.0, rl.BLACK);
}
```

### 3.4 X-Space Renderer (Right Panel)
```zig
// renderer_xspace.zig
pub fn renderXSpace(
    substrate: *KSpaceSubstrate,
    x: i32, y: i32, width: i32, height: i32,
    physics: PhysicsState,
) void {
    // Inverse Fourier transform (expensive!)
    // OR: Direct projection using N^(2/3) scaling
    
    // Option 1: Full inverse FFT (toggleable, slow)
    if (use_full_fft) {
        const xspace = inverseFourier2D(substrate);
        renderField(xspace, x, y, width, height);
    }
    
    // Option 2: Holographic projection (fast approximation)
    else {
        const scale = physics.holographic_scale();
        renderProjected(substrate, scale, x, y, width, height);
    }
}
```

---

## Phase 4: UI Controls

### 4.1 Parameter Sliders (Left Sidebar)
```zig
// ui_controls.zig
pub const UIState = struct {
    N_slider: f64,  // Adjustable universe age
    N_min: f64 = 1e50,
    N_max: f64 = 1e70,
    
    show_kspace: bool = true,
    show_xspace: bool = true,
    render_mode: RenderMode = .XSpace,
    
    spectrum_wavelength: f32 = 550.0,  // nm (visible light)
    
    show_fps: bool = true,
    show_physics_info: bool = true,
};

pub fn drawControls(ui: *UIState, x: i32, y: i32) void {
    // N slider
    rl.GuiSlider(...);
    
    // Toggles
    rl.GuiCheckBox("K-Space View", ...);
    rl.GuiCheckBox("X-Space View", ...);
    
    // Spectrum slider (400-700 nm visible)
    rl.GuiSlider("Wavelength (nm)", ...);
    
    // Mode toggle
    rl.GuiToggle("K-Space/X-Space", ...);
}
```

### 4.2 Info Panels
```zig
pub fn drawPhysicsInfo(physics: PhysicsState, x: i32, y: i32) void {
    var buffer: [256]u8 = undefined;
    
    // Current N
    const n_text = std.fmt.bufPrintZ(&buffer, 
        "N = {d:.2e}", .{physics.N}) catch unreachable;
    rl.DrawText(n_text.ptr, x, y, 16, rl.WHITE);
    
    // Force couplings
    const alpha_text = std.fmt.bufPrintZ(&buffer,
        "α⁻¹ = {d:.3f}", .{physics.alpha_em_inv()}) catch unreachable;
    rl.DrawText(alpha_text.ptr, x, y + 20, 16, rl.WHITE);
    
    // Gravity
    const g_text = std.fmt.bufPrintZ(&buffer,
        "αg = {d:.2e}", .{physics.alpha_g()}) catch unreachable;
    rl.DrawText(g_text.ptr, x, y + 40, 16, rl.WHITE);
    
    // Dark energy
    const de_text = std.fmt.bufPrintZ(&buffer,
        "ρΛ = {d:.2e}", .{physics.dark_energy_density()}) catch unreachable;
    rl.DrawText(de_text.ptr, x, y + 60, 16, rl.WHITE);
}

pub fn drawGameInfo(game: *tautrisGame, x: i32, y: i32) void {
    // Score, level, lines
    // FPS counter
    // Current piece preview
}
```

---

## Phase 5: Spectrum & Visualization

### 5.1 Light Spectrum
```zig
// spectrum.zig
pub const Spectrum = struct {
    wavelength_nm: f32,  // 400-700 (visible)
    
    pub fn toRGB(self: Spectrum) rl.Color {
        // Wavelength to RGB conversion
        // 400-450: violet
        // 450-495: blue
        // 495-570: green
        // 570-590: yellow
        // 590-620: orange
        // 620-700: red
    }
    
    pub fn fromPhysics(physics: PhysicsState) Spectrum {
        // Map α_em or other constant to wavelength
        // Example: α⁻¹ = 137 → green (550nm)
    }
};
```

### 5.2 Mode Toggles
- **K-Space mode**: Render center panel as 2D substrate (like viewer)
- **X-Space mode**: Render center panel as 3D tautris
- Toggle key: `TAB`

---

## Phase 6: Controls & Game Loop

### 6.1 Input Mapping
```zig
// tautris controls
WASD:      Move piece (X/Z plane)
Arrow Up:  Rotate X axis
Arrow Down: Rotate Y axis  
Arrow L/R: Rotate Z axis
Space:     Hard drop
Shift:     Soft drop

// Camera (3D view)
Mouse drag: Orbit camera
Scroll:    Zoom

// UI
TAB:       Toggle K-Space/X-Space rendering
F1:        Toggle info panels
F2:        Toggle FPS
P:         Save screenshot
N:         Adjust N slider (hold and scroll)
```

### 6.2 Main Loop
```zig
pub fn main() !void {
    // Setup
    var substrate = try KSpaceSubstrate.init(allocator, 512);
    var game = tautrisGame.init();
    var physics = PhysicsState{ .N = 9e60 };
    var ui = UIState{};
    
    var camera = rl.Camera3D{
        .position = .{ .x = 15, .y = 20, .z = 15 },
        .target = .{ .x = 5, .y = 10, .z = 5 },
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45,
        .projection = rl.CAMERA_PERSPECTIVE,
    };
    
    while (!rl.WindowShouldClose()) {
        const dt = rl.GetFrameTime();
        
        // Update physics from UI
        physics.N = ui.N_slider;
        
        // Update substrate (wave evolution)
        substrate.step(dt, physics);
        
        // Update game
        game.update(dt);
        handleInput(&game, &camera, &ui);
        
        // Inject locked pieces into substrate
        if (game.piece_locked) {
            game.injectIntoSubstrate(&substrate);
        }
        
        // Render
        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.BLACK);
        
        // Left panel: K-Space
        if (ui.show_kspace) {
            renderKSpace(&substrate, 0, 0, 400, 900, ...);
        }
        
        // Center panel: tautris or K-Space fullscreen
        if (ui.render_mode == .XSpace) {
            rendertautris3D(&game, physics, ui.spectrum, camera);
        } else {
            renderKSpace(&substrate, 400, 0, 800, 900, ...);
        }
        
        // Right panel: X-Space
        if (ui.show_xspace) {
            renderXSpace(&substrate, 1200, 0, 400, 900, physics);
        }
        
        // UI overlays
        drawControls(&ui, 10, 10);
        drawPhysicsInfo(physics, 10, 800);
        drawGameInfo(&game, 1210, 10);
        
        if (ui.show_fps) {
            const fps_text = std.fmt.bufPrintZ(&buffer, 
                "FPS: {d}", .{rl.GetFPS()}) catch unreachable;
            rl.DrawText(fps_text.ptr, 650, 10, 20, rl.GREEN);
        }
    }
}
```

---

## Phase 7: Physics Integration Details

### 7.1 Block → K-Space Mapping
```zig
fn injectBlock(substrate: *KSpaceSubstrate, pos: Vec3i, piece: Tetromino, physics: PhysicsState) void {
    // Each block creates localized k-mode excitation
    const k_x = @as(f32, @floatFromInt(pos.x)) * physics.holographic_scale();
    const k_y = @as(f32, @floatFromInt(pos.z)) * physics.holographic_scale();
    
    // Mass determines amplitude
    const mass = physics.lepton_mass(piece);
    const amplitude = @sqrt(mass);
    
    // Inject Gaussian pulse
    substrate.addGaussian(k_x, k_y, amplitude, width);
}
```

### 7.2 Gravity from α_g
```zig
fn applyGravity(game: *tautrisGame, physics: PhysicsState, dt: f32) void {
    const g = physics.gravity_coupling() * 100.0;  // Scale for gameplay
    game.velocity.y -= g * dt;
}
```

### 7.3 Line Clear = Annihilation
```zig
fn clearLine(substrate: *KSpaceSubstrate, y: i32) void {
    // Particle-antiparticle annihilation
    // Release energy as wave burst
    substrate.addRadialWave(y, amplitude, frequency);
}
```

---

## Implementation Order

### Week 1: Core Structure
1. Split working viewer into modules
2. Set up 3-panel layout (basic)
3. Implement PhysicsState with all derivations
4. Test parameter changes affect display

### Week 2: tautris Mechanics
1. Implement tautrisGame (2D first, then 3D)
2. Basic collision detection
3. Piece rotation (quaternions)
4. Score/level system

### Week 3: 3D Rendering
1. Raylib 3D camera setup
2. Render tautris grid
3. Render falling/locked pieces
4. Ghost piece preview

### Week 4: Integration
1. Connect game events to substrate
2. Implement X-space projection
3. UI sliders and controls
4. Spectrum visualization

### Week 5: Polish
1. FPS optimization
2. Visual effects (particle bursts)
3. Sound effects (optional)
4. Save/load game state

---

## Performance Considerations

- **K-Space**: Already optimized (512×512 substrate)
- **3D tautris**: Lightweight (max 200 blocks)
- **X-Space**: Heavy (inverse FFT) → optional toggle
- Target: 60 FPS with all panels active (30 FPS acceptable with X-space FFT)

---

## Success Criteria

- [ ] All physics quantities derive from single N parameter
- [ ] tautris gameplay smooth at 60 FPS (center panel)
- [ ] K-space visualization shows wave interference
- [ ] X-space projection renders (even if slow)
- [ ] UI sliders change physics in real-time
- [ ] Game events affect substrate visibly
- [ ] Spectrum maps to physics constants
- [ ] Can toggle between K/X rendering modes
- [ ] Screenshot/save functionality works

---

## Future Extensions

- Multiplayer (two players, two substrates)
- Campaign mode (unlock physics regimes)
- Sandbox mode (pure physics playground, no game)
- VR support (full 3D immersion)
- Custom piece shapes from eigenmodes
- Replay system with substrate evolution

---

**Ready to implement?** Start with Phase 1 modularization. Want me to begin with the file structure and first module?