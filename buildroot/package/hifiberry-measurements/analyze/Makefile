CC = gcc
# for RPi2 Arm A7/NEON
CFLAGS  = -mtune=cortex-a7 -mfpu=neon -mfloat-abi=hard -marm -O3 -Wall
LD = ld
LDFLAGS = -lm
all: bin


OBJ = analyze.o
BIN = analyze

bin: $(OBJ)
	$(CC) $(CFLAGS) -o $(BIN) $(OBJ) $(LDFLAGS)

%.o: %.c %.h
	$(CC) $(CFLAGS) -c $<

.PHONY: clean
clean:
	rm -rf $(BIN) *.o
