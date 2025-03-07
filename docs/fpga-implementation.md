# Using Header Files for FPGA and CPU Communication

To manage multiple applications on both the CPU and FPGA, header files are used to define application identifiers (app_id) and related configurations for proper intercommunication.

---

## CPU Side

### 1. Define Applications and Use Application IDs in CPU Code

```c
// main.c
#include <rah.h>

#define APP_ID_1 1
#define APP_ID_2 2
#define APP_ID_3 3

void app1() {
    char data[] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06};
    rah_write(APP_ID_1, data, 6);
}

void app2() {
    char data[] = {
        0x00, 0x01, 0x00, 0x05, 0x05, 0x02,
        0x70, 0x01, 0x03, 0x04, 0x05, 0x02
    };
    rah_write(APP_ID_2, data, sizeof(data));
}

void app3() {
    char data[] = {
        0x90, 0x01, 0x25, 0x05, 0x34, 0x02,
        0x70, 0x01, 0x03, 0x04, 0x05, 0x02,
        0x70, 0x67, 0x03, 0x78, 0x05, 0x65
    };
    rah_write(APP_ID_3, data, sizeof(data));
}

int main() {
    app1();
    app2();
    app3();
    return 0;
}
```

### 2. Compilation and Running

- **Compilation**:

```bash
gcc filename.c -lrah
```

- **Running the Executable**:

```bash
./a.out
```

For more information on the RAH API functions, refer to the RAH protocol's API [documentation](docs/cpu-usage-guide.md).

---

## FPGA Side

### 1. Define Applications in a Header File (rah_var_defs.vh)

```verilog
// rah_var_defs.vh
`define TOTAL_APPS 3

`define APP_ID_1 1
`define APP_ID_2 2
`define APP_ID_3 3
// Add more application IDs as needed

`define GET_DATA_RAH(a) rd_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
`define SET_DATA_RAH(a) wr_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
```

### 2. Include and Use Application IDs in FPGA Code

```verilog
// top.v
`include "rah_var_defs.vh"

module top (
    ..........
);

/* Accessing data from APP_WR_FIFO */
assign rd_clk[`APP_ID_1] = rd_clk_app1;

app1_recv #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) er (
    .clk                    (rd_clk_app1),
    .data_queue_empty       (data_queue_empty[`APP_ID_1]),
    .data_queue_almost_empty(data_queue_almost_empty[`APP_ID_1]),
    .request_data           (rd_request_data[`APP_ID_1])
);

endmodule
```

---

# FIFO Operations on FPGA and CPU Sides

## Requesting Data from FIFO on FPGA Side

When requesting data from the FIFO (`APP_WR_FIFO`), the process follows these steps:

1. **Check if the FIFO is empty.**
2. **Assert the FIFO Enable signal.**
3. **Wait for one clock period.**
4. **Sample the data.**
5. **Read data from FIFO using the read pointer.**

```verilog
// FPGA - Read from APP_WR_FIFO
reg [1:0] state = 0;
localparam IDLE = 2'b00;
localparam WAIT = 2'b01;
localparam READ = 2'b10;

always @(posedge clk) begin
  case (state)

  IDLE: begin
      if (!APP_WR_FIFO_empty_1) begin
          APP_WR_FIFO_EN_1 <= 1'b1;
          state <= WAIT;
      end
  end
  
  WAIT: begin
      APP_WR_FIFO_EN_1 <= 0;
      state <= READ;
  end

  READ: begin
      READ_DATA <= APP_WR_FIFO_READ_DATA_1;
      state <= IDLE;
  end

  default : state <= IDLE;

  endcase
end
```

## Writing Data to FIFO on FPGA Side

When writing data to the FIFO (`APP_RD_FIFO`), ensure the following steps are taken:

1. **Assert the FIFO Enable signal.**
2. **Write the data to the FIFO at the same clock edge.**

```verilog
// FPGA - Write to APP_RD_FIFO
always @(posedge clk) begin
    case(state)
    // Additional states for handling FIFO writing
    WRITE: begin
        APP_RD_FIFO_EN <= 1;
        APP_RD_FIFO_DATA <= DATA;
    end
    // Other cases
    endcase
end
```

## Reading Data from FIFO on CPU Side

To read data from the FIFO (`APP_RD_FIFO`) on the CPU side, use the following function call:

```c
// CPU - Read from APP_RD_FIFO
char data[6];
rah_read(app_id, data, 6); // 6 is the length of the data
```

Call `rah_read(app_id)` to get the data associated with the `app_id`.

## Writing Data to FIFO on CPU Side

To write data to the FIFO (`APP_WR_FIFO`) on the CPU side, use the following function:

```c
// CPU - Write to APP_WR_FIFO
char data[] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06};
rah_write(app_id, data, sizeof(data));
```

Call `rah_write(app_id, data, length)` to encapsulate and send data to FPGA. The `length` is the number of bytes to be sent.

---

## Conclusion

By utilizing header files to define application identifiers and organizing the data using these IDs, you can efficiently manage communication between the CPU and FPGA. This structure promotes flexibility, clarity, and better organization when using the RAH protocol for intersystem data transfer.

---

This document provides a structured approach to managing multiple applications on both CPU and FPGA systems and implementing FIFO operations for seamless communication.
