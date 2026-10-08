module dram_controller #(
    parameter SYS_CLK_PERIOD     = 32'd100_000_000,     //System Clock Period
    parameter NUM_PORTS          = 8,                   //number of ports
    parameter BURST_LENGTH_WIDTH = 8,                   //burst length width
    parameter ADDRESS_WIDTH      = 32,                  //address width
    parameter IN_ADDR            = 8,                   //addr width of port
    parameter POINTER_COUNT      = 10,                  //fifo depth width
    parameter RAM_DEPTH          = (1 << POINTER_COUNT),//fifo depth
    parameter ID_WIDTH           = 8,                   //ID width after arbiter
    parameter AXI_ID_BLEN_CON    = 8 ,                  //AXI burst length width
    parameter AXI_DATA_WIDTH     = 128 ,                //Axi data width
    parameter AXI_BYTE_NUMBER    = AXI_DATA_WIDTH/8,
    parameter ADW_C              = AXI_DATA_WIDTH,
    parameter ABN_C              = AXI_BYTE_NUMBER
) (
    /* System Clock Signal */
    input                                       clk,

    /* PLL Locked signal */
	input [ 1:0]                                PllLocked,

    /* Reset Signal - Active Low */
    input                                       rst,

    /* DDR Controller Reset Sequencer Signals */
    output                                       DdrCtrl_CFG_RST_N,
    output                                       DdrCtrl_CFG_SEQ_RST,
    output                                       DdrCtrl_CFG_SEQ_START,

    /* Port Controller interface signals */
    input [NUM_PORTS-1:0]                        port_ctrl_i_valid,
    input [(NUM_PORTS * 8)-1:0]                  port_ctrl_i_address,
    input [(NUM_PORTS * BURST_LENGTH_WIDTH)-1:0] port_ctrl_i_BLEN,
    input [NUM_PORTS-1:0]                        port_ctrl_i_rw_enable,
    input [NUM_PORTS-1:0]                        port_ctrl_i_last,

    /* Axi signals and  request controller interface signals */
    output [AXI_DATA_WIDTH-1 :0]                 axi_read_o_data,
    output                                       rd_r_last,
    output                                       rd_r_valid,
    output                                       wr_id_o_wready,
    output [BURST_LENGTH_WIDTH-1:0]              wr_axi_blen,
    input                                        wr_axi_valid,
    input                                        wr_axi_last,
    input  [AXI_DATA_WIDTH-1:0]                  wr_axi_data,
    output [NUM_PORTS-1:0]                       select_wr,
    output [NUM_PORTS-1:0]                       select_rd,
    output                                       d_done,
    output [31:0]                                RR_o_addr,
    output                                       AXI_rst,

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
    input  [7:0]                                rid,
    input                                       rlast,
    input                                       rvalid,
    output                                      rready,
    input  [1:0]                                rresp,
    input  [ADW_C-1:0]                          rdata,
    input  [7:0]                                bid,
    input                                       bvalid,
    output                                      bready
);

/* Port Controller parameters */
localparam DATA_WIDTH = ADDRESS_WIDTH + BURST_LENGTH_WIDTH + PORT_ID_WIDTH + 1;
localparam BIN_WIDTH = $clog2(NUM_PORTS);

/* DDR Reset and intilisation signals */
assign AXI_rst = Axi1Rst_N;
assign d_done = DdrInitDone;

/* Internal Wire Signals */
reg  [AXI_DATA_WIDTH-1 :0]          axi_read_o_delay_data = 0;
wire [(NUM_PORTS * DATA_WIDTH)-1:0] port_ctrl_req_out;
wire [NUM_PORTS-1:0]                fifo_empty_out;
wire [NUM_PORTS-1:0]                port_ctrl_o_valid, fifo_rd_en;
wire [(NUM_PORTS*DATA_WIDTH)-1 : 0] fifo_o_data;
wire [NUM_PORTS-1:0]                fifo_rd_o_valid;
wire                                r_en_ack, w_en_ack;
wire [AXI_ID_BLEN_CON-1:0]          axi_id, rd_blen;
wire                                axi_wr_start, axi_rd_start;
wire [BURST_LENGTH_WIDTH-1:0]       RR_o_blen;
wire [PORT_ID_WIDTH-1:0]            RR_o_port_id;
wire                                RR_o_rw;
wire                                RR_o_valid_req;

/*  generate port_ ID */
//  This logic will generate port ID based on the number of ports using
//  NUM_PORTS parameter and the PORT_ID_WIDTH

localparam PORT_ID_WIDTH                  = ($clog2(NUM_PORTS));
localparam TOTAL_PORT_WIDTH               = PORT_ID_WIDTH * NUM_PORTS;
localparam [TOTAL_PORT_WIDTH-1:0] PORT_ID = generate_port_id(NUM_PORTS,
                                                            PORT_ID_WIDTH);

/* function to generate port ID  */

function [(TOTAL_PORT_WIDTH)-1:0] generate_port_id;
    input integer num_port;
    input integer id_width;
    integer i;
    reg [(TOTAL_PORT_WIDTH)-1:0] result;
    reg [31:0] mask;
    begin
        result = 0;
        mask = (1 << id_width) - 1;  // Create mask based on id_width
        for (i = 0; i < num_port; i = i + 1) begin
            result = (result << id_width) | (i & mask);
        end
        generate_port_id = result;
    end
endfunction


/* instiation of Port Controller generator module */
port_ctrl_gen #(
    .NUM_PORTS              (NUM_PORTS),
    .ADDRESS_WIDTH          (ADDRESS_WIDTH),
    .IN_ADDR                (IN_ADDR),
    .PORT_ID                (PORT_ID),
    .COMBINED_DATA_WIDTH    (DATA_WIDTH),
    .BURST_LENGTH_WIDTH     (BURST_LENGTH_WIDTH),
    .PORT_ID_WIDTH          (PORT_ID_WIDTH)
) PORT_CTRL_GEN_INST (
    .clk                    (clk),
    .rst                    (Axi1Rst_N),
    .valid                  (port_ctrl_i_valid),
    .last                   (port_ctrl_i_last),
    .o_valid                (port_ctrl_o_valid),
    .in_address             (port_ctrl_i_address),
    .in_burst_len           (port_ctrl_i_BLEN),
    .in_enable_rw           (port_ctrl_i_rw_enable),
    .combined_out           (port_ctrl_req_out)
);

/* instiation of Req queue generator module */
req_queue_gen #(
    .NUM_QUEUE              (NUM_PORTS),
    .DATA_WIDTH             (DATA_WIDTH),
    .ADDR_WIDTH             (POINTER_COUNT),
    .RAM_DEPTH              (RAM_DEPTH)
) REQ_QUEUE_GEN_INST (
    .clk                    (clk),
    .rst                    (Axi1Rst_N),
    .empty_flag             (fifo_empty_out),
    .rd_en                  (fifo_rd_en),
    .Wr_en                  (port_ctrl_o_valid),
    .data_in                (port_ctrl_req_out),
    .data_out               (fifo_o_data),
    .rd_out                 (fifo_rd_o_valid)
);

rr_arb #(
    .N                      (NUM_PORTS),
    .NUM_PORTS              (NUM_PORTS),
    .PORT_ID_WIDTH          (PORT_ID_WIDTH),
    .ADDRESS_WIDTH          (ADDRESS_WIDTH),
    .BIN_WIDTH              (BIN_WIDTH),
    .BURST_LENGTH_WIDTH     (BURST_LENGTH_WIDTH),
    .DATA_WIDTH             (DATA_WIDTH)
) RR_ARB_INST (
	.rst_an                 (Axi1Rst_N),
	.clk                    (clk),
	.req                    (~fifo_empty_out),
	.grant_out              (),
    .en_pin                 (RR_en_pin),
    .rd_sel_binary          (),
    .req_out                (fifo_rd_en),
    .in_data_div            (fifo_o_data),
    .o_addr_div             (RR_o_addr),
    .o_burst_div            (RR_o_blen),
    .o_port_div             (RR_o_port_id),
    .o_rw_div               (RR_o_rw),
    .r_valid                (fifo_rd_o_valid),
    .valid_req              (RR_o_valid_req)
);

/* Logic to identify port IDs when consecutive requests occurs */
localparam EXT = ID_WIDTH - PORT_ID_WIDTH ;
reg RR_en_pin;

reg [EXT-1 : 0] t = 0;
always@(posedge clk) begin
    if(!Axi1Rst_N) begin
        t <= 0;
    end else begin
        if(w_en_ack|r_en_ack) t <= ~t;
    end
end

/* Assignment of AXI signals */
assign rd_blen = RR_o_blen;
assign wr_axi_blen = RR_o_blen;
assign axi_id = {t, RR_o_port_id};

// read/write enable pin and valid request signal come from
// request manager and arbiter module to enable the DDR RAM Write operation
assign axi_wr_start = RR_o_rw & RR_o_valid_req;
assign axi_rd_start = !RR_o_rw & RR_o_valid_req;

/* DDR Reset Sequencer Instantiation and intilaisation */
reg [7:0] PowerOnResetCnt = 8'h0; //Power On Reset Counter
reg [2:0] ResetShiftReg   = 3'h0; //Reset Shift Regist
wire      DdrResetCtrl;           //DDR Controller Reset Control

assign DdrResetCtrl = ~rst;

always @(posedge clk) if (&PllLocked) begin
    PowerOnResetCnt <= PowerOnResetCnt + {7'h0,(~&PowerOnResetCnt)};
end

always @( posedge clk) begin
    ResetShiftReg[2] <= ResetShiftReg[1];
    ResetShiftReg[1] <= ResetShiftReg[0];
    ResetShiftReg[0] <= (&PowerOnResetCnt) & (~DdrResetCtrl);
end

//DDR Reset
wire  DdrInitDone;  //DDR Initial Done status

ddr_reset_sequencer #(
    .FREQ                   (SYS_CLK_PERIOD / 1_000_000)
) U0_DDR_RESET (
    .ddr_rstn_i             (ResetShiftReg[2]), // user DDR reset, active low
    .clk                    (clk),              // user clock

    /* Connect these three signals to DDR reset interface */
    .ddr_rstn               (DdrCtrl_CFG_RST_N),      // Master Reset
    .ddr_cfg_seq_rst        (DdrCtrl_CFG_SEQ_RST),    // Sequencer Reset
    .ddr_cfg_seq_start      (DdrCtrl_CFG_SEQ_START),  // Sequencer Start

    /* optional status monitor for user logic */
    .ddr_init_done		    (DdrInitDone)             // Done status
);

/* System Reset signal generation after DDR intitialisation */
reg [2:0] SysClkResetReg = 3'h0;    //System Clock Reset Register

always @( posedge clk) begin
    SysClkResetReg[2] <=  SysClkResetReg[1];
    SysClkResetReg[1] <=  SysClkResetReg[0];
    SysClkResetReg[0] <= (~DdrResetCtrl) & DdrInitDone;
end

wire Reset_N = SysClkResetReg[2]; //System Reset (Low Active)

reg   [2:0] Axi0ResetReg = 3'h0;    //System Clock Reset Register

always @( posedge clk) begin
    Axi0ResetReg[2] <= Axi0ResetReg[1];
    Axi0ResetReg[1] <= Axi0ResetReg[0];
    Axi0ResetReg[0] <= (~DdrResetCtrl) & DdrInitDone;
end

wire Axi0Rst_N;
assign Axi0Rst_N = Axi0ResetReg[2]; //System Reset (Low Active)

/////////////////////////////////////////////////////////
reg [2:0] Axi1ResetReg = 3'h0;    //System Clock Reset Register

always @( posedge clk) begin
    Axi1ResetReg[2] <= Axi1ResetReg[1];
    Axi1ResetReg[1] <= Axi1ResetReg[0];
    Axi1ResetReg[0] <= (~DdrResetCtrl) & DdrInitDone;
end

wire Axi1Rst_N;
assign Axi1Rst_N  = Axi1ResetReg[2]; //System Reset (Low Active)

/* Axi instantiation */
axi_top #(
    .AXI_DATA_WIDTH         (AXI_DATA_WIDTH),
    .AXI_BYTE_NUMBER        (AXI_BYTE_NUMBER),
    .ADW_C                  (ADW_C),
    .ABN_C                  (ABN_C)
) NATIVE_AXI_INST(
    .SysClk                 (clk),
    .rst                    (Axi1Rst_N),
    .RamRdStart             (axi_rd_start),
    .RamRdData              (axi_read_o_data),
    .CfgRdAddr              (RR_o_addr),
    .CfgRdBLen              (rd_blen),
    .w_ctrl_valid           (wr_axi_valid),
    .w_ctrl_last            (wr_axi_last),
    .RamWrStart             (axi_wr_start),
    .axi_wr_id              (axi_id),
    .axi_rd_id              (axi_id),
    .RamWrData              (wr_axi_data),
    .CfgWrAddr              (RR_o_addr),
    .CfgWrBlen              (wr_axi_blen),

    /* Axi signal connected with DDR controller */
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

/* Write ID Manager instantiation */
wr_id_manager #(
    .NUM_PORTS_SEL          (NUM_PORTS),
    .ID_WIDTH               (ID_WIDTH),
    .PORT_ID_WIDTH          (PORT_ID_WIDTH)
) WR_ID_MANAGER_INST (
    .clk                    (clk),
    .rst                    (Axi1Rst_N),
    .aid                    (aid),
    .valid                  (avalid),
    .atype                  (atype),
    .wready                 (wready),
    .wready_out             (wr_id_o_wready),
    .wlast                  (wlast),
    .wid                    (wid),
    .w_en_ack               (w_en_ack),
    .select                 (select_wr),
    .ack                    ()
);

/* Read ID Manager instantiation */
rd_id_manager #(
    .ID_WIDTH               (ID_WIDTH),
    .NUM_PORTS_SEL          (NUM_PORTS),
    .PORT_ID_WIDTH          (PORT_ID_WIDTH)
) RD_ID_MANAGER_INST (
    .clk                    (clk),
    .rst                    (Axi1Rst_N),
    .valid                  (avalid),
    .id_rd_in               (aid),
    .atype                  (atype),
    .rvalid                 (rvalid),
    .rlast                  (rlast),
    .rid                    (rid),
    .r_en_ack               (r_en_ack),
    .select_rd              (select_rd),
    .rd_r_valid             (rd_r_valid),
    .rd_r_last              (rd_r_last),
    .ack_rd                 ()
);

/* delay logic for read axi data */
always @ (posedge clk) begin
    axi_read_o_delay_data <= rdata;
end

reg flag;
always@(posedge clk) begin
    if (!Axi1Rst_N) flag <= 0;
    else begin
        if(fifo_rd_en!=0) flag <= 1;
        else if(w_en_ack|r_en_ack) flag <= 0;
    end
end

/* This logic is to enable RR_en used in arbiter module */
always@(*) begin
    if(!Axi1Rst_N) RR_en_pin = 1;
    else begin
        if(fifo_rd_en!=0) RR_en_pin = 0;
        else if (w_en_ack|r_en_ack) RR_en_pin = 1;
        else if ((fifo_rd_en == 0) && ~flag) RR_en_pin = 1;
        else RR_en_pin = 0;
    end
end

endmodule