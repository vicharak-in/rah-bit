# Bitcoin Mining on FPGA

## Introduction

Bitcoin mining is the process of solving computationally intensive proof-of-work problems to secure transactions on the Bitcoin blockchain. This involves repeatedly hashing block headers using the SHA256 algorithm until a valid hash is found. FPGA (Field-Programmable Gate Array) mining offers an efficient alternative to CPU and GPU mining by providing higher hashing rates with optimized energy consumption.

## Block Diagram of RAH

<div align="center">

![rah design](images/rah_user_guide.svg)

</div>

## Block Diagram of Bitcoin Mining Algorithm

<div align="center">

![rah design](images/rah_user_guide.svg)

</div>

## Motivation
With the increasing difficulty of Bitcoin mining, specialized hardware solutions such as FPGA and ASIC have gained popularity. While ASIC miners dominate the industry, FPGA-based mining offers flexibility for developers to optimize the SHA256 hashing algorithm for power efficiency and performance gains.

## FPGA-Based Mining Architecture

An FPGA-based mining system typically consists of the following components:
1. Mining Core: The core logic implementing the SHA256 hashing algorithm.
2. Communication Interface: A method to communicate with a mining pool or Stratum proxy.
3. Control Unit: Logic for handling nonces, timestamps, and Merkle root updates.
4. Power Management: Efficient use of available power to maximize hash rate.

### Optimizing SHA256 for Bitcoin Mining
Optimizing SHA256 hashing for Bitcoin mining involves:

1. Reducing Computational Overhead: Avoid redundant calculations in SHA256 rounds.
2. Pipeline Optimization: Using deep pipelining to increase throughput.
3. Parallel Processing: Implementing multiple SHA256 cores for concurrent processing.
4. Carry-Save Adders (CSA): Reducing propagation delay in critical path operations.
5. Unrolling and Pipelining: Minimizing clock cycles required per hash calculation.

## Stratum Mining Proxy Migration
Since many FPGA miners rely on Python-based mining proxies, migrating the Stratum proxy from Python 2.7 to Python 3.10 ensures compatibility with modern security standards and optimizations.


## Implementation Details

FPGA Mining Setup

1. Hardware Requirements: FPGA board with sufficient logic elements (e.g., Xilinx or Altera FPGAs).
2. Development Tools:
Verilog or VHDL for hardware description.
MATLAB for simulation and verification.
Xilinx Vivado or Intel Quartus for FPGA synthesis and implementation.
3. Mining Software:
Cgminer or BFGminer for pool connectivity.
Custom Python-based Stratum proxy for job handling.

## Verilog Implementation of SHA256
A Verilog-based SHA256 module consists of:

1. Message Scheduler: Expands 512-bit input into 64 rounds.
2. Compression Function: Performs modular additions and bitwise operations.
3. Final Hash Computation: Outputs the valid hash for comparison with the target.

## Performance Evaluation
1. Hash Rate: Number of hashes computed per second.
2. Power Efficiency: Hashes per joule of energy consumed.
3. Latency: Time required for a single hash computation.
