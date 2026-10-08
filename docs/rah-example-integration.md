# RAH Design Integration Guide

This guide walks you through integrating the RAH design (version 1.4.0) into your Efinity project and adding your own modules to it.

> [!NOTE]
> The reference for everything below is `rtl/top.v`. If a snippet here and `top.v` disagree, `top.v` is right.
> Coming from an older RAH (1.2.x)? Read [migration-1.2-to-1.4.md](migration-1.2-to-1.4.md) first.

## Required Files

Make sure all of these are in your project:

| Path | Purpose |
|---|---|
| `rtl/top.v` | Top module, wires everything together |
| `rtl/rah_var_defs.vh` | App IDs, `TOTAL_APPS`, `VERSION`, data access macros |
| `rtl/constraints.sdc` | Clock definitions (`rx_pixel_clk`, `tx_pixel_clk`, `tx_vga_clk`, `axi_clk`) |
| `rtl/data_aligner.v` | Aligns incoming MIPI data to RAH packets |
| `rtl/rah_decoder.v`, `rtl/rah_encoder.v` | Depacketizer / packetizer |
| `rtl/rrq.v`, `rtl/video_gen.v` | Used by the encoder |
| `rtl/rah_meta_app.v` | Meta app (app 0): version check and DRAM configuration |
| `rtl/data_path_interface.v` | Routes each app's data either via RAH FIFOs or DRAM |
| `rtl/mem_ctrl/` | DRAM interface (AXI, request queues, arbiters) |
| `rtl/example.v`, `rtl/uart.v` | Reference app (UART loopback) |
| `ip/` (`async_fifo`, `async_fifo_32bit`, `sync_fifo`, `sync_128_fifo`, `synchronous_fifo`) | FIFO IP used by the decoder, encoder and data path |
| `rah.xml`, `rah.peri.xml` | Efinity project and Interface Designer (peripheral) configuration |

> [!NOTE]
> `rah.peri.xml` must contain the MIPI RX/TX blocks, the DDR controller, and the PLLs that generate `axi_clk`.
> The port names of `top` (including `DdrCtrl_*_1`, `axi_clk` and `PllLocked`) must match the pin names in this file.
> The easiest way is to start from the `rah.xml` / `rah.peri.xml` in this repository.

## Steps

1. **Check the files.** Verify that every file in the table above is present, with the same names and paths.
2. **Add the sources.** Add `rtl/` (including `rtl/mem_ctrl/`) and the `ip/` cores to your Efinity project (`rah.xml` already does this).
3. **Set up your apps.** Edit `rah_var_defs.vh` and add your module to `top.v` (see below).
4. **Build.** Run the Efinity flow and program the bitstream.

## Clocks

| Clock | Frequency | Used for |
|---|---|---|
| `rx_pixel_clk` | 25 MHz (40 ns) | MIPI RX, `data_aligner`, decoder input side |
| `tx_pixel_clk` | 25 MHz (40 ns) | MIPI TX, encoder output side |
| `tx_vga_clk` | 50 MHz (20 ns) | Video generation (`vid_gen_clk`) |
| `axi_clk` | 50 MHz (20 ns) | `data_path_interface`, DRAM, `rah_meta_app`, decoder read side, encoder write side |

`rx_pixel_clk` / `axi_clk` and `tx_pixel_clk` / `tx_vga_clk` are declared as exclusive clock groups in `constraints.sdc`.
Your app can run on any of these clocks, or on your own, since the per-app FIFOs are asynchronous.

## What `top.v` Contains

Top-level ports, in addition to the MIPI RX/TX interfaces:

- `axi_clk` (input), `PllLocked[1:0]` (input): the system clock and PLL lock flags.
- `DdrCtrl_*_1`: the AXI and reset-sequencer pass-through to the DDR controller.
- `uart_rx_pin`, `uart_tx_pin`: used by the reference example.

Parameters:

```verilog
parameter RAH_PACKET_WIDTH   = 48;
parameter ACTIVE_VID_WIDTH   = 320;
parameter ACTIVE_VID_HEIGHT  = 240;
parameter DRAM_ADDRESS_WIDTH = 32;
parameter APP_MODE_WIDTH     = 2;
parameter TOTAL_APPS         = `TOTAL_APPS + 1;   // +1 for the meta app (app 0)
parameter RAH_ADDR_WIDTH     = 9;
```

Data flow:

```
 MIPI RX -> data_aligner -> rah_decoder -> data_path_interface -> your app   (CPU to FPGA)
                                 ^                  |  ^
                      rah_meta_app (app 0)          v  |
                                              dram_interface <-> DDR

 your app -> data_path_interface -> rah_encoder -> MIPI TX                   (FPGA to CPU)
```

- `rah_meta_app` (instance `rma`) is app 0. It reads CPU requests straight from the decoder and answers through the encoder (`rah_dec_async_rd_data`, `rah_enc_async_wr_data`). It reports the `VERSION` and drives `dram_start_addr`, `dram_stop_addr` and `dram_app_mode` from the CPU's DRAM configuration. See [dram-and-meta-app.md](dram-and-meta-app.md).
- `data_path_interface` (instance `DATA_PATH_INTERFACE`) holds the per-app FIFOs. `dram_app_mode` is wired to its `path_select`.
- `rah_decoder` / `rah_encoder` no longer take per-app clocks; `rd_clk` / `wr_clk` are the single `axi_clk`.
- The MIPI TX reset outputs (`my_mipi_tx_DPHY_RSTN`, `my_mipi_tx_RSTN`) are tied to `1`.

## Adding Your Own App

### 1. Choose an ID in `rah_var_defs.vh`

Following the example of an adder app:

```verilog
// rah_var_defs.vh
`define TOTAL_APPS 1

`define ADD 1

`define VERSION "1.4.0"

`define GET_DATA_RAH(a) rd_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
`define SET_DATA_RAH(a) wr_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
```

- `TOTAL_APPS` is the number of user apps, without the meta app.
- App IDs start at `1`; they must be the same on the CPU side.
- Bump `VERSION` whenever you change something the CPU side must know about.

### 2. Write the module

Your module only sees plain FIFO-style ports. Nothing in it depends on `data_path_interface`:

```verilog
module adder (
  input                               clk,
  input [RAH_PACKET_WIDTH-1:0]        a,
  input                               empty,
  output reg [RAH_PACKET_WIDTH-1:0]   c = 0,
  output reg                          rden = 0,
  output reg                          wren = 0
);
```

### 3. Instantiate it in `top.v`

Replace the `example_recv` / `example_trans` instances in `top.v` with yours. The CPU-to-FPGA side uses `rd_clk`, `wr_app_fifo_*` and `GET_DATA_RAH`; the FPGA-to-CPU side uses `wr_clk`, `rd_app_fifo_*` and `SET_DATA_RAH`:

```verilog
wire calc_clk;
assign calc_clk = rx_pixel_clk;

assign rd_clk[`ADD] = calc_clk;   // clock of APP_WR_FIFO (CPU to FPGA)
assign wr_clk[`ADD] = calc_clk;   // clock of APP_RD_FIFO (FPGA to CPU)

adder #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) adder (
    .clk            (calc_clk),
    .a              (`GET_DATA_RAH(`ADD)),
    .empty          (wr_app_fifo_empty[`ADD]),
    .rden           (wr_app_fifo_rd_en[`ADD]),

    .c              (`SET_DATA_RAH(`ADD)),
    .wren           (rd_app_fifo_wr_en[`ADD])
);
```

`ADD` is the app ID; it is `1` here.

| Your module's port | Connect to in `top.v` |
|---|---|
| input: FIFO empty | `wr_app_fifo_empty[APP]` |
| input: FIFO almost empty (optional) | `wr_app_fifo_a_empty[APP]` |
| output: read enable | `wr_app_fifo_rd_en[APP]` |
| input: data from CPU | `` `GET_DATA_RAH(APP) `` |
| output: data to CPU | `` `SET_DATA_RAH(APP) `` |
| output: write enable | `rd_app_fifo_wr_en[APP]` |
| input: FIFO nearly full (optional) | `rd_app_fifo_prog_full[APP]` |

The read handshake is: when not empty, pulse read enable for one clock, wait one clock, then sample the data. See [fpga-implementation.md](fpga-implementation.md).

> [!NOTE]
> The per-app FIFOs are asynchronous. It is mandatory to assign `rd_clk[APP]` and `wr_clk[APP]` for every app.
> If an app only receives or only sends, still assign both clocks.

### Multiple apps

Repeat steps 1-3 for every app, with a unique ID each, and set `TOTAL_APPS` accordingly. [`examples/calc_ops`](../examples/calc_ops/README.md) does this for three apps (`ADD`, `SHIFT`, `MUL`).

## Verifying

1. Program the bitstream.
2. On the CPU, make sure `rah-service` is running and the FPGA overlay is enabled (see the [README](../README.md)).
3. Run a CPU example against your app IDs, for example `rah_write` / `rah_read` as described in the [CPU usage guide](cpu-usage-guide.md).
4. `rah_check_version_compatible()` returns `1` when the `VERSION` reported by the bitstream is new enough for the installed CPU library, `0` when it is not (and `-1` if not run as root).

> [!NOTE]
> The `.bit` and `.hex` files for the calc_ops project are available in the [releases](https://github.com/vicharak-in/rah-bit/releases/tag/calc_ops_bitstream). Check that the release version matches the library version on your board.

If you run into trouble, compare your `top.v` against the one in this repository first.
