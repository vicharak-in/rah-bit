#!/usr/bin/python3

import pyrah

APPID = 1
def concatenate_bytes(byte_obj1, byte_obj2):
    concatenated_bytes = byte_obj1 + byte_obj2
    return concatenated_bytes

def input_data_and_mode():
    print("Select the mode:")
    print("1. Add")
    print("2. Shift")
    print("3. Mult")
    print("4. All")
    print("5. Exit")

    # Get user's choice
    choice = int(input("Enter the number corresponding to the function (1-4): "))

    # Ensure the user enters a valid choice
    if choice not in [1, 2, 3, 4, 5]:
        print("Invalid choice. Please select a number between 1 and 5")
    elif choice == 5:
        exit()
    else:
        # Ask for the angle in degrees for choices 1 and 2
            input1 = int(input("Enter the first input for calculations "))
            input2 = int(input("Enter the second input for calculations "))
            byte_1 = int_to_hex(input1)
            byte_2 = int_to_hex(input2)
            concatenated_result = concatenate_bytes(byte_1, byte_2)
            transfer_data(concatenated_result,choice)
    return choice

def int_to_hex(input_value):
    # Convert the integer to a hex string and remove the '0x' prefix
    hex_value = hex(input_value)  # Strip '0x' prefix
    hex_value = hex_value.lstrip('0x')

    # Ensure the hex string has an even length (pad with '0' if necessary)
    if len(hex_value) % 2 != 0:

        hex_value = '0' + hex_value

    # Convert the hex string into bytes
    byte_data = bytes.fromhex(hex_value)

    # Pad or trim to ensure it's exactly 6 bytes
    if len(byte_data) < 6:
        # Pad with zero bytes (b'\x00') if less than 6 bytes
        byte_data = byte_data.rjust(6, b'\x00')
    elif len(byte_data) > 6:
        # Trim extra bytes if greater than 6 bytes
        byte_data = byte_data[:6]
    return byte_data


def transfer_data(data_in,appid):

    if appid not in [1, 2, 3]:
        pyrah.rah_write(1,data_in)
        pyrah.rah_write(2,data_in)
        pyrah.rah_write(3,data_in)
    else :
        pyrah.rah_write(appid,data_in)

def receive_data():
    while True:
        choice = input_data_and_mode()
        if choice == 4:
            adder_data = pyrah.rah_read(1, 6)
            shift_data = pyrah.rah_read(2, 6)
            mult_data = pyrah.rah_read(3, 12)


            adder_value = int.from_bytes(adder_data, byteorder='big')
            shift_value = int.from_bytes(shift_data, byteorder='big')
            mult_value = int.from_bytes(mult_data, byteorder='big')

            print("Output for the adder is :", adder_value)
            print("Output for the shift is :", shift_value)
            print("Output for the multiplier is:", mult_value)

        elif choice == 3:
            mult_data = pyrah.rah_read(choice,12)
            mult_value = int.from_bytes(mult_data, byteorder='big')
            print("output for multiplier is:",mult_value)
        else:
            received_data = pyrah.rah_read(choice,6)
            decimal_value = int.from_bytes(received_data, byteorder='big')
            if choice == 2:
                print("output for shift is:",decimal_value)
            elif choice == 1:
                print("output for add is:", decimal_value)


if __name__ == "__main__":
    receive_data()

