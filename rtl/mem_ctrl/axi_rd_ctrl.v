module axi_rd_ctrl (
    /* System Signals */
    SysClk,             //System Clock
    Reset_N,            //System Reset

    /* Operate Control & State */
    RamRdStart,         //(I)Ram Read Start
    RamRdData,          //(O)Ram Read Data

    /* Config DDR & AXI Operate Parameter */
    CfgRdAddr,          //(I)Config Read Start Address
    CfgRdBLen,          //(I)[DdrOpCtrl]Config Read Burst Length
    axi_rd_id,

    /* Axi4 Read Address & Data Bus */
    ARID,               //(O)[RdAddr]Read address ID.
    ARADDR,             //(O)[RdAddr]Read address.
    ARLEN,              //(O)[RdAddr]Burst length.
    ARSIZE,             //(O)[RdAddr]Burst size.
    ARBURST,            //(O)[RdAddr]Burst type.
    ARLOCK,             //(O)[RdAddr]Lock type.
    ARVALID,            //(O)[RdAddr]Read address valid.
    ARREADY,            //(I)[RdAddr]Read address ready.

    RID,                //(I)[RdData]Read ID tag.
    RDATA,              //(I)[RdData]Read data.
    RRESP,              //(I)[RdData]Read response.
    RLAST,              //(I)[RdData]Read last.
    RVALID,             //(I)[RdData]Read valid.
    RREADY              //(O)[RdData]Read ready.
);

/* parameter Declaration */
parameter   TCo_C           = 1;
parameter   AXI_DATA_WIDTH  = 128;

localparam  AXI_BYTE_NUMBER = AXI_DATA_WIDTH/8;
localparam  AXI_DATA_SIZE   = $clog2(AXI_BYTE_NUMBER);
localparam  ADW_C           = AXI_DATA_WIDTH;
localparam  ABN_C           = AXI_BYTE_NUMBER;

/* Port Declaration */
/* System Signals */
input                       SysClk;
input                       Reset_N;

/* Operate Control & State */
input                       RamRdStart;
output [ADW_C-1:0]          RamRdData;
input [7:0]                 axi_rd_id;

//Config DDR & AXI Operate Parameter
input [31:0]                CfgRdAddr;
input [7:0]                 CfgRdBLen;

/* Axi4 Read Address & Data Bus */
output [7:0]                ARID;
output [31:0]               ARADDR;
output [7:0]                ARLEN;
output [2:0]                ARSIZE;
output [1:0]                ARBURST;
output [1:0]                ARLOCK;
output                      ARVALID;
input                       ARREADY;

input [7:0]                 RID;
input [1:0]                 RRESP;
input                       RLAST;
input                       RVALID;
output                      RREADY;
input [ADW_C-1:0]           RDATA;

/* Address handshake */
wire  AddrReady = ARREADY;

/* Store burst length and start address */
reg   [7:0]   RdBurstLen  = 8'h0;
reg   [31:0]  RdStartAddr = 32'h0;

always @(posedge SysClk) begin
    if(RamRdStart)  RdBurstLen    <=   CfgRdBLen;
    else RdBurstLen  <=  RdBurstLen ;
end
always @( posedge SysClk) begin 
    if(RamRdStart)  RdStartAddr   <=  CfgRdAddr;
    else RdStartAddr  <=  RdStartAddr ;
end

// This signal indicates that the channel is signaling 
// valid read address and control information.
reg    AddrValid = 1'h0;

always @(posedge SysClk) begin
    if (RamRdStart)  AddrValid <= 1'h1;
    else AddrValid <= 1'h0 ;
end

/* Address handshake enable */
wire AddrRdEn = (AddrValid & AddrReady);

/*  AXI read address signals */
wire  [7:0]   ARID    = axi_rd_id;
wire  [31:0]  ARADDR  = RdStartAddr;
wire  [7:0]   ARLEN   = RdBurstLen;
wire  [2:0]   ARSIZE  = AXI_DATA_SIZE;
wire  [1:0]   ARBURST = 2'b01;
wire  [1:0]   ARLOCK  = 2'h00;
wire          ARVALID = AddrValid;

/*  AXI read data channel signals */
wire  [7:0]        DataRdId    = RID;
wire  [1:0]        DataRdResp  = RRESP;
wire               DataRdLast  = RLAST;
wire               DataRdValid = RVALID;
wire  [ADW_C-1:0]  DataRdData  = RDATA;

/* Read ready and handshake */
reg   DataRdReady = 1'h0;

wire  DataRdEn    = DataRdReady & DataRdValid;
wire  DataRdEnd   = DataRdReady & DataRdValid & DataRdLast;

/* End detection register */
reg   DataRdEndReg;
reg   DataRdStart = 0;
always @(posedge SysClk) DataRdEndReg <=  DataRdEnd;

/* Read ready control */
always @(posedge SysClk) begin
    if (!Reset_N)    DataRdReady  <= 1'h0;
    else begin
        if (RamRdStart)      DataRdReady  <= 1'h1;
        else if (DataRdValid)DataRdReady  <= 1'h1;
        else if (DataRdEnd)  DataRdReady  <= 1'h0;
    end 
end

/* AXI ready output */
wire  RREADY  = DataRdReady;

/* Address counter update */
wire [7:0]   RdByteNum =  AXI_BYTE_NUMBER ;
reg  [31:0]  RdAddrCnt = 32'h0  ; //(O)[DdrRdCtrl]Ram Read Addrdss

always @(posedge SysClk) begin
    if (DataRdStart)    RdAddrCnt <=  RdStartAddr;
    else if (DataRdEn)  RdAddrCnt <=  RdAddrCnt + {24'h0,RdByteNum};
end

/* Busy flag */
reg   DataRdBusy = 1'h0;

always @(posedge SysClk)
begin
  if (DataRdEnd)      DataRdBusy <=  1'h0;
  else if (DataRdEn)  DataRdBusy <=  1'h1;
end

/* Output read data */
reg   [ADW_C-1:0]   RamRdData ; //(O)[DdrRdCtrl]Ram Read Data

always @(posedge SysClk) begin
    if (DataRdEn) RamRdData <=  DataRdData; //[DdrRdCtrl]Ram Read Data
end

endmodule