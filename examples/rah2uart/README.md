# RAH-to-UART

### Introduction

This project demonstates the character passing from FPGA's UART to processor,
the RAH protocol will send 6 bytes at a time and UART only sends 1.
To negotiate that we will append 0's at MSB and send the data.

## Usage Guide

### On FPGA
1. **Define RAH2UART in a Header File (rah_var_defs.vh)**:
    
The definition should be same as defined in the CPU side.

```verilog
// rah_var_defs.vh
`define TOTAL_APPS 2

`define RAH2UART 0
`define XYZ 1

`define GET_DATA_RAH(a) rd_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
`define SET_DATA_RAH(a) wr_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
```

2. **Include and Use RAH2UART IDs in top module**:

```verilog
// top.v
`include "rah_var_defs.vh"

module top (
    ..........
);

/* Accesssing data from APP_WR_FIFO */

assign rd_clk[`RAH2UART] = rah2uart_clk;
assign wr_clk[`RAH2UART] = rah2uart_clk;

rah2uart #(
    .RAH_PACKET_WIDTH       (RAH_PACKET_WIDTH)
) er (
    .clk                    (rah2uart_clk),
    .data_queue_empty       (data_queue_empty[`RAH2UART]),
    .data_queue_almost_empty(data_queue_almost_empty[`RAH2UART]),
    .data_frame             (`GET_DATA_RAH(`RAH2UART)),
    .uart_rx_pin            (uart_rx_pin),

    .tx_data                (`SET_DATA_RAH(`RAH2UART)),
    .send_data              (write_apps_data[`RAH2UART]),
    .request_data           (request_data[`RAH2UART]),
    .uart_tx_pin            (uart_tx_pin)
);

/* Writing data into APP_RD_FIFO */

.....

endmodule
```

> [!NOTE]
>
> The FIFOs used here for data transfer are asynchronous. So, it is mandatory to assign the read and write clocks for every application FIFO. It facilitates us Clock Domain Crossing (CDC) among RAH and different applications.

### On CPU

This are the pre-requisite for the rah:

- [rah-service](https://github.com/vicharak-in/rah-bit#pre-requisite)
- [Turning on FPGA communication from the overlays](https://docs.vicharak.in/vaaman-linux/linux-configuration-guide/vicharak-config-tool/#vicharak-config-overlays)

After doing that, compile and run it by:

```bash
make
./bin/uart
```

This will start the uart process, and now whatever you type on will be sent on
FPGA's UART and whatever FPGA side it receives will be seen here.
