# Meta app and DRAM

From version 1.4.0 the FPGA design can keep the data of an application in the
on-board DDR memory instead of the on-chip FIFOs. The CPU controls this through
a small application called the meta app.

## Meta app

The meta app is `rah_meta_app`, instantiated as `rma` in top.v. It always has
the app id 0, that is why user apps start from 1 and top.v uses
`TOTAL_APPS + 1`. It is connected directly to the decoder and the encoder, runs
on `axi_clk`, and you do not need to change it in your design.

The CPU talks to it with a 6 byte frame, the first byte is the configuration id
and the second byte is the app id. The ids are defined in `meta_app.h` of the
processor side repository.

| Id | Name | Purpose |
| :-: | :--- | :--- |
| 0 | VERSION_CHECK | Returns the VERSION from rah_var_defs.vh |
| 1 | DRAM_CPU2FPGA_START_ADDR | Start of the CPU to FPGA region |
| 2 | DRAM_CPU2FPGA_STOP_ADDR | Stop of the CPU to FPGA region |
| 3 | DRAM_FPGA2CPU_START_ADDR | Start of the FPGA to CPU region |
| 4 | DRAM_FPGA2CPU_STOP_ADDR | Stop of the FPGA to CPU region |
| 5 | DRAM_APP_MODE | DRAM mode of the app |
| 6 | DRAM_SET_USECASE | Sets the usecase of the app |
| 7 | DRAM_GET_USECASE | Gets the usecase of the app |

The meta app drives `dram_start_addr`, `dram_stop_addr` and `dram_app_mode`.
Each of them has two entries per app, one for each direction. The addresses go
to the DRAM interface, and the mode goes to `path_select` of the
data_path_interface.

## DRAM modes

The mode is set per application with `rah_dram_set_mode`, and it decides which
path the data of that application takes.

| Mode | Value | Meaning |
| :--- | :-: | :--- |
| NO_DRAM | 0 | Only the on-chip FIFOs are used |
| DIRECT_DRAM | 1 | Data is directly stored into the DRAM |
| HYBRID_DRAM | 2 | DRAM is used along with the on-chip FIFOs |

The usecase decides in which direction the DRAM is used.

| Usecase | Value | Meaning |
| :--- | :-: | :--- |
| USE_DRAM_CPU2FPGA_ONLY | 0 | Only for the data sent to FPGA |
| USE_DRAM_FPGA2CPU_ONLY | 1 | Only for the data received from FPGA |
| USE_DRAM_CPU2FPGA_AND_FPGA2CPU | 2 | For both, the memory is divided equally |

## What changes in your module

Nothing. Your module sees the same FIFO ports whatever mode the CPU chooses,
the data path interface hides the DRAM. Keep in mind that the 512MB of DRAM is
shared by all the applications and each application can hold only one
allocation at a time. If you send a lot of data, check `rd_app_fifo_prog_full`
before writing.

## CPU side

```c
rah_dram_set_usecase(APP_ID, USE_DRAM_CPU2FPGA_AND_FPGA2CPU);
rah_dram_set_mode(APP_ID, HYBRID_DRAM);

if (rah_dram_memory_alloc(APP_ID, 10 * 1024 * 1024) < 0) {
    printf("memory allocation failed\n");
    return -1;
}

/* rah_write and rah_read as usual */

rah_dram_memory_free(APP_ID);
```

The full API is in the [CPU usage guide](cpu-usage-guide.md).

## Hardware

Everything needed for the DRAM path is already in top.v, rah.xml and
rah.peri.xml of this repository: `axi_clk`, `PllLocked`, the `DdrCtrl_*_1`
ports, `rtl/mem_ctrl` and the FIFO IPs in `ip/`.
