# CPU API usage Guide

## User Guide

For the usage of the Rah, Use shared library i.e. librah.
Call rah_write and rah_read function to send and receive data from the
FPGA respectively. If you do not want to wait for the data, use rah_read_nb
instead. There are also APIs to reserve the FPGA side DRAM for your
application, they are described at the end of this guide.

All the APIs need root permission, so run your application as root.

## Sending data

**int rah_write**(const **uint8_t** appid, const **char*** message,
const **unsigned long** len);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |
| message	| The message to send |
| len		| The length of the message |

</div>

Here is the quick demo of the **rah_write**,
```C
#include <rah.h>
#define APP_ID 3

int main(void) {
	rah_write(APP_ID, "Hello!", 6);
}
```

For more fined grained access over the memory pointer, below APIs can be used,
follow the mentioned steps:

1. **void \*rah_request_mem**(const **uint8_t** appid,
const **unsigned long** len);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |
| len		| The length of the message |

</div>

It will provide a memory location, now it can be accessed by the
applications to copy data into this provided location. It returns NULL if
len is zero or bigger than the value of **rah_max_buffer_size**.

2. **int rah_write_mem**(const **uint8_t** appid, **void*** ptr,
const **unsigned long** len);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |
| ptr		| Allocated buffer from the request |
| len		| The length of the message |

</div>

Copy the data into ptr and then call this API, to send the message to FPGA.

3. **void rah_free_mem**(**void*** ptr);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| ptr		| Allocated buffer from the request |

</div>

Call this once you send all of your data.

```C
#include <string.h>
#include <rah.h>
#define APP_ID 3

int main(void) {
	const char *message = "Hello World!";
	char *ptr = rah_request_mem(APP_ID, strlen(message));
	memcpy(ptr, message, strlen(message));
	rah_write_mem(APP_ID, ptr, strlen(message));
	rah_free_mem(ptr);
}
```

**unsigned long rah_max_buffer_size**(void);

It returns the maximum number of bytes that can be sent with one call of
**rah_request_mem** and **rah_write_mem**. If you want to send more then
split the data into multiple packets and send the same. Note that
**rah_write** does this splitting for you.

## Receiving data

**int rah_read**(const **uint8_t** appid, **char*** message,
const **unsigned long** len);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |
| message	| Pointer of receiving message |
| len		| Number of bytes to get |

</div>

It blocks until len bytes are received from the FPGA. Here is the quick demo
of the **rah_read**,
```C
#include <rah.h>
#define APP_ID 3

int main(void) {
	char message[6];
	rah_read(APP_ID, message, 6);
}
```

**int rah_read_nb**(const **uint8_t** appid, **char*** message,
const **unsigned long** len);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |
| message	| Pointer of receiving message |
| len		| Maximum number of bytes to get |

</div>

This is the non blocking version of the **rah_read**. It returns right away
with the number of bytes copied into message, which can be less than len. If
nothing has been received yet it returns 0.

```C
#include <rah.h>
#define APP_ID 3

int main(void) {
	char message[6];
	int got = 0;

	while (got < 6) {
		int n = rah_read_nb(APP_ID, message + got, 6 - got);
		if (n > 0)
			got += n;
		/* do some other work here while the data is on its way */
	}
}
```

**int rah_clear_buffer**(const **uint8_t** appid);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |

</div>

Throw away the data received for `appid` which is not read yet.

## Version check

**int rah_check_version_compatible**(void);

It checks whether the version of the FPGA design works with the installed
rah. It returns a non zero value if it is compatible and 0 if it is not.
On error it returns -1.

```C
#include <stdio.h>
#include <rah.h>

int main(void) {
	if (!rah_check_version_compatible())
		printf("Please update the FPGA design or the rah service\n");
}
```

## DRAM control

The FPGA can keep the data of an application in its DRAM instead of
only using the small on chip queues. The below APIs let you choose how the
DRAM is used by each application. All of them return -1 on failure.

The mode decides if and how the DRAM is used,

<div align="center">

| Mode 		| Meaning |
| :-------: | :---: |
| NO_DRAM		| DRAM is not used for the data transfer |
| DIRECT_DRAM	| Data is directly stored into the DRAM |
| HYBRID_DRAM	| DRAM is used along with the on chip queues |

</div>

The usecase decides in which direction the DRAM is used,

<div align="center">

| Usecase 	| Meaning |
| :-------: | :---: |
| USE_DRAM_CPU2FPGA_ONLY			| Only for the data sent to FPGA |
| USE_DRAM_FPGA2CPU_ONLY			| Only for the data received from FPGA |
| USE_DRAM_CPU2FPGA_AND_FPGA2CPU	| For both, the memory is divided equally |

</div>

**int rah_dram_set_mode**(const **uint8_t** appid, const **uint8_t** mode);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |
| mode		| One of the modes from above table |

</div>

**int rah_dram_set_usecase**(const **uint8_t** appid,
const **uint8_t** usecase);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |
| usecase	| One of the usecases from above table |

</div>

**int rah_dram_get_usecase**(const **uint8_t** appid, **uint8_t*** usecase);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |
| usecase	| Pointer to store the current usecase |

</div>

**int rah_dram_memory_alloc**(const **uint8_t** appid, const **int** len);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |
| len		| Size of the DRAM to reserve in bytes |

</div>

Reserves len bytes of the DRAM for the application and returns len on
success. Set the usecase and the mode before calling this, because the
usecase decides how the reserved memory is divided. Total DRAM available is
512MB, shared by all the applications. An application can hold only one
allocation at a time, so free it first if you want a different size.

**int rah_dram_memory_free**(const **uint8_t** appid);

<div align="center">

| Field 	| Value |
| :-------: | :---: |
| appid		| The ID of running application on FPGA |

</div>

Gives the reserved DRAM of the application back.

Here is a demo which reserves 10MB for an application, using the DRAM in both
directions (5MB each),
```C
#include <stdio.h>
#include <rah.h>
#define APP_ID 3

int main(void) {
	rah_dram_set_usecase(APP_ID, USE_DRAM_CPU2FPGA_AND_FPGA2CPU);
	rah_dram_set_mode(APP_ID, HYBRID_DRAM);

	if (rah_dram_memory_alloc(APP_ID, 10 * 1024 * 1024) < 0) {
		printf("memory allocation failed\n");
		return -1;
	}

	/* send and receive the data as usual */

	rah_dram_memory_free(APP_ID);
}
```

### Installing and Running

```
gcc filename.c -lrah
./a.out
```

For more details, please refer to the given example.
