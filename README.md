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

### Write Cycle (CPU to FPGA)

1. **CPU Application**: Generates data to be sent to the FPGA.
2. **RAH Services on CPU**: Encapsulates the data into a data-frame, including the `app_id`.
3. **RAH Design on FPGA**: Receives the data-frame and decodes it.
4. **FPGA Application**: Reads the decoded data from the appropriate `APP_WR_FIFO`.

### Read Cycle (FPGA to CPU)

1. **FPGA Application**: Writes data to the `APP_RD_FIFO`.
2. **RAH Design on FPGA**: Encapsulates the data from `APP_RD_FIFO` into a data-frame.
3. **RAH Services on CPU**: Receives the data-frame and decodes it.
4. **CPU Application**: Processes the received data.

## Data Alignment

> [!NOTE]  
> The alignment of data to be sent and received throughout the RAH protocol is user-defined. The user must ensure that the data is sampled in the same way as it is aligned at the time of transmission. This applies to both write and read cycles.

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
