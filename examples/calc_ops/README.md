# Calculator arithmetic operations using RAH

### Introduction

This project demonstrates the use of the RAH interface to communicate with the FPGA. The FPGA is used to perform arithmetic operations on the data passed by the CPU. The FPGA is programmed to perform the following operations:

1. **Addition**
2. **Shift**
3. **Multiplication**

The CPU passes the data to the FPGA in the form of a 10-byte packet. The FPGA processes the data and sends the result back to the CPU. The CPU then displays the result on the console.

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
`define TOTAL_APPS 1

`define CALC 1

`define VERSION "1.2.0"

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

assign rd_clk[`CALC] = calc_clk;
assign wr_clk[`CALC] = calc_clk;

calc0 (
    .clk            (calc_clk),
    .datain         (`GET_DATA_RAH(`CALC)),
    .empty          (data_queue_empty[`CALC]),
    .rstn           (1'b0),
    .dataout        (`SET_DATA_RAH(`CALC)),
    .rden           (request_data[`CALC]),
    .wren           (write_apps_data[`CALC])
);

.....
endmodule
```

> [!NOTE]
>
> The FIFOs used here for data transfer are asynchronous. So, it is mandatory to assign the read and write clocks for every application FIFO. It facilitates us Clock Domain Crossing (CDC) among RAH and different applications.

### On CPU

This Python script is designed to perform mathematical operations (addition, shifting, and multiplication) on user-provided input. It allows the user to select a mode for calculation, input two numbers, and sends the result to the appropriate destination. Data is then transferred and displayed based on the selected mode.

The script uses multithreading to concurrently handle user input and data reception processes.

**Requirements:**

Before using the script, ensure the following libraries are installed:

- `pyrah` (External library for reading and writing data)

Additionally, make sure you are running this script in a Python 3+ environment.

**Install `pyrah`:**
If the `pyrah` library is not installed, you can install it via pip:

```bash
pip install git+https://github.com/vicharak-in/pyrah
```
**Running the Program**

- Save the Python script to your local machine.
- Open a terminal or command prompt.
- Run the script using the command:
```bash
sudo python3 calc.py
```
This will start the program and display the main menu for selecting the operation mode.

**How to Use**
**1. Select an Operation Mode**

Upon starting the program, you will see the following options:

```bash
Select the mode:
1. Add
2. Shift
3. Mult
4. All
5. Exit
```
- **Option 1: Add**  
  Perform addition on two input numbers. The program will take two input numbers and calculate their sum.

- **Option 2: Shift**  
  Perform a bitwise shift on two input numbers. The program will take two input numbers and apply a bitwise shift operation on them.

- **Option 3: Mult**  
  Perform multiplication on two input numbers. The program will multiply the two input numbers and return the result.

- **Option 4: All**  
  Execute all operations (Add, Shift, Multiply) at once. The program will perform the addition, bitwise shift, and multiplication operations in sequence and return the results for all.

- **Option 5: Exit**  
  Exit the program. Select this option to quit the program when you're done.

> [!NOTE]  
> In this design, 'SHIFT' refers to a left shift operation only.

**2. Input the Data**

After selecting a mode (e.g., Add or Shift), the program will prompt you to enter two integer values:
```bash
Enter the first input for calculations:
Enter the second input for calculations:
```
### 3. Results

Once the data is processed, the program will display the result in decimal format. For example:

- Add: The result of the addition will be displayed.
- Shift: The result of the bit-shifting operation will be displayed.
- Mult: The result of the multiplication will be shown.
- All: The results for all operations (Add, Shift, Multiply) will be displayed together.

Example:

If you selected Add and entered the values 5 and 10, the program would display:
```bash
Output for add is: 15
```
**4. Repeat or Exit**

After the operation is complete, the program will return to the main menu, allowing you to choose another operation or exit the program by selecting Exit (5).
