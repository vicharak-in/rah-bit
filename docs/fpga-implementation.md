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

For more information on the RAH API functions, refer to the RAH protocol's API [documentation](cpu-usage-guide.md).

---

## FPGA Side

### 1. Define Applications in a Header File (rah_var_defs.vh)

`TOTAL_APPS` is the number of **user** applications. App ID `0` is reserved for
the meta app (`rah_meta_app`), so `top.v` internally uses `TOTAL_APPS + 1`.
User app IDs start at `1` and must match the IDs used on the CPU side.

```verilog
// rah_var_defs.vh
`define TOTAL_APPS 3

`define APP_ID_1 1
`define APP_ID_2 2
`define APP_ID_3 3
// Add more application IDs as needed

`define VERSION "1.4.0"

`define GET_DATA_RAH(a) rd_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
`define SET_DATA_RAH(a) wr_data[a * RAH_PACKET_WIDTH +: RAH_PACKET_WIDTH]
```

> [!NOTE]
> `GET_DATA_RAH` / `SET_DATA_RAH` refer to the nets `rd_data` / `wr_data`
> declared in `top.v`. These nets are the app-side data buses of
> `data_path_interface`, not of the decoder / encoder.

### 2. Connect Your App to the Data Path Interface

User apps do **not** connect to `rah_decoder` / `rah_encoder` directly. Every app
talks to `data_path_interface`, which routes the data either through the RAH
FIFOs or through DRAM, depending on the DRAM mode set by the CPU
(see [DRAM and meta app](dram-and-meta-app.md)).

Each app has two independent FIFOs. Both are asynchronous, so **you must assign
a clock to each of them**; the data path performs the clock domain crossing.

| Direction | Clock | Signals (index = your app ID) |
|---|---|---|
| CPU to FPGA (`APP_WR_FIFO`) | `rd_clk[APP]` | `wr_app_fifo_empty`, `wr_app_fifo_a_empty`, `wr_app_fifo_rd_en`, data: `` `GET_DATA_RAH(APP) `` |
| FPGA to CPU (`APP_RD_FIFO`) | `wr_clk[APP]` | `rd_app_fifo_wr_en`, `rd_app_fifo_prog_full`, data: `` `SET_DATA_RAH(APP) `` |

Naming is from the CPU's point of view: the CPU *writes* into `APP_WR_FIFO`
(you read it on the FPGA), and the CPU *reads* from `APP_RD_FIFO` (you write it
on the FPGA).

```verilog
// top.v
`include "rah_var_defs.vh"

module top (
    ..........
);

/* Receive from CPU (APP_WR_FIFO) */
assign rd_clk[`APP_ID_1] = rx_pixel_clk;     // any clock your app runs on

app1_recv #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) a1r (
    .clk                     (rx_pixel_clk),
    .data_queue_empty        (wr_app_fifo_empty[`APP_ID_1]),
    .data_queue_almost_empty (wr_app_fifo_a_empty[`APP_ID_1]),
    .request_data            (wr_app_fifo_rd_en[`APP_ID_1]),
    .data_frame              (`GET_DATA_RAH(`APP_ID_1))
);

/* Send to CPU (APP_RD_FIFO) */
assign wr_clk[`APP_ID_1] = tx_pixel_clk;     // any clock your app runs on

app1_trans #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) a1t (
    .clk       (tx_pixel_clk),
    .data      (`SET_DATA_RAH(`APP_ID_1)),
    .send_data (rd_app_fifo_wr_en[`APP_ID_1])
);

endmodule
```

The port names of your own module are up to you (the examples keep the
`data_queue_*` / `request_data` / `send_data` names); only the signals on the
`top.v` side are fixed.

---

# FIFO Operations on FPGA and CPU Sides

## Reading Data from APP_WR_FIFO on FPGA Side

1. **Check that the FIFO is not empty** (`wr_app_fifo_empty` is low).
2. **Pulse the read enable** (`wr_app_fifo_rd_en`) for one clock.
3. **Wait one clock period.**
4. **Sample the data** (`` `GET_DATA_RAH(APP) ``).

`wr_app_fifo_a_empty` (almost empty) can be used if you want to drain the FIFO
in bursts; it is optional.

```verilog
// FPGA - Read from APP_WR_FIFO (see rtl/example.v: example_recv)
reg [1:0] state = 0;
localparam IDLE = 2'd0;
localparam WAIT = 2'd1;
localparam READ = 2'd2;

always @(posedge clk) begin
  case (state)
  IDLE: begin
      if (~data_queue_empty) begin
          request_data <= 1'b1;
          state <= WAIT;
      end
  end

  WAIT: begin
      request_data <= 1'b0;
      state <= READ;
  end

  READ: begin
      read_data <= data_frame;
      state <= IDLE;
  end

  default: state <= IDLE;
  endcase
end
```

## Writing Data to APP_RD_FIFO on FPGA Side

1. Put the data on the data bus (`` `SET_DATA_RAH(APP) ``).
2. Assert `rd_app_fifo_wr_en` for one clock **together with** the data.
3. If your app can produce bursts, check `rd_app_fifo_prog_full` first and stop
   writing while it is high; data written to a full FIFO is lost.

```verilog
// FPGA - Write to APP_RD_FIFO
always @(posedge clk) begin
    case (state)
    WRITE: begin
        if (~prog_full) begin       // rd_app_fifo_prog_full[APP]
            send_data <= 1;         // one-clock strobe, with data
            data <= DATA;
            state <= IDLE;
        end
    end

    IDLE: send_data <= 0;
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
