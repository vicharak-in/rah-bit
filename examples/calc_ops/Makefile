CFLAGS += -Wall
LDFLAGS += -lrah -lpthread
CC = gcc

SRC_DIR = src
OUT_DIR = bin

SOURCES = $(wildcard $(SRC_DIR)/*.c)
BINS = $(patsubst $(SRC_DIR)/%.c, $(OUT_DIR)/%, $(SOURCES))
$(info $(BINS))

.PHONY: all bin clean

all: dir_check bin

bin: $(BINS)

dir_check:
	if [ ! -d "$(OUT_DIR)" ]; then mkdir $(OUT_DIR); fi

$(OUT_DIR)/%: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

clean:
	rm -f bin/*
