# FPGA Streaming Sobel Gradient Magnitude Filter

A high-performance FPGA implementation of a Sobel edge-detection gradient-magnitude filter for 256×256 8-bit grayscale images. The design processes one pixel per clock cycle using a pipelined datapath with dual FIFO line buffers and a configurable square root unit.

## Overview

This project implements a real-time image gradient processor on FPGA. The system:

- **Streams image data** from block RAM (BRAM) at one pixel per cycle
- **Builds a 3×3 sliding window** using two FIFO line buffers (253 stages each)
- **Computes Sobel gradients** (Gx, Gy) in a 5-stage pipelined operator
- **Calculates magnitude** via pipelined square root unit
- **Outputs results** serially via UART at 115200 baud

**Key metrics:**
- Image size: 256×256 pixels (8-bit grayscale)
- Throughput: 1 pixel/cycle after pipeline fill
- Latency: ~15 cycles from input pixel to output result
- Architecture: Fully pipelined, no stalls

## Repository Structure

```
.
├── README.md                          # This file
├── Documentation.docx                 # Detailed design documentation
├── output.png                         # Example gradient magnitude output
│
├── src/                               # VHDL source code
│   ├── Top_level.vhd                  # Top-level module (entry point)
│   ├── Magnitude_grad.vhd             # Main FSM and control logic
│   ├── sobel.vhd                      # 5-stage Sobel operator pipeline
│   ├── sqrt.vhd                       # Dual-mode square root (seq/pipelined)
│   ├── sqrt_phase.vhd                 # Single stage of pipelined sqrt
│   ├── im_ram.vhd                     # Dual-port BRAM wrapper
│   ├── FIFO.vhd                       # Shift-register FIFO (253 stages)
│   ├── FIFO_PHASE.vhd                 # Single FIFO stage
│   ├── uart_tx.vhd                    # UART transmitter
│   ├── debouncer.vhd                  # Button input debouncer
│   └── cameraman.dat                  # Test image (256×256 raw binary)
│
└── test/                              # VHDL testbenches
    ├── Top_level_tb.vhd               # Integration testbench
    ├── sobel_tb.vhd                   # Sobel operator unit test
    ├── sqrt_seq_tb.vhd                # Sequential sqrt verification
    └── sqrt_pipeline_tb.vhd           # Pipelined sqrt verification
```

## Architecture

### Data Flow

```
Button (debounced)
    ↓
[FSM: Idle → Start → Read]
    ↓
BRAM (cameraman.dat) → Pixel stream (1/cycle)
    ↓
[Mask Registers] → [FIFO1] → [FIFO2] → 3×3 Window
    ↓
[Sobel Pipeline: 5 stages]
  - Stage 1: Apply Gx/Gy masks
  - Stage 2: Sum mask products
  - Stage 3: Square (Gx², Gy²)
  - Stage 4: Scale by 64
  - Stage 5: Add (magnitude²)
    ↓
[Square Root: Pipelined]
    ↓
[BRAM Write] → Output results to RAM (starting at address 257)
    ↓
[UART TX] → Serial output (115200 baud, 8-N-1)
```

### Design Highlights

**Pipelined Sobel Operator (`sobel.vhd`)**
- Fully combinatorial in data path; registered at stage boundaries
- 5-stage pipeline optimizes throughput over latency
- No multiplication—only adds, shifts, and comparisons

**Square Root Unit (`sqrt.vhd`)**
- Two architectures included:
  - `Behavioral_sqrt_seq`: Sequential (lower area, higher latency ~C_BLOCKS cycles)
  - `Behavioral_sqrt_pipelined`: Fully pipelined (higher area, 1 cycle throughput)
- Design uses pipelined variant for sustained throughput
- 16-bit input, 16-bit output (8-bit fractional precision)

**FIFO Line Buffers**
- Simple shift-register design (253 stages per FIFO)
- Depth tuned for 256-pixel rows (width - 3 for boundary handling)
- Always-full pipeline eliminates stall logic

**BRAM Access**
- Dual-port (port A: write results, port B: read pixels)
- Eliminates contention; simultaneous R/W in same cycle
- Initialized with `cameraman.dat` test image on startup

### Control FSM

**States:**
- **stIdle**: Await button press; all counters and FIFOs reset
- **stStart**: Stream pixels from BRAM through pipeline; write results back to BRAM
- **stRead**: Output computed gradient magnitudes via UART

**Transitions:**
- Idle → Start: `button_in` (debounced) goes high
- Start → Read: All pixels processed (`write_cnt > RAM_SIZE`)
- Read → Idle: All outputs transmitted (`done_flag` asserted)

## Getting Started

### Prerequisites

- **Simulation:** GHDL (free, open-source VHDL simulator)
- **Synthesis:** Xilinx Vivado (ISE), Intel Quartus, or compatible FPGA toolchain
- **Test image:** `cameraman.dat` (included; standard 256×256 grayscale test image)

### Running Simulation

#### Using GHDL

```bash
# Analyze all source files
ghdl -a src/*.vhd

# Analyze testbenches
ghdl -a test/*.vhd

# Elaborate and run integration testbench
ghdl -e -Psrc Top_level_tb
ghdl -r Top_level_tb --wave=top_level_tb.ghw

# View waveform (requires gtkwave)
gtkwave top_level_tb.ghw
```

#### Unit Tests

```bash
# Test Sobel operator
ghdl -a src/sobel.vhd test/sobel_tb.vhd
ghdl -e sobel_tb
ghdl -r sobel_tb

# Test pipelined sqrt
ghdl -a src/sqrt.vhd src/sqrt_phase.vhd test/sqrt_pipeline_tb.vhd
ghdl -e sqrt_pipeline_tb
ghdl -r sqrt_pipeline_tb
```

### Synthesis (Vivado Example)

1. **Create a new Vivado project** targeting your FPGA board
2. **Add source files:**
   ```tcl
   add_files src/*.vhd
   set_property top Top_level [current_fileset]
   ```
3. **Add constraints** (e.g., clock period, pin locations):
   ```
   create_clock -period 10 -name clk [get_ports clk]
   set_property PACKAGE_PIN <pin> [get_ports clk]
   set_property IOSTANDARD LVCMOS33 [get_ports clk]
   # ... repeat for button_in, tx, reset
   ```
4. **Synthesize and implement:**
   ```tcl
   launch_runs synth_1
   wait_on_run synth_1
   launch_runs impl_1 -to_step write_bitstream
   wait_on_run impl_1
   ```
5. **Program your FPGA** with the generated `.bit` file

## Input/Output Specification

### Ports (Top_level.vhd)

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | in | 1 | System clock (10 ns period recommended) |
| `reset` | in | 1 | Asynchronous active-high reset |
| `button_in` | in | 1 | Push button (debounced internally) |
| `tx` | out | 1 | UART transmit line (115200 baud, 8-N-1) |

### Test Image Format

**cameraman.dat** (589,824 bytes = 256×256×1)
- **Format:** Raw binary, row-major (left-to-right, top-to-bottom)
- **Encoding:** Unsigned 8-bit per pixel (0–255 grayscale)
- **Generation:** Standard Cameraman test image (public domain)

To generate a custom image:
```python
import numpy as np
from PIL import Image

img = Image.open("your_image.png").convert('L').resize((256, 256))
img.tobytes()  # Write to cameraman.dat (binary)
```

## Expected Behavior

1. **Simulation starts:** FSM in `stIdle`, all signals low
2. **Pulse `button_in`:** FSM enters `stStart`
3. **Pixels stream:** One pixel/cycle flows through pipeline (256×256 cycles to fill)
4. **Results written:** Gradient magnitudes stored in BRAM starting at address 257
5. **FSM transitions to `stRead`:** UART outputs one byte per cycle
6. **Completion:** `done` flag asserts; FSM returns to `stIdle`

### Simulation Output

Expected sequence (first few bytes via UART):
```
Border pixels (zeros) → Gradient values (interior) → Border pixels (zeros)
```

See `output.png` for a visual example of gradient magnitude output.

## Performance Characteristics

| Metric | Value |
|--------|-------|
| **Clock frequency** | 100 MHz (10 ns period) |
| **Pixels per cycle** | 1 (after pipeline fill) |
| **Total latency** | ~15–17 cycles |
| **BRAM blocks** | 1 (256×256×8 bits = 512 KB) |
| **FIFO depth** | 253 stages × 8 bits = 506 stages |
| **LUT utilization** | ~2–3k (board-dependent) |
| **Processing time** | 256×256 cycles + 20 overhead ≈ 65.5 µs @ 100 MHz |

*Estimates based on typical Xilinx 7-series FPGA. Actual values vary by architecture and optimization.*

## Design Decisions

### Why Pipelined Sqrt?

The sequential sqrt unit (`Behavioral_sqrt_seq`) computes one result every `C_BLOCKS` cycles (~10–12). The pipelined version (`Behavioral_sqrt_pipelined`) maintains 1 result/cycle by cascading square-root stages, trading area for throughput. This project uses pipelined to match Sobel output rate.

### Why Dual FIFOs Instead of SRAM?

Distributed FIFO (shift registers) avoid dual-port SRAM complexity and provide deterministic latency. With 253-stage FIFOs, the design implements a simple, synthesizable line buffer without LUT-RAM inference hassles.

### Why Start Output at Address 257?

The Sobel operator requires a 3×3 neighborhood. Border pixels (top row, bottom row, left/right columns) cannot compute valid gradients. Skipping the first 256 pixels (top row + 1 border pixel per subsequent row) aligns output naturally with the interior 254×254 valid region.

## Troubleshooting

### Simulation doesn't find cameraman.dat

- Ensure working directory is the repo root when running simulations
- Alternatively, modify `im_ram.vhd` line 81 to use an absolute path:
  ```vhdl
  signal ram_name : ram_type := init_from_file_or_zeroes("/absolute/path/cameraman.dat");
  ```

### BRAM inference fails in synthesis

- Check that your toolchain recognizes the impure function `initramfromfile` (most do)
- If not, pre-generate a BRAM initialization file (`.coe`, `.mem`) and use the toolchain's memory editor

### UART output is garbled

- Verify clock frequency matches baud rate calculation in `uart_tx.vhd`
- Default assumes 100 MHz clock; adjust divisor if different

### Timing violations in synthesis

- Increase clock period in constraints (e.g., `create_clock -period 12`—12 ns = ~83 MHz)
- The pipelined design is optimized for ≥100 MHz; lower frequencies may require retiming

## References

- **Sobel Operator:** [Wikipedia](https://en.wikipedia.org/wiki/Sobel_operator)
- **FPGA Design:** See `Documentation.docx` for detailed schematics and timing analysis
- **VHDL Standard:** IEEE 1076-2019

## Future Enhancements

- [ ] Support variable image sizes (configurable via generics)
- [ ] Add other edge detectors (Prewitt, Canny preprocessing)
- [ ] Implement output scaling/thresholding
- [ ] Stream results to external memory (DDR3/4) for real-time processing
- [ ] Add hardware verification (formal methods)

## License

This project is provided as-is for educational and research purposes. See individual files for copyright notices.

## Author

**Andrej Donev**  
FPGA design & optimization | September 2026

---

## Quick Reference

**Simulate:**
```bash
ghdl -a src/*.vhd test/Top_level_tb.vhd && ghdl -e Top_level_tb && ghdl -r Top_level_tb
```

**Synthesize (Vivado):**
```tcl
add_files src/*.vhd
set_property top Top_level [current_fileset]
launch_runs synth_1 -jobs 4
```

**Pin Configuration Example (Arty A7):**
```
clk     → E3   (100 MHz oscillator)
reset   → C2   (reset button)
button_in → D9 (button 0)
tx      → D10  (UART TX)
```
