#include <stdio.h>
#include <pthread.h>
#include <fcntl.h>

#include <rah.h>

#define RAH2UART 0

void *rd_thread(void *arg) {
	char rd_data[6] = {0};
	int ret = 0;

	while(1) {
		rah_read(RAH2UART, rd_data, 6);
		printf("%c", rd_data[5]);
		fflush(stdout);
	}
}

int main(void) {
	char wr_data[6] = {0};
	pthread_t tid;

	rah_clear_buffer(RAH2UART);
	pthread_create(&tid, NULL, rd_thread, NULL);

	while(1) {
		scanf("%c", &wr_data[5]);
		rah_write(RAH2UART, wr_data, 6);
	}

	pthread_cancel(tid);
	return 0;
}
