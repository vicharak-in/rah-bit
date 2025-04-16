# FIXED-POINT TO FLOATING-POINT & FLOATING-POINT TO FIXED-POINT CONVERSION

## Overview
This document describes the conversion process between fixed-point and floating-point representations. The system supports various data sizes and facilitates bidirectional conversion.

## Applications
There are two primary applications:
1. **Fixed to Floating-Point Conversion**
2. **Floating-Point to Fixed Conversion**

Each application supports the following sizes:
- **Floating-Point Sizes:** 32-bit, 64-bit, 80-bit
- **Fixed-Point Sizes (Integer & Fraction):** 16-bit, 32-bit, 40-bit

## Data Frame Structure

### Packet Format

![Image](https://github.com/user-attachments/assets/0a881d9f-c4c1-47dd-b954-d14562d0f94e)

- **1st Byte:** Application (2 bits), Size (3 bits), Packet (3 bits)
  - Application: 1 (Floating-Point to Fixed), 2 (Fixed to Floating-Point)
  - Size:  
    - 1 (2 bytes integer & fraction, 4 bytes floating-point)
    - 2 (4 bytes integer & fraction, 8 bytes floating-point)
    - 3 (5 bytes integer & fraction, 10 bytes floating-point)
  - Packet: Packet 1, Packet 2
- **2nd - 5th Byte:** Input Data (Integer, Fraction, Floating-Point)

---

## Fixed-Point to Floating-Point Conversion
This conversion transforms a fixed-point integer and fraction into a floating-point representation.

### Input/Output Formats

#### **Size 1**

   Input packet :-
   
   ![Image](https://github.com/user-attachments/assets/3c45c899-25f4-4b22-9021-b347b3b38900)

   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/b52aaf41-128e-44d1-88ee-c19f7261c2d3)

- **Application Selection, Size & Packet:** First packet: `88`
  - Application: `2 (2'b10)`
  - Size: `1 (3'b001)`
  - Packet: `0 (3'b000)`
- **Input:** 2 bytes (integer & fraction)
  - Data: 2 bytes (integer), 2 bytes (fraction), 1 byte (reserved)
- **Output:** 4 bytes (floating point)
  - Data: 4 bytes (floating point), 1 byte (reserved)

  
##### Example

**Input Details**  
- **Decimal Value:** `28.6528`  
- **Integer Part:** `28` → Hex: `00 1c`  
- **Fractional Part:** `0.6528` → Hex: `a7 90`

The input data is structured as follows:
```sh
Input  packet: 88 00 1c a7 90 00 
```
- `88` → Header/Identifier(application,size & packet)  
- `00 1c` → Integer representation (`28`)  
- `a7 90` → Fractional representation (`0.6528`)  
- `00` → **Reserved**

The output data packet is structured as follows:
```sh
Output Packet: 88 41 E5 3C 80 00
```
- `88` → Header/Identifier(application,size & packet) 
- `41 e5 3c 80` → Floating-point representation of `28.6528`  
- `00` → **Reserved**

#### **Size 2**

   Input packet :-

   ![Image](https://github.com/user-attachments/assets/bdc8e910-47da-40d3-8c82-9ce5f4a51ab9)

   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/6c40116e-fed5-43fb-822b-e1f6564fbf3a)

- **Application Selection, Size & Packet:**
  - First packet: `91`, Second packet: `92`
  - Application: `2 (2'b10)`
  - Size: `2 (3'b010)`
  - Packet: `1,2 (3'b001, 3'b010)`
- **Input:** 4 bytes (integer & fraction)
  - Data Packet 1: 4 bytes (integer), 1 byte (reserved)
  - Data Packet 2: 4 bytes (fraction), 1 byte (reserved)
- **Output:** 8 bytes (floating point)
  - Data Packet 1: 5 bytes (floating point)
  - Data Packet 2: 3 bytes (floating point), 1 byte (reserved)
  
##### Example

```sh
Input  packet1: 91 00 00 00 1c 00
Input  packet2: 92 a7 90 00 00 00
Output packet1: 91 40 3c a7 90 00 
Output packet2: 92 00 00 00 00 00
```

#### **Size 3**

   Input packet :-
   
   ![Image](https://github.com/user-attachments/assets/0383cc85-d567-450d-93b6-fed7c8b14b1c)

   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/976e29c7-f8a8-478b-ae63-42a03b1df3b5)

- **Application Selection, Size & Packet:**
  - First packet: `99`, Second packet: `9a`
  - Application: `2 (2'b10)`
  - Size: `3 (3'b011)`
  - Packet: `1,2 (3'b001, 3'b010)`
- **Input:** 5 bytes (integer & fraction)
  - Data Packet 1: 5 bytes (integer)
  - Data Packet 2: 5 bytes (fraction)
- **Output:** 10 bytes (floating point)
  - Data Packet 1: 5 bytes (floating point)
  - Data Packet 2: 5 bytes (floating point)

##### Example

```sh
Input  packet1: 99 00 00 00 00 1C
Input  packet2: 9a a7 90 00 00 00
Output packet1: 99 40 03 ca 79 00
Output packet2: 9a 00 00 00 00 00
```

---

## Floating-Point to Fixed-Point Conversion
This conversion transforms a floating-point number into its fixed-point integer and fraction components.

### Input/Output Formats

#### **Size 1**
    
   Input packet :-
   
   ![Image](https://github.com/user-attachments/assets/b52aaf41-128e-44d1-88ee-c19f7261c2d3)

   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/3c45c899-25f4-4b22-9021-b347b3b38900)
    
- **Application Selection, Size & Packet:** First packet: `48`
  - Application: `1 (2'b01)`
  - Size: `1 (3'b001)`
  - Packet: `0 (3'b000)`
- **Input:** 4 bytes (floating point)
  - Data: 4 bytes (floating point), 1 byte (reserved)
- **Output:** 2 bytes (integer & fraction)
  - Data: 2 bytes (integer), 2 bytes (fraction), 1 byte (reserved)

##### Example

**Input Details**  
- **Floation-point hex value:** `41 e5 3c 80`  

The input data is structured as follows:
```sh
Input  packet: 48 41 e5 3c 80 00
```
- `48` → Header/Identifier(application,size & packet)  
- `41 E5 3C 80` → Floating-point representation of `28.6528`  
- `00` → **Reserved**

The output data packet is structured as follows:
  
```sh
Output packet: 48 00 1c a7 90 00
```

- `48` → Header/Identifir(application,size & packet) 
- Integer Part: `00 1c` → Decimal: `28`  
- Fractional Part: `a7 90` → Decimal: `0.6528`  
- `00` → **Reserved**

#### **Size 2**
    
   Input packet :-
   
   ![Image](https://github.com/user-attachments/assets/6c40116e-fed5-43fb-822b-e1f6564fbf3a)

   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/bdc8e910-47da-40d3-8c82-9ce5f4a51ab9)
    
- **Application Selection, Size & Packet:**
  - First packet: `51`, Second packet: `52`
  - Application: `1 (2'b01)`
  - Size: `2 (3'b010)`
  - Packet: `1,2 (3'b001, 3'b010)`
- **Input:** 8 bytes (floating point)
  - Data Packet 1: 5 bytes (floating point)
  - Data Packet 2: 3 bytes (floating point), 2 bytes (reserved)
- **Output:** 4 bytes (integer & fraction)
  - Data Packet 1: 4 bytes (integer), 1 byte (reserved)
  - Data Packet 2: 4 bytes (fraction), 1 byte (reserved)

##### Example

```sh
Input  packet1: 51 40 3c a7 90 00
Input  packet2: 52 00 00 00 00 00
Output packet1: 51 00 00 00 1c 00
Output packet2: 52 a7 90 00 00 00 
```

#### **Size 3**

   Input packet :-
   
   ![Image](https://github.com/user-attachments/assets/976e29c7-f8a8-478b-ae63-42a03b1df3b5)
   
   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/0383cc85-d567-450d-93b6-fed7c8b14b1c)

- **Application Selection, Size & Packet:**
  - First packet: `59`, Second packet: `5a`
  - Application: `1 (2'b01)`
  - Size: `3 (3'b011)`
  - Packet: `1,2 (3'b001, 3'b010)`
- **Input:** 10 bytes (floating point)
  - Data Packet 1: 5 bytes (floating point)
  - Data Packet 2: 5 bytes (floating point)
- **Output:** 4 bytes (integer & fraction)
  - Data Packet 1: 5 bytes (integer)
  - Data Packet 2: 5 bytes (fraction)

##### Example

```sh
Input  packet1: 59 40 03 ca 79 00
Input  packet2: 5a 00 00 00 00 00
Output packet1: 59 00 00 00 00 1C
Output packet2: 5a a7 90 00 00 00 
```


