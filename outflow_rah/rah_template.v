
// Efinity Top-level template
// Version: 2024.1.163
// Date: 2025-03-21 12:31

// Copyright (C) 2013 - 2024 Efinix Inc. All rights reserved.

// This file may be used as a starting point for Efinity synthesis top-level target.
// The port list here matches what is expected by Efinity constraint files generated
// by the Efinity Interface Designer.

// To use this:
//     #1)  Save this file with a different name to a different directory, where source files are kept.
//              Example: you may wish to save as /home/neel/Downloads/float_to_fix/rah.v
//     #2)  Add the newly saved file into Efinity project as design file
//     #3)  Edit the top level entity in Efinity project to:  rah
//     #4)  Insert design content.


module rah
(
  (* syn_peri_port = 0 *) input mipi_refclk,
  (* syn_peri_port = 0 *) input mipi_rx_refclk,
  (* syn_peri_port = 0 *) input mipi_tx_refclk,
  (* syn_peri_port = 0 *) input uart_rx_pin,
  (* syn_peri_port = 0 *) input [3:0] my_mipi_rx_CNT,
  (* syn_peri_port = 0 *) input [63:0] my_mipi_rx_DATA,
  (* syn_peri_port = 0 *) input [17:0] my_mipi_rx_ERROR,
  (* syn_peri_port = 0 *) input [3:0] my_mipi_rx_HSYNC,
  (* syn_peri_port = 0 *) input [5:0] my_mipi_rx_TYPE,
  (* syn_peri_port = 0 *) input [3:0] my_mipi_rx_ULPS,
  (* syn_peri_port = 0 *) input my_mipi_rx_ULPS_CLK,
  (* syn_peri_port = 0 *) input my_mipi_rx_VALID,
  (* syn_peri_port = 0 *) input [1:0] my_mipi_rx_VC,
  (* syn_peri_port = 0 *) input [3:0] my_mipi_rx_VSYNC,
  (* syn_peri_port = 0 *) input tx_pixel_clk,
  (* syn_peri_port = 0 *) input tx_esc_clk,
  (* syn_peri_port = 0 *) input tx_vga_clk,
  (* syn_peri_port = 0 *) input mipi_rx_cal_clk,
  (* syn_peri_port = 0 *) input rx_pixel_clk,
  (* syn_peri_port = 0 *) output uart_tx_pin,
  (* syn_peri_port = 0 *) output my_mipi_rx_CLEAR,
  (* syn_peri_port = 0 *) output my_mipi_rx_DPHY_RSTN,
  (* syn_peri_port = 0 *) output [1:0] my_mipi_rx_LANES,
  (* syn_peri_port = 0 *) output my_mipi_rx_RSTN,
  (* syn_peri_port = 0 *) output [3:0] my_mipi_rx_VC_ENA,
  (* syn_peri_port = 0 *) output [63:0] my_mipi_tx_DATA,
  (* syn_peri_port = 0 *) output my_mipi_tx_DPHY_RSTN,
  (* syn_peri_port = 0 *) output my_mipi_tx_FRAME_MODE,
  (* syn_peri_port = 0 *) output [15:0] my_mipi_tx_HRES,
  (* syn_peri_port = 0 *) output my_mipi_tx_HSYNC,
  (* syn_peri_port = 0 *) output [1:0] my_mipi_tx_LANES,
  (* syn_peri_port = 0 *) output my_mipi_tx_RSTN,
  (* syn_peri_port = 0 *) output [5:0] my_mipi_tx_TYPE,
  (* syn_peri_port = 0 *) output my_mipi_tx_ULPS_CLK_ENTER,
  (* syn_peri_port = 0 *) output my_mipi_tx_ULPS_CLK_EXIT,
  (* syn_peri_port = 0 *) output [3:0] my_mipi_tx_ULPS_ENTER,
  (* syn_peri_port = 0 *) output [3:0] my_mipi_tx_ULPS_EXIT,
  (* syn_peri_port = 0 *) output my_mipi_tx_VALID,
  (* syn_peri_port = 0 *) output [1:0] my_mipi_tx_VC,
  (* syn_peri_port = 0 *) output my_mipi_tx_VSYNC
);


endmodule

