# Bitcoin Mining on FPGA

## Introduction

Bitcoin mining is the process of solving computationally intensive proof-of-work problems to secure transactions on the Bitcoin blockchain. This involves repeatedly hashing block headers using the SHA256 algorithm until a valid hash is found. FPGA (Field-Programmable Gate Array) mining offers an efficient alternative to CPU and GPU mining by providing higher hashing rates with optimized energy consumption.

## Block Diagram

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

### Read Cycle (FPGA to CPU)

1. **FPGA Application**: Writes data to the `APP_RD_FIFO`.
2. **RAH Design on FPGA**: Encapsulates the data from `APP_RD_FIFO` into a data-frame.
3. **RAH Services on CPU**: Receives the data-frame and decodes it.
4. **CPU Application**: Processes the received data.

## Stratum Mining Proxy Migration

Since many FPGA miners rely on Python-based mining proxies, migrating the Stratum proxy from Python 2.7 to Python 3.10 ensures compatibility with modern security standards and optimizations.

## Generating Multiple Applications

### Pre-requisite

1. **Enable FPGA Communication from the Vicharak Utility**
    - [Enabling the overlay](https://docs.vicharak.in/vaaman-linux/linux-configuration-guide/vicharak-config-tool/#vicharak-config-overlays)

2. **Install RAH Service on the Board:**

    ```bash
    sudo apt update
    sudo apt install rah-service
    ```

> [!NOTE]  
> RAH service is frequently updated, so it is recommended to update the RAH service before using it on both:w CPU side as well as FPGA side.

## RAH Protocol User Guide - Resources

For further details on how to use the RAH protocol, you can refer to the following guides:

1. **[CPU Usage Guide](docs/cpu-usage-guide.md)**:  
   This guide will provide detailed instructions on how to set up and use the RAH protocol on the CPU side, including configuration, data encapsulation, and integration with CPU applications.

2. **[FPGA Implementation Guide](docs/fpga-implementation.md)**:  
   This guide covers the FPGA side of the RAH protocol, explaining how to implement the RAH design, decode data frames, and manage the FIFO buffers for both write and read cycles.

3. **[RAH Example Integration](docs/rah-example-integration.md)**:  
   This document provides a step-by-step example of integrating the RAH protocol between the CPU and FPGA, demonstrating the complete flow from data generation on the CPU to processing on the FPGA and back.
