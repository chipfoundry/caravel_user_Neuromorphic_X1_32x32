# Neuromorphic X1 — cocotb Simulation Demo

## 📺 Video tutorial
[Watch on YouTube](https://www.youtube.com/watch?v=AhED7Xki4TE) — end-to-end walkthrough of the same flow shown in this README.

This repository demonstrates how to integrate and simulate the **NEUROMORPHIC_X1** IP using a **Wishbone** slave interface and a **cocotb** testbench. The example drives multiple write/read scenarios, generates a VCD waveform file, and shows how to inspect signals in GTKWave.

## Repository layout

```
.
├─ Makefile                         # cocotb makefile to build & run the test
├─ testbench-test_ReRAM_Wishbone_Interface.py # cocotb testbench (multiple scenarios)
├─ ReRAM_Wishbone_Interface.v       # DUT: top + Wishbone datapath/glue
├─ wishbone_slave_interface.v       # Wishbone protocol handshake (stb/cyc/we/ack)
├─ NEUROMORPHIC_X1.v                # Neuromorphic X1 IP wrapper/top integration
└─ NEUROMORPHIC_X1_macro.v          # Macro variant (hardened/synth hook)
```

## Prerequisites

- Python 3.8+
- `cocotb` (`pip install cocotb`)
- A supported simulator (e.g., Icarus Verilog, Questa)
- GTKWave (for `sim.vcd` viewing)

Quick install (Ubuntu/Debian example):
```bash
python -m pip install cocotb
sudo apt-get install iverilog gtkwave
```

## Quick start

From the repo root:
```bash
# Build & run with default simulator selected in Makefile
make

```

**Outputs**
- Console logs from the cocotb test (WRITE/READ lines and final “Simulation complete.”).
- `sim.vcd` waveform file (open with GTKWave).

Open the waveform:
```bash
gtkwave sim.vcd
```

## What the testbench does

`test_ReRAM_Wishbone_Interface.py` starts a 10 ns clock, resets the DUT, and runs multiple scenarios of Wishbone traffic:

- **Scenario 1** — write **32** entries, read **20**
- **Scenario 2** — write **10**, read **20**
- **Scenario 3** — write **30**, read **32**
- **Scenario 3b** — write **10**, read **8**
- **Scenario 4** — **reset mid‑operation**, then resume
- **Scenario 5** — write **10**, read **7**

Writes compose a 32‑bit word (packing row/col/data), drive `stb/cyc/we/sel/adr/dat`, wait for `ack`, and deassert. Reads assert `we=1`, wait for `ack`, capture `wbs_dat_o`, and log the value with a timestamp.

## RTL overview

- **ReRAM_Wishbone_Interface.v** — Connects the Wishbone slave to the ReRAM/neuromorphic datapath; decodes packed row/col/data on writes and returns composite data on reads.
- **wishbone_slave_interface.v** — Implements Wishbone slave signaling (`stb`, `cyc`, `we`, `sel`, `ack`), including ready/ack handling.
- **NEUROMORPHIC_X1.v / NEUROMORPHIC_X1_macro.v** — Wrapper(s) for the Neuromorphic X1 IP; the macro variant is handy for hardened macro flows.

## Makefile notes

```
MODULE=testbench.test_ReRAM_Wishbone_Interface
TOPLEVEL=ReRAM_Wishbone_Interface
VERILOG_SOURCES=./NEUROMORPHIC_X1.v ./NEUROMORPHIC_X1_macro.v ./wishbone_slave_interface.v ./ReRAM_Wishbone_Interface.v
SIM=icarus

include $(shell cocotb-config --makefiles)/Makefile.sim
```
Run with:

```bash
make            # default SIM
```

## Viewing waveforms (GTKWave)

1. `gtkwave sim.vcd`
2. Add signals:
   - `wb_rst_i`, `wb_clk_i`
   - `wbs_stb_i`, `wbs_cyc_i`, `wbs_we_i`, `wbs_sel_i[3:0]`
   - `wbs_adr_i[31:0]`, `wbs_dat_i[31:0]`, `wbs_dat_o[31:0]`
   - `wbs_ack_o`
3. Check:
   - `ack` timing vs `stb/cyc/we`
   - Address/data stability on edges
   - Recovery after the mid‑op reset (Scenario 4)

## Troubleshooting

- **No `sim.vcd`:** ensure your simulator is supported and Makefile includes cocotb’s `Makefile.sim`.
- **No `ack`:** verify the Wishbone slave logic and that the DUT asserts `ack` only when ready.
- **All zeros on read:** confirm read‑path muxing and `we` polarity; verify `sel` mask and address decode.
