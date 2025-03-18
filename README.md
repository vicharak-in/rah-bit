# FIXED POINT - FLOAT POINT & FLOAT POINT - FIXED POINT

## Overview
This provides conversion between fixed-point and floating-point numbers. The system supports multiple data sizes and allows bidirectional conversion.

## Applications
There are two main applications:
1. **Fixed to Float Conversion**
2. **Float to Fixed Conversion**

Each application supports the following sizes:
- Floating Point: 32-bit, 64-bit, 80-bit
- Fixed Point (Integer & Fraction): 16-bit, 32-bit, 40-bit

## Data Frame Structure

![Image](https://github.com/user-attachments/assets/0a881d9f-c4c1-47dd-b954-d14562d0f94e)

### FIXED to FLOAT
Converts a fixed-point integer and fraction into a floating-point value.

#### Input/Output Formats
1. **SIZE 1**
   - **Input:** 2 bytes (integer & fraction)
   - **Output:** 4 bytes (floating point)
   - **First byte for application selection and size:** First packet: `88`

   Input packet :-
   
   ![Image](https://github.com/user-attachments/assets/3c45c899-25f4-4b22-9021-b347b3b38900)

   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/b52aaf41-128e-44d1-88ee-c19f7261c2d3)

   ![Image](https://github.com/user-attachments/assets/14d3f224-29cf-4a4c-a71d-c3714a565086)
   
2. **SIZE 2**
   - **Input:** 4 bytes (integer & fraction)
   - **Output:** 8 bytes (floating point)
   - **First byte for application selection and size:** First packet: `91`, Second packet: `92`

   Input packet :-

   ![Image](https://github.com/user-attachments/assets/bdc8e910-47da-40d3-8c82-9ce5f4a51ab9)

   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/6c40116e-fed5-43fb-822b-e1f6564fbf3a)

   ![Image](https://github.com/user-attachments/assets/079bbfb1-a16d-4961-b879-1f064e780e76)

3. **SIZE 3**
   - **Input:** 5 bytes (integer & fraction)
   - **Output:** 10 bytes (floating point)
   - **First byte for application selection and size:** First packet: `99`, Second packet: `9A`
  
   Input packet :-
   
   ![Image](https://github.com/user-attachments/assets/0383cc85-d567-450d-93b6-fed7c8b14b1c)

   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/976e29c7-f8a8-478b-ae63-42a03b1df3b5)

   ![Image](https://github.com/user-attachments/assets/0b915752-8bc3-4e3a-926e-029b607edf15)

---

### FLOAT to FIXED
Converts a floating-point value into an integer and fraction.

#### Input/Output Formats
1. **SIZE 1**
   - **Input:** 4 bytes (floating point)
   - **Output:** 2 bytes (integer & fraction)
   - **First byte for application selection and size:** First packet: `48`

   Input packet :-
   
   ![Image](https://github.com/user-attachments/assets/b52aaf41-128e-44d1-88ee-c19f7261c2d3)

   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/3c45c899-25f4-4b22-9021-b347b3b38900)

   ![Image](https://github.com/user-attachments/assets/d1e82d0f-31cb-4f1c-be79-38d673fa061b)
   
2. **SIZE 2**
   - **Input:** 8 bytes (floating point)
   - **Output:** 4 bytes (integer & fraction)
   - **First byte for application selection and size:** First packet: `51`, Second packet: `52`

   Input packet :-
   
   ![Image](https://github.com/user-attachments/assets/72fa2b6f-3991-4b8d-b151-5e3eeb4ef4db)

   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/bdc8e910-47da-40d3-8c82-9ce5f4a51ab9)

   ![Image](https://github.com/user-attachments/assets/0a9d2100-4001-4cd0-9cb7-ca127a3e488a)

3. **SIZE 3**
   - **Input:** 10 bytes (floating point)
   - **Output:** 5 bytes (integer & fraction)
   - **First byte for application selection and size:** First packet: `59`, Second packet: `5A`

   Input packet :-
   
   ![Image](https://github.com/user-attachments/assets/976e29c7-f8a8-478b-ae63-42a03b1df3b5)
   
   Ouput packet :-

   ![Image](https://github.com/user-attachments/assets/0383cc85-d567-450d-93b6-fed7c8b14b1c)

   ![Image](https://github.com/user-attachments/assets/62044824-aa41-40c8-874b-a08a0eb24bdb)

---

## How to Use
### Setup Instructions
1. Open a terminal and clone the repository:
   ```sh
   git clone https://github.com/neel147063/float_to_fix.git
   ```
2. Flash the bitstream using **Efinity** on the **Vaman Board**.
3. Open a new terminal and connect to the board via SSH:
   ```sh
   ssh vicharak@neelv.local
   ssh vicharak@192.168.0.45
   ```
4. Install **PyRah** and **RahComm** on the board:

   for pyrah
   ```sh
   git clone https://github.com/vicharak-in/pyrah
   sudo python3 setup.py install
   ```
   
   for rahcomm
   ```sh
   git clone https://github.com/vicharak-in/rahcomm
   cd rahcomm
   sudo python3 setup.py install
   ```
   
6. Start communication using:
   ```sh
   sudo rahcomm -appid 1
   ```
7. Send packets using Rah Write.

---
