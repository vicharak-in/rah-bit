module axi_top #(
    parameter  AXI_DATA_WIDTH  = 128 ,
    parameter  AXI_BYTE_NUMBER = AXI_DATA_WIDTH/8,
    parameter  ADW_C           = AXI_DATA_WIDTH,
    parameter  ABN_C           = AXI_BYTE_NUMBER
) ( 
    input                       SysClk,
    input                       rst,
    input                       RamRdStart,
    input                       w_ctrl_last,
    input                       w_ctrl_valid,
    output [ADW_C-1:0]          RamRdData,
    input [31:0]                CfgRdAddr,
    input [7:0]                 CfgRdBLen,
    input                       RamWrStart,
    input [7:0]                 axi_wr_id,
    input [7:0]                 axi_rd_id,
    input [ADW_C-1:0]           RamWrData,
    input [31:0]                CfgWrAddr,
    input [7:0]                 CfgWrBlen,
    output [7:0]                aid,
    output [31:0]               aaddr,
    output [7:0]                alen,
    output [2:0]                asize,
    output [1:0]                aburst,
    output [1:0]                alock,
    output                      avalid,
    input                       aready,
    output                      atype,
    output [7:0]                wid,
    output [ABN_C-1:0]          wstrb,
    output                      wlast,
    output                      wvalid,
    input                       wready,
    output [ADW_C-1:0]          wdata,
    input  [7:0]                rid,
    input                       rlast,
    input                       rvalid,
    output                      rready,
    input [1:0]                 rresp,
    input [ADW_C-1:0]           rdata,
    input [7:0]                 bid,
    input                       bvalid,
    output                      bready
);

wire [7:0] AWID, WID, AWLEN, BID, ARID, ARLEN, RID;
wire [31:0] AWADDR , ARADDR;
wire [ABN_C-1:0] WSTRB;
wire [2:0] AWSIZE, ARSIZE;
wire [1:0] AWBURST, AWLOCK, ARBURST, ARLOCK, RRESP;
wire [ADW_C-1:0] WDATA, RDATA;
wire AWVALID, AWREADY,WLAST, WREADY, WVALID,BVALID, BREADY;
wire ARVALID, ARREADY, RLAST, RREADY, RVALID;

axi4_fulldeplex AXI_FULL_INST (
    .SysClk         (SysClk),       //System Clock
    .Reset_N        (rst),          //System Reset

    /* Axi Slave Interfac Signal */
    .AWID           (AWID),         //(I)[WrAddr]Write address ID.
    .AWADDR         (AWADDR),       //(I)[WrAddr]Write address.
    .AWLEN          (AWLEN),        //(I)[WrAddr]Burst length.
    .AWSIZE         (AWSIZE),       //(I)[WrAddr]Burst size.
    .AWBURST        (AWBURST),      //(I)[WrAddr]Burst type.
    .AWLOCK         (AWLOCK),       //(I)[WrAddr]Lock type.
    .AWVALID        (AWVALID),      //(I)[WrAddr]Write address valid.
    .AWREADY        (AWREADY),      //(O)[WrAddr]Write address ready.

    .WID            (WID),          //(I)[WrData]Write ID tag.
    .WDATA          (WDATA),        //(I)[WrData]Write data.
    .WSTRB          (WSTRB),        //(I)[WrData]Write strobes.
    .WLAST          (WLAST),        //(I)[WrData]Write last.
    .WVALID         (WVALID),       //(I)[WrData]Write valid.
    .WREADY         (WREADY),       //(O)[WrData]Write ready.

    .BID            (BID),          //(O)[WrResp]Response ID tag.
    .BVALID         (BVALID),       //(O)[WrResp]Write response valid.
    .BREADY         (BREADY),       //(I)[WrResp]Response ready.

    .ARID           (ARID),         //(I)[RdAddr]Read address ID.
    .ARADDR         (ARADDR),       //(I)[RdAddr]Read address.
    .ARLEN          (ARLEN),        //(I)[RdAddr]Burst length.
    .ARSIZE         (ARSIZE),       //(I)[RdAddr]Burst size.
    .ARBURST        (ARBURST),      //(I)[RdAddr]Burst type.
    .ARLOCK         (ARLOCK),       //(I)[RdAddr]Lock type.
    .ARVALID        (ARVALID),      //(I)[RdAddr]Read address valid.
    .ARREADY        (ARREADY),      //(O)[RdAddr]Read address ready.

    .RID            (RID),          //(O)[RdData]Read ID tag.
    .RDATA          (RDATA),        //(O)[RdData]Read data.
    .RRESP          (RRESP),        //(O)[RdData]Read response.
    .RLAST          (RLAST),        //(O)[RdData]Read last.
    .RVALID         (RVALID),       //(O)[RdData]Read valid.
    .RREADY         (RREADY),       //(I)[RdData]Read ready.

    /* DDR Controner AXI4 Signal */
    .aid            (aid),          //(O)[Addres] Address ID
    .aaddr          (aaddr),        //(O)[Addres] Address
    .alen           (alen),         //(O)[Addres] Address Brust Length
    .asize          (asize),        //(O)[Addres] Address Burst size
    .aburst         (aburst),       //(O)[Addres] Address Burst type
    .alock          (alock),        //(O)[Addres] Address Lock type
    .avalid         (avalid),       //(O)[Addres] Address Valid
    .aready         (aready),       //(I)[Addres] Address Ready
    .atype          (atype),        //(O)[Addres] Operate Type 0=Read, 1=Write

    .wid            (wid),          //(O)[Write]  ID
    .wdata          (wdata),        //(O)[Write]  Data
    .wstrb          (wstrb),        //(O)[Write]  Data Strobes(Byte valid)
    .wlast          (wlast),        //(O)[Write]  Data Last
    .wvalid         (wvalid),       //(O)[Write]  Data Valid
    .wready         (wready),       //(I)[Write]  Data Ready

    .rid            (rid),          //(I)[Read]   ID
    .rdata          (rdata),        //(I)[Read]   Data
    .rlast          (rlast),        //(I)[Read]   Data Last
    .rvalid         (rvalid),       //(I)[Read]   Data Valid
    .rready         (rready),       //(O)[Read]   Data Ready
    .rresp          (rresp),        //(I)[Read]   Response

    .bid            (bid),          //(I)[Answer] Response Write ID
    .bvalid         (bvalid),       //(I)[Answer] Response valid
    .bready         (bready)        //(O)[Answer] Response Ready
);

axi_wr_ctrl WR_CTRL_INST (
    .SysClk         (SysClk),       //System Clock
    .Reset_N        (rst),          //System Reset

    /* config AXI & DDR Operate Parameter */
    .CfgWrAddr      (CfgWrAddr),   //(I)Config Write Start Address
    .CfgWrBLen      (CfgWrBlen),   //(I)Config Write Burst Length
    .axi_wr_id      (axi_wr_id),
    .w_ctrl_valid   (w_ctrl_valid),
    .w_ctrl_last    (w_ctrl_last),

    /* Operate Control & State */
    .RamWrStart     (RamWrStart),   //(I)Ram Operate Start
    .RamWrData      (RamWrData),    //(I)Ram Write Data

    /* Axi Slave Interfac Signal */
    .AWID           (AWID),         //(O)[WrAddr]Write address ID.
    .AWADDR         (AWADDR),       //(O)[WrAddr]Write address.
    .AWLEN          (AWLEN),        //(O)[WrAddr]Burst length.
    .AWSIZE         (AWSIZE),       //(O)[WrAddr]Burst size.
    .AWBURST        (AWBURST),      //(O)[WrAddr]Burst type.
    .AWLOCK         (AWLOCK),       //(O)[WrAddr]Lock type.
    .AWVALID        (AWVALID),      //(O)[WrAddr]Write address valid.
    .AWREADY        (AWREADY),      //(I)[WrAddr]Write address ready.

    .WID            (WID),          //(O)[WrData]Write ID tag.
    .WDATA          (WDATA),        //(O)[WrData]Write data.
    .WSTRB          (WSTRB),        //(O)[WrData]Write strobes.
    .WLAST          (WLAST),        //(O)[WrData]Write last.
    .WVALID         (WVALID),       //(O)[WrData]Write valid.
    .WREADY         (WREADY),       //(I)[WrData]Write ready.

    .BID            (BID),          //(I)[WrResp]Response ID tag.
    .BVALID         (BVALID),       //(I)[WrResp]Write response valid.
    .BREADY         (BREADY)        //(O)[WrResp]Response ready.
);

axi_rd_ctrl RD_CTRL_INST (
    .SysClk         (SysClk),       //System Clock
    .Reset_N        (rst),          //System Reset
    .axi_rd_id      (axi_rd_id),

    /* Operate Control & State */
    .RamRdStart     (RamRdStart),   //(I)Ram Read Start
    .RamRdData      (RamRdData),    //(O)Ram Read Data

    /* Config DDR & AXI Operate Parameter */
    .CfgRdAddr      (CfgRdAddr),    //(I)Config Read Start Address
    .CfgRdBLen      (CfgRdBLen),    //(I)[DdrOpCtrl]Config Read Burst Length

    /* Axi4 Read Address & Data Bus */
    .ARID           (ARID),         //(O)[RdAddr]Read address ID.
    .ARADDR         (ARADDR),       //(O)[RdAddr]Read address.
    .ARLEN          (ARLEN),        //(O)[RdAddr]Burst length.
    .ARSIZE         (ARSIZE),       //(O)[RdAddr]Burst size.
    .ARBURST        (ARBURST),      //(O)[RdAddr]Burst type.
    .ARLOCK         (ARLOCK),       //(O)[RdAddr]Lock type.
    .ARVALID        (ARVALID),      //(O)[RdAddr]Read address valid.
    .ARREADY        (ARREADY),      //(I)[RdAddr]Read address ready.
   
    .RID            (RID),          //(I)[RdData]Read ID tag.
    .RDATA          (RDATA),        //(I)[RdData]Read data.
    .RRESP          (RRESP),        //(I)[RdData]Read response.
    .RLAST          (RLAST),        //(I)[RdData]Read last.
    .RVALID         (RVALID),       //(I)[RdData]Read valid.
    .RREADY         (RREADY)        //(O)[RdData]Read ready.
);

endmodule