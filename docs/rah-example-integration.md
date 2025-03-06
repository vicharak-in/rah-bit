# RAH Design Integration Guide

Welcome to the RAH Design Integration Guide! This document will walk you through the steps to successfully integrate the RAH design into your project. Let's get started!

## Required Files

Before you begin, make sure that all the necessary files are included in your project directory. The required files for the integration are:

- `constraints.sdc`
- `data_aligner.v`
- `example.v`
- `rah_decoder.v`
- `rah_encoder.v`
- `rah_var_defs.vh`
- `rah_version_check.v`
- `rrq.v`
- `top.v`
- `video_gen.v`

Ensure all these files are available before proceeding.

## Steps to Add Files to Your Project

Follow these steps to integrate the RAH design into your project:

1. **Verify File Presence**  
   Check if all the required files are already in your project directory.

3. **Copy Files to Your Project**  
   Once downloaded, copy the files into your project directory, ensuring they are placed according to the structure listed above.

4. **Verify File Names and Paths**  
   Double-check that all files are named correctly and in the appropriate paths.

Once you’ve confirmed that everything is in place, your RAH design integration will be up and running!

---

## Example: `top.v` from RAH

Here is an example of how the `top.v` file should look in your project. This file includes the integration of the RAH design modules and necessary connections.

```verilog
`include "rah_var_defs.vh"

module top (
/* Clocks of MIPI TX and RX parallel interfaces */
    input                       rx_pixel_clk,
    input                       tx_pixel_clk,
    input                       tx_vga_clk,

/* Signals used by the MIPI RX Interface Designer instance */
    input                       my_mipi_rx_VALID,
    input [3:0]                 my_mipi_rx_HSYNC,
    input [3:0]                 my_mipi_rx_VSYNC,
    input [63:0]                my_mipi_rx_DATA,
    input [5:0]                 my_mipi_rx_TYPE,
    input [1:0]                 my_mipi_rx_VC,
    input [3:0]                 my_mipi_rx_CNT,
    input [17:0]                my_mipi_rx_ERROR,
    input                       my_mipi_rx_ULPS_CLK,
    input [3:0]                 my_mipi_rx_ULPS,

    output                      my_mipi_rx_DPHY_RSTN,
    output                      my_mipi_rx_RSTN,
    output                      my_mipi_rx_CLEAR,
    output [1:0]                my_mipi_rx_LANES,
    output [3:0]                my_mipi_rx_VC_ENA,

/* Signals used by the MIPI TX Interface Designer instance */
    output                      my_mipi_tx_DPHY_RSTN,
    output                      my_mipi_tx_RSTN,
    output                      my_mipi_tx_VALID,
    output                      my_mipi_tx_HSYNC,
    output                      my_mipi_tx_VSYNC,
    output [63:0]               my_mipi_tx_DATA,
    output [5:0]                my_mipi_tx_TYPE,
    output [1:0]                my_mipi_tx_LANES,
    output                      my_mipi_tx_FRAME_MODE,
    output [15:0]               my_mipi_tx_HRES,
    output [1:0]                my_mipi_tx_VC,
    output [3:0]                my_mipi_tx_ULPS_ENTER,
    output [3:0]                my_mipi_tx_ULPS_EXIT,
    output                      my_mipi_tx_ULPS_CLK_ENTER,
    output                      my_mipi_tx_ULPS_CLK_EXIT,
    
/* Connections to the GPIOs */
    input                       uart_rx_pin,
    output                      uart_tx_pin
);

parameter RAH_PACKET_WIDTH = 48;
parameter ACTIVE_VID_WIDTH = 1280;
parameter ACTIVE_VID_HEIGHT = 1024;
parameter TOTAL_APPS = `TOTAL_APPS + 1;

/* Rah Decoder definition for multiple Apps */
assign my_mipi_rx_DPHY_RSTN = 1'b1;
assign my_mipi_rx_RSTN = 1'b1;
assign my_mipi_rx_CLEAR = 1'b0;
assign my_mipi_rx_LANES = 2'b11;
assign my_mipi_rx_VC_ENA = 4'b0001;

wire [TOTAL_APPS-1:0] rd_clk;
wire [TOTAL_APPS-1:0] request_data;

wire [TOTAL_APPS-1:0] data_queue_empty;
wire [TOTAL_APPS-1:0] data_queue_almost_empty;
wire [TOTAL_APPS-1:0] rd_error;

wire [(TOTAL_APPS*RAH_PACKET_WIDTH)-1:0] rd_data;

wire [RAH_PACKET_WIDTH-1:0] aligned_data;
wire end_of_packet;

/* Align the data for the decoding process */
data_aligner #(
    .DATA_WIDTH(RAH_PACKET_WIDTH)
) da (
    .clk            (rx_pixel_clk),

    .mipi_data      (my_mipi_rx_DATA),
    .end_of_packet  (end_of_packet),
    .rx_valid       (my_mipi_rx_VALID),

    .aligned_data   (aligned_data)
);

/* Depacketizing the recevied data */
rah_decoder #(
    .TOTAL_APPS(TOTAL_APPS),
    .DATA_WIDTH(RAH_PACKET_WIDTH)
) rd (
    /* rah raw input variables */
    .clk                        (rx_pixel_clk),

    .mipi_data                  (aligned_data),
    .mipi_rx_valid              (my_mipi_rx_VALID),

    .rd_clk                     (rd_clk),
    .request_data               (request_data),

    .end_of_packet              (end_of_packet),
    .data_queue_empty           (data_queue_empty),
    .data_queue_almost_empty    (data_queue_almost_empty),
    .rd_data                    (rd_data),
    .error                      (rd_error)
);

assign rd_clk[0] = rx_pixel_clk;
assign wr_clk[0] = rx_pixel_clk;

/* Rah Version verifier */
rah_version_check #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) rvc (
    .clk            (rx_pixel_clk),
    .in_data        (`GET_DATA_RAH(0)),
    .q_empty        (data_queue_empty[0]),

    .request_data   (request_data[0]),
    .w_en           (write_apps_data[0]),
    .out_data       (`SET_DATA_RAH(0))
);

/* Periplex instantiation for multiplexing peripherals */
assign rd_clk[`EXAMPLE] = rx_pixel_clk; 


/* Send data to processor */
wire [TOTAL_APPS-1:0] wr_clk;
wire [(TOTAL_APPS*RAH_PACKET_WIDTH)-1:0] wr_data;
wire [TOTAL_APPS-1:0] write_apps_data;
wire [TOTAL_APPS-1:0] wr_fifo_full;
wire [TOTAL_APPS-1:0] wr_almost_fifo_full;
wire [TOTAL_APPS-1:0] wr_prog_fifo_full;

wire vid_gen_clk;
assign vid_gen_clk = tx_vga_clk;

wire mipi_out_rst;
wire mipi_valid;
wire [RAH_PACKET_WIDTH-1:0] mipi_out_data;
wire hsync;
wire vsync;

rah_encoder #(
    .TOTAL_APPS(TOTAL_APPS),
    .WIDTH(ACTIVE_VID_WIDTH),
    .HEIGHT(ACTIVE_VID_HEIGHT),
    .DATA_WIDTH(RAH_PACKET_WIDTH)
) re (
    .clk                    (tx_pixel_clk),
    .vid_gen_clk            (vid_gen_clk),

    .send_data              (write_apps_data),
    .wr_clk                 (wr_clk),
    .wr_data                (wr_data),

    .wr_fifo_full           (wr_fifo_full),
    .wr_almost_fifo_full    (wr_almost_fifo_full),
    .wr_prog_fifo_full      (wr_prog_fifo_full),

    .mipi_rst               (mipi_out_rst),
    .mipi_valid             (mipi_valid),
    .mipi_data              (mipi_out_data),
    .hsync_patgen           (hsync),
    .vsync_patgen           (vsync)
);

assign wr_clk[`EXAMPLE] = tx_pixel_clk;


assign my_mipi_tx_DPHY_RSTN = ~mipi_out_rst;
assign my_mipi_tx_RSTN = ~mipi_out_rst;
assign my_mipi_tx_VALID = mipi_valid;
assign my_mipi_tx_HSYNC = hsync;
assign my_mipi_tx_VSYNC = vsync;
assign my_mipi_tx_DATA = mipi_out_data;
assign my_mipi_tx_TYPE = 6'h24;
assign my_mipi_tx_LANES = 2'b11;
assign my_mipi_tx_FRAME_MODE = 1'b0;
assign my_mipi_tx_HRES = ACTIVE_VID_WIDTH;
assign my_mipi_tx_VC = 2'b00;
assign my_mipi_tx_ULPS_ENTER = 4'b0000;
assign my_mipi_tx_ULPS_EXIT = 4'b0000;
assign my_mipi_tx_ULPS_CLK_ENTER = 1'b0;
assign my_mipi_tx_ULPS_CLK_EXIT = 1'b0;

endmodule
```
## Example of Adder Module

Here is an example of the adder module you might want to add to your design:

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
If you want to add the adder module to your project, you'll need to instantiate it correctly in the design. Here’s an example of how to instantiate the adder module:
```verilog
adder #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) adder (
    .clk            (calc_clk),
    .a              (`GET_DATA_RAH(`ADD)),
    .empty          (data_queue_empty[`ADD]),
    .c              (`SET_DATA_RAH(`ADD)),
    .rden           (request_data[`ADD]),
    .wren           (write_apps_data[`ADD])
);
```
In this example, ADD refers to the app_id of the device that the adder is connected to. The app_id specifies the application instance in the design, which is set as 1 for this example.

Make sure to update the header file (rah_var_defs.vh) to define the app_id and other macros:

Header file of the rah will look like this.

```verilog
`define TOTAL_APPS 1

`define ADD 1

`define VERSION "1.2.0"

`define GET_DATA_RAH(a) rd_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
`define SET_DATA_RAH(a) wr_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
```

Once you’ve updated your header file, your top.v module will look like this:

```verilog

`include "rah_var_defs.vh"
module top (
/* Clocks of MIPI TX and RX parallel interfaces */
    input                       rx_pixel_clk,
    input                       tx_pixel_clk,
    input                       tx_vga_clk,
/* Signals used by the MIPI RX Interface Designer instance */
    input                       my_mipi_rx_VALID,
    input [3:0]                 my_mipi_rx_HSYNC,
    input [3:0]                 my_mipi_rx_VSYNC,
    input [63:0]                my_mipi_rx_DATA,
    input [5:0]                 my_mipi_rx_TYPE,
    input [1:0]                 my_mipi_rx_VC,
    input [3:0]                 my_mipi_rx_CNT,
    input [17:0]                my_mipi_rx_ERROR,
    input                       my_mipi_rx_ULPS_CLK,
    input [3:0]                 my_mipi_rx_ULPS,
    output                      my_mipi_rx_DPHY_RSTN,
    output                      my_mipi_rx_RSTN,
    output                      my_mipi_rx_CLEAR,
    output [1:0]                my_mipi_rx_LANES,
    output [3:0]                my_mipi_rx_VC_ENA,
/* Signals used by the MIPI TX Interface Designer instance */
    output                      my_mipi_tx_DPHY_RSTN,
    output                      my_mipi_tx_RSTN,
    output                      my_mipi_tx_VALID,
    output                      my_mipi_tx_HSYNC,
    output                      my_mipi_tx_VSYNC,
    output [63:0]               my_mipi_tx_DATA,
    output [5:0]                my_mipi_tx_TYPE,
    output [1:0]                my_mipi_tx_LANES,
    output                      my_mipi_tx_FRAME_MODE,
    output [15:0]               my_mipi_tx_HRES,
    output [1:0]                my_mipi_tx_VC,
    output [3:0]                my_mipi_tx_ULPS_ENTER,
    output [3:0]                my_mipi_tx_ULPS_EXIT,
    output                      my_mipi_tx_ULPS_CLK_ENTER,
    output                      my_mipi_tx_ULPS_CLK_EXIT,
/* Connections to the GPIOs */
    input                       uart_rx_pin,
    output                      uart_tx_pin
);
parameter RAH_PACKET_WIDTH = 48;
parameter ACTIVE_VID_WIDTH = 1280;
parameter ACTIVE_VID_HEIGHT = 1024;
parameter TOTAL_APPS = `TOTAL_APPS + 1;
/* Rah Decoder definition for multiple Apps */
assign my_mipi_rx_DPHY_RSTN = 1'b1;
assign my_mipi_rx_RSTN = 1'b1;
assign my_mipi_rx_CLEAR = 1'b0;
assign my_mipi_rx_LANES = 2'b11;
assign my_mipi_rx_VC_ENA = 4'b0001;
wire [TOTAL_APPS-1:0] rd_clk;
wire [TOTAL_APPS-1:0] request_data;
wire [TOTAL_APPS-1:0] data_queue_empty;
wire [TOTAL_APPS-1:0] data_queue_almost_empty;
wire [TOTAL_APPS-1:0] rd_error;
wire [(TOTAL_APPS*RAH_PACKET_WIDTH)-1:0] rd_data;
wire [RAH_PACKET_WIDTH-1:0] aligned_data;
wire end_of_packet;
/* Align the data for the decoding process */
data_aligner #(
    .DATA_WIDTH(RAH_PACKET_WIDTH)
) da (
    .clk            (rx_pixel_clk),
    .mipi_data      (my_mipi_rx_DATA),
    .end_of_packet  (end_of_packet),
    .rx_valid       (my_mipi_rx_VALID),
    .aligned_data   (aligned_data)
);
/* Depacketizing the recevied data */
rah_decoder #(
    .TOTAL_APPS(TOTAL_APPS),
    .DATA_WIDTH(RAH_PACKET_WIDTH)
) rd (
    /* rah raw input variables */
    .clk                        (rx_pixel_clk),
    .mipi_data                  (aligned_data),
    .mipi_rx_valid              (my_mipi_rx_VALID),
    .rd_clk                     (rd_clk),
    .request_data               (request_data),
    .end_of_packet              (end_of_packet),
    .data_queue_empty           (data_queue_empty),
    .data_queue_almost_empty    (data_queue_almost_empty),
    .rd_data                    (rd_data),
    .error                      (rd_error)
);
assign rd_clk[0] = rx_pixel_clk;
assign wr_clk[0] = rx_pixel_clk;
/* Rah Version verifier */
rah_version_check #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) rvc (
    .clk            (rx_pixel_clk),
    .in_data        (`GET_DATA_RAH(0)),
    .q_empty        (data_queue_empty[0]),
    .request_data   (request_data[0]),
    .w_en           (write_apps_data[0]),
    .out_data       (`SET_DATA_RAH(0))
);
wire [TOTAL_APPS-1:0] wr_clk;
wire [(TOTAL_APPS*RAH_PACKET_WIDTH)-1:0] wr_data;
wire [TOTAL_APPS-1:0] write_apps_data;
wire [TOTAL_APPS-1:0] wr_fifo_full;
wire [TOTAL_APPS-1:0] wr_almost_fifo_full;
wire [TOTAL_APPS-1:0] wr_prog_fifo_full;
wire vid_gen_clk;
assign vid_gen_clk = tx_vga_clk;
wire mipi_out_rst;
wire mipi_valid;
wire [RAH_PACKET_WIDTH-1:0] mipi_out_data;
wire hsync;
wire vsync;
rah_encoder #(
    .TOTAL_APPS(TOTAL_APPS),
    .WIDTH(ACTIVE_VID_WIDTH),
    .HEIGHT(ACTIVE_VID_HEIGHT),
    .DATA_WIDTH(RAH_PACKET_WIDTH)
) re (
    .clk                    (tx_pixel_clk),
    .vid_gen_clk            (vid_gen_clk),
    .send_data              (write_apps_data),
    .wr_clk                 (wr_clk),
    .wr_data                (wr_data),
    .wr_fifo_full           (wr_fifo_full),
    .wr_almost_fifo_full    (wr_almost_fifo_full),
    .wr_prog_fifo_full      (wr_prog_fifo_full),
    .mipi_rst               (mipi_out_rst),
    .mipi_valid             (mipi_valid),
    .mipi_data              (mipi_out_data),
    .hsync_patgen           (hsync),
    .vsync_patgen           (vsync)
);
wire calc_clk;
assign calc_clk = rx_pixel_clk;
assign rd_clk[`ADD] = calc_clk;
assign wr_clk[`ADD] = calc_clk;
adder #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) adder (
    .clk            (calc_clk),
    .a              (`GET_DATA_RAH(`ADD)),
    .empty          (data_queue_empty[`ADD]),
    .c              (`SET_DATA_RAH(`ADD)),
    .rden           (request_data[`ADD]),
    .wren           (write_apps_data[`ADD])
);
assign rd_clk[`SHIFT] = calc_clk;
assign wr_clk[`SHIFT] = calc_clk;
shift #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) shift (
    .clk            (calc_clk),
    .a              (`GET_DATA_RAH(`SHIFT)),
    .empty          (data_queue_empty[`SHIFT]),
    .c              (`SET_DATA_RAH(`SHIFT)),
    .rden           (request_data[`SHIFT]),
    .wren           (write_apps_data[`SHIFT])
);
assign rd_clk[`MUL] = calc_clk;
assign wr_clk[`MUL] = calc_clk;
mul #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) mul (
    .clk            (calc_clk),
    .a              (`GET_DATA_RAH(`MUL)),
    .empty          (data_queue_empty[`MUL]),
    .c              (`SET_DATA_RAH(`MUL)),
    .rden           (request_data[`MUL]),
    .wren           (write_apps_data[`MUL])
);
assign my_mipi_tx_DPHY_RSTN = ~mipi_out_rst;
assign my_mipi_tx_RSTN = ~mipi_out_rst;
assign my_mipi_tx_VALID = mipi_valid;
assign my_mipi_tx_HSYNC = hsync;
assign my_mipi_tx_VSYNC = vsync;
assign my_mipi_tx_DATA = mipi_out_data;
assign my_mipi_tx_TYPE = 6'h24;
assign my_mipi_tx_LANES = 2'b11;
assign my_mipi_tx_FRAME_MODE = 1'b0;
assign my_mipi_tx_HRES = ACTIVE_VID_WIDTH;
assign my_mipi_tx_VC = 2'b00;
assign my_mipi_tx_ULPS_ENTER = 4'b0000;
assign my_mipi_tx_ULPS_EXIT = 4'b0000;
assign my_mipi_tx_ULPS_CLK_ENTER = 1'b0;
assign my_mipi_tx_ULPS_CLK_EXIT = 1'b0;
endmodule
```


By following these steps, you should be able to successfully integrate the RAH design into your project and add any custom modules, like the adder, into the design flow.

> [!NOTE]
> 1. The `adder.v` file is an example provided in the "example" folder for your understanding. You can also check out other examples there for additional guidance on implementing similar modules.  
> 2. The `.bit` and `.hex` files for the same project are also available in the [releases](https://github.com/vicharak-in/rah-bit/releases/tag/calc_ops_bitstream). Please feel free to use them as needed.

If you encounter any issues, feel free to refer to this guide for help or reach out for further clarification!

Good luck with your integration, and happy coding!

