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

---

**int rah_clear_buffer**(const **uint8_t** appid);

<div align="center">

| Field 	| Value |
| :-------: | :---: | 
| appid		| The ID of running application on FPGA |

</div>

Clear file buffer for `appid`. This is the file that receives incoming
data from the FPGA. You can inspect it at location `/tmp/(<appid> + 3)`.

---

### Installing and Running

```
gcc filename.c -lrah
./a.out
```

For more details, please refer to the given example.



# Pyrah: Python Wrapper for RAH Protocol

The Pyrah library provides a Python wrapper for the RAH protocol, simplifying communication with an FPGA. With Pyrah, you can easily interact with the FPGA using Python, making tasks such as writing and reading data to/from the FPGA more accessible.

## Installation

To install the Pyrah library, follow these steps:

1. Clone the repository:

    ```bash
    git clone https://github.com/vicharak-in/pyrah
    ```

2. Navigate into the `pyrah` directory:

    ```bash
    cd pyrah
    ```

3. Install the package:

    ```bash
    sudo python3 setup.py install
    ```

## Usage

Once installed, you can use the Pyrah library to communicate with the FPGA. Below is an example Python code demonstrating how to interact with the FPGA.

### Example Python Code:

```python
import pyrah

APPID = 3

# Write a message to the FPGA
pyrah.rah_write(APPID, b"Hello World!")

# Read data from the FPGA
data = pyrah.rah_read(APPID, 10)  # Here 10 is the length of data we need
print(data)
```
### Functions:

- **`rah_write(APPID, data)`**  
  Sends a message to the FPGA using the specified `APPID`.
  
- **`rah_read(APPID, length)`**  
  Reads the specified number of bytes from the FPGA. The `length` parameter defines how many bytes of data should be read.

## Additional Resources

- **[Pyrah](https://github.com/vicharak-in/pyrah)**  
  Access the source code and additional documentation.

- **[Rahcomm](https://github.com/vicharak-in/rahcomm)**   
  A wrapper for Pyrah that enables seamless data communication with RAH.
 
This documentation outlines how to use the Pyrah library to facilitate CPU-FPGA communication in Python.

