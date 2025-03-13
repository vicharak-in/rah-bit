#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#include <rah.h>

#define ADD 1
#define SHIFT 2
#define MUL 3

void xprintf(char *data, int len) {
	for (int i = 0; i < len; i++)
		printf("%02x ", data[i]);

	printf("\n");
}

int main(int argc, char *argv[]) {
	/* The example takes 2 inputs of packed 6 bytes and compute the ADD,SHIFT,MULT operations for it, { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06 } and { 0x01, 0x02, 0x03, 0x04, 0x05, 0x06 } for ADD { 0x02, 0x04, 0x06, 0x08, 0x0a, 0x0c } */	
	
	if (argc <= 3) {
		printf("Usage: adder <num1> <num2> ...\n");
		exit(EXIT_FAILURE);
	}

	char message[12] = {0};

	for (int i = 0; i < argc - 1; i++)
		message[i] = (char) strtol(argv[i + 1], NULL, 16);

	rah_write(ADD, message, sizeof(message));
	rah_write(SHIFT, message, sizeof(message));
	rah_write(MUL, message, sizeof(message));

	char add_result[6];
	
	rah_read(ADD, add_result, sizeof(add_result));
	printf("ADD : ");
	xprintf(add_result, sizeof(add_result));
	printf("\n");

	char div_result[6];
	rah_read(SHIFT, div_result, sizeof(div_result));
	printf("SHIFT : ");
	xprintf(div_result, sizeof(div_result));
	printf("\n");

	char mul_result[12];
	rah_read(MUL, mul_result, sizeof(mul_result));
	printf("MULT : ");
	xprintf(mul_result, sizeof(mul_result));
	printf("\n");

	exit(EXIT_SUCCESS);
}
