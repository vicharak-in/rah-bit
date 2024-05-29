#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#include <rah.h>

#define ADD 0
#define SHIFT 1
#define MUL 2

void xprintf(char *data, int len) {
	for (int i = 0; i < len; i++)
		printf("%02x ", data[i]);

	printf("\n");
}

int main(int argc, char *argv[]) {
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
	xprintf(add_result, sizeof(add_result));

	char div_result[6];
	rah_read(SHIFT, div_result, sizeof(div_result));
	xprintf(div_result, sizeof(div_result));

	char mul_result[12];
	rah_read(MUL, mul_result, sizeof(mul_result));
	xprintf(mul_result, sizeof(mul_result));

	exit(EXIT_SUCCESS);
}
