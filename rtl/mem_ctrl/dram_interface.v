module dram_interface #(
    parameter SYS_CLK_PERIOD     =  32'd100_000_000,   // System Clock Period
    parameter NUM_PORTS          =  (2 * NUM_FIFO),    // number of ports
    parameter BURST_LEN_WIDTH    =  8,                 // burst length width
    parameter ADDR_CHUNK_OUT     =  8,                 // Req Addr chunk width
    parameter ADDRESS_WIDTH      =  32,                // address width
    parameter IN_ADDR            =  8,                 // addr width of port
    parameter POINTER_COUNT      =  10,                // fifo depth width
    parameter ID_WIDTH           =  8,                 //ID width after arbiter
    parameter AXI_DATA_WIDTH     =  128 ,              // Axi data width
    parameter AXI_BYTE_NUMBER    =  AXI_DATA_WIDTH/8,  // AXI BYTE NUMBER
    parameter ADW_C              =  AXI_DATA_WIDTH,    // AXI DATA WIDTH
    parameter ABN_C              =  AXI_BYTE_NUMBER,   // AXI BYTE NUMBER
    parameter THRESHOLD_VALUE    =  10,                // occ to Rd from FIFO
    parameter WAIT_CYCLE_COUNT   =  50,                // No. of cycles wait
    parameter NUM_FIFO           =  4,                 // No.of App FIFO's
    parameter FIFO_DEPTH         =  512,               // 128 bit FIFO Depth
    parameter FIFO_DATA_WIDTH    =  48,                // Rah fifo data width
    parameter FIFO_OCC_WIDTH     =  $clog2(FIFO_DEPTH),// 128 bit fifo occ width
    parameter CNT_WIDTH          =  32,                // Counters reg width
    parameter TOTAL_APPS         =  1
) (
    /* System Clock signal */
    input                                       clk,

    /* PLL locked Signal */
    input [1:0]                                 PllLocked,

    /* System Reset Signal -> Active Low */
    input                                       rst,

    /* Start and Stop address of DRAM */
    input [(NUM_FIFO * ADDRESS_WIDTH)-1:0]      start_address,
    input [(NUM_FIFO * ADDRESS_WIDTH)-1:0]      stop_address,

    /* Input side Rah fifo signals */
    output [(NUM_FIFO - 1) : 0]                 rah_fifo_rd_en,
    input  [(NUM_FIFO - 1) : 0]                 rah_fifo_empty,
    input  [(NUM_FIFO - 1) : 0]                 rah_fifo_a_empty,
    input  [(NUM_FIFO * FIFO_DATA_WIDTH)-1:0]   rah_rd_data,

    /* DDR Fifo interface signals */
    input  [(NUM_FIFO - 1) : 0]                 ddr_fifo_rd_en,
    output [(NUM_FIFO - 1) : 0]                 ddr_fifo_empty,
    output [(NUM_FIFO - 1) : 0]                 ddr_fifo_a_empty,
    output [(NUM_FIFO * FIFO_DATA_WIDTH)-1:0]   ddr_fifo_rd_data,

    /* DDR Controller Reset Sequencer Signals */
    output                                      DdrCtrl_CFG_RST_N,
    output                                      DdrCtrl_CFG_SEQ_RST,
    output                                      DdrCtrl_CFG_SEQ_START,

    /* DDR controller Interface signals */
    output [7:0]                                aid,
    output [31:0]                               aaddr,
    output [7:0]                                alen,
    output [2:0]                                asize,
    output [1:0]                                aburst,
    output [1:0]                                alock,
    output                                      avalid,
    input                                       aready,
    output                                      atype,

    output [7:0]                                wid,
    output [ABN_C-1:0]                          wstrb,
    output                                      wlast,
    output                                      wvalid,
    input                                       wready,
    output [ADW_C-1:0]                          wdata,

    input [7:0]                                 rid,
    input                                       rlast,
    input                                       rvalid,
    output                                      rready,
    input [1:0]                                 rresp,
    input [ADW_C-1:0]                           rdata,

    input [7:0]                                 bid,
    input                                       bvalid,
    output                                      bready
);

/* Axi signals from Dram ctrl and req grant signals */
wire                                    rd_r_last;
wire                                    rd_r_valid;
wire                                    wr_id_o_wready;
wire                                    wr_axi_valid;
wire                                    wr_axi_last;
wire                                    Axi1Rst_N;
wire [NUM_PORTS - 1 : 0]                select_wr;
wire [NUM_PORTS - 1 : 0]                select_rd;
wire [ADDRESS_WIDTH - 1 : 0]            RR_o_addr;
wire [AXI_DATA_WIDTH - 1 : 0]           wr_axi_data;

/* Axi write ctrl signals to write into dram */
wire [NUM_FIFO - 1 : 0]                 valid_ctrl;
wire [NUM_FIFO - 1 : 0]                 last_ctrl;
wire [NUM_FIFO - 1 : 0]                 header;
wire [NUM_PORTS - 1 : 0]                select;
wire [(NUM_FIFO * AXI_DATA_WIDTH)-1:0]  h_data;

/* Rah to 128-bit Fifo interface signals (Wr side) */
wire [NUM_FIFO - 1 : 0]                 rah2fifo_128_wr_en;
wire [NUM_FIFO - 1 : 0]                 rah2fifo_128_rd_en;
wire [NUM_FIFO - 1 : 0]                 rah2fifo_128_full;
wire [NUM_FIFO - 1 : 0]                 rah2fifo_128_prog_full;
wire [(NUM_FIFO * FIFO_OCC_WIDTH)-1:0]  rah2fifo_128_data_cnt;
wire [(NUM_FIFO * AXI_DATA_WIDTH)-1:0]  rah2fifo_128_rd_data;
wire [(NUM_FIFO * AXI_DATA_WIDTH)-1:0]  rah2fifo_128_wr_data;

/* Write request Signals for port controllers */
wire [NUM_FIFO - 1 : 0]                 valid;
wire [NUM_FIFO - 1 : 0]                 last;
wire [NUM_FIFO - 1 : 0]                 rw_enable;
wire [(NUM_FIFO * ADDR_CHUNK_OUT)-1:0]  addr;
wire [(NUM_FIFO * BURST_LEN_WIDTH)-1:0] r_burst_length;

/* Handshake signals between Write mem ctrl and rd req ctrl modules */
wire [NUM_FIFO - 1 : 0]                 read_done;
wire [(NUM_FIFO * CNT_WIDTH)-1:0]       wr_cnt;

/* DRAM to 128-bit Fifo interface signals (Rd side) */
wire [NUM_FIFO - 1 : 0]                 dram2fifo_128_a_full;
wire [NUM_FIFO - 1 : 0]                 dram2fifo_128_wr_en;
wire [NUM_FIFO - 1 : 0]                 dram2fifo_128_empty;
wire [NUM_FIFO - 1 : 0]                 dram2fifo_128_rd_en;
wire [(NUM_FIFO *FIFO_OCC_WIDTH)-1:0]   dram2fifo_128_data_cnt;
wire [(NUM_FIFO * AXI_DATA_WIDTH)-1:0]  dram2fifo_128_rd_data;
wire [(NUM_FIFO * AXI_DATA_WIDTH)-1:0]  dram2fifo_128_wr_data;

/* Read request Signals for port controllers */
wire [NUM_FIFO - 1 : 0]                 rd_rw_en;
wire [NUM_FIFO - 1 : 0]                 rd_last_req;
wire [NUM_FIFO - 1 : 0]                 rd_valid_req;
wire [(NUM_FIFO * ADDR_CHUNK_OUT)-1:0]  rd_addr_req;
wire [(NUM_FIFO * BURST_LEN_WIDTH)-1:0] rd_blen_req;

/* DDR Fifo (48-bit) interface signals */
wire [NUM_FIFO - 1 : 0]                 ddr_fifo_prog_full;
wire [NUM_FIFO - 1 : 0]                 ddr_fifo_full;
wire [NUM_FIFO - 1 : 0]                 ddr_fifo_wr_en;
wire [(NUM_FIFO * FIFO_DATA_WIDTH)-1:0] ddr_fifo_wr_data;

/* Combined Req signals to port controller */
wire [NUM_PORTS - 1 : 0]                valid_out;
wire [NUM_PORTS - 1 : 0]                rw_en_out;
wire [NUM_PORTS - 1 : 0]                last_out;
wire [(NUM_PORTS * ADDR_CHUNK_OUT)-1:0] addr_out;
wire [(NUM_PORTS * BURST_LEN_WIDTH)-1:0]blen_out;

/* Write and Read request interface signals */
assign select    = select_wr | select_rd;
assign valid_out = {valid, rd_valid_req};
assign last_out  = {last, rd_last_req};
assign rw_en_out = {rw_enable, rd_rw_en};
assign addr_out  = {addr, rd_addr_req};
assign blen_out  = {r_burst_length, rd_blen_req};

dram_controller #(
    .SYS_CLK_PERIOD         (SYS_CLK_PERIOD),
    .NUM_PORTS              (NUM_PORTS),
    .BURST_LENGTH_WIDTH     (BURST_LEN_WIDTH),
    .ADDRESS_WIDTH          (ADDRESS_WIDTH),
    .IN_ADDR                (IN_ADDR),
    .POINTER_COUNT          (POINTER_COUNT),
    .ID_WIDTH               (ID_WIDTH),
    .AXI_DATA_WIDTH         (AXI_DATA_WIDTH),
    .AXI_BYTE_NUMBER        (AXI_BYTE_NUMBER),
    .ADW_C                  (ADW_C),
    .ABN_C                  (ABN_C)
) DRAM_TOP_INST (
    .clk (clk),
	.PllLocked (PllLocked),
    .rst (rst),

    /* DDR Controner Control Signal*/
    .DdrCtrl_CFG_RST_N      (DdrCtrl_CFG_RST_N),
    .DdrCtrl_CFG_SEQ_RST    (DdrCtrl_CFG_SEQ_RST),
    .DdrCtrl_CFG_SEQ_START  (DdrCtrl_CFG_SEQ_START),
    .port_ctrl_i_valid      (valid_out),
    .port_ctrl_i_address    (addr_out),
    .port_ctrl_i_BLEN       (blen_out),
    .port_ctrl_i_rw_enable  (rw_en_out),
    .port_ctrl_i_last       (last_out),

    /* Axi Interface signals */
    .rd_r_last              (rd_r_last),
    .rd_r_valid             (rd_r_valid),
    .wr_id_o_wready         (wr_id_o_wready),
    .wr_axi_valid           (wr_axi_valid),
    .wr_axi_last            (wr_axi_last),
    .wr_axi_data            (wr_axi_data),
    .select_wr              (select_wr),
    .select_rd              (select_rd),
    .RR_o_addr              (RR_o_addr),
    .AXI_rst                (Axi1Rst_N),

    /*DDR controller Axi signals */
    .aid                    (aid),
    .aaddr                  (aaddr),
    .alen                   (alen),
    .asize                  (asize),
    .aburst                 (aburst),
    .alock                  (alock),
    .avalid                 (avalid),
    .aready                 (aready),
    .atype                  (atype),
    .wid                    (wid),
    .wstrb                  (wstrb),
    .wlast                  (wlast),
    .wvalid                 (wvalid),
    .wready                 (wready),
    .wdata                  (wdata),
    .rid                    (rid),
    .rlast                  (rlast),
    .rvalid                 (rvalid),
    .rready                 (rready),
    .rresp                  (rresp),
    .rdata                  (rdata),
    .bid                    (bid),
    .bvalid                 (bvalid),
    .bready                 (bready)
);

/* WVALID signal select module Instantiation */
vector_mux_param #(
    .PORT_SIZE              (1),
    .NO_PORT                (NUM_FIFO)
) MUX_VALID_INST (
    .in                     (valid_ctrl),
    .out                    (wr_axi_valid),
    .sel                    (select)
);

/* WLAST signal select module Instantiation */
vector_mux_param #(
    .PORT_SIZE              (1),
    .NO_PORT                (NUM_FIFO)
) MUX_LAST (
    .in                     (last_ctrl),
    .out                    (wr_axi_last),
    .sel                    (select)
);

/* WDATA signal select module Instantiation */
vector_mux_data #(
    .PORT_SIZE              (AXI_DATA_WIDTH),
    .NO_PORT                (NUM_FIFO)
) MUX_DATA (
    .in                     (rah2fifo_128_rd_data),
    .h_data                 (h_data),
    .header                 (header),
    .out                    (wr_axi_data),
    .sel                    (select)
);

/* Instantiation of Data handling modules */
genvar i ;
generate
    for (i = 0; i < NUM_FIFO; i = i + 1) begin
        if(i != 0 && i != TOTAL_APPS) begin
            /* Data from rah fifo stores in this 128-bit fifo */
            sync_128_fifo RAH_TO_FIFO_128_INST (
                .clk_i              (clk),
                .a_rst_i            (~ Axi1Rst_N),
                .wr_en_i            (rah2fifo_128_wr_en[(NUM_FIFO - i) - 1]),
                .rd_en_i            (rah2fifo_128_rd_en[(NUM_FIFO - i) - 1]),
                .wdata              (rah2fifo_128_wr_data[(AXI_DATA_WIDTH
                            * (NUM_FIFO - i)) - 1 -: AXI_DATA_WIDTH]),
                .rdata              (rah2fifo_128_rd_data[(AXI_DATA_WIDTH
                            * (NUM_FIFO - i)) - 1 -: AXI_DATA_WIDTH]),
                .almost_full_o      (),
                .prog_full_o        (rah2fifo_128_prog_full[(NUM_FIFO- i) - 1]),
                .full_o             (rah2fifo_128_full[(NUM_FIFO - i) - 1]),
                .overflow_o         (),
                .empty_o            (),
                .almost_empty_o     (),
                .datacount_o        (rah2fifo_128_data_cnt[(FIFO_OCC_WIDTH
                            * (NUM_FIFO - i)) - 1 -: FIFO_OCC_WIDTH])
            );

            /* Writes data from rah to 128bit fifo and generates wr reuests */
            wr_req_ctrl #(
                .THRESHOLD_VALUE    (THRESHOLD_VALUE),
                .WAIT_CYCLE_COUNT   (WAIT_CYCLE_COUNT),
                .AXI_BYTES          (AXI_BYTE_NUMBER),
                .INPUT_DATA_WIDTH   (FIFO_DATA_WIDTH),
                .OUTPUT_DATA_WIDTH  (AXI_DATA_WIDTH),
                .FIFO_OCC_WIDTH     (FIFO_OCC_WIDTH)
            ) WRITE_REQ_CTRL (
                .clk                (clk),
                .rst                (Axi1Rst_N),

                .start_addr         (start_address[(ADDRESS_WIDTH
                                * (NUM_FIFO - i)) - 1 -: ADDRESS_WIDTH]),
                .stop_addr          (stop_address[(ADDRESS_WIDTH
                                * (NUM_FIFO - i)) - 1 -: ADDRESS_WIDTH]),

                .rah_fifo_empty     (rah_fifo_empty[(NUM_FIFO - i) - 1]),
                .rah_fifo_a_empty   (rah_fifo_a_empty[(NUM_FIFO - i) - 1]),
                .rah_fifo_rd_en     (rah_fifo_rd_en[(NUM_FIFO - i) - 1]),
                .rah_fifo_data_in   (rah_rd_data[(FIFO_DATA_WIDTH
                                * (NUM_FIFO - i)) - 1 -: FIFO_DATA_WIDTH]),

                .fifo_128_full      (rah2fifo_128_full[(NUM_FIFO - i) - 1]),
                .fifo_128_prog_full (rah2fifo_128_prog_full[(NUM_FIFO - i)- 1]),
                .fifo_128_wr_en     (rah2fifo_128_wr_en[(NUM_FIFO - i) - 1]),
                .fifo_128_data_out  (rah2fifo_128_wr_data[(AXI_DATA_WIDTH
                                * (NUM_FIFO - i)) - 1 -: AXI_DATA_WIDTH]),
                .fifo_occupants     (rah2fifo_128_data_cnt[(FIFO_OCC_WIDTH
                                * (NUM_FIFO - i)) - 1 -: FIFO_OCC_WIDTH]),

                .valid              (valid[(NUM_FIFO - i) - 1]),
                .last               (last[(NUM_FIFO - i) - 1]),
                .rw_enable          (rw_enable[(NUM_FIFO - i) - 1]),
                .addr               (addr[(ADDR_CHUNK_OUT * (NUM_FIFO - i))
                                - 1 -: ADDR_CHUNK_OUT]),
                .burst_length       (r_burst_length[(BURST_LEN_WIDTH
                                * (NUM_FIFO - i)) - 1 -: BURST_LEN_WIDTH]),

                .data_last          (last_ctrl[(NUM_FIFO - i) - 1]),
                .header_data        (h_data[(AXI_DATA_WIDTH * (NUM_FIFO - i))
                                - 1 -: AXI_DATA_WIDTH])
            );

            /* Generates the write axi signals while wr req gets grants */
            mem_wr_ctrl WRITE_TO_MEM_CTRL (
                .clk                (clk),
                .rst                (Axi1Rst_N),

                .in_addr            (RR_o_addr),
                .BLEN_w             (r_burst_length[(BURST_LEN_WIDTH
                                * (NUM_FIFO - i)) - 1 -: BURST_LEN_WIDTH]),

                .select             (select[i]),
                .wready_w           (wr_id_o_wready),
                .w_valid            (valid_ctrl[(NUM_FIFO - i) - 1]),
                .w_last             (last_ctrl[(NUM_FIFO - i) - 1]),
                .WriteEn            (rah2fifo_128_rd_en[(NUM_FIFO - i) - 1]),
                .header             (header[(NUM_FIFO - i) - 1]),

                .write_counter      (wr_cnt[(CNT_WIDTH *(NUM_FIFO - i)) - 1
                                -: CNT_WIDTH]),
                .read_done          (read_done[(NUM_FIFO - i) - 1])
            );

            /* Generates rd req and Reads data from from DRAM and write into
                128-fifo and then followed by DDR fifo(48-bit) */
            rd_rqst_ctrl #(
                .AXI_BYTES          (AXI_BYTE_NUMBER),
                .BURST_LEN_WIDTH    (BURST_LEN_WIDTH),
                .ADDR_CHUNCK_WIDTH  (IN_ADDR),
                .AXI_DATA_WIDTH     (AXI_DATA_WIDTH),
                .FIFO_DATA_WIDTH    (FIFO_DATA_WIDTH),
                .FIFO_DEPTH         (FIFO_DEPTH),
                .FIFO_OCC_WIDTH     (FIFO_OCC_WIDTH)
            ) RD_RQST_1 (
                .clk                (clk),
                .rst_n              (Axi1Rst_N),

                .start_addr         (start_address[(ADDRESS_WIDTH
                                * (NUM_FIFO - i)) - 1 -: ADDRESS_WIDTH]),
                .stop_addr          (stop_address[(ADDRESS_WIDTH
                                * (NUM_FIFO - i)) - 1 -: ADDRESS_WIDTH]),

                .last_data          (rd_r_last),
                .rvalid             (rd_r_valid),
                .select_rd          (select[NUM_FIFO + i]),
                .rd_start           (last_ctrl[(NUM_FIFO - i) - 1]),
                .read_done          (read_done[(NUM_FIFO - i) - 1]),

                .wr_fifo_occ        (rah2fifo_128_data_cnt[(FIFO_OCC_WIDTH
                                * (NUM_FIFO - i)) - 1 -: FIFO_OCC_WIDTH]),
                .rd_fifo_occ        (dram2fifo_128_data_cnt[(FIFO_OCC_WIDTH
                                * (NUM_FIFO - i)) - 1 -: FIFO_OCC_WIDTH]),
                .data_valid         (dram2fifo_128_wr_en[(NUM_FIFO - i) - 1]),
                .header_data        (dram2fifo_128_wr_data[(AXI_DATA_WIDTH
                                * (NUM_FIFO - i)) - 1 -: AXI_DATA_WIDTH]),
                .write_counter      (wr_cnt[(CNT_WIDTH *(NUM_FIFO - i))
                                - 1 -: CNT_WIDTH]),

                .burst_length       (rd_blen_req[(BURST_LEN_WIDTH
                                * (NUM_FIFO - i)) - 1 -: BURST_LEN_WIDTH]),
                .addr_out           (rd_addr_req[(ADDR_CHUNK_OUT
                                * (NUM_FIFO - i)) - 1 -: ADDR_CHUNK_OUT]),
                .rw_enable          (rd_rw_en[(NUM_FIFO - i) - 1]),
                .last               (rd_last_req[(NUM_FIFO - i) - 1]),
                .valid              (rd_valid_req[(NUM_FIFO - i) - 1]),

                .fifo_128_a_full    (dram2fifo_128_a_full[(NUM_FIFO - i) - 1]),
                .fifo_128_empty     (dram2fifo_128_empty[(NUM_FIFO - i) - 1]),
                .fifo_128_rd_en     (dram2fifo_128_rd_en[(NUM_FIFO - i) - 1]),
                .fifo_128_data_in   (dram2fifo_128_rd_data[(AXI_DATA_WIDTH
                                * (NUM_FIFO - i)) - 1 -: AXI_DATA_WIDTH]),

                .rah_out_prog_full  (ddr_fifo_prog_full[(NUM_FIFO - i) - 1]),
                .rah_fifo_full      (ddr_fifo_full [(NUM_FIFO - i) - 1]),
                .rah_fifo_wr_en     (ddr_fifo_wr_en [(NUM_FIFO - i) - 1]),
                .rah_fifo_wr_data   (ddr_fifo_wr_data[(FIFO_DATA_WIDTH
                                * (NUM_FIFO - i)) - 1 -: FIFO_DATA_WIDTH])
            );

            /* 128-bit sync fifo stores data that has been read from DRAM */
            sync_128_fifo DRAM_TO_FIFO_128_OUT (
                .clk_i              (clk),
                .a_rst_i            (~ Axi1Rst_N),
                .wr_en_i            (dram2fifo_128_wr_en[(NUM_FIFO - i) - 1]),
                .rd_en_i            (dram2fifo_128_rd_en[(NUM_FIFO - i) - 1]),
                .wdata              (dram2fifo_128_wr_data[(AXI_DATA_WIDTH
                                * (NUM_FIFO - i)) - 1 -: AXI_DATA_WIDTH]),
                .rdata              (dram2fifo_128_rd_data[(AXI_DATA_WIDTH
                                * (NUM_FIFO - i)) - 1 -: AXI_DATA_WIDTH]),
                .almost_full_o      (dram2fifo_128_a_full[(NUM_FIFO - i) - 1]),
                .prog_full_o        (),
                .full_o             (),
                .overflow_o         (),
                .empty_o            (dram2fifo_128_empty[(NUM_FIFO - i) - 1]),
                .datacount_o        (dram2fifo_128_data_cnt[(FIFO_OCC_WIDTH
                                * (NUM_FIFO - i)) - 1 -: FIFO_OCC_WIDTH])
            );

            /* Reads Data from DRAM and write into 128-bit fifo */
            mem_rd_ctrl #(
                .AXI_DATA_WIDTH     (AXI_DATA_WIDTH)
            ) DRAM_READ_CTRL_1 (
                .clk                (clk),
                .rst                (Axi1Rst_N),
                .select_rd          (select[NUM_FIFO + i]),
                .rvalid_rd          (rd_r_valid),
                .rlast_rd           (rd_r_last),
                .rdata_in           (rdata),
                .rdata_out          (dram2fifo_128_wr_data[(AXI_DATA_WIDTH
                                * (NUM_FIFO - i)) - 1 -: AXI_DATA_WIDTH]),
                .data_valid         (dram2fifo_128_wr_en[(NUM_FIFO - i) - 1])
            );

            /* Final stage 48-bit fifo will interface with Rah out fifo */
            synchronous_fifo OUTPUT_DDR_FIFO (
                .a_rst_i            (~Axi1Rst_N),
                .clk_i              (clk),
                .wr_en_i            (ddr_fifo_wr_en [(NUM_FIFO - i) - 1]),
                .wdata              (ddr_fifo_wr_data[(FIFO_DATA_WIDTH
                                * (NUM_FIFO - i)) - 1 -: FIFO_DATA_WIDTH]),
                .rd_en_i            (ddr_fifo_rd_en [(NUM_FIFO - i) - 1]),
                .rdata              (ddr_fifo_rd_data [(FIFO_DATA_WIDTH
                                * (NUM_FIFO - i)) - 1 -: FIFO_DATA_WIDTH]),
                .full_o             (ddr_fifo_full [(NUM_FIFO - i) - 1]),
                .prog_full_o        (ddr_fifo_prog_full[(NUM_FIFO - i) - 1]),
                .empty_o            (ddr_fifo_empty  [(NUM_FIFO - i) - 1]),
                .almost_empty_o     (ddr_fifo_a_empty  [(NUM_FIFO - i) - 1]),
                .datacount_o        ()
            );
        end
    end
endgenerate

endmodule