module axi_wr_ctrl (
    /* System Signals */
    SysClk,             //System Clock
    Reset_N,            //System Reset

    /*config AXI&DDR Operate Parameter */
    CfgWrAddr,          //(I)Config Write Start Address  // Axi address
    CfgWrBLen,          //(I)Config Write Burst Length   // axi_blen
    axi_wr_id,
    w_ctrl_valid,
    w_ctrl_last,

    /* Operate Control & State Signals */
    RamWrStart,         //(I)Ram Operate Start   // axi valid
    RamWrData,          //(I)Ram Write Data

    /* Axi Slave Interfac Signal */
    AWID,               //(O)[WrAddr]Write address ID.
    AWADDR,             //(O)[WrAddr]Write address.
    AWLEN,              //(O)[WrAddr]Burst length.
    AWSIZE,             //(O)[WrAddr]Burst size.
    AWBURST,            //(O)[WrAddr]Burst type.
    AWLOCK,             //(O)[WrAddr]Lock type.
    AWVALID,            //(O)[WrAddr]Write address valid.
    AWREADY,            //(I)[WrAddr]Write address ready.

    WID,                //(O)[WrData]Write ID tag.
    WDATA,              //(O)[WrData]Write data.
    WSTRB,              //(O)[WrData]Write strobes.
    WLAST,              //(O)[WrData]Write last.
    WVALID,             //(O)[WrData]Write valid.
    WREADY,             //(I)[WrData]Write ready.

    BID,                //(I)[WrResp]Response ID tag.
    BVALID,             //(I)[WrResp]Write response valid.
    BREADY              //(O)[WrResp]Response ready.
);

/*  Parameter Declarations */
parameter   TCo_C           = 1;
parameter   AXI_DATA_WIDTH  = 128;

localparam  AXI_BYTE_NUMBER = AXI_DATA_WIDTH/8;
localparam  AXI_DATA_SIZE   = $clog2(AXI_BYTE_NUMBER);
localparam  ADW_C           = AXI_DATA_WIDTH;
localparam  ABN_C           = AXI_BYTE_NUMBER;

/* Define Ports */
input                   SysClk;
input                   Reset_N;

/* Operate Control & State Signals */
input                   RamWrStart;
input [ADW_C-1:0]       RamWrData;
input                   w_ctrl_valid;
input                   w_ctrl_last;

/*config AXI & DDR Operate Parameter */
input [31:0]            CfgWrAddr;
input [7:0]             CfgWrBLen;
input [7:0]             axi_wr_id;

/* Axi Slave Interfac Signal */
output [7:0]            AWID;
output [31:0]           AWADDR;
output [7:0]            AWLEN;
output [2:0]            AWSIZE;
output [1:0]            AWBURST;
output [1:0]            AWLOCK;
output                  AWVALID;
input                   AWREADY;

output [7:0]            WID;
output [ABN_C- 1:0]     WSTRB;
output                  WLAST;
output                  WVALID;
input                   WREADY;
output [ADW_C-1:0]      WDATA;

input [7:0]             BID;
input                   BVALID;
output                  BREADY;

/* Address capture logic */
wire AddrReady = AWREADY ;
reg  DataWrStart = 0;
reg   [7:0]   WrBurstLen  =  8'h0;
reg   [31:0]  WrStartAddr = 32'h0;

always @( posedge SysClk)  begin
  if(RamWrStart)  WrBurstLen  <=  CfgWrBLen;
  else WrBurstLen  <= WrBurstLen;
end

always @( posedge SysClk)  begin
  if(RamWrStart)  WrStartAddr <= CfgWrAddr;
  else WrStartAddr <= WrStartAddr;
end

/* Address valid generation */
reg     AddrValid = 1'h0;

always @( posedge SysClk) begin
   if (RamWrStart)  AddrValid <= 1'h1;
   else  AddrValid <=  1'h0;
end

wire AddrWrEn = (AddrValid & AddrReady);

/* AXI address channel signals */
wire  [7:0]   AWID    = axi_wr_id;
wire  [31:0]  AWADDR  = WrStartAddr;
wire  [7:0]   AWLEN   = WrBurstLen;

wire  [2:0]   AWSIZE  = AXI_DATA_SIZE;
wire  [1:0]   AWBURST = 2'b01;
wire  [1:0]   AWLOCK  = 2'b00;
wire          AWVALID = AddrValid;

/*  Write data channel control */
wire  DataWrReady     = WREADY;
reg   DataWrValid     = 1'h0;
reg   DataWrLast      = 1'h0;

assign  DataWrEn      = DataWrValid & DataWrReady;
assign  DataWrEnd     = DataWrValid & DataWrReady & DataWrLast;

always @( posedge SysClk or negedge Reset_N) begin
    if (!Reset_N)           DataWrValid  <= # TCo_C 1'h0;
    else if (DataWrStart)   DataWrValid  <= # TCo_C 1'h1;
    else if (DataWrEnd)     DataWrValid  <= # TCo_C 1'h0;
end

/* AXI write data signals */
wire  [7:0]         WID     = axi_wr_id;
wire  [ABN_C-1:0]   WSTRB   = {ABN_C{1'h1}};
wire                WVALID  = w_ctrl_valid;
wire                WLAST   = w_ctrl_last;
wire  [ADW_C-1:0]   WDATA   = RamWrData;

wire [7:0]   WrByteNum = AXI_BYTE_NUMBER;
reg  [31:0]  WrAddrCnt = 32'h0;

/* Write response handling */
wire          BackValid = BVALID;
reg           BackReady = 1'h0;

always @( posedge SysClk ) begin
    if (!Reset_N)           BackReady  <=  # TCo_C 1'h0;
    else if (w_ctrl_last)    BackReady <=  # TCo_C 1'h1;
    else if (BackValid)     BackReady  <=  # TCo_C 1'h0;
end

wire  BackRespond = BackReady & BackValid;
wire  BREADY = BackReady;

endmodule