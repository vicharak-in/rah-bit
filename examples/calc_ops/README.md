# Calculator arithmetic operations using RAH

### Introduction

This project demonstrates the use of the RAH interface to communicate with the FPGA. The FPGA is used to perform arithmetic operations on the data passed by the CPU. The FPGA is programmed to perform the following operations:

1. **Addition**
2. **Shift**
3. **Multiplication**

The CPU passes the data to the FPGA in the form of a 6-byte packet. The FPGA processes the data and sends the result back to the CPU. The CPU then displays the result on the console.

## Usage Guide

### On FPGA

> [!NOTE]
>
> To implement example project, just edit in the `rah-bit` repository, don't copy the code from rah-bit to your project. Make sure to add your module in rah-bit and then include it in the top module.

1. **Define Calculator Operations in a Header File (rah_var_defs.vh)**:

Open the `rah_var_defs.vh` file and define the calculator operations and the total number of applications.
    
The definition should be same as defined on the CPU side.

```verilog
// rah_var_defs.vh
`define TOTAL_APPS 3

`define ADD 0
`define SHIFT 1
`define MUL 2

`define GET_DATA_RAH(a) rd_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
`define SET_DATA_RAH(a) wr_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
```

2. **Include and Use Calculator operation IDs in top module**:

To implement the project, open existing `top.v` from the `rah-bit` repository and add the following modules to it:

```verilog
// top.v
`include "rah_var_defs.vh"

module top (
    ..........
);

.........

/* Accesssing data from APP_WR_FIFO */

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
./bin/calc 12 67 89 90 48 72 90 64 23 45 67 89
```
Here, we will pass the data into hex format, the above command will pass 6 bytes at a time to the FPGA. The data will be processed by the FPGA and the result will be displayed on the console.
