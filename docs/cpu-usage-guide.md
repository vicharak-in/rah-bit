# CPU API usage Guide

## User Guide

For the usage of the Rah, Use shared library i.e. librah.
Call rah_write and rah_read function to send and receive data from the
FPGA respectively.

---

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

---

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

It will provide the memory location kinf of mmap, now it can be accessed by the
applications to copy data into this provided location.

2. **void rah_write_mem**(const **uint8_t** appid, **void*** ptr,
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

> [!NOTE]
>
> It can send at max 100663278 bytes at once, if you want to send more then split the data into multiple packets and send the same.

---

**int rah_read**(const **uint8_t** appid, **char*** message,
const **unsigned long** len);

<div align="center">

| Field 	| Value |
| :-------: | :---: | 
| appid		| The ID of running application on FPGA |
| message	| Pointer of receiving message |
| len		| Number of bytes to get |

</div>

Here is the quick demo of the **rah_read**, 
```C
#include <rah.h>
#define APP_ID 3

int main(void) {
	char message[6];
	rah_read(APP_ID, message, 6);
}
```

### Installing and Running

```
gcc filename.c -lrah
./a.out
```
