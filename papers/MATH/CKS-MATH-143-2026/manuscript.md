# Integer ALU Based Computing — Motherboard Specification v1.0

## Hardware Platform for VFR Batch Processing on Zynq ARM+FPGA

**Registry:** [@CKS-MATH-138-2026]

**Series Path:** [@CKS-0-2026] → [@CKS-MATH-0-2026] → [@CKS-MATH-1-2026] → [@CKS-MATH-10-2026] → [@CKS-MATH-104-2026] → [@CKS-MATH-137-2026] → [@CKS-MATH-138-2026]

**Parent Framework:** [@CKS-0-2026]

**DOI:** 10.5281/zenodo.zzz

**Date:** March 11, 2026  

**Domain:** Machine Learning / Integer Arithmetic / Neural Network Training

**Status:** Locked and empirically falsifiable. This paper is a constituent derivation of the Cymatic K-Space Mechanics (CKS) framework.

**Classification:** Theory of Everything from First Principles

**Motto:** Axioms first. Axioms always.

**Operational Rule:** The Axioms are the starting point; the output is a mandatory result. Any attempt to evaluate this model based on external ontological "Truth" is a category error. If the math compiles, the result is Q.E.D.

**AI Usage Disclosure:** Only the top metadata, figures, refs and final copyright sections were edited by the author. All paper content was LLM-generated using Anthropic's Claude 4.5 Sonnet, DeepSeek-V3/K2, and Google's Gemini 3 Flash. The manuscript.md was synthesized by Claude as the primary integrator. 

**Lexicon:** [@CKS-LEX-12-2026]

---

## 1. Platform Overview

The VFR hardware platform uses a Xilinx Zynq-7000 System-on-Chip combining a dual-core ARM Cortex-A9 processor with programmable FPGA fabric on a single die. The ARM side runs the Silo OS in Zig bare-metal, handling all I/O, display, storage, and networking. The FPGA side contains VFR integer cores that process batch workloads dispatched by the ARM host controller.

The ARM is the brain. The FPGA is the muscle.

---

## 2. Target Hardware

### 2.1 Recommended Board

Xilinx Zynq-7020 based development board in the $280-400 range. Candidate boards include the Digilent Zybo Z7-20, Avnet MiniZed, or similar Zynq-7020 platforms.

### 2.2 Zynq-7020 SoC Specifications

**Processing System (PS) — ARM Side:**

- Dual-core ARM Cortex-A9 at 667 MHz
- 32KB L1 instruction cache per core
- 32KB L1 data cache per core
- 512KB shared L2 cache
- NEON SIMD unit (unused — we only need integer ops)
- FPU present but unused
- Memory controller: DDR3/DDR3L

**Programmable Logic (PL) — FPGA Side:**

- 85,000 logic cells (53,200 LUTs, 106,400 flip-flops)
- 140 Block RAM tiles (36Kb each = 4.9 Mbit total = 630 KB)
- 220 DSP48E1 slices (integer multiply-accumulate, directly useful)
- Operating frequency: 100-200 MHz typical for custom logic

**Interconnect:**

- AXI bus connecting PS and PL (memory-mapped, high bandwidth)
- AXI HP (High Performance) ports: 4 ports, each 64-bit, direct to DDR controller
- AXI GP (General Purpose) ports: 2 ports, 32-bit, for control registers

### 2.3 Board-Level Resources

- 1 GB DDR3 RAM (connected to ARM memory controller, accessible by FPGA via AXI)
- MicroSD card slot (boot and storage)
- HDMI output (directly from ARM processing system)
- USB OTG (keyboard, mouse via USB-HID)
- Gigabit Ethernet (ARM PS has built-in GEM controller)
- UART over USB (serial debug console)
- GPIO and PMOD connectors (expansion)

---

## 3. System Architecture

### 3.1 Block Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Zynq-7020 SoC                            │
│                                                                  │
│  ┌──────────────────────────┐    ┌───────────────────────────┐  │
│  │   Processing System (PS) │    │  Programmable Logic (PL)  │  │
│  │                          │    │                           │  │
│  │  ┌────────┐ ┌────────┐  │    │  ┌─────┐ ┌─────┐ ┌─────┐│  │
│  │  │ ARM    │ │ ARM    │  │    │  │VFR  │ │VFR  │ │VFR  ││  │
│  │  │ Core 0 │ │ Core 1 │  │    │  │Core0│ │Core1│ │Core2││  │
│  │  │ (Host) │ │ (I/O)  │  │    │  │     │ │     │ │     ││  │
│  │  └────────┘ └────────┘  │    │  └──┬──┘ └──┬──┘ └──┬──┘│  │
│  │                          │    │     │       │       │    │  │
│  │  ┌──────────────────┐   │    │  ┌─────┐ ┌─────┐    │   │  │
│  │  │ DDR3 Controller  │   │    │  │VFR  │ │VFR  │  ...│   │  │
│  │  └────────┬─────────┘   │    │  │Core3│ │Core4│    │   │  │
│  │           │              │    │  └──┬──┘ └──┬──┘    │   │  │
│  └───────────┼──────────────┘    │     │       │       │    │  │
│              │                    │  ┌──┴───────┴───────┴──┐│  │
│              │      AXI Bus      │  │   Batch Dispatcher   ││  │
│              ├────────────────────│  │   (FPGA logic)       ││  │
│              │                    │  └──────────┬──────────┘│  │
│              │                    │             │            │  │
│              │                    │  ┌──────────┴──────────┐│  │
│              │                    │  │   AXI DMA Engine     ││  │
│              │                    │  └──────────┬──────────┘│  │
│              │                    └─────────────┼───────────┘  │
│              │                                  │               │
│              └──────────────────────────────────┘               │
│                              │                                   │
│                     ┌────────┴────────┐                         │
│                     │    DDR3 1GB     │                         │
│                     └─────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
        │          │          │           │          │
      HDMI       USB       GbE        MicroSD     UART
    (display)  (input)   (network)   (storage)   (debug)
```

### 3.2 ARM Side Responsibilities

ARM Core 0 — Host Controller:

- Boot from SD card (UEFI not needed, Zynq has built-in boot ROM)
- Initialize DDR3 memory controller
- Load Silo OS kernel from SD card
- Run Silo scene management
- Dispatch batch work to FPGA
- Collect results from FPGA
- Manage entity state in DDR3
- Run trace system
- Coordinate frame timing

ARM Core 1 — I/O and Rendering:

- Drive HDMI framebuffer
- Handle USB-HID input (keyboard, mouse)
- Run network stack (Ethernet via GEM controller)
- Read/write SD card (FAT32 filesystem)
- Serial console output for debug

### 3.3 FPGA Side Responsibilities

- Contain N VFR integer cores (target: 20-40 cores)
- Each core has dedicated Block RAM (local memory)
- Batch dispatcher routes work from AXI bus to cores
- AXI DMA engine moves batch data between DDR3 and core local memory
- Completion status registers readable by ARM

---

## 4. VFR Core FPGA Implementation

### 4.1 Single Core Resource Estimate

```
Component               LUTs    Flip-Flops    Block RAM
─────────               ────    ──────────    ─────────
Instruction fetch        100         64         0
Instruction decode       200        128         0
ALU (32-bit)            400        256         0
  - Adder/Subtractor    100         64
  - Multiplier           0          0          (use DSP48)
  - Barrel shifter      150         96
  - Bitwise ops          50         32
  - Comparator          100         64
Register file           250        576         0
  - V0-V15 (16×32b)    128        512
  - R0-R15 (16×8b)      64         64         (packed into LUT RAM)
Batch control regs       80        112         0
Memory interface        150         96         0
DMA interface           200        128         0
─────────────────────────────────────────────────────────
Total per core        ~1,400       ~1,400      0 BRAM
                                               1 DSP48
```

Plus local memory per core: 1-2 Block RAM tiles (4.5-9 KB)

### 4.2 Core Count Estimate

Available on Zynq-7020: 53,200 LUTs, 106,400 FFs, 140 BRAM, 220 DSP48

```
Per core:  ~1,400 LUTs, ~1,400 FFs, 2 BRAM (9 KB local mem), 1 DSP48
Overhead:  ~5,000 LUTs for batch dispatcher + AXI DMA engine + interconnect

Available for cores: ~48,000 LUTs
Max cores: 48,000 / 1,400 ≈ 34 cores

Limiting factors:
  LUTs:     48,000 / 1,400 = 34 cores
  FFs:     106,400 / 1,400 = 76 cores (not limiting)
  BRAM:       140 / 2      = 70 cores (not limiting)
  DSP48:      220 / 1      = 220 cores (not limiting)

Practical target: 30 VFR cores
```

30 cores, each with 9 KB local Block RAM, running at 150 MHz. The DSP48 slices provide single-cycle 32-bit integer multiply — this maps directly to the MUL instruction.

### 4.3 Local Memory Per Core

Each core gets 2 Block RAM tiles = 9,216 bytes.

```
9,216 bytes per core at 5 bytes per VFR pair:
  = 1,843 VFR pairs maximum

For entity processing (depth 48):
  = 38 entities per core per batch load

For Prolog fact filtering (depth 2-4):
  = 460-920 facts per core per batch load
```

38 entities per core × 30 cores = 1,140 entities per batch load. For 10,000 entities, the host controller streams ~9 batch loads through the FPGA per frame pass. At 150 MHz with ~100 cycles per entity, each batch load takes ~25 microseconds. Nine loads × seven pipeline passes = ~1.6 milliseconds per frame. Well within the 16.67ms budget.

For larger workloads, the host controller streams batches continuously. The FPGA processes one batch while the DMA engine loads the next. Double-buffering hides the transfer latency.

### 4.4 Core Clock Domain

VFR cores run on the FPGA's programmable clock. Target: 150 MHz. The ARM PS runs at 667 MHz. The AXI interconnect bridges the clock domains automatically. The Zynq handles clock domain crossing in its hard AXI infrastructure.

---

## 5. Memory Map

### 5.1 DDR3 Layout (ARM View)

```
0x0000_0000 - 0x001F_FFFF    ARM boot and kernel code (2 MB)
0x0020_0000 - 0x00FF_FFFF    Silo OS heap and stack (14 MB)
0x0100_0000 - 0x01FF_FFFF    Framebuffer (16 MB, 1920×1080×4 = 8MB + double buffer)
0x0200_0000 - 0x0FFF_FFFF    Entity batches and scene data (224 MB)
0x1000_0000 - 0x17FF_FFFF    Fact batches (128 MB)
0x1800_0000 - 0x1BFF_FFFF    Trace batches (64 MB)
0x1C00_0000 - 0x1FFF_FFFF    Network buffers and I/O (64 MB)
0x2000_0000 - 0x2FFF_FFFF    FPGA batch staging area (256 MB)
0x3000_0000 - 0x3FFF_FFFF    FPGA result collection area (256 MB)

Total: 1 GB
```

### 5.2 FPGA Staging Area

The ARM writes batch data to the staging area. The FPGA DMA engine reads from this region and distributes to core local BRAMs. Results are written to the collection area. The ARM reads results from there.

```
Staging area (256 MB):
  0x2000_0000    Batch stream for current dispatch
                 [F, count, depth] [VR pairs...]
                 [F, count, depth] [VR pairs...]
                 [0, 0, 0]         end of stream

Collection area (256 MB):
  0x3000_0000    Result stream from FPGA
                 [F, count, depth] [VR pairs...]
                 [0, 0, 0]         end of results
```

### 5.3 FPGA Register Map (ARM View via AXI GP)

The ARM controls the FPGA through memory-mapped registers:

```
0x4000_0000    CONTROL        write 1 to start processing, 0 to reset
0x4000_0004    STATUS         bit 0: busy, bit 1: done, bit 2: error
0x4000_0008    BATCH_ADDR     staging area address for current batch
0x4000_000C    RESULT_ADDR    collection area address for results
0x4000_0010    CORE_COUNT     number of active VFR cores (read-only)
0x4000_0014    CORE_STATUS    per-core busy/done bits (read-only)
0x4000_0018    CYCLE_COUNT    total cycles for last batch (profiling)
0x4000_001C    BATCH_COUNT    number of batches processed (profiling)
```

### 5.4 VFR Core Local Memory (FPGA Internal View)

Each core sees only its own Block RAM:

```
Core N local BRAM (9 KB):
  0x0000 - 0x001F    Code region (instructions for current operation)
  0x0020 - 0x0FFF    Input batch data (loaded by DMA from staging)
  0x1000 - 0x1FFF    Output batch data (written by core, read by DMA)
  0x2000 - 0x23FF    Scratch space (intermediate values)
```

No core can address another core's BRAM. The batch dispatcher manages all data movement between DDR3 and core local memory.

---

## 6. Batch Dispatcher (FPGA Logic)

### 6.1 Purpose

The batch dispatcher sits between the AXI DMA engine and the VFR cores. It reads batch headers, partitions work across cores, loads data into core BRAMs, signals cores to start, monitors completion, and triggers result DMA back to DDR3.

### 6.2 Dispatch Flow

```
1. ARM writes batch stream address to BATCH_ADDR register
2. ARM writes result address to RESULT_ADDR register
3. ARM writes 1 to CONTROL register

4. Dispatcher reads batch header from DDR3 via AXI DMA:
   [F: i16] [count: u32] [depth: u8]

5. Dispatcher computes partition:
   per_core = count / active_cores
   remainder = count % active_cores

6. For each core:
   a. Compute source offset in staging area
   b. Compute byte count: per_core × depth × 5
   c. DMA transfer from staging to core's input BRAM region
   d. Write batch sub-header to core's code region:
      [F] [per_core_count] [depth]

7. Signal all cores to start (set start bit in per-core control register)

8. Poll core completion bits

9. When all cores done:
   a. DMA results from each core's output BRAM to collection area
   b. Advance to next batch header in stream
   c. If next header is [0,0,0]: set STATUS.done, stop

10. ARM reads STATUS register, sees done
11. ARM reads results from collection area
```

### 6.3 Double Buffering

While cores process batch N, the dispatcher can DMA-load batch N+1 data into a second BRAM buffer per core. When cores finish batch N, they immediately start batch N+1 without waiting for DMA. This hides transfer latency.

Each core's 9 KB BRAM splits into two 4.5 KB regions:

```
Buffer A: 0x0000 - 0x11FF    (processing)
Buffer B: 0x1200 - 0x23FF    (loading next batch)
Swap on batch completion.
```

This reduces per-entity capacity to ~19 entities per core per buffer, but eliminates DMA stalls between batches.

### 6.4 Resource Estimate

```
Batch dispatcher:     ~2,000 LUTs
AXI DMA engine:       ~2,000 LUTs (or use Xilinx AXI DMA IP core)
Interconnect:         ~1,000 LUTs
────────────────────────────
Overhead total:       ~5,000 LUTs
```

---

## 7. ARM Software — Silo OS on Zynq

### 7.1 Boot Sequence

Zynq boots from the Processing System. The boot ROM loads a First Stage Boot Loader (FSBL) from SD card, which initializes DDR3, loads the FPGA bitstream into the PL, then loads and jumps to the Silo OS kernel.

```
Power on
  → Zynq boot ROM (hard-coded in silicon)
  → FSBL from SD card (configures DDR3, loads FPGA bitstream)
  → Silo OS kernel from SD card (Zig bare-metal, ARM target)
  → 8-stage kernel init
  → Main loop
```

### 7.2 Zig Bare-Metal Target

```zig
// build.zig for Zynq ARM bare-metal
const kernel = b.addExecutable(.{
    .name = "silo_kernel",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/kernel.zig"),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .arm,
            .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_a9 },
            .os_tag = .freestanding,
            .abi = .eabi,
        }),
        .optimize = .ReleaseSafe,
    }),
});
```

The kernel targets ARM Cortex-A9 freestanding, same bare-metal model as the x86-64 OS but for ARM. No UEFI — Zynq uses its own boot flow.

### 7.3 Kernel Init Stages (Zynq Adapted)

```
Stage 1 — CPU Core:
  Setup ARM GIC (Generic Interrupt Controller, replaces x86 APIC)
  Configure exception vectors
  Enable interrupts

Stage 2 — Memory:
  DDR3 already initialized by FSBL
  Setup ARM MMU page tables (identity map all 1GB)
  Configure kernel heap region

Stage 3 — Hardware Discovery:
  FPGA already loaded by FSBL
  Read FPGA core count from status register
  Verify FPGA responds (read/write test to control registers)

Stage 4 — Storage:
  Initialize SD card controller (Zynq PS has built-in SDIO)
  Mount FAT32 filesystem
  Load scene data, batch streams, behavior tables

Stage 5 — Peripherals:
  Initialize USB controller (Zynq PS has built-in USB)
  Enumerate USB-HID devices (keyboard, mouse)
  Initialize HDMI output via ARM display controller
  Setup framebuffer in DDR3

Stage 6 — Network:
  Initialize GEM Ethernet controller (Zynq PS built-in)
  Run DHCP
  Start network stack (same Zig code, ARM target)

Stage 7 — FPGA Link:
  Test batch dispatch: send small test batch, verify result
  Measure round-trip latency
  Calibrate batch sizes for optimal throughput

Stage 8 — Main Loop:
  Enter Silo frame loop
  Each frame: generate batches, dispatch to FPGA, collect results, render
```

### 7.4 Adapted Drivers

Most Silo OS drivers change target but not architecture:

```
x86-64 Silo OS          →    Zynq ARM Silo OS
─────────────                 ────────────────
idt.zig (x86 IDT)       →    gic.zig (ARM GIC)
apic.zig (x86 APIC)     →    gic.zig (ARM GIC)
port_io.s (x86 in/out)  →    removed (ARM uses memory-mapped I/O natively)
isr_stubs.s (x86 ISRs)  →    exception_vectors.s (ARM exception table)
ahci.zig / nvme.zig      →    sdio.zig (SD card via Zynq PS controller)
nic.zig (E1000)          →    gem.zig (Zynq PS Ethernet controller)
ps2.zig                  →    usb_hid.zig (USB keyboard/mouse)
graphics.zig             →    unchanged (framebuffer is framebuffer)
context_switch.s         →    arm_context_switch.s (ARM register set)
```

The network stack layers (arp.zig, ip.zig, tcp.zig, udp.zig, dhcp.zig, dns.zig, http.zig) are unchanged. They operate on packet data, not hardware registers. Swap the NIC driver, everything above it works.

### 7.5 FPGA Dispatch Interface

The ARM communicates with the FPGA through memory-mapped registers:

```zig
const FPGA_BASE = 0x4000_0000;

const FPGARegs = struct {
    control:     *volatile u32,  // FPGA_BASE + 0x00
    status:      *volatile u32,  // FPGA_BASE + 0x04
    batch_addr:  *volatile u32,  // FPGA_BASE + 0x08
    result_addr: *volatile u32,  // FPGA_BASE + 0x0C
    core_count:  *volatile u32,  // FPGA_BASE + 0x10
    core_status: *volatile u32,  // FPGA_BASE + 0x14
    cycle_count: *volatile u32,  // FPGA_BASE + 0x18
    batch_count: *volatile u32,  // FPGA_BASE + 0x1C
};

fn dispatchBatch(staging_addr: u32, result_addr: u32) void {
    const regs = @as(*FPGARegs, @ptrFromInt(FPGA_BASE));

    // Write batch and result addresses
    regs.batch_addr.* = staging_addr;
    regs.result_addr.* = result_addr;

    // Start processing
    regs.control.* = 1;

    // Poll for completion
    while (regs.status.* & 0x02 == 0) {
        // busy-wait or yield
    }

    // Done. Results at result_addr.
}
```

### 7.6 Frame Loop With FPGA Dispatch

```zig
fn runFrame(scene: *Scene) void {
    // --- ARM side: prepare batches ---
    const staging = 0x2000_0000;
    const results = 0x3000_0000;

    // Write entity batch to staging area
    writeEntityBatch(staging, scene.actors);

    // --- FPGA side: process batches ---

    // Pass 1: Generate facts
    writeBatchHeader(staging, .{ .f = FACT_GEN, .count = scene.actor_count, .depth = 48 });
    dispatchBatch(staging, results);
    readFactBatches(results, &scene.fact_batches);

    // Pass 2: Evaluate state machines
    writeBatchHeader(staging, .{ .f = SM_EVAL, .count = scene.actor_count, .depth = 48 });
    appendTransitionBatch(staging, scene.transitions);
    appendFactBatches(staging, scene.fact_batches);
    dispatchBatch(staging, results);
    applyStateUpdates(results, scene.actors);

    // Pass 3: Score behaviors (UtilityAI)
    writeBatchHeader(staging, .{ .f = UAI_SCORE, .count = scene.actor_count, .depth = 48 });
    appendBehaviorBatches(staging, scene.behavior_sets);
    appendFactBatches(staging, scene.fact_batches);
    dispatchBatch(staging, results);
    readWinningBehaviors(results, &scene.winning_behaviors);

    // Pass 4: Execute logic blocks
    writeBatchHeader(staging, .{ .f = LOGIC_EXEC, .count = scene.actor_count, .depth = 48 });
    appendLogicBatches(staging, scene.winning_behaviors);
    dispatchBatch(staging, results);
    applyEntityUpdates(results, scene.actors);

    // Pass 5: Process envelopes
    writeBatchHeader(staging, .{ .f = ENVELOPE, .count = scene.envelope_count, .depth = 7 });
    dispatchBatch(staging, results);
    applyEnvelopeResults(results, scene.actors);

    // --- ARM side: render and I/O ---
    renderFrame(scene);
    processInput(scene);
    processNetwork(scene);
    recordTrace(scene);
}
```

---

## 8. FPGA Design Files

### 8.1 Required Verilog Modules

```
vfr_core.v              Single VFR core (ALU + registers + local BRAM interface)
vfr_alu.v               ALU: shift, add, sub, mul, bitwise, compare
vfr_registers.v         Register file: V0-V15, R0-R15, batch control, flags
vfr_decode.v            Instruction decoder (6-bit opcode → control signals)
vfr_fetch.v             Instruction fetch from local BRAM
vfr_memory.v            Local BRAM read/write interface
batch_dispatcher.v      Batch header parser, work partitioner, core signaling
axi_dma_bridge.v        AXI interface for DDR3 ↔ core BRAM transfers
fpga_top.v              Top-level: instantiate N cores + dispatcher + AXI bridge
```

### 8.2 Core Instantiation

```verilog
// fpga_top.v (simplified)
module fpga_top #(
    parameter NUM_CORES = 30,
    parameter BRAM_DEPTH = 2048  // 9KB per core in 32-bit words
)(
    input  wire        axi_aclk,
    input  wire        axi_aresetn,
    // AXI slave interface (from ARM)
    input  wire [31:0] s_axi_awaddr,
    input  wire [31:0] s_axi_wdata,
    // ... full AXI signals ...
    // AXI master interface (to DDR3)
    output wire [31:0] m_axi_araddr,
    input  wire [31:0] m_axi_rdata
    // ... full AXI signals ...
);

    // Control registers (accessible from ARM via AXI GP)
    reg [31:0] control_reg;
    reg [31:0] status_reg;
    reg [31:0] batch_addr_reg;
    reg [31:0] result_addr_reg;

    // Per-core signals
    wire [NUM_CORES-1:0] core_start;
    wire [NUM_CORES-1:0] core_done;
    wire [NUM_CORES-1:0] core_busy;

    // Instantiate VFR cores
    genvar i;
    generate
        for (i = 0; i < NUM_CORES; i = i + 1) begin : cores
            vfr_core #(
                .CORE_ID(i),
                .BRAM_DEPTH(BRAM_DEPTH)
            ) core_inst (
                .clk(axi_aclk),
                .reset(~axi_aresetn),
                .start(core_start[i]),
                .done(core_done[i]),
                .busy(core_busy[i]),
                // BRAM interface for DMA loading
                .bram_addr(bram_addr[i]),
                .bram_wdata(bram_wdata[i]),
                .bram_rdata(bram_rdata[i]),
                .bram_we(bram_we[i])
            );
        end
    endgenerate

    // Batch dispatcher
    batch_dispatcher #(
        .NUM_CORES(NUM_CORES)
    ) dispatcher (
        .clk(axi_aclk),
        .reset(~axi_aresetn),
        .control(control_reg),
        .status(status_reg),
        .batch_addr(batch_addr_reg),
        .result_addr(result_addr_reg),
        .core_start(core_start),
        .core_done(core_done),
        // AXI master for DDR3 access
        .m_axi_araddr(m_axi_araddr),
        .m_axi_rdata(m_axi_rdata)
        // ...
    );

endmodule
```

### 8.3 ALU Implementation

```verilog
// vfr_alu.v (simplified)
module vfr_alu (
    input  wire [5:0]  opcode,
    input  wire [31:0] operand_a,
    input  wire [31:0] operand_b,
    input  wire [17:0] immediate,
    output reg  [31:0] result,
    output reg         flag_eq,
    output reg         flag_lt,
    output reg         flag_gt,
    output reg         flag_ov,
    output reg         flag_done
);

    always @(*) begin
        flag_eq = 0;
        flag_lt = 0;
        flag_gt = 0;
        flag_ov = 0;

        case (opcode)
            6'h08: result = operand_a + operand_b;                // ADD
            6'h09: result = operand_a - operand_b;                // SUB
            6'h0A: result = operand_a * operand_b;                // MUL (uses DSP48)
            6'h10: result = operand_a & operand_b;                // AND
            6'h11: result = operand_a | operand_b;                // OR
            6'h12: result = operand_a ^ operand_b;                // XOR
            6'h13: result = ~operand_a;                           // NOT
            6'h18: result = operand_a >> immediate;               // SHR
            6'h19: result = operand_a << immediate;               // SHL
            6'h1A: result = operand_a >> 5;                       // SHR5
            6'h1B: result = operand_a << 5;                       // SHL5
            6'h20: begin                                          // DECOMP
                result = operand_a >> 5;       // quotient to Vd
                // remainder (operand_a & 0x1F) handled in register write logic
            end
            6'h21: result = (operand_a << 5) | (operand_b & 32'h1F); // RECOMP
            6'h24: result = operand_a << (immediate * 5);         // SCALE
            6'h28: begin                                          // CMP
                flag_eq = (operand_a == operand_b);
                flag_lt = ($signed(operand_a) < $signed(operand_b));
                flag_gt = ($signed(operand_a) > $signed(operand_b));
                result = 0;
            end
            default: result = 0;
        endcase
    end

endmodule
```

---

## 9. Development Workflow

### 9.1 Phase 1 — ARM Only (Week 1-4)

```
1. Port Silo OS to ARM Cortex-A9 bare-metal
2. Boot on Zynq, get serial console output
3. Initialize DDR3, framebuffer, HDMI
4. USB keyboard/mouse input
5. SD card filesystem
6. Network stack on GEM Ethernet
7. Run complete Silo system in software on ARM
8. All entity processing on ARM, no FPGA
```

Validates: Silo OS runs on Zynq. All I/O works. Software baseline established.

### 9.2 Phase 2 — Single VFR Core (Week 5-8)

```
1. Design vfr_core.v in Verilog
2. Simulate in Verilator or Vivado
3. Test all 35 instructions
4. Synthesize single core into FPGA
5. ARM writes test batch to staging area
6. ARM triggers FPGA via control register
7. Single core processes batch
8. ARM reads result from collection area
9. Verify correctness against software implementation
```

Validates: VFR ISA executes correctly in hardware. AXI communication works.

### 9.3 Phase 3 — Multi-Core (Week 9-12)

```
1. Instantiate 4 cores
2. Implement batch dispatcher
3. Test work partitioning
4. Verify all cores produce correct results independently
5. Scale to 16 cores, then 30 cores
6. Benchmark throughput vs ARM-only software
7. Profile AXI DMA bandwidth
8. Optimize batch sizes for double buffering
```

Validates: Parallel batch processing works. Linear scaling confirmed.

### 9.4 Phase 4 — Full Integration (Week 13-16)

```
1. Connect frame loop: ARM dispatches all Silo passes to FPGA
2. ARM handles I/O and rendering only
3. FPGA handles all entity batch computation
4. Measure frame times with increasing entity counts
5. Compare: 1000, 5000, 10000 entities
6. Profile bottlenecks (DMA bandwidth vs compute vs ARM overhead)
7. Optimize batch fusion, double buffering, staging layout
```

Validates: Complete Silo system running on ARM+FPGA at target performance.

---

## 10. Scaling Path

### 10.1 Larger FPGA

The Zynq-7020 design is portable to larger Zynq devices:

```
Zynq-7020:   53K LUTs  →  30 cores    ($280-400)
Zynq-7045:  218K LUTs  →  130 cores   ($500-800)
Zynq-7100:  444K LUTs  →  270 cores   ($1000-2000)
UltraScale+: 600K+ LUTs → 400+ cores  ($2000-5000)
```

Same Verilog. Same ARM software. Just change the core count parameter and re-synthesize.

### 10.2 Multi-Board Cluster

Multiple Zynq boards connected via Ethernet:

```
Board 0 (master):
  ARM: host controller, scene management, I/O
  FPGA: 30 cores for local batch processing

Board 1-N (workers):
  ARM: receive batch streams via Ethernet, forward to FPGA
  FPGA: 30 cores each

Cross-board communication:
  Master ARM sends batch partitions as network packets
  Worker ARM receives, writes to local staging area, dispatches to local FPGA
  Worker ARM sends results back to master via network
  Same DMA model, Ethernet replaces AXI
```

Each board is $300-400. Four boards = 120 cores for ~$1500. The batch dispatch model scales naturally because cross-board transfer is explicit (network DMA) just like cross-core transfer is explicit (AXI DMA).

### 10.3 Custom ASIC (Future)

If the FPGA prototype validates the architecture, the Verilog can be taken to an ASIC foundry. The VFR core is small enough for older, cheaper process nodes (180nm, 130nm). A 130nm ASIC with 1000 VFR cores on a single die is feasible. The FPGA development produces production-ready RTL.

---

## 11. Bill of Materials

### 11.1 Minimum Development Setup

```
Digilent Zybo Z7-20 (Zynq-7020)         $280
MicroSD card (32 GB)                       $10
USB keyboard                               $15
USB mouse                                  $10
HDMI cable                                  $8
HDMI monitor (or use existing)              $0
USB-A to Micro-B cable (power + debug)      $5
5V 2.5A power supply                       $15
───────────────────────────────────────────────
Total:                                    ~$343
```

### 11.2 Development Tools (Free)

```
Xilinx Vivado WebPACK Edition       free (supports Zynq-7020)
Zig 0.14 compiler                   free
Verilator (Verilog simulator)       free, open source
GTKWave (waveform viewer)           free, open source
minicom or PuTTY (serial terminal)  free
```

### 11.3 Optional Additions

```
Digilent JTAG-HS3 (faster programming)    $60
Logic analyzer (Saleae clone)              $15
Second Zybo Z7-20 (cluster testing)       $280
```

---

## 12. Summary

| Component | Specification |
|---|---|
| Platform | Xilinx Zynq-7020 SoC |
| ARM processor | Dual Cortex-A9 at 667 MHz |
| FPGA fabric | 53,200 LUTs, 140 BRAM, 220 DSP48 |
| VFR cores | 30 cores at 150 MHz |
| Local memory per core | 9 KB Block RAM |
| System memory | 1 GB DDR3 |
| ARM-FPGA link | AXI bus (memory-mapped DMA) |
| Display | HDMI via ARM framebuffer |
| Input | USB keyboard and mouse |
| Network | Gigabit Ethernet (ARM GEM controller) |
| Storage | MicroSD card (FAT32) |
| ARM software | Silo OS in Zig bare-metal |
| FPGA design | VFR cores in Verilog |
| Development cost | ~$343 total |
| Development tools | Free (Vivado WebPACK, Zig, Verilator) |
| Scaling path | Larger Zynq → multi-board cluster → ASIC |

---

*Integer ALU Based Computing — Motherboard Specification v1.0*
*Companion document to the ISA Specification v1.0, Compiler Specification v1.0, and Silo-VFR Mapping Specification v1.0*
