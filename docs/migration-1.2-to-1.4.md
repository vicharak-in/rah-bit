# Moving from 1.2.x to 1.4.0

Your own module does not change, only the way it is connected in top.v and the
files around it.

## Connections in top.v

Apps are no longer connected to the decoder and the encoder, they connect to the
data_path_interface signals.

| Before | Now |
| :--- | :--- |
| `data_queue_empty[APP]` | `wr_app_fifo_empty[APP]` |
| `data_queue_almost_empty[APP]` | `wr_app_fifo_a_empty[APP]` |
| `request_data[APP]` | `wr_app_fifo_rd_en[APP]` |
| `write_apps_data[APP]` | `rd_app_fifo_wr_en[APP]` |
| none | `rd_app_fifo_prog_full[APP]` (optional) |

`GET_DATA_RAH` and `SET_DATA_RAH` stay the same. `rd_clk[APP]` and `wr_clk[APP]`
still need to be assigned for every app, they now clock the app FIFOs of the
data path interface.

Before:

```verilog
adder #(.RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)) adder (
    .clk    (calc_clk),
    .a      (`GET_DATA_RAH(`ADD)),
    .empty  (data_queue_empty[`ADD]),
    .c      (`SET_DATA_RAH(`ADD)),
    .rden   (request_data[`ADD]),
    .wren   (write_apps_data[`ADD])
);
```

Now:

```verilog
adder #(.RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)) adder (
    .clk    (calc_clk),
    .a      (`GET_DATA_RAH(`ADD)),
    .empty  (wr_app_fifo_empty[`ADD]),
    .c      (`SET_DATA_RAH(`ADD)),
    .rden   (wr_app_fifo_rd_en[`ADD]),
    .wren   (rd_app_fifo_wr_en[`ADD])
);
```

## Other changes in top.v

- `rah_version_check rvc` is now `rah_meta_app rma`. It runs on `axi_clk`, takes
  the `TOTAL_APPS` parameter, and uses `rah_dec_async_rd_data` and
  `rah_enc_async_wr_data` instead of `GET_DATA_RAH(0)` and `SET_DATA_RAH(0)`.
- `rd_clk` of the decoder and `wr_clk` of the encoder are now the single
  `axi_clk`, so `assign rd_clk[0]` and `assign wr_clk[0]` are gone.
- New ports: `axi_clk`, `PllLocked[1:0]` and the `DdrCtrl_*_1` signals.
- New instances: `data_path_interface` and `dram_interface`.
- The resolution is 320x240 and the MIPI TX resets are tied to 1.
- `VERSION` is "1.4.0".

## Project files

- Rename `rah_version_check.v` to `rah_meta_app.v`.
- Add `rtl/data_path_interface.v`, `rtl/mem_ctrl` and the new IPs in `ip/`
  (`async_fifo_32bit`, `sync_fifo`, `sync_128_fifo`).
- In constraints.sdc add `axi_clk` with a 20 ns period and use
  `-group {rx_pixel_clk axi_clk} -group {tx_pixel_clk tx_vga_clk}`.
- In rah.peri.xml add the DDR controller, the DDR PLL and the PLL output for
  `axi_clk`. The easiest way is to take rah.xml and rah.peri.xml from this
  repository and add your own GPIOs back.

## CPU side

Nothing breaks, `rah_read` and `rah_write` work as before. The new things are
`rah_read_nb` and the DRAM APIs, see the [CPU usage guide](cpu-usage-guide.md)
and [dram-and-meta-app.md](dram-and-meta-app.md).
