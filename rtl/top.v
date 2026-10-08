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
    output                      uart_tx_pin,

/* DDR controller Axi signals */
    input                       axi_clk,
    input [1:0]                 PllLocked,

    output                      DdrCtrl_CFG_RST_N,
    output                      DdrCtrl_CFG_SEQ_RST,
    output                      DdrCtrl_CFG_SEQ_START,

    output [7:0]                DdrCtrl_AID_1,
    output [31:0]               DdrCtrl_AADDR_1,
    output [7:0]                DdrCtrl_ALEN_1,
    output [2:0]                DdrCtrl_ASIZE_1,
    output [1:0]                DdrCtrl_ABURST_1,
    output [1:0]                DdrCtrl_ALOCK_1,
    output                      DdrCtrl_AVALID_1,
    input                       DdrCtrl_AREADY_1,
    output                      DdrCtrl_ATYPE_1,

    output [7:0]                DdrCtrl_WID_1,
    output [ABN_C-1:0]          DdrCtrl_WSTRB_1,
    output                      DdrCtrl_WLAST_1,
    output                      DdrCtrl_WVALID_1,
    input                       DdrCtrl_WREADY_1,
    output [ADW_C-1:0]          DdrCtrl_WDATA_1,

    input [7:0]                 DdrCtrl_RID_1,
    input                       DdrCtrl_RLAST_1,
    input                       DdrCtrl_RVALID_1,
    output                      DdrCtrl_RREADY_1,
    input [1:0]                 DdrCtrl_RRESP_1,
    input [ADW_C-1:0]           DdrCtrl_RDATA_1,

    input [7:0]                 DdrCtrl_BID_1,
    input                       DdrCtrl_BVALID_1,
    output                      DdrCtrl_BREADY_1
);

/* DRAM Controller Parameters */
parameter SYS_CLK_PERIOD     =  32'd50_000_000;    // System Clock Period
parameter NUM_PORTS          =  (2 * NUM_FIFO);    // number of ports
parameter ADDRESS_WIDTH      =  32;                // address width
parameter POINTER_COUNT      =  10;                // fifo depth width
parameter AXI_DATA_WIDTH     =  128;               // Axi data width
parameter AXI_BYTE_NUMBER    =  AXI_DATA_WIDTH/8;  // AXI BYTE NUMBER
parameter ADW_C              =  AXI_DATA_WIDTH;    // AXI DATA WIDTH
parameter ABN_C              =  AXI_BYTE_NUMBER;   // AXI BYTE NUMBER
parameter THRESHOLD_VALUE    =  127;               // occ to Rd from FIFO
parameter WAIT_CYCLE_COUNT   =  5;                 // No. of cycles wait
parameter NUM_FIFO           =  (2 * TOTAL_APPS);  // No.of App FIFO's
parameter FIFO_DEPTH         =  256;               // Depth of 128-bit FIFO
parameter PATH_SEL_WIDTH     =  2;                 // Width of Path_select

/* Rah Parameters */
parameter RAH_PACKET_WIDTH = 48;
parameter ACTIVE_VID_WIDTH = 320;
parameter ACTIVE_VID_HEIGHT = 240;
parameter DRAM_ADDRESS_WIDTH = 32;
parameter APP_MODE_WIDTH = 2;
parameter TOTAL_APPS = `TOTAL_APPS + 1;
parameter RAH_ADDR_WIDTH = 9;

/* Rah Decoder definition for multiple Apps */
assign my_mipi_rx_DPHY_RSTN = 1'b1;
assign my_mipi_rx_RSTN = 1'b1;
assign my_mipi_rx_CLEAR = 1'b0;
assign my_mipi_rx_LANES = 2'b11;
assign my_mipi_rx_VC_ENA = 4'b0001;

wire [(2*TOTAL_APPS*DRAM_ADDRESS_WIDTH)-1:0] dram_start_addr;
wire [(2*TOTAL_APPS*DRAM_ADDRESS_WIDTH)-1:0] dram_stop_addr;
wire [(2*TOTAL_APPS*APP_MODE_WIDTH)-1:0] dram_app_mode;

wire [TOTAL_APPS-1:0] request_data;
wire [TOTAL_APPS-1:0] data_queue_empty;
wire [TOTAL_APPS-1:0] data_queue_almost_empty;
wire [TOTAL_APPS-1:0] rd_error;
wire [(TOTAL_APPS * RAH_PACKET_WIDTH) - 1 : 0] rah_dec_async_rd_data;

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
    .DATA_WIDTH(RAH_PACKET_WIDTH),
    .TOTAL_APPS(TOTAL_APPS)
) rd (
    /* rah raw input variables */
    .clk                        (rx_pixel_clk),

    .mipi_data                  (aligned_data),
    .mipi_rx_valid              (my_mipi_rx_VALID),

    .rd_clk                     (axi_clk),
    .request_data               (request_data),

    .end_of_packet              (end_of_packet),
    .data_queue_empty           (data_queue_empty),
    .data_queue_almost_empty    (data_queue_almost_empty),
    .rd_data                    (rah_dec_async_rd_data),
    .error                      (rd_error)
);

/* Rah Version verifier */
rah_meta_app #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH),
    .TOTAL_APPS(TOTAL_APPS)
) rma (
    .clk                (axi_clk),
    .in_data            (rah_dec_async_rd_data[RAH_PACKET_WIDTH-1:0]),
    .q_empty            (data_queue_empty[0]),

    .request_data       (request_data[0]),
    .w_en               (write_apps_data[0]),
    .out_data           (rah_enc_async_wr_data[RAH_PACKET_WIDTH-1:0]),

    .dram_start_addr    (dram_start_addr),
    .dram_stop_addr     (dram_stop_addr),
    .dram_app_mode      (dram_app_mode)
);

assign rd_clk[`EXAMPLE] = rx_pixel_clk; 

/* change this module as your app */
example_recv #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) er (
    .clk(rx_pixel_clk),
    .data_queue_empty(wr_app_fifo_empty[`EXAMPLE]),
    .data_queue_almost_empty(wr_app_fifo_a_empty[`EXAMPLE]),
    .request_data(wr_app_fifo_rd_en[`EXAMPLE]),
    .data_frame(`GET_DATA_RAH(`EXAMPLE)),
    .uart_tx_pin(uart_tx_pin)
);

/* Send data to processor */
wire [TOTAL_APPS-1:0] write_apps_data;
wire [TOTAL_APPS-1:0] wr_fifo_full;
wire [TOTAL_APPS-1:0] wr_almost_fifo_full;
wire [TOTAL_APPS-1:0] wr_prog_fifo_full;
wire [(TOTAL_APPS * RAH_PACKET_WIDTH) - 1 : 0] rah_enc_async_wr_data;

wire vid_gen_clk;
assign vid_gen_clk = tx_vga_clk;

wire mipi_out_rst;
wire mipi_valid;
wire [RAH_PACKET_WIDTH-1:0] mipi_out_data;
wire hsync;
wire vsync;

rah_encoder #(
    .WIDTH(ACTIVE_VID_WIDTH),
    .HEIGHT(ACTIVE_VID_HEIGHT),
    .DATA_WIDTH(RAH_PACKET_WIDTH),
    .TOTAL_APPS(TOTAL_APPS)
) re (
    .clk                    (tx_pixel_clk),
    .vid_gen_clk            (vid_gen_clk),

    .send_data              (write_apps_data),
    .wr_clk                 (axi_clk),
    .wr_data                (rah_enc_async_wr_data),

    .wr_fifo_full           (wr_fifo_full),
    .wr_almost_fifo_full    (wr_almost_fifo_full),
    .wr_prog_fifo_full      (wr_prog_fifo_full),

    .mipi_rst               (mipi_out_rst),
    .mipi_valid             (mipi_valid),
    .mipi_data              (mipi_out_data),
    .hsync_patgen           (hsync),
    .vsync_patgen           (vsync)
);

/* DRAM_Interface signals */
wire [(NUM_FIFO - 1) : 0] buffer_rd_en;
wire [(NUM_FIFO - 1) : 0] buffer_empty;
wire [(NUM_FIFO - 1) : 0] buffer_a_empty;
wire [(NUM_FIFO * RAH_PACKET_WIDTH)-1:0] buffer_rd_data;
wire [NUM_FIFO - 1 : 0] ddr_fifo_empty;
wire [NUM_FIFO - 1 : 0] ddr_fifo_a_empty;
wire [NUM_FIFO - 1 : 0] ddr_fifo_rd_en;
wire [(NUM_FIFO * RAH_PACKET_WIDTH)-1:0] ddr_fifo_rd_data;

/* WR_APP_FIFO Interface signals */
wire [TOTAL_APPS - 1 : 0] rd_clk;
wire [TOTAL_APPS - 1 : 0] wr_app_fifo_empty;
wire [TOTAL_APPS - 1 : 0] wr_app_fifo_a_empty;
wire [TOTAL_APPS - 1 : 0] wr_app_fifo_rd_en;
wire [(TOTAL_APPS * RAH_PACKET_WIDTH) - 1 : 0] rd_data;

/* RD_APP_FIFO Interface signals */
wire [TOTAL_APPS - 1 : 0] wr_clk;
wire [TOTAL_APPS - 1 : 0] rd_app_fifo_prog_full;
wire [TOTAL_APPS - 1 : 0] rd_app_fifo_wr_en;
wire [(TOTAL_APPS * RAH_PACKET_WIDTH) - 1 : 0] wr_data;

/* Instantiating Data_Path Interface */
data_path_interface #(
    .RAH_PACKET_WIDTH        (RAH_PACKET_WIDTH),
    .TOTAL_APPS              (TOTAL_APPS),
    .RAH_ADDR_WIDTH          (RAH_ADDR_WIDTH),
    .THRESHOLD_VALUE         (THRESHOLD_VALUE),
    .NUM_FIFO                (NUM_FIFO),
    .PATH_SEL_WIDTH          (PATH_SEL_WIDTH)
) DATA_PATH_INTERFACE (
    .clk                     (axi_clk),
    .path_select             (dram_app_mode),

    .rah_dec_async_empty     (data_queue_empty),
    .rah_dec_async_a_empty   (data_queue_almost_empty),
    .rah_dec_async_rd_en     (request_data),
    .rah_dec_async_rd_data   (rah_dec_async_rd_data),

    .buffer_rd_en            (buffer_rd_en),
    .buffer_empty            (buffer_empty),
    .buffer_a_empty          (buffer_a_empty),
    .buffer_rd_data          (buffer_rd_data),
    .ddr_fifo_empty          (ddr_fifo_empty),
    .ddr_fifo_a_empty        (ddr_fifo_a_empty),
    .ddr_fifo_rd_en          (ddr_fifo_rd_en),
    .ddr_fifo_rd_data        (ddr_fifo_rd_data),

    .wr_app_fifo_rd_clk      (rd_clk),
    .wr_app_fifo_empty       (wr_app_fifo_empty),
    .wr_app_fifo_a_empty     (wr_app_fifo_a_empty),
    .wr_app_fifo_rd_en       (wr_app_fifo_rd_en),
    .wr_app_fifo_rd_data     (rd_data),

    .rd_app_fifo_wr_clk      (wr_clk),
    .rd_app_fifo_prog_full   (rd_app_fifo_prog_full),
    .rd_app_fifo_wr_en       (rd_app_fifo_wr_en),
    .rd_app_fifo_wr_data     (wr_data),

    .rah_enc_async_prog_full (wr_prog_fifo_full),
    .rah_enc_async_wr_en     (write_apps_data),
    .rah_enc_async_wr_data   (rah_enc_async_wr_data)
);

/* Instantiating top module of dram_interface */
dram_interface #(
    .SYS_CLK_PERIOD         (SYS_CLK_PERIOD),
    .NUM_PORTS              (NUM_PORTS),
    .ADDRESS_WIDTH          (ADDRESS_WIDTH),
    .POINTER_COUNT          (POINTER_COUNT),
    .AXI_DATA_WIDTH         (AXI_DATA_WIDTH),
    .AXI_BYTE_NUMBER        (AXI_BYTE_NUMBER),
    .ADW_C                  (ADW_C),
    .ABN_C                  (ABN_C),
    .THRESHOLD_VALUE        (THRESHOLD_VALUE),
    .WAIT_CYCLE_COUNT       (WAIT_CYCLE_COUNT),
    .NUM_FIFO               (NUM_FIFO),
    .FIFO_DEPTH             (FIFO_DEPTH),
    .FIFO_DATA_WIDTH        (RAH_PACKET_WIDTH),
    .TOTAL_APPS             (TOTAL_APPS)
) DDR_INST (
    /* System Clock signal */
    .clk                    (axi_clk),

    /* PLL locked Signal */
    .PllLocked              (PllLocked),

    /* System Reset Signal */
    .rst                    (1'b1),

    /* Start and Stop address of DRAM */
    .start_address          (dram_start_addr),
    .stop_address           (dram_stop_addr),

    /* Input side Rah fifo signals */
    .rah_fifo_rd_en         (buffer_rd_en),
    .rah_fifo_empty         (buffer_empty),
    .rah_fifo_a_empty       (buffer_a_empty),
    .rah_rd_data            (buffer_rd_data),

    /* DDR Fifo interface signals */
    .ddr_fifo_rd_en         (ddr_fifo_rd_en),
    .ddr_fifo_empty         (ddr_fifo_empty),
    .ddr_fifo_a_empty       (ddr_fifo_a_empty),
    .ddr_fifo_rd_data       (ddr_fifo_rd_data),

    /* DDR Controller Reset Sequencer Signals */
    .DdrCtrl_CFG_RST_N      (DdrCtrl_CFG_RST_N),
    .DdrCtrl_CFG_SEQ_RST    (DdrCtrl_CFG_SEQ_RST),
    .DdrCtrl_CFG_SEQ_START  (DdrCtrl_CFG_SEQ_START),

    /* DDR controller Interface signals */
    .aid                    (DdrCtrl_AID_1),
    .aaddr                  (DdrCtrl_AADDR_1),
    .alen                   (DdrCtrl_ALEN_1),
    .asize                  (DdrCtrl_ASIZE_1),
    .aburst                 (DdrCtrl_ABURST_1),
    .alock                  (DdrCtrl_ALOCK_1),
    .avalid                 (DdrCtrl_AVALID_1),
    .aready                 (DdrCtrl_AREADY_1),
    .atype                  (DdrCtrl_ATYPE_1),

    .wid                    (DdrCtrl_WID_1),
    .wstrb                  (DdrCtrl_WSTRB_1),
    .wlast                  (DdrCtrl_WLAST_1),
    .wvalid                 (DdrCtrl_WVALID_1),
    .wready                 (DdrCtrl_WREADY_1),
    .wdata                  (DdrCtrl_WDATA_1),

    .rid                    (DdrCtrl_RID_1),
    .rlast                  (DdrCtrl_RLAST_1),
    .rvalid                 (DdrCtrl_RVALID_1),
    .rready                 (DdrCtrl_RREADY_1),
    .rresp                  (DdrCtrl_RRESP_1),
    .rdata                  (DdrCtrl_RDATA_1),

    .bid                    (DdrCtrl_BID_1),
    .bvalid                 (DdrCtrl_BVALID_1),
    .bready                 (DdrCtrl_BREADY_1)
);

assign wr_clk[`EXAMPLE] = tx_pixel_clk;

/* Include your module */
example_trans #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) et (
    .clk            (tx_pixel_clk),
    .uart_rx_pin    (uart_rx_pin),
    .data           (`SET_DATA_RAH(`EXAMPLE)),
    .send_data      (rd_app_fifo_wr_en[`EXAMPLE])
);

assign my_mipi_tx_DPHY_RSTN = 1;
assign my_mipi_tx_RSTN = 1;
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
