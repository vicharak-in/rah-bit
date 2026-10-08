module axi4_fulldeplex (
    /* System Signals */
    SysClk,             //System Clock
    Reset_N,            //System Reset

    /* Axi Slave Interfac Signal */
    AWID,               //(I)[WrAddr]Write address ID.
    AWADDR,             //(I)[WrAddr]Write address.
    AWLEN,              //(I)[WrAddr]Burst length.
    AWSIZE,             //(I)[WrAddr]Burst size.
    AWBURST,            //(I)[WrAddr]Burst type.
    AWLOCK,             //(I)[WrAddr]Lock type.
    AWVALID,            //(I)[WrAddr]Write address valid.
    AWREADY,            //(O)[WrAddr]Write address ready.

    WID,                //(I)[WrData]Write ID tag.
    WDATA,              //(I)[WrData]Write data.
    WSTRB,              //(I)[WrData]Write strobes.
    WLAST,              //(I)[WrData]Write last.
    WVALID,             //(I)[WrData]Write valid.
    WREADY,             //(O)[WrData]Write ready.

    BID,                //(O)[WrResp]Response ID tag.
    BVALID,             //(O)[WrResp]Write response valid.
    BREADY,             //(I)[WrResp]Response ready.

    ARID,               //(I)[RdAddr]Read address ID.
    ARADDR,             //(I)[RdAddr]Read address.
    ARLEN,              //(I)[RdAddr]Burst length.
    ARSIZE,             //(I)[RdAddr]Burst size.
    ARBURST,            //(I)[RdAddr]Burst type.
    ARLOCK,             //(I)[RdAddr]Lock type.
    ARVALID,            //(I)[RdAddr]Read address valid.
    ARREADY,            //(O)[RdAddr]Read address ready.

    RID,                //(O)[RdData]Read ID tag.
    RDATA,              //(O)[RdData]Read data.
    RRESP,              //(O)[RdData]Read response.
    RLAST,              //(O)[RdData]Read last.
    RVALID,             //(O)[RdData]Read valid.
    RREADY,             //(I)[RdData]Read ready.

    /* DDR Controner AXI4 Signals */
    aid,                //(O)[Addres] Address ID
    aaddr,              //(O)[Addres] Address
    alen,               //(O)[Addres] Address Brust Length
    asize,              //(O)[Addres] Address Burst size
    aburst,             //(O)[Addres] Address Burst type
    alock,              //(O)[Addres] Address Lock type
    avalid,             //(O)[Addres] Address Valid
    aready,             //(I)[Addres] Address Ready
    atype,              //(O)[Addres] Operate Type 0=Read, 1=Write

    wid,                //(O)[Write]  ID
    wdata,              //(O)[Write]  Data
    wstrb,              //(O)[Write]  Data Strobes(Byte valid)
    wlast,              //(O)[Write]  Data Last
    wvalid,             //(O)[Write]  Data Valid
    wready,             //(I)[Write]  Data Ready

    rid,                //(I)[Read]   ID
    rdata,              //(I)[Read]   Data
    rlast,              //(I)[Read]   Data Last
    rvalid,             //(I)[Read]   Data Valid
    rready,             //(O)[Read]   Data Ready
    rresp,              //(I)[Read]   Response

    bid,                //(I)[Answer] Response Write ID
    bvalid,             //(I)[Answer] Response valid
    bready              //(O)[Answer] Response Ready
);

/* Parameter Declaration */
parameter   TCo_C               = 1;
parameter   DDR_WRITE_FIRST     = 1'h1;
parameter   AXI_DATA_WIDTH      = 128 ;

localparam  AXI_BYTE_NUMBER     = AXI_DATA_WIDTH/8;
localparam  ADW_C               = AXI_DATA_WIDTH;
localparam  ABN_C               = AXI_BYTE_NUMBER;

/* Port Declaration */
input                       SysClk;
input                       Reset_N;

/* AXI4 Full Deplex Signals */
input [7:0]                 AWID;
input [31:0]                AWADDR;
input [7:0]                 AWLEN;
input [2:0]                 AWSIZE;
input [1:0]                 AWBURST;
input [1:0]                 AWLOCK;
input                       AWVALID;
output                      AWREADY;

input [7:0]                 WID;
input [ABN_C-1:0]           WSTRB;
input                       WLAST;
input                       WVALID;
output                      WREADY;
input [ADW_C-1:0]           WDATA;

output [7:0]                BID;
output                      BVALID;
input                       BREADY;

input [7:0]                 ARID;
input [31:0]                ARADDR;
input [7:0]                 ARLEN;
input [2:0]                 ARSIZE;
input [1:0]                 ARBURST;
input [1:0]                 ARLOCK;
input                       ARVALID;
output                      ARREADY;

output [7:0]                RID;
output [1:0]                RRESP;
output                      RLAST;
output                      RVALID;
input                       RREADY;
output [ADW_C-1:0]          RDATA;

/* DDR Controner AXI4 Signals Declaration */
output [7:0]                aid;
output [31:0]               aaddr;
output [7:0]                alen;
output [2:0]                asize;
output [1:0]                aburst;
output [1:0]                alock;
output                      avalid;
input                       aready;
output                      atype;
output [7:0]                wid;
output [ABN_C-1:0]          wstrb;
output                      wlast;
output                      wvalid;
input                       wready;
output [ADW_C-1:0]          wdata;
input [7:0]                 rid;
input                       rlast;
input                       rvalid;
output                      rready;
input [1:0]                 rresp;
input [ADW_C-1:0]           rdata;
input [7:0]                 bid;
input                       bvalid;
output                      bready;

//  This signals indicates that the slave is ready to accept 
//  an address and associated control signals.
//  Operation type: 0 = Read, 1 = Write
reg   OpType   = 1'h0;

wire  AWREADY =  OpType & aready;
wire  ARREADY = ~OpType & aready;

/* Select between read/write when both valid */
reg   OperateSel = 1'h0;

always @( posedge SysClk) begin
    if (aready) begin
        if      (AWVALID ^ ARVALID)   OperateSel <= ~DDR_WRITE_FIRST;
        else if (AWVALID & ARVALID)   OperateSel <= ~OperateSel;
    end
end

/* Track available operations */
reg   [1:0] OprateAva = 2'h3;

always @( posedge SysClk) begin
    if (! Reset_N )      OprateAva <=  2'h3;
    else begin
        case (OprateAva)
            2'h0:               OprateAva <=  2'h3;
            2'h1: if (ARREADY)  OprateAva <=  {AWVALID  , 1'h0   };
            2'h2: if (AWREADY)  OprateAva <=  {1'h0     , ARVALID};
            2'h3: begin
                case ({AWVALID , ARVALID})
                    2'h0:   OprateAva  <=  2'h3;
                    2'h1:   OprateAva  <=  2'h1;
                    2'h2:   OprateAva  <=  2'h2;
                    2'h3:   OprateAva  <=  OperateSel ? 2'h2 : 2'h1;
                endcase
            end
        endcase
    end
end

/* Decide active transaction type */
wire  [1:0]  AddrVal = {AWVALID , ARVALID} & OprateAva;

always @( * ) begin
    case (AddrVal)
        2'h0:   OpType  <=  OperateSel;
        2'h1:   OpType  <=  1'h0;
        2'h2:   OpType  <=  1'h1;
        2'h3:   OpType  <=  OperateSel;
    endcase
end

/* Address channel signals */
wire  [7:0]  aid     = OpType ? AWID     : ARID;
wire  [31:0] aaddr   = OpType ? AWADDR   : ARADDR;
wire  [7:0]  alen    = OpType ? AWLEN    : ARLEN;
wire  [2:0]  asize   = OpType ? AWSIZE   : ARSIZE;
wire  [1:0]  aburst  = OpType ? AWBURST  : ARBURST;
wire  [1:0]  alock   = OpType ? AWLOCK   : ARLOCK;
wire         avalid  = OpType ? AWVALID  : ARVALID;
wire         atype   = OpType;

/* Write data path signals */
wire  [7:0]           wid     = WID;
wire  [ABN_C - 1 : 0] wstrb   = WSTRB;
wire                  wlast   = WLAST;
wire                  wvalid  = WVALID;
wire  [ADW_C - 1 : 0] wdata   = WDATA;
wire                  WREADY  = wready;

/* Write data response signals */
wire              bready  = BREADY;
wire  [7:0]       BID     = bid;
wire              BVALID  = bvalid;

/* Read data path signals */
wire              rready  = RREADY;
wire  [7:0]       RID     = rid;
wire  [1:0]       RRESP   = rresp;
wire              RLAST   = rlast;
wire              RVALID  = rvalid;
wire [ADW_C-1:0]  RDATA   = rdata;

endmodule  